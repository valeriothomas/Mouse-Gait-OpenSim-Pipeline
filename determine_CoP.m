%% Load STL

stl_foot = stlread('C:\Users\md1tva\Desktop\Model_rat_Johnson\Geometry\foot.stl');
F = stl_foot.ConnectivityList;
V = stl_foot.Points;

%% PCA

centroid = mean(V,1);
V0 = V - centroid;

[coeff,~,latent] = pca(V0);

PC1 = coeff(:,1);   % proximal-distal
PC2 = coeff(:,2);   % medio-lateral
PC3 = coeff(:,3);

%% Projection onto PC1

s = V0*PC1;

%% Determine distal side

nPct = 5;

thrMax = prctile(s,100-nPct);
thrMin = prctile(s,nPct);

sideMax = V0(s>=thrMax,:);
sideMin = V0(s<=thrMin,:);

widthMax = range(sideMax*PC2);
widthMin = range(sideMin*PC2);

if widthMax > widthMin
    distalSign = +1;
else
    distalSign = -1;
    PC1 = -PC1;
    s = -s;
end

%% Extract distal region (15%)

thrDist = prctile(s,85);

distalPts = V0(s>=thrDist,:);

%% Mediolateral coordinate

ml = distalPts*PC2;

%% Central metatarsal region

tol = 0.15*range(ml);

centralPts = distalPts( ...
    abs(ml-median(ml)) < tol , :);

%% Most distal point of central metatarsal

sCentral = centralPts*PC1;

[~,idx] = max(sCentral);

GRF_point = centralPts(idx,:) + centroid;

%% Visualization

figure;
trisurf(F,V(:,1),V(:,2),V(:,3), ...
    'FaceColor',[0.8 0.8 0.8], ...
    'EdgeColor','none');
axis equal
camlight
lighting gouraud
hold on

scatter3(GRF_point(1), ...
         GRF_point(2), ...
         GRF_point(3), ...
         150,'r','filled');

title('Estimated distal end of 3rd metatarsal');