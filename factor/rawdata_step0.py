
import h5py
import pandas as pd
import numpy as np

# 合并原始日度量价数据
df0 = pd.read_csv('./q1/TRD_BwardQuotation.csv')
df1 = pd.read_csv('./q1/TRD_BwardQuotation1.csv')
stock = pd.concat([df0, df1], axis=0)
df0 = pd.read_csv('./q2/TRD_BwardQuotation.csv')
df1 = pd.read_csv('./q2/TRD_BwardQuotation1.csv')
stock = pd.concat([stock, df0, df1], axis=0)
df0 = pd.read_csv('./q3/TRD_BwardQuotation.csv')
df1 = pd.read_csv('./q3/TRD_BwardQuotation1.csv')
df2 = pd.read_csv('./q3/TRD_BwardQuotation2.csv')
df3 = pd.read_csv('./q3/TRD_BwardQuotation3.csv')
stock = pd.concat([stock, df0, df1, df2, df3], axis=0)
df0 = pd.read_csv('./q4/TRD_BwardQuotation.csv')
df1 = pd.read_csv('./q4/TRD_BwardQuotation1.csv')
df2 = pd.read_csv('./q4/TRD_BwardQuotation2.csv')
df3 = pd.read_csv('./q4/TRD_BwardQuotation3.csv')
df4 = pd.read_csv('./q4/TRD_BwardQuotation4.csv')
stock = pd.concat([stock, df0, df1, df2, df3, df4], axis=0)
df0 = pd.read_csv('./q5/TRD_BwardQuotation.csv')
stock = pd.concat([stock, df0], axis=0)
del df0, df1, df2, df3, df4
stock.reset_index(drop=True, inplace=True)


# 股票交易状态的合并,用以确定股票是否是ST股
df0 = pd.read_csv('./trade_state/s1/TRD_Dalyr.csv')
df1 = pd.read_csv('./trade_state/s1/TRD_Dalyr1.csv')
stock_trade_date = pd.concat([df0, df1], axis=0)
df0 = pd.read_csv('./trade_state/s2/TRD_Dalyr.csv')
df1 = pd.read_csv('./trade_state/s2/TRD_Dalyr1.csv')
df2 = pd.read_csv('./trade_state/s2/TRD_Dalyr2.csv')
df3 = pd.read_csv('./trade_state/s2/TRD_Dalyr3.csv')
stock_trade_date = pd.concat([stock_trade_date, df0, df1, df2, df3], axis=0)
df0 = pd.read_csv('./trade_state/s3/TRD_Dalyr.csv')
df1 = pd.read_csv('./trade_state/s3/TRD_Dalyr1.csv')
df2 = pd.read_csv('./trade_state/s3/TRD_Dalyr2.csv')
df3 = pd.read_csv('./trade_state/s3/TRD_Dalyr3.csv')
df4 = pd.read_csv('./trade_state/s3/TRD_Dalyr4.csv')
stock_trade_date = pd.concat([stock_trade_date, df0, df1, df2, df3, df4], axis=0)
del df0, df1, df2, df3, df4
stock_trade_date.reset_index(drop=True, inplace=True)
stock_trade_date.columns = ['Symbol', 'TradingDate', 'is_st']  # is_st中只有为1的值代表是正常交易的股票

# 将上述两个数据合并
stock = pd.merge(stock, stock_trade_date, on=['Symbol', 'TradingDate'], how='left')
stock1 = stock.loc[stock['TradingDate'] < '2022-09-22']
stock2 = stock.loc[stock['TradingDate'] >= '2022-09-22']
del stock
stock2['is_st'] = stock2.groupby('Symbol')['is_st'].ffill()
stock = pd.concat([stock1, stock2], axis=0)
del stock1, stock2


# 中证800成分股
df0 = pd.read_csv('./zz800_compo/IDX_Smprat_1.csv')
df1 = pd.read_csv('./zz800_compo/IDX_Smprat_2.csv')
df2 = pd.read_csv('./zz800_compo/IDX_Smprat_3.csv')
zz800 = pd.concat([df0, df1, df2], axis=0)
zz800.columns = ['TradingDate', 'Symbol', 'is_zz800']

# 再次合并
stock = pd.merge(stock, zz800, on=['Symbol', 'TradingDate'], how='left')
stock1 = stock.loc[stock['TradingDate'] < '2022-09-22']
stock2 = stock.loc[stock['TradingDate'] >= '2022-09-22']
del stock
stock2['is_zz800'] = stock2.groupby('Symbol')['is_zz800'].ffill()
stock = pd.concat([stock1, stock2], axis=0)
del stock1, stock2


# 合并pe和pb指标
valuation = pd.DataFrame()
df0 = pd.read_csv('./pe/p1/STK_MKT_ValuationMetrics.csv')
df1 = pd.read_csv('./pe/p1/STK_MKT_ValuationMetrics1.csv')
valuation = pd.concat([df0, df1], axis=0)
df0 = pd.read_csv('./pe/p2/STK_MKT_ValuationMetrics.csv')
df1 = pd.read_csv('./pe/p2/STK_MKT_ValuationMetrics1.csv')
valuation = pd.concat([valuation, df0, df1], axis=0)
df0 = pd.read_csv('./pe/p3/STK_MKT_ValuationMetrics.csv')
valuation = pd.concat([valuation, df0], axis=0)
df0 = pd.read_csv('./pe/p4/STK_MKT_ValuationMetrics.csv')
df1 = pd.read_csv('./pe/p4/STK_MKT_ValuationMetrics1.csv')
valuation = pd.concat([valuation, df0, df1], axis=0)
df0 = pd.read_csv('./pe/p5/STK_MKT_ValuationMetrics.csv')
df1 = pd.read_csv('./pe/p5/STK_MKT_ValuationMetrics1.csv')
valuation = pd.concat([valuation, df0, df1], axis=0)
df0 = pd.read_csv('./pe/p6/STK_MKT_ValuationMetrics.csv')
df1 = pd.read_csv('./pe/p6/STK_MKT_ValuationMetrics1.csv')
df2 = pd.read_csv('./pe/p6/STK_MKT_ValuationMetrics2.csv')
valuation = pd.concat([valuation, df0, df1, df2], axis=0)
df0 = pd.read_csv('./pe/p7/STK_MKT_ValuationMetrics.csv')
df1 = pd.read_csv('./pe/p7/STK_MKT_ValuationMetrics1.csv')
df2 = pd.read_csv('./pe/p7/STK_MKT_ValuationMetrics2.csv')
valuation = pd.concat([valuation, df0, df1, df2], axis=0)
del df0, df1, df2

# 将估值指标和量价数据合并
stock = pd.merge(stock, valuation, on=['Symbol', 'TradingDate'], how='left')

# 北向资金持股比例
df0 = pd.read_csv('./hk_hold/STK_MKTLink_Shares.csv')
df1 = pd.read_csv('./hk_hold/STK_MKTLink_Shares1.csv')
df2 = pd.read_csv('./hk_hold/STK_MKTLink_Shares2.csv')
df3 = pd.read_csv('./hk_hold/STK_MKTLink_Shares3.csv')
hk_hold = pd.concat([df0, df1, df2, df3], axis=0)
del df0, df1, df2, df3
hk_hold = hk_hold.loc[(hk_hold['MarketLinkCode'] == 'HKEXtoSSE') | (
    hk_hold['MarketLinkCode'] == 'HKEXtoSZSE')]
hk_hold.reset_index(drop=True, inplace=True)
hk_hold.drop(['MarketLinkCode'], axis=1, inplace=True)
hk_hold.columns = ['TradingDate', 'Symbol', 'hkhold1', 'hkhold2']
# 将北向持仓和量价数据合并
stock = pd.merge(stock, hk_hold, on=['Symbol', 'TradingDate'], how='left')

# 资金流动
df0 = pd.read_csv('./flow/p1/HF_BSImbalance.csv')
cash_flow = pd.concat([df0], axis=0)
df0 = pd.read_csv('./flow/p2/HF_BSImbalance.csv')
df1 = pd.read_csv('./flow/p2/HF_BSImbalance1.csv')
df2 = pd.read_csv('./flow/p2/HF_BSImbalance2.csv')
cash_flow = pd.concat([cash_flow, df0, df1, df2], axis=0)
df0 = pd.read_csv('./flow/p3/HF_BSImbalance.csv')
df1 = pd.read_csv('./flow/p3/HF_BSImbalance1.csv')
df2 = pd.read_csv('./flow/p3/HF_BSImbalance2.csv')
cash_flow = pd.concat([cash_flow, df0, df1, df2], axis=0)
df0 = pd.read_csv('./flow/p4/HF_BSImbalance.csv')
df1 = pd.read_csv('./flow/p4/HF_BSImbalance1.csv')
df2 = pd.read_csv('./flow/p4/HF_BSImbalance2.csv')
df3 = pd.read_csv('./flow/p4/HF_BSImbalance3.csv')
cash_flow = pd.concat([cash_flow, df0, df1, df2, df3], axis=0)
del df0, df1, df2, df3
cash_flow.reset_index(drop=True, inplace=True)
cash_flow['main_vol'] = cash_flow['B_Volume_L'] + cash_flow['B_Volume_B']-cash_flow['S_Volume_L']-cash_flow['S_Volume_B']
cash_flow['small_vol'] = cash_flow['B_Volume_M'] + cash_flow['B_Volume_S']-cash_flow['S_Volume_M']-cash_flow['S_Volume_S']
cash_flow = cash_flow[['Stkcd', 'Trddt', 'main_vol', 'small_vol']]
cash_flow.columns = ['Symbol' ,'TradingDate', 'main_vol', 'small_vol']
# 将北向持仓和量价数据合并
stock = pd.merge(stock, cash_flow, on=['Symbol', 'TradingDate'], how='left')


del valuation, hk_hold, stock_trade_date, zz800, cash_flow

# 剔除st股票和停牌股票
stock = stock.loc[stock['is_zz800'] == 1]
stock['Symbol'] = stock['Symbol'].astype(str).str.zfill(6)
stock = stock.loc[(stock['Symbol'].str[:2] == '00') | (stock['Symbol'].str[:2] == '60')]  # 选择沪深A股,不包括创业板
stock = stock.loc[(stock['Filling'] == 0) & (stock['StateCode'] == 0) & (stock['is_st'] == 1.0), :]
stock.dropna(subset=['Volume'], axis=0, inplace=True)
stock.reset_index(drop=True, inplace=True)
stock.drop(['Filling', 'StateCode', 'is_st', 'is_zz800'], axis=1, inplace=True)
stock.drop(['Distance'], axis=1, inplace=True)

# 行业
stock.columns = ['time', 'id', 'open', 'close', 'high',
                 'low', 'vol', 'amt', 'ret_close', 'total_share',
                 'cir_share', 'turnover', 'mv',
                 'cir_mv', 'pettm', 'pb', 'hkhold1', 'hkhold2',
                 'main_vol', 'small_vol']
stock['year'] = stock['time'].str[:4].astype(int)
industry = pd.read_csv('industry.csv')
industry.columns = ['id', 'year', 'ind']
industry['year'] = industry['year'].str[:4].astype(int)
stock['id'] = stock['id'].astype(int)
stock = pd.merge(stock, industry, on=['id', 'year'], how='left')
stock['ind'] = stock['ind'].bfill()
a = stock['ind'].unique()
a.sort()
ind_map = {}
for i in range(30):
    ind_map[a[i]] = f'ind{i}'
stock['ind'] = stock['ind'].map(ind_map)
stock.drop(['year'], axis=1, inplace=True)
stock['hkhold1'].fillna(stock['hkhold2'], inplace=True) 
stock.drop(['hkhold2'], axis=1, inplace=True)
stock.rename(columns={'hkhold1':'hkhold'},inplace=True)

# 计算辅助变量
stock['reach_limit'] = 1*(stock['ret_close'] > 0.098)
stock['pre_close'] = stock.groupby('id')['close'].shift(1)
stock['amplitude'] = (stock['high']-stock['low'])/stock['pre_close']
stock['pvernight'] = (stock['open']-stock['pre_close'])/stock['pre_close']
stock.drop(['pre_close'], axis=1, inplace=True)
stock['intraday'] = (stock['close']-stock['open'])/stock['open']
stock['average'] = stock['amt']/stock['vol']
stock['ret'] = stock.groupby('id')['average'].pct_change()
stock['high_low'] = stock['high']/stock['low']
stock['main_vol']=stock['main_vol']/stock['vol']
stock['small_vol']=stock['small_vol']/stock['vol']
stock['main_min_small']=(stock['main_vol']-stock['small_vol'])/stock['vol']

stock.sort_values(['id', 'time'], inplace=True)
stock.reset_index(drop=True, inplace=True)
stock.to_hdf('stock_zz800.h5', 'stock')



