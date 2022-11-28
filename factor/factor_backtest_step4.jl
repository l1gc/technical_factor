import HDF5 as h5
import StatsBase as st
import DataFrames as df
import LinearAlgebra as la
import NaNStatistics as nast
import Plots as plt
import Dates

f = h5.h5open("factors_scale_combine.h5", "r")
data_cols = h5.read(f, "col_name")
#equals: a=f["data_cols"]; read(a)

rawdata = (h5.read(f, "factors"));

asset = df.DataFrame(rawdata, Symbol.(data_cols)[:]) # 先用Symbol函数把字符串"x"转为symbol :x,然后用[:]把矩阵变成向量
h5.close(f)
include("calc_factor.jl")
include("factor_processing.jl")
include("utils.jl")


###############################################################################################


df.sort!(asset, [:time, :id]);
gdf = df.groupby(asset, [:time]);
n = length(unique(asset[!,:id])) # n assets
t = length(unique(asset[!,:time])) # n assets
m = 10; # divide into m groups
k = length(factor_name); # k factors
init_cap = 100000.0;
trading_cost = 0.0003;

asset.ret_1 = asset.ret_1 .+ 1;
ret = df.unstack(asset, :time, :id, :ret_1);
ret = df.coalesce.(ret, 1);
ret_m = ret[:, 2:end];
ret_m = Matrix(ret_m);
ret_m = 1 * ret_m';
replace!(ret_m, NaN => 1);


for (idx,reb) in enumerate([1,3,5,10])
    sharpe_ratio = zeros(m,1) # sharpe ratio is m*1 vector
    ret_rank_corr = Dict()
    sharpe_rank_corr = Dict() #zeros(k,1) # spearman rank correlation between sharpe ratio and group rank
    cos_smi_mean = Dict()
    cos_smi_std = Dict()
    cos_smi_m = []


    if reb>1
        df.sort!(asset, [:id, :time])
        gdf = df.groupby(asset, [:id])
        asset[:, "rolling_mean_factor"] = df.combine(x -> rolling_mean(x[!,"score_$reb"], reb), gdf).x1
        asset[:, "rank"] = df.combine(x -> qcut(x[!, "rolling_mean_factor"], m), gdf).x1


        df.sort!(asset, [:time, :id])
        gdf = df.groupby(asset, [:time])
    else
        asset[:, "rank"] = df.combine(x -> qcut(x[!, "score_$reb"], m), gdf).x1
    end
    
    n_port_v = []
    for j in 1:m
        asset[:, "weight"] = df.combine(x -> group_weight(x[!, "rank"], j), gdf).x1
        replace!(asset.weight, NaN => 0)
        weight = df.unstack(asset, :time, :id, :weight)
        weight = df.coalesce.(weight, 0)
        weight_m = weight[:, 2:end]
        weight_m = Matrix(weight_m)
        weight_m = 1 * weight_m'
        portfolio_value = group_backtest(ret_m, weight_m, init_cap, trading_cost, reb)
        push!(n_port_v, portfolio_value)
    end

    first_nan_idx = findfirst(x -> x!=init_cap,n_port_v[1])
    pv=[]
    sampletime=[]
    try 
        sampletime = sample_time[first_nan_idx:end]
        pv = [i[first_nan_idx:end,:]/init_cap for i in n_port_v]
    catch
        sampletime = sample_time
        pv = n_port_v
    end

    #full_sample_return = [i[end]-1 for i in pv]
    #ret_rank_corr["score_$reb"] = st.corspearman(1:m,full_sample_return)
    sharpe_ratio = 15.8 * st.mean.([calc_ret(i) for i in pv]) ./ st.std.([calc_ret(i) for i in pv])
    sharpe_rank_corr["score_$reb"] = st.corspearman(1:m,sharpe_ratio)

    #f_cos_smi = calc_cos_sim(pv)
    #cos_smi_mean["score_$reb"] = st.mean(f_cos_smi)
    #cos_smi_std["score_$reb"] = st.std(f_cos_smi)
    #push!(cos_smi_m,f_cos_smi)

    plt.bar(1:m,sharpe_ratio,title="score_$reb",legend=false) #,fmt=:png
    plt.savefig("./fig/bar_score_$reb.png")

    plt.plot(sampletime, pv, linewidth=1.5, title="score_$reb", legend=:topleft) #,fmt=:png
    plt.savefig("./fig/line_score_$reb.png")
end