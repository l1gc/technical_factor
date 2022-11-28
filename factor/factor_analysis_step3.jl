import HDF5 as h5
import StatsBase as st
import DataFrames as df
import LinearAlgebra as la
import NaNStatistics as nast
import Plots as plt
import Dates

f = h5.h5open("factors.h5", "r")
data_cols = h5.read(f, "col_name")
#equals: a=f["data_cols"]; read(a)

rawdata = (h5.read(f, "factors"));

asset = df.DataFrame(rawdata, Symbol.(data_cols)[:]) # 先用Symbol函数把字符串"x"转为symbol :x,然后用[:]把矩阵变成向量
h5.close(f)
include("calc_factor.jl")
include("factor_processing.jl")
include("utils.jl")


###############################################################################################
include("factor_names.jl")

df.sort!(asset, [:time, :id])
gdf = df.groupby(asset, [:time])
for f in factor_name
    asset[:,f] = df.combine(x -> mad(x[:,f]), gdf).x1
    asset[:,f] = df.combine(x -> standardlize(x[:,f]), gdf).x1
end

# 在截面上计算IC
println("start calculating xsection ic")
df.sort!(asset, [:time, :id])
gdf = df.groupby(asset, [:time])
ic = zeros(length(unique(asset.time)), length(factor_name))
len_f = length(factor_name)
sig_factors = Array{Vector, 1}(undef, 4) # 由于有5个再平衡周期,重要因子的集合为一个5*1的向量
f = open("sig_factor.txt","w")
for (idx,reb) in enumerate([1,3,5,10])
    for f in 1:len_f
        ic[:, f] = df.combine(x -> factor_ic(x[:, "fwd_ret_$reb"], x[:, factor_name[f]]), gdf).x1
    end

    #df.sort!(asset, [:time, :id])
    #gdf = df.groupby(asset, [:time])
    sig_f = []
    write(f, "holding period $reb \n")
    # 单因子测试: IC
    len_ic = size(ic, 2)
    for i in 1:len_ic
        ic_tmp = ic[:, i]
        ic_mean = nast.nanmean(ic_tmp)
        ic_std = nast.nanstd(ic_tmp)
        sample_n = count(!isnan, ic_tmp)
        icir = 16 * ic_mean / ic_std
        ic_t = sqrt(sample_n) * ic_mean / ic_std
        if abs(ic_mean) > 0.03 || abs(ic_t) > 3
            f_name = factor_name[i]
            write(f, "factor $f_name:ic mean is $ic_mean and icir is $icir, ic t is $ic_t \n")
            push!(sig_f,f_name)
            if ic_mean<0
                asset[:,f_name] = -1 .* asset[:,f_name]
            end
        end
    end
    sig_factors[idx] = sig_f
    write(f, " \n")

    # 将上述因子合成
    asset[:,"score_$reb"] = df.select(asset, df.AsTable(sig_f) => df.ByRow(nast.nanmean) => :x).x
    asset[:,"score_$reb"] = df.combine(x -> mad(x[:,"score_$reb"]), gdf).x1
    asset[:,"score_$reb"] = df.combine(x -> standardlize(x[:,"score_$reb"]), gdf).x1
end
close(f)


###############################################################################################
df.sort!(asset, [:time, :id])
gdf = df.groupby(asset, [:time])
for reb in [1,3,5,10]
    
    println("holding period $reb")
    ic_tmp = df.combine(x -> factor_ic(x[:, "fwd_ret_$reb"], x[:, "score_$reb"]), gdf).x1


    ic_mean = nast.nanmean(ic_tmp)
    ic_std = nast.nanstd(ic_tmp)
    sample_n = count(!isnan, ic_tmp)
    icir = 16 * ic_mean / ic_std
    ic_t = sqrt(sample_n) * ic_mean / ic_std
    println("factor score_$reb:ic mean is $ic_mean and icir is $icir, ic t is $ic_t")
    print(" ")
end


###############################################################################################


col_name = names(asset)
h5.h5open("factors_scale_combine.h5", "w") do file
    h5.write(file, "factors", Matrix(asset))  # alternatively, say "@write file A"
    h5.write(file, "col_name", col_name)
    h5.write(file, "factor_name", factor_name)
end