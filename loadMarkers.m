function xyz = loadMarkers(c3dFile,markerNames)

acq = btkReadAcquisition(c3dFile);

allMarkers = btkGetMarkers(acq);

xyz = struct();

for k=1:length(markerNames)

    name = markerNames{k};

    if ~isfield(allMarkers,name)

        error(['Missing marker: ' name])

    end

    data = allMarkers.(name);

    zeroRows = all(data==0,2);

    data(zeroRows,:) = NaN;

    xyz.(name) = data;

end

end