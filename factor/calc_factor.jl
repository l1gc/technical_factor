import LinearAlgebra as la
import NaNStatistics as nast
import StatsBase as st




######################################################################
## momentum part
######################################################################
function mmt_relative(ret::Union{VecOrMat,Array,SubArray}, sample_period::Int, time_cycle::Vector)
    """
    ret: 收益率
    sample_period: 样本期
    """

    ret = ret[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))

    if length(ret) <= sample_period
        return res[:]
    end

    if sample_period == time_cycle[1]
        for i in sample_period:rows
            sample_ret = ret[(i-sample_period+1):i]
            res[i] = sample_ret[end] / nast.nanmean(sample_ret)
        end
    else
        for i in sample_period:rows
            sample_ret = ret[(i-sample_period+1):i]
            res[i] = sample_ret[end-time_cycle[1]] / nast.nanmean(sample_ret)
        end
    end

    return res[:]
end


function mmt_amplitude_adjust(ret::Union{VecOrMat,Array,SubArray}, amplitude::Union{VecOrMat,Array,SubArray}, sample_period::Int)
    """
    ret: 收益率
    amplitude: 振幅
    sample_period: 样本期
    """
    if sample_period < 5
        error("sample_period must be larger than 5")
    end

    ret = ret[:]
    amplitude = amplitude[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))
    perc20 = Int(floor(sample_period * 0.2))

    for i in sample_period:rows
        sample_ret = ret[(i-sample_period+1):i, 1]
        sample_amp = amplitude[(i-sample_period+1):i, 1]

        amplitude_perc80 = sort(sample_amp, rev=true)[perc20]
        amplitude_perc20 = sort(sample_amp, rev=false)[perc20]

        high_amp_idx = findall(x -> x >= amplitude_perc80, sample_amp)
        low_amp_idx = findall(x -> x <= amplitude_perc20, sample_amp)

        res[i] = sum(sample_ret[high_amp_idx]) - sum(sample_ret[low_amp_idx])
    end

    return res[:]
end

function mmt_average_adjust(ret::Union{VecOrMat,Array,SubArray}, average::Union{VecOrMat,Array,SubArray}, sample_period::Int)
    """
    ret: 收益率
    average: 均价
    sample_period: 样本期
    """
    if sample_period < 5
        error("sample_period must be larger than 5")
    end

    ret = ret[:]
    average = average[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))
    perc20 = Int(floor(sample_period * 0.2))

    for i in sample_period:rows
        sample_ret = ret[(i-sample_period+1):i, 1]
        sample_amp = average[(i-sample_period+1):i, 1]

        average_perc80 = sort(sample_amp, rev=true)[perc20]
        average_perc20 = sort(sample_amp, rev=false)[perc20]

        high_amp_idx = findall(x -> x >= average_perc80, sample_amp)
        low_amp_idx = findall(x -> x <= average_perc20, sample_amp)

        res[i] = sum(sample_ret[high_amp_idx]) - sum(sample_ret[low_amp_idx])
    end

    return res[:]
end

function mmt_exclude_limit(ret::Union{VecOrMat,Array,SubArray}, is_limit::Union{VecOrMat,Array,SubArray}, sample_period::Int)
    """
    ret: 收益率
    sample_period: 样本期
    """

    ret = ret[:]
    is_limit = reshape(is_limit, :, 1)
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))

    for i in sample_period:rows
        sample_ret = ret[(i-sample_period+1):i, 1]
        sample_limit = is_limit[(i-sample_period+1):i, 1]

        sample_ret = sample_ret .* (1 .- sample_limit) .+ sample_limit
        res[i] = cumprod(sample_ret)[end]
    end

    return res[:]
end

function mmt_infomation_discrete(ret::Union{VecOrMat,Array,SubArray}, sample_period::Int)
    """
    ret: 收益率
    sample_period: 样本期
    """

    ret = ret[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))

    for i in sample_period:rows
        sample_ret = ret[(i-sample_period+1):i, 1]
        up_days = count(x -> x > 1, sample_ret)
        down_days = count(x -> x < 1, sample_ret)
        res[i] = (up_days - down_days) / sample_period
    end

    return res[:]
end

function mmt_time_rank(ret::Union{VecOrMat,Array,SubArray}, sample_period::Int, tracing_period::Int)
    """
    ret: 收益率
    sample_period: 样本期
    """


    ret = ret[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))
    tracing_period_ret_rank = zeros(rows, 1)
    tracing_period_ret_rank = replace(res, 0.0 => NaN)

    if rows < tracing_period
        return res[:]
    end

    for i in tracing_period:rows
        tracing_period_ret = ret[(i-tracing_period+1):i, 1]
        tracing_period_ret_rank[i] = st.denserank(tracing_period_ret, rev=true)[end]
    end

    for i in (tracing_period+sample_period):rows
        sample_rank = tracing_period_ret_rank[(i-sample_period+1):i, 1]
        res[i] = nast.nanmean(sample_rank)
    end

    return res[:]
end

function announ_date(ret::Union{VecOrMat,Array,SubArray}, ann_date::Union{VecOrMat,Array,SubArray})

    ret = ret[:]
    mod_ann_date = ann_date .* .!(isnan.(ret))

    for i in findall(x -> x > 0, ann_date)

        for k in 1:5
            if isnan(ret[i]) & !isnan(ret[i+k])
                mod_ann_date[i+k] = 1
                break
            end
        end

    end

    return mod_ann_date[:]
end

function mmt_pead(ret::Union{VecOrMat,Array,SubArray}, mod_ann_date::Union{VecOrMat,Array,SubArray})
    """
    ret: 收益率
    sample_period: 样本期
    """


    ret = ret[:]
    mod_ann_date = mod_ann_date[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))


    for i in findall(x -> x > 0, mod_ann_date)
        res[i] = cumprod(ret[i-1:i+1])
    end

    return res[:]
end


######################################################################
## volatility part
######################################################################
function vol_up_adjust(ret::Union{VecOrMat,Array,SubArray}, sample_period::Int)
    """
    计算上行波动率
    ret: 收益率
    sample_period: 样本期
    """


    ret = ret[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))


    for i in sample_period:rows
        res[i] = st.std(ret[findall(x -> x > 0, ret)])
    end

    return res[:]
end

function vol_down_adjust(ret::Union{VecOrMat,Array,SubArray}, sample_period::Int)
    """
    计算下行波动率
    ret: 收益率
    sample_period: 样本期
    """


    ret = ret[:]
    rows = size(ret, 1)
    res = fill(NaN, (rows, 1))


    for i in sample_period:rows
        res[i] = st.std(ret[findall(x -> x < 0, ret)])
    end

    return res[:]
end

######################################################################
## liquidity part
######################################################################



######################################################################
## correlation part
######################################################################
function corr_sync(a::Union{VecOrMat,Array,SubArray}, b::Union{VecOrMat,Array,SubArray}, sample_period::Int)
    """
    计算两个变量的同期相关性
    """
    a = a[:]
    b = b[:]
    rows = size(a, 1)
    res = fill(NaN, (rows, 1))

    for i in sample_period:rows
        res[i] = nast.nancor(a[(i-sample_period+1):i], b[(i-sample_period+1):i])
    end

    return res[:]
end

function corr_lead(a::Union{VecOrMat,Array,SubArray}, b::Union{VecOrMat,Array,SubArray}, sample_period::Int, is_a_lead::Int)
    """
    计算两个变量的相关性,但其中一个变量领先一期,即t期时领先变量按t+1期的值参与计算
    """
    a = a[:]
    b = b[:]
    rows = size(a, 1)
    res = fill(NaN, (rows, 1))

    if is_a_lead
        tmp = res
        tmp[1:end-1]=a[2:end]
    else
        tmp = res
        tmp[1:end-1]=b[2:end]
    end

    for i in sample_period:rows
        res[i] = nast.nancor(a[(i-sample_period+1):i], b[(i-sample_period+1):i])
    end

    return res[:]
end


######################################################################
## beta
######################################################################
function calc_beta(ret::Union{VecOrMat,Array,SubArray}, mkt_ret::Union{VecOrMat,Array,SubArray}, rf::Union{VecOrMat,Array,SubArray}, sample_period::Int, method::String)

    ret_full, mkt_ret_full = copy(ret), copy(mkt_ret)

    not_nan_idx = [i for i in intersect(Set(findall(!isnan,ret)), Set(findall(!isnan,mkt_ret)))]
    ret, mkt_ret, rf = ret[not_nan_idx], mkt_ret[not_nan_idx], rf[not_nan_idx]
    ret, mkt_ret = ret - rf, mkt_ret-rf

    rows = size(ret,1)
    beta = fill(NaN, (rows,1))

    if method == "sw"
        for i in sample_period:rows
            x = mkt_ret[(i-sample_period+1):sample_period]
            y = ret[(i-sample_period+1):sample_period]
            betas = zeros(3,1)
            for (k,j) in enumerate([-1,0,1])
                x = lag(x,j)
                betas[k] = nast.nancov(x,y)/nast.nanvar(x)
            end
            beta[i] = nast.nanmean(betas)
        end
    end

    if method =="capm"
        for i in sample_period:rows
            x = mkt_ret[(i-sample_period+1):sample_period]
            if count(!isnan,x)<250
                beta[i]=NaN
                continue
            end
            y = ret[(i-sample_period+1):sample_period]

            beta[i] = nast.nancov(x,y)/nast.nanvar(x)
        end
    end
    return beta[:]
end