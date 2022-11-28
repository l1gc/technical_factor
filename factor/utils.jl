import LinearAlgebra as la
import NaNStatistics as nast
import StatsBase as st

function lag(x::AbstractArray,n::Int)
    """
    返回向量x的n阶滞后
    """
    if n==0
        return x
    end

    if n<0
        return lead(x,-n)
    end

    a = fill(NaN, (n,size(x,2)) )
    return vcat(a, x[1:end-n,:])
end

function lead(x::AbstractArray,n::Int)
    """
    返回向量x的n阶前置
    """
    if n==0
        return x
    end

    if n<0
        return lag(x,-n)
    end

    a = fill(NaN, (n,size(x,2)) )
    return vcat(x[1+n:end,:], a)
end

function rolling_sum(ret::Union{VecOrMat,Array,SubArray},sample_period::Int)
    """
    ret: 待计算的向量
    sample_period: 样本期
    """
    ret = ret[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))

    for i in sample_period:rows
        res[i] = nast.nansum(ret[(i-sample_period+1) : i])
    end

    return res[:]

end

function rolling_mean(ret::Union{VecOrMat,Array,SubArray},sample_period::Int)
    """
    ret: 待计算的向量
    sample_period: 样本期
    """
    ret = ret[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))

    for i in sample_period:rows
        res[i] = nast.nanmean(ret[(i-sample_period+1) : i])
    end

    return res[:]

end

function rolling_std(ret::Union{VecOrMat,Array,SubArray},sample_period::Int)
    """
    ret: 待计算的向量
    sample_period: 样本期
    """
    ret = ret[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))

    for i in sample_period:rows
        res[i] = nast.nanstd(ret[(i-sample_period+1) : i])
    end

    return res[:]

end


function mmt_naive(price::Union{VecOrMat,Array,SubArray},sample_period::Int)
    """
    计算简单动量,计算结果为收益率加1
    对于超过21天的动量,计算时减去21天内的动量

    price: 待计算的价格向量
    sample_period: 样本期
    """
    price = price[:]
    rows = size(price, 1)
    res = fill(NaN, (rows, 1))

    if rows<sample_period
        return res
    end

    if sample_period <= 21
        for i in (sample_period+1):rows
            res[i] = 1 + (price[i]-price[i-sample_period]) / price[i-sample_period]
        end
    else
        for i in (sample_period+1):rows
            res[i] = 1 + ((price[i]-price[i-sample_period]) / price[i-sample_period] - (price[i]-price[i-21]) / price[i-21])
        end
    end

    return res[:]
end

function max_drawdown(port_v::Union{VecOrMat,Array,SubArray})
    """
    port_v: 资产价值向量
    """
    sample_len = length(port_v)
    res = zeros(sample_len,1)
    max_port_fn = port_v[1] # maximize portfolio value for now
    max_dd = 0
    res[1] = max_dd

    for i in 2:sample_len
        if port_v[i] < max_port_fn
            dd_i = (port_v[i]-max_port_fn) / max_port_fn
        else
            dd_i = 0
            max_port_fn = port_v[i]
        end

        if dd_i < max_dd
            max_dd = dd_i
        end
        res[i] = max_dd

    end

    return res
end

function sortino_ratio(ret::Union{VecOrMat,Array,SubArray},rf::Union{VecOrMat,Array,SubArray})
    if rf===nothing
        ret_down = ret[findall(ret .< 0)]
        return st.mean((ret)) / st.std((ret_down))
    else
        ret_down = ret[findall(ret .< rf)]
        return st.mean((ret - rf)) / st.std((ret_down-rf))
    end
end

function sharpe_raio(ret::Union{VecOrMat,Array,SubArray},rf::Union{VecOrMat,Array,SubArray})
    if rf===nothing
        return st.mean((ret)) / st.std((ret))
    else
        return st.mean((ret-rf)) / st.std((ret-rf))
    end
end

function calc_ret(v::Union{VecOrMat,Array,SubArray})
    dates = size(v,1)
    res = zeros(dates,1)
    for i in 2:dates
        res[i] = (v[i]-v[i-1])/v[i-1]
    end
    return res[:]
end

function calc_cos_sim(v::Union{VecOrMat,Array,SubArray})
    v = reduce(hcat,v)
    v = 1 * v'

    m = size(v,1)
    t = size(v,2)
    ret = zeros(m,t)
    cos_sim = zeros(t,1)
    
    for i in 1:m
        ret[i,:] .= calc_ret(v[i,:])
    end
    
    for i in 2:t
        cos_sim[i,1] = la.dot(ret[:,i-1],ret[:,i]) / (la.norm(ret[:,i-1]) * la.norm(ret[:,i]))
    end

    cos_sim = replace(cos_sim,NaN => 0)

    return cos_sim[:]
end

function backtest(is_rebalance::Union{VecOrMat,Array,SubArray,BitVector}, returns::Union{VecOrMat,Array,SubArray}, target_weight::Union{VecOrMat,Array,SubArray}, inital_capital::Float64, commission_fee::Float64)

    # is_rebalance: t*1的01调仓向量;0代表不调仓
    # returns: t*k的个股收益率矩阵, t日收益率=(t日收盘价-t-1日收盘价)/t-1日收盘价
    # target_weight: t*k的目标权重矩阵;t行代表调仓日t的个股资产权重目标;调仓日外均为0
    # inital_capital: 回测初始资金

    dates = size(target_weight, 2); # dates为回测期间交易日总数
    k = size(target_weight, 1); # k为回测期间个股数

    # 初始化输出矩阵
    position = zeros(k, dates); # 每日交易前个股资产头寸
    weight = zeros(k, dates); # 每日交易后个股头寸占总资产权重
    commission = zeros(k, dates); # 每日交易成本

    # 初始化个股头寸
    if is_rebalance[1]==1
        position[:, 1] = inital_capital * target_weight[:, 1]
        weight[:, 1] = target_weight[:, 1]
        commission[:, 1] = position[:, 1] * commission_fee
    else
        position[:, 1] = repeat([inital_capital / k], k, 1)
        weight[:, 1] = repeat([1 / k], k, 1)
        commission[:, 1] = position[:, 1] * commission_fee
    end

    for t in 2:dates

        if is_rebalance[t]==1
            position[:, t] = position[:, t-1] .* returns[:, t]; # t日调仓前个股资产头寸
            position[:, t] = sum(position[:, t]) * target_weight[:, t]; # 调仓
            weight[:, t] = target_weight[:, t]; # 更新头寸权重
            commission[:, t] = abs.(position[:, t] - position[:, t-1]) * commission_fee; # 计算调仓成本
            position[:, t] = position[:, t] - commission[:, t]; # 调仓完成后个股头寸
        else
            position[:, t] = position[:, t-1] .* returns[:, t]
            weight[:, t] = position[:, t] ./ sum(position[:, t])
            commission[:, t] = repeat([0.0], k, 1)
        end

    end

    portfolio_value = sum(position,dims=1); # 计算t*1的组合头寸

    return [position, weight, commission, portfolio_value]
end


function qcut(x::Union{VecOrMat,Array,SubArray}, n::Int)
    """
    x: 待处理的向量
    p: 分位数,例如五分位 range(0,1,step=1/n)[2:end-1]
    """
    # @assert issorted(p)
    if count(isnan, x) == length(x)
        return x
    end

    nan_idx = findall(isnan, x)

    x = replace(x, NaN => missing)
    q = st.quantile(skipmissing(x), range(0, 1, step=1 / n)[2:end-1])

    res = 1.0 * searchsortedfirst.(Ref(q), x)
    res[nan_idx] .= NaN
    return res
end

function group_weight(x::Union{VecOrMat,Array,SubArray}, n::Int)
    """
    x: 因子
    n: 分为n组
    """
    weight = (x .== n)
    weight = weight / sum(weight)
    return weight
end

function group_backtest(ret::Union{VecOrMat,Array,SubArray}, weight::Union{VecOrMat,Array,SubArray}, init_cap::Float64, commission_fee::Float64, reb::Int64)
    """
    通过调用backtest函数对每组进行回测

    ret: n*t的收益率矩阵,n行t列的元素代表以t-1日均价买入t日均价卖出资产n的收益率
    weight: n*t的权重矩阵,代表t日收盘后依据更新数据计算出的将于t+1日再平衡时的目标权重,因此需整体取一阶滞后
    init_cap: 初始资本
    commission_fee: 交易成本
    reb: 再平衡周期
    """

    k = size(ret, 1) # k代表k个风险资产
    t = size(ret, 2) # t代表样本期长度
    ret = [ret; ones(1, size(ret, 2))]

    is_rebalance = range(1, t, step=1)
    is_rebalance = (mod.(is_rebalance, reb) .== 0)
    is_rebalance[1] = 1 # 第一天总是调仓

    # 计算资产权重
    cash_weight = 1 .- sum(weight, dims=1)
    weight = [weight; cash_weight]
    weight = [zeros(k + 1, 1) weight]
    weight = weight[:, 1:end-1]
    weight[end, 1] = 1

    position, w, commission, portfolio_value = backtest(is_rebalance, ret, weight, init_cap, commission_fee)
    return portfolio_value[:]
end

