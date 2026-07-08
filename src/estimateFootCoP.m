function CoP = estimateFootCoP(V)
% ESTIMATEFOOTCOP
%
% Estimate the distal end of the 3rd metatarsal from a mouse foot mesh.
%
% INPUT
%   V : Nx3 matrix of STL vertices
%
% OUTPUT
%   CoP : 1x3 coordinates of the estimated center of pressure
%
% Example:
%   [F,V] = stlread('mouse_foot.stl');
%   CoP = estimateFootCoP(V);

%% Center mesh

centroid = mean(V,1);
V0 = V - centroid;

%% Principal component analysis

[coeff,~,~] = pca(V0);

PC1 = coeff(:,1); % Proximal-distal
PC2 = coeff(:,2); % Medio-lateral
PC3 = coeff(:,3); %#ok<NASGU>

%% Projection onto first principal axis

s = V0 * PC1;

%% Determine distal side

nPct = 5;

thrMax = prctile(s,100-nPct);
thrMin = prctile(s,nPct);

sideMax = V0(s >= thrMax,:);
sideMin = V0(s <= thrMin,:);

widthMax = range(sideMax * PC2);
widthMin = range(sideMin * PC2);

if widthMax < widthMin
    PC1 = -PC1;
    s = -s;
end

%% Extract distal region (15% most distal points)

thrDist = prctile(s,85);

distalPts = V0(s >= thrDist,:);

%% Mediolateral coordinate

ml = distalPts * PC2;

%% Central metatarsal region

tol = 0.15 * range(ml);

centralPts = distalPts( ...
    abs(ml - median(ml)) < tol , :);

%% Most distal point within central region

sCentral = centralPts * PC1;

[~,idx] = max(sCentral);

CoP = centralPts(idx,:) + centroid;

end