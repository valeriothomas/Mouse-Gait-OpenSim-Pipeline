function filtered = butterLowpassFilter1D(x,cutoff,fs,order)

if nargin<4
    order=4;
end

x = double(x(:));

nanMask = isnan(x);

if all(nanMask)
    filtered = x;
    return
end

valid = find(~nanMask);

interpX = x;

interpX(1:valid(1)-1) = x(valid(1));
interpX(valid(end)+1:end) = x(valid(end));

interpX(nanMask) = interp1( ...
    valid,...
    x(valid),...
    find(nanMask),...
    'linear');

[b,a] = butter(order,...
    cutoff/(fs/2),...
    'low');

filtered = filtfilt(b,a,interpX);

filtered(nanMask)=NaN;

end