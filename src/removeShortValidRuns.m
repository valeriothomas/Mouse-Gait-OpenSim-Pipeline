function marker = removeShortValidRuns(marker,minValidRun)

valid = ~isnan(marker(:,1));

idx = find(valid);

if isempty(idx)
    return
end

breaks = [0; find(diff(idx)>1); numel(idx)];

for k=1:length(breaks)-1

    runIdx = idx(...
        breaks(k)+1:breaks(k+1));

    if numel(runIdx) < minValidRun
        marker(runIdx,:) = NaN;
    end

end

end