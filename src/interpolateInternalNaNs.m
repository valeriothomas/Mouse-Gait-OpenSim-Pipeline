function out = interpolateInternalNaNs(arr)

out = arr;

[n,m] = size(arr);

for j = 1:m

    col = arr(:,j);

    nanMask = isnan(col);

    if all(nanMask)
        continue
    end

    valid = find(~nanMask);

    firstValid = valid(1);
    lastValid = valid(end);

    nanIdx = find(nanMask);

    internal = ...
        nanIdx > firstValid & ...
        nanIdx < lastValid;

    fillIdx = nanIdx(internal);

    if ~isempty(fillIdx)

        out(fillIdx,j) = interp1(...
            valid,...
            col(valid),...
            fillIdx,...
            'linear');

    end

end

end