function [res] = calc_ret(v)
    dates = size(v,1);
    res = zeros(dates,1);
    for i = 2:dates
        res(i) = (v(i)-v(i-1))/v(i-1);
    end
end