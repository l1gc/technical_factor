clear
is_cls =0;

% 计算资产回报
ret=readtable("ret.csv");
ret(:,1)=[];
ret=table2array(ret);
k=size(ret,2); % k代表k个风险资产
ret(:,k+1)=1.0;

% 计算资产权重
if is_cls
    data=readtable("weight_cls.csv");
else
    data=readtable("weight.csv");
end
sample_time=data{1:end,1};
data(:,1)=[]; % delete date
target_weights=table2array(data);
target_weights(:,k+1)=1 - sum(target_weights(:,1:k),2);
target_weights=[zeros(1,k+1);target_weights];
target_weights=target_weights(1:end-1,:);
target_weights(1,end)=1;


% 计算调仓日
dates=size(target_weights,1);
n=5; % 每n天调仓
is_reb=linspace(1,dates,dates);
is_reb=(mod(is_reb,n)==0);
is_reb(1) = 1; % 第一天总是调仓


% 设定初始资本和交易成本
inital_capital=100000;
commission_fee=0.0003;

%
[position, weight, commission, portfolio_value] = backtest(is_reb, ret, target_weights, inital_capital, commission_fee);

scaled_portfolio_value=portfolio_value/inital_capital;
s = datetime(sample_time,'ConvertFrom', 'yyyymmdd');
plot(s,scaled_portfolio_value,'k','Linewidth', 1.5)

port_ret = calc_ret(scaled_portfolio_value);
port_ret = [sample_time port_ret];
weight_date=readtable("weight.csv");

t2020=2200;
since_2020=s(t2020:end);
scaled_portfolio_value_since_2020=scaled_portfolio_value(t2020:end);
plot(since_2020,scaled_portfolio_value_since_2020,'k','Linewidth', 1.5)