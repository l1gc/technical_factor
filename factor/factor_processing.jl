######################################################################
## miscellaneous
######################################################################
function mad(x::Union{VecOrMat,Array,SubArray},n::Int=3)
    median = nast.nanmedian(x)
    diff_median =  nast.nanmedian(abs.(x .- median))
    max_range = median + 1.4826 * n * diff_median
    min_range = median - 1.4826 * n * diff_median
    clamp!(x, min_range, max_range)
    return x
end

function winsorize(x::Union{VecOrMat,Array,SubArray}, prop::Float64=0.02)
    x = replace(x, NaN => missing)
    x = skipmissing(x)
    return collect(st.winsor(x,prop=prop))
end

function standardlize(x::Union{VecOrMat,Array,SubArray})
    x = (x .- nast.nanmean(x)) ./ nast.nanstd(x)
    return x
end

function neutralize(ret::Union{VecOrMat,Array,SubArray}, ind::Union{VecOrMat,Array,SubArray}, mv::Union{VecOrMat,Array,SubArray})
    """
    行业市值中性化
    """
    ind_dummy = 1*(permutedims(unique(ind)) .== ind)
    ind_dummy = ind_dummy[:,2:end]
    X = [ind_dummy mv]
    residual = ret .- X * la.inv(X' * X) * X' * ret
    return residual[:]
end


######################################################################
## factor statistics calculation
######################################################################
function factor_ic(ret::Union{VecOrMat,Array,SubArray},fac::Union{VecOrMat,Array,SubArray},cor_method::String="spearman")
    """
    ret: 收益率
    fac: 因子
    cor_method: 计算相关性的方法,默认spearman
    """
    res = 0.0
    not_nan_idx = [i for i in intersect(Set(findall(!isnan,ret)), Set(findall(!isnan,fac)))]

    try
        if cor_method == "spearman"
            res = st.corspearman(ret[not_nan_idx], fac[not_nan_idx])
        else
            res = st.cor(ret[not_nan_idx], fac[not_nan_idx])
        end
    catch
        res = NaN
    end
    return res
end

function factor_ir(ic::Union{VecOrMat,Array,SubArray},sample_period::Int)
    """
    ic: ic序列
    sample_period: 样本长度 
    """

    ic = ic[:]
    rows = size(ic, 1)
    res = zeros(rows, 1)
    res = replace(res, 0.0 => NaN)


    for i in sample_period:rows
        tmp = ic[(i-sample_period+1):i]
        res[i] = nast.nanmean(tmp) / nast.nanstd(tmp)
    end

    return res[:]
end

function factor_ic_t()

end

######################################################################
## factor combination
######################################################################
function ic_weighting(asset::Union{df.DataFrame,df.SubDataFrame},ic_weight::Union{df.DataFrame,df.SubDataFrame},fac_name::VecOrMat)
    """
    asset: (t*n)*k的资产因子暴露矩阵
    fac_name: 向量,包含因子名称
    ic_weight: 以ic度量的因子权重矩阵
    """

    dates = unique(asset[:,:time])[1]
    ic_weight = df.subset(ic_weight, :time => df.ByRow(x -> x == dates)) # ic_weight is a 1*k matrix
    ic_weight = ic_weight[:,fac_name]
    ic_weight = Matrix(ic_weight)
    asset[:,fac_name] = asset[:,fac_name] .* ic_weight

    return asset
end

function icir_weighting()

end

function max_icir_weighting()

end