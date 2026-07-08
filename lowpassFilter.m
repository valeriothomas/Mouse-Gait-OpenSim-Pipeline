function signal = lowpassFilter(signal,fs,cutoff)

if nargin<2
    fs = 960;
end

if nargin<3
    cutoff = 20;
end

[b,a] = butter(4,cutoff/(fs/2),'low');

signal = filtfilt(b,a,signal);

end