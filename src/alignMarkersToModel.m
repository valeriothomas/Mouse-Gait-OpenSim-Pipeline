function [alignedXYZ,R,T,rmsError] = ...
    alignMarkersToModel( ...
    xyzDict,...
    experimentalNames,...
    modelNames,...
    modelPath,...
    f0,...
    f1)

import org.opensim.modeling.*

%% ----------------------------------------------------
% Load OpenSim model
%% ----------------------------------------------------

model = Model(modelPath);
state = model.initSystem();

markerSet = model.getMarkerSet();

modelPts = struct();
expPts   = struct();

%% ----------------------------------------------------
% Extract marker positions
%% ----------------------------------------------------

for k = 1:length(experimentalNames)

    expName   = experimentalNames{k};
    modelName = modelNames{k};

    try
        marker = markerSet.get(modelName);
    catch
        warning('Marker %s not found in model',modelName)
        continue
    end

    loc = marker.get_location();

    modelPts.(expName) = [ ...
        loc.get(0) ...
        loc.get(1) ...
        loc.get(2)] .* 1000;

    expPts.(expName) = ...
        mean( ...
        xyzDict.(expName)(f0:f1,:), ...
        1,...
        'omitnan');

end

%% ----------------------------------------------------
% Required markers
%% ----------------------------------------------------

required = { ...
    'LASI',...
    'RASI',...
    'RightHIP',...
    'RightKNEE'};

for k = 1:length(required)

    m = required{k};

    if ~isfield(expPts,m)

        error('Missing marker: %s',m)

    end

    if any(isnan(expPts.(m)))

        error('Marker %s contains NaNs',m)

    end

end

%% ----------------------------------------------------
% Experimental progression
%% ----------------------------------------------------

pelvisCenter = ...
    (xyzDict.LASI + xyzDict.RASI)/2;

startPos = mean( ...
    pelvisCenter(f0:f0+5,:),...
    1,...
    'omitnan');

endPos = mean( ...
    pelvisCenter(f1-5:f1,:),...
    1,...
    'omitnan');

progressionExp = ...
    normalizeVector( ...
    endPos - startPos);

%% ----------------------------------------------------
% Model progression
%% ----------------------------------------------------

progressionModel = [1 0 0];

%% ----------------------------------------------------
% Frames
%% ----------------------------------------------------

Rexp = buildFrame( ...
    progressionExp,...
    expPts.RASI,...
    expPts.LASI);

Rmodel = buildFrame( ...
    progressionModel,...
    modelPts.RASI,...
    modelPts.LASI);

%% ----------------------------------------------------
% Rotation matrix
%% ----------------------------------------------------

R = Rmodel * Rexp';

%% ----------------------------------------------------
% Translation
%% ----------------------------------------------------

T = modelPts.RightHIP' ...
    - R*expPts.RightHIP';

T = T(:);

%% ----------------------------------------------------
% RMS error
%% ----------------------------------------------------

residuals = [];

for k=1:length(experimentalNames)

    name = experimentalNames{k};

    if ~isfield(expPts,name)
        continue
    end

    pFit = ...
        R*expPts.(name)' ...
        + T;

    residuals(end+1) = ...
        norm( ...
        pFit - ...
        modelPts.(name)' );

end

rmsError = ...
    sqrt(mean(residuals.^2));

fprintf( ...
    'Registration RMS error = %.3f mm\n',...
    rmsError);

%% ----------------------------------------------------
% Progression error
%% ----------------------------------------------------

progressionAfter = ...
    normalizeVector( ...
    (R*progressionExp')');

progressionAngle = ...
    acosd( ...
    max(-1,...
    min(1,...
    dot( ...
    progressionAfter,...
    progressionModel))));

fprintf( ...
    'Progression error = %.2f deg\n',...
    progressionAngle);

%% ----------------------------------------------------
% Transform trajectories
%% ----------------------------------------------------

alignedXYZ = struct();

names = fieldnames(xyzDict);

for k = 1:length(names)

    name = names{k};

    traj = xyzDict.(name);

    alignedXYZ.(name) = ...
        traj*R' + T';

end

end