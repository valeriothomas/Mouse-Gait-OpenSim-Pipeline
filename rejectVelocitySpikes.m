function marker = rejectVelocitySpikes(marker,fs,vMax)

dt = 1/fs;
n = size(marker,1);

for i=2:n-1

    if any(isnan(marker(i,:)))
        continue
    end

    vPrev = 0;
    vNext = 0;

    if ~any(isnan(marker(i-1,:)))
        vPrev = norm(marker(i,:)-marker(i-1,:))/dt;
    end

    if ~any(isnan(marker(i+1,:)))
        vNext = norm(marker(i+1,:)-marker(i,:))/dt;
    end

    if max(vPrev,vNext) > vMax
        marker(i,:) = NaN;
    end

end

end