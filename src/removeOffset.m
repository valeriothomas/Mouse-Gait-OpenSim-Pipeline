function signal = removeOffset(signal,nBaseline)

if nargin<2
    nBaseline = 500;
end

baseline = mean(signal(1:nBaseline));

signal = signal - baseline;

end