clc; clear; close all
import org.opensim.modeling.*

%% Inverse kinematic
% 1. Setup File Paths
mouse_age = "19weeks";
mouse_name = "Cage6none";
trcName = 'cage6none19weeks10_StanceNorm_04.trc';

modelFile  = strcat(mouse_age,'/',mouse_name,'/Model_data/Model_mouse_right_markers.osim');
trcFile    = strcat(mouse_age,'/',mouse_name,'/Vicon_data/',trcName);
resultsDir = 'IK_Results';

if ~exist(resultsDir, 'dir'); mkdir(resultsDir); end

% 2. Initialize Model
model = Model(modelFile);
model.initSystem();

% 3. Initialize IK Tool
ikTool = InverseKinematicsTool();
ikTool.setModel(model);
ikTool.setMarkerDataFileName(trcFile);
ikTool.setResultsDir(resultsDir);

% 4. Custom Marker Weighting
% Define your weights in a Map or Cell array
markerWeights = {
    'Right_Illiac', 1.0; 
    'Right_Hip', 1.0;
    'Right_Knee', 1.0;
    'Right_Ankle', 1.0;
    'Right_Met', 1.0;
    'Left_Illiac', 1.0; 
};

% Clear existing tasks and add new ones
ikTaskSet = ikTool.getIKTaskSet();
ikTaskSet.clearAndDestroy();

for i = 1:size(markerWeights, 1)
    name = markerWeights{i,1};
    weight = markerWeights{i,2};

    newMarkerTask = IKMarkerTask();
    newMarkerTask.setName(name);
    newMarkerTask.setApply(true);
    newMarkerTask.setWeight(weight);

    ikTaskSet.adoptAndAppend(newMarkerTask);
end

% 5. Lock/Unlock Degrees of Freedom (Coordinate Tasks)
% Locking a coordinate forces IK to ignore the marker data for that DOF
coordsToLock = {'zR_TorsoToPelvis', 'MTP_flexion_r'};

for i = 1:length(coordsToLock)
    coordName = coordsToLock{i};
    if model.getCoordinateSet().contains(coordName)
        % Set the coordinate to locked in the model itself
        model.getCoordinateSet().get(coordName).set_locked(true);
    end
end

% 6. Set Time Range and Output Name
markerData = MarkerData(trcFile);
ikTool.setStartTime(markerData.getStartFrameTime());
ikTool.setEndTime(markerData.getLastFrameTime());

% Specify the name of the output .mot file
outputMotionFile = 'ik_results_output.mot';
ikTool.setOutputMotionFileName(fullfile(resultsDir, outputMotionFile));

% 7. Run IK
disp(['Running IK. Output will be saved to: ', outputMotionFile]);

% Save the setup file (.xml) for future record/OpenSim GUI use
ikTool.print(fullfile(resultsDir, 'ik_setup_settings.xml')); 

% Execute
ikTool.run();

disp('IK Processing Complete. The .mot file has been generated.');

%% --- 0. Settings ---
Scale = 0.01; 
InDegrees = true;
motionFile = 'IK_Results/ik_results_output.mot';
grfFile = strcat(mouse_age,'/',mouse_name,'/Model_data/cage6none19weeks10_StanceNorm_04_grf.mot');
markerRadius = 0.0005; 

% Read the GRF file
grfTable = readtable(grfFile,'FileType','text','Delimiter','\t','HeaderLines',5);

grfTime = grfTable.time;

GRF = [ ...
    grfTable.("x1_ground_force_vx"), ...
    grfTable.("x1_ground_force_vy"), ...
    grfTable.("x1_ground_force_vz")];

COP = [ ...
    grfTable.("x1_ground_force_px"), ...
    grfTable.("x1_ground_force_py"), ...
    grfTable.("x1_ground_force_pz")];

% --- NEW: Video Settings ---
saveVideo = true; % Set to false if you just want to preview
videoName = 'Hindlimb_Animation.avi';
v = VideoWriter(videoName, 'Uncompressed AVI');
v.FrameRate = 10; % Adjust based on your pause(0.1)
if saveVideo, open(v); end

% --- 1. Load Model & Motion ---
m(1).model = Model(modelFile);
m(1).state = m(1).model.initSystem();
m(1).color = [0.8, 0.8, 0.8]; 
m(1).alpha = 0.8; 

motion = Storage(motionFile);
labels = motion.getColumnLabels();

trcData = MarkerData(trcFile);
nExpMarkers = trcData.getNumMarkers();
nFrames = trcData.getNumFrames();
expMarkerNames = {'Right_Illiac', 'Right_Hip', 'Right_Knee', 'Right_Ankle', 'Right_Met',...
                  'Left_Illiac'}; % Must match TRC column names

% --- 2. Setup Visualization ---
bodies = {'Pelvis', 'Thigh_r', 'Leg_r', 'Foot_r', 'Toes_r'}; 
stls   = {'Geometry/Pelvis_r.stl', 'Geometry/femur_r.stl', ...
          'Geometry/tibfib_r.stl', 'Geometry/foot_r.stl', 'Geometry/phalanges_r.stl'};

figure('Color', 'w'); hold on; axis equal; view(2); light; grid off;

% Initialize Meshes and Capture Neutral Transforms
m(1).model.realizePosition(m(1).state);
for i = 1:length(bodies)
    if exist(stls{i}, 'file')
        TR = stlread(stls{i});
        m(1).mesh(i).V_orig = TR.Points * Scale;
        m(1).mesh(i).bodyName = bodies{i};
        m(1).mesh(i).handle = patch('Vertices', m(1).mesh(i).V_orig, ...
            'Faces', TR.ConnectivityList, 'FaceColor', m(1).color, ...
            'EdgeColor', 'none', 'FaceAlpha', m(1).alpha, 'FaceLighting', 'gouraud');
        
        body = m(1).model.getBodySet().get(bodies{i});
        T_Neutral = body.getTransformInGround(m(1).state);
        R_n = T_Neutral.R().asMat33(); p_n = T_Neutral.p();
        M_Neutral = [R_n.get(0,0), R_n.get(0,1), R_n.get(0,2), p_n.get(0);
                     R_n.get(1,0), R_n.get(1,1), R_n.get(1,2), p_n.get(1);
                     R_n.get(2,0), R_n.get(2,1), R_n.get(2,2), p_n.get(2);
                     0, 0, 0, 1];
        m(1).mesh(i).M_Neutral_Inv = inv(M_Neutral);
    end
end

% --- 3. Setup Spheres ---
[uX, uY, uZ] = sphere(10);
uX = uX*markerRadius; uY = uY*markerRadius; uZ = uZ*markerRadius;

% Model Markers (Pink)
markerSet = m(1).model.getMarkerSet();
for k = 1:markerSet.getSize()
    m(1).marker(k).handle = surf(uX, uY, uZ, 'FaceColor', [1.0, 0.41, 0.70], 'EdgeColor', 'none');
end

% Experimental Markers (Blue)
for k = 1:length(expMarkerNames)
    m(1).expMarker(k).handle = surf(uX, uY, uZ, 'FaceColor', [0 0 1], 'EdgeColor', 'none');
end

%% Ground reaction force arrow
GRFscale = 0.1; % adjust visually
grfHandle = quiver3( 0,0,0,0,0,0,'LineWidth',2,'MaxHeadSize',0.5);

% --- 4. ANIMATION LOOP ---
for f = 0:nFrames-1
    dataVector = motion.getStateVector(f).getData();
    
    % [A through F: Your existing update logic remains exactly as is]
    
    % A. Global Translation
    globalOffset = [dataVector.get(4), dataVector.get(5), dataVector.get(6)];
    
    % B. Update Model Rotations (SKIP TRANSLATIONS)
    for j = 0:labels.size() - 1
        colName = char(labels.get(j));
        if m(1).model.getCoordinateSet().contains(colName)
            if ~contains(colName, '_T') && ~contains(colName, 'pos')
                val = dataVector.get(j - 1); 
                if InDegrees, val = val * (pi/180); end 
                m(1).model.getCoordinateSet().get(colName).setValue(m(1).state, val);
            else
                m(1).model.getCoordinateSet().get(colName).setValue(m(1).state, 0);
            end
        end
    end
    
    m(1).model.realizePosition(m(1).state);
    
    % D. Update Bone Meshes
    for i = 1:length(m(1).mesh)
        body = m(1).model.getBodySet().get(m(1).mesh(i).bodyName);
        T = body.getTransformInGround(m(1).state);
        R_curr = T.R().asMat33(); p_curr = T.p();
        M_Abs = [R_curr.get(0,0), R_curr.get(0,1), R_curr.get(0,2), p_curr.get(0);
                 R_curr.get(1,0), R_curr.get(1,1), R_curr.get(1,2), p_curr.get(1);
                 R_curr.get(2,0), R_curr.get(2,1), R_curr.get(2,2), p_curr.get(2);
                 0, 0, 0, 1];
        M_Final = M_Abs * m(1).mesh(i).M_Neutral_Inv;
        new_V = (m(1).mesh(i).V_orig * M_Final(1:3, 1:3)') + (M_Final(1:3, 4)' + globalOffset);
        set(m(1).mesh(i).handle, 'Vertices', new_V);
    end
    
    % E. Update Model Markers
    for k = 1:markerSet.getSize()
        loc = markerSet.get(k-1).getLocationInGround(m(1).state);
        set(m(1).marker(k).handle, 'XData', uX + loc.get(0) + globalOffset(1), ...
                                   'YData', uY + loc.get(1) + globalOffset(2), ...
                                   'ZData', uZ + loc.get(2) + globalOffset(3));
    end

    % F. Update Experimental Markers
    frameData = trcData.getFrame(f);
    for k = 1:length(expMarkerNames)
        mIdx = trcData.getMarkerIndex(expMarkerNames{k});
        p_exp_raw = frameData.getMarker(mIdx);
        set(m(1).expMarker(k).handle, 'XData', uX + p_exp_raw.get(0), ...
                                      'YData', uY + p_exp_raw.get(1), ...
                                      'ZData', uZ + p_exp_raw.get(2));
    end

    %% G. Update GRF

    if f+1 <= size(GRF,1)
    
        cop = COP(f+1,:);
    
        force = GRF(f+1,:);
    
        set(grfHandle,...
            'XData',cop(1),...
            'YData',cop(2),...
            'ZData',cop(3),...
            'UData',force(1)*GRFscale,...
            'VData',force(2)*GRFscale,...
            'WData',force(3)*GRFscale);
    
    end

    drawnow limitrate;
    
    % --- NEW: Capture Frame for Video ---
    if saveVideo
        frame = getframe(gcf); % Captures the current figure
        writeVideo(v, frame);
    end
    
    pause(0.01);
end

% --- NEW: Finalize Video ---
if saveVideo
    close(v);
    fprintf('Video saved as %s\n', videoName);
end