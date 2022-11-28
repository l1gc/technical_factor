import HDF5 as h5
import StatsBase as st
import DataFrames as df
import LinearAlgebra as la
import NaNStatistics as nast
import Plots as plt
import Dates

f = h5.h5open("zz800.h5", "r")
data_cols = h5.read(f, "data_cols")
#equals: a=f["data_cols"]; read(a)

rawdata = transpose(h5.read(f, "data")); # 不知道为什么h5py写入时会将矩阵转置,因此此处需转置回来

asset = df.DataFrame(rawdata, Symbol.(data_cols)[:]) # 先用Symbol函数把字符串"x"转为symbol :x,然后用[:]把矩阵变成向量
h5.close(f)
is_stock = true
asset.id = "id" .* string.(convert.(Int, asset.id))
sample_dates = sort!(unique(asset.time))
sample_dates = string.(convert.(Int, sample_dates))
sample_time = Dates.Date.(sample_dates, "yyyymmdd")

include("calc_factor.jl")
include("factor_processing.jl")
include("utils.jl")

time_cycle = [5,15,30,63,120]
print(names(asset)[:])

####################################################################################
####################################################################################
####################################################################################

df.sort!(asset, [:id, :time]) # 由于后面会直接合并,因此此处需要先按id再按time排序
gdf = df.groupby(asset, [:id]) # 由于按id分组因此会先按id再按time排序
# mmt_relative
for i in time_cycle
    asset[:, "mmt_relative_$i"] = df.combine(x -> mmt_relative(x.close, i, time_cycle), gdf).x1
end

# mmt_range
for i in time_cycle
    asset[:, "mmt_amplitude_adjust_$i"] = df.combine(x -> mmt_amplitude_adjust(x.ret, x.amplitude, i), gdf).x1
end

# mmt_average
for i in time_cycle
    asset[:, "mmt_average_adjust_$i"] = df.combine(x -> mmt_average_adjust(x.ret, x.average, i), gdf).x1
end

# mmt_exclude_limit
if is_stock
    for i in time_cycle
        asset[:, "mmt_exclude_limit_$i"] = df.combine(x -> mmt_exclude_limit(x.ret, x.reach_limit, i), gdf).x1
    end
end


# mmt_infomation_discrete
for i in time_cycle
    asset[:, "mmt_infomation_discrete_$i"] = df.combine(x -> mmt_infomation_discrete(x.ret, i), gdf).x1
end

# mmt_time_rank
for i in time_cycle
    asset[:, "mmt_time_rank_$i"] = df.combine(x -> mmt_time_rank(x.ret, 21, i), gdf).x1
end

# vol_up_adjust
for i in time_cycle
    asset[:, "vol_up_adjust_$i"] = df.combine(x -> vol_up_adjust(x.ret, i), gdf).x1
end

#
for i in time_cycle
    asset[:, "corr_sync_$i"] = df.combine(x -> corr_sync(x.average, x.vol, i), gdf).x1
end

print(names(asset)[:])

###############################################################################################
include("factor_names.jl")
function str_sub(x,n)
    return x[n:end]
end

# 将之前的id转为数字
asset.id = str_sub.(asset.id, 3)
asset.id = parse.(Int, asset.id)

col_name = names(asset)
h5.h5open("factors.h5", "w") do file
    h5.write(file, "factors", Matrix(asset))  # alternatively, say "@write file A"
    h5.write(file, "col_name", col_name)
    h5.write(file, "factor_name", factor_name)
end