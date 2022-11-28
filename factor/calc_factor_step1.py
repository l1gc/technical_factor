import h5py
import numpy as np
import pandas as pd

stock = pd.read_hdf('stock_zz800_rawdata.h5')
stock.rename(columns={'pvernight':'overnight'},inplace=True)
stock.rename(columns={'main_min_samll':'main_min_small'},inplace=True)

#reb = 3
#time_cycle = [3,9,18,36,63]
reb=5
time_cycle = [5,15,30,63,120]

# 普通动量
mmt_method = 'average'
#mmt_method = 'close'
for i in time_cycle:
    stock[f'mmt_{i}']=stock.groupby('id')[mmt_method].pct_change(i)
    if i>time_cycle[0]:
        stock[f'mmt_{i}']=stock[f'mmt_{i}'] - stock[f'mmt_{time_cycle[0]}']

# 日内动量
for i in time_cycle:
    stock[f'mmt_intraday_{i}']=stock.groupby('id')['intraday'].transform(lambda x: x.rolling(i).sum())
    if i>time_cycle[0]:
        stock[f'mmt_intraday_{i}']=stock[f'mmt_intraday_{i}'] - stock[f'mmt_intraday_{time_cycle[0]}']

# 隔夜动量
for i in time_cycle:
    stock[f'mmt_overnight_{i}']=stock.groupby('id')['overnight'].transform(lambda x: x.rolling(i).sum())
    if i>time_cycle[0]:
        stock[f'mmt_overnight_{i}']=stock[f'mmt_overnight_{i}'] - stock[f'mmt_overnight_{time_cycle[0]}']

# 截面动量
stock['ret_rank']=stock.groupby('time')['ret'].rank(ascending=True,na_option='keep')
# def scale_ret_rank(x):
#     n=x.notna().sum()
#     return (x-(n+1)/2)/np.sqrt((n+1)*(n-1)/12)

# stock['ret_rank']=stock.groupby('time')['ret_rank'].apply(scale_ret_rank)
for i in time_cycle:
    stock[f'mmt_rank_{i}']=stock.groupby('id')['ret_rank'].transform(lambda x: x.rolling(i).mean())
    if i>time_cycle[0]:
        stock[f'mmt_rank_{i}']=stock[f'mmt_rank_{i}']-stock[f'mmt_rank_{time_cycle[0]}']
stock.drop(['ret_rank'],axis=1,inplace=True)

# 平滑动量
stock['ret_abs'] = stock['ret'].abs()
for i in time_cycle:
    stock[f'mmt_smooth_{i}']=stock.groupby('id')['ret_abs'].transform(lambda x: x.rolling(i).sum())
    if i>time_cycle[0]:
        stock[f'mmt_smooth_{i}']=stock[f'mmt_{i}'] / stock[f'mmt_smooth_{i}'] - stock[f'mmt_smooth_{time_cycle[0]}']
    else:
        stock[f'mmt_smooth_{i}']=stock[f'mmt_{i}'] / stock[f'mmt_smooth_{i}']
stock.drop(['ret_abs'],axis=1,inplace=True)

# 1年内高点
stock['mmt_high_252']=stock.groupby('id')['high'].transform(lambda x: x.rolling(252).max())
stock['mmt_high_252']=stock['hkhold'] / stock['mmt_high_252'] -1


# 波动率
for i in time_cycle:
    stock[f'ret_vol_{i}']=stock.groupby('id')['ret'].transform(lambda x: x.rolling(i).std())

# for i in time_cycle:
#     stock[f'ret_up_vol_{i}']=stock.groupby('id')['up_ret'].transform(lambda x: x.rolling(i,min_periods=2).std())

# for i in time_cycle:
#     stock[f'ret_down_vol_{i}']=stock.groupby('id')['down_ret'].transform(lambda x: x.rolling(i,min_periods=2).std())

for i in time_cycle:
    stock[f'high_low_{i}']=stock.groupby('id')['high_low'].transform(lambda x: x.rolling(i).std())


# 流动性
for i in time_cycle:
    stock[f'turnover_mean_{i}']=stock.groupby('id')['turnover'].transform(lambda x: x.rolling(i).mean())

for i in time_cycle:
    stock[f'turnover_std_{i}']=stock.groupby('id')['turnover'].transform(lambda x: x.rolling(i).std())

# 资金流动
for i in time_cycle:
    stock[f'main_vol_mean_{i}']=stock.groupby('id')['main_vol'].transform(lambda x: x.rolling(i).mean())
    stock[f'main_vol_mean_{i}']=stock['main_vol'] - stock[f'main_vol_mean_{i}']

for i in time_cycle:
    stock[f'small_vol_mean_{i}']=stock.groupby('id')['small_vol'].transform(lambda x: x.rolling(i).mean())
    stock[f'small_vol_mean_{i}']=stock['small_vol'] - stock[f'small_vol_mean_{i}']

for i in time_cycle:
    stock[f'main_min_small_mean_{i}']=stock.groupby('id')['main_min_small'].transform(lambda x: x.rolling(i).mean())
    stock[f'main_min_small_mean_{i}']=stock['main_min_small'] - stock[f'main_min_small_mean_{i}']

for i in time_cycle:
    stock[f'main_vol_std_{i}']=stock.groupby('id')['main_vol'].transform(lambda x: x.rolling(i).std())

for i in time_cycle:
    stock[f'small_vol_std_{i}']=stock.groupby('id')['small_vol'].transform(lambda x: x.rolling(i).std())

for i in time_cycle:
    stock[f'main_min_small_std_{i}']=stock.groupby('id')['main_min_small'].transform(lambda x: x.rolling(i).std())

# 北向流动
for i in time_cycle:
    stock[f'hkhold_mean_{i}']=stock.groupby('id')['hkhold'].transform(lambda x: x.rolling(i).mean())
    stock[f'hkhold_mean_{i}']=stock['hkhold'] - stock[f'hkhold_mean_{i}']

for i in time_cycle:
    stock[f'hkhold_std_{i}']=stock.groupby('id')['hkhold'].transform(lambda x: x.rolling(i).std())

for hold_period in [1,3,5,10,21]:
    stock[f'ret_{hold_period}'] = stock.groupby('id')['average'].pct_change(hold_period)
    stock[f'fwd_ret_{hold_period}'] = stock.groupby('id')[f'ret_{hold_period}'].shift(-(hold_period+1))

ind_map = {}
for i in range(30):
    ind_map[f'ind{i}'] = i
stock['ind'] = stock['ind'].map(ind_map)
stock['time'] = stock['time'].str.replace('-', '', regex=False).astype(int)
c = stock.values
col = stock.columns
colnames = np.array(col)
colnames = np.array([[i.encode('utf8')]
                    for i in colnames])  # 需要先转成utf8格式才能写入h5
dt = h5py.special_dtype(vlen=str)
with h5py.File('zz800.h5', 'w') as f:
    f.create_dataset('data', data=c, compression='gzip', compression_opts=9)
    f.create_dataset('data_cols', data=colnames, dtype=dt, compression='gzip', compression_opts=9)