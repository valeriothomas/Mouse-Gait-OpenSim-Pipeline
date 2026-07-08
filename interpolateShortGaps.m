function marker = interpolateShortGaps(marker,maxGap)

n = size(marker,1);

for dim = 1:3

    x = marker(:,dim);

    nanMask = isnan(x);

    if all(nanMask)
        continue
    end

    idx = find(~nanMask);

    xInterp = x;

    gaps = bwconncomp(nanMask);

    for g = 1:gaps.NumObjects

        gap = gaps.PixelIdxList{g};

        if numel(gap) <= maxGap

            xInterp(gap) = pchip(...
                idx,...
                x(idx),...
                gap);

        end
    end

    marker(:,dim) = xInterp;

end

end