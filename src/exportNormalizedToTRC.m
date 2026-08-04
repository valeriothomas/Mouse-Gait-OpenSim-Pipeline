function exportNormalizedToTRC( ...
    filePath,...
    xyzDict,...
    markerNames,...
    markerTRCNames,...
    startFrame,...
    endFrame,...
    frequency,...
    outputMotionFolder)

nFrames = endFrame-startFrame+1;

%nInterp = 101; % to normalize the stance phase
nInterp = nFrames; % to keep the original number 

duration = (nFrames-1)/frequency;
time = linspace(0, duration, nInterp);


%% Normalize trajectories

normalizedXYZ = struct();

for k=1:length(markerNames)

    name = markerNames{k};

    segment = ...
        xyzDict.(name)( ...
        startFrame:endFrame,:)/1000;

    normMatrix = zeros(nInterp,3);

    for dim=1:3

        normMatrix(:,dim) = ...
            normalizeCycle( ...
            segment(:,dim),...
            frequency,...
            nInterp);

    end

    normalizedXYZ.(name) = normMatrix;

end

%% Write TRC

fid = fopen(fullfile(outputMotionFolder,filePath),'w');

[~,trcName,ext] = fileparts(filePath);

fprintf(fid,...
'PathFileType\t4\t(X/Y/Z)\t%s%s\n',...
trcName,ext);

fprintf(fid,...
'DataRate\tCameraRate\tNumFrames\tNumMarkers\tUnits\tOrigDataRate\tOrigDataStartFrame\tOrigNumFrames\n');

fprintf(fid,...
'120\t120\t%d\t%d\tm\t120\t%d\t%d\n',...
nInterp,...
length(markerNames),...
startFrame,...
endFrame);

%% Marker labels

fprintf(fid,'Frame#\tTime\t');

for k=1:length(markerTRCNames)

    fprintf(fid,...
    '%s\t\t\t',...
    markerTRCNames{k});

end

fprintf(fid,'\n');

fprintf(fid,'\t\t');

for k=1:length(markerNames)

    fprintf(fid,...
    'X%d\tY%d\tZ%d\t',...
    k,k,k);

end

fprintf(fid,'\n\n');

%% Data

for i=1:nInterp

    fprintf(fid,...
    '%d\t%.10f\t',...
    i,...
    time(i));

    for m=1:length(markerNames)

        name = markerNames{m};

        coords = ...
            normalizedXYZ.(name)(i,:);

        if any(isnan(coords))

            fprintf(fid,...
            '0\t0\t0\t');

        else

            fprintf(fid,...
            '%.10f\t%.10f\t%.10f\t',...
            coords(1),...
            coords(2),...
            coords(3));

        end

    end

    fprintf(fid,'\n');

end

fclose(fid);

end
