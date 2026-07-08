clear
clc

%% Configuration

ACQUISITION_DATES = {"22weeks"};
MOUSE_NAMES = {"1R"};
CAGE_NUMBER = 6;

SAMPLING_RATE = 120;
FORCE_RATE = 960;
MIN_SPEED = 0.25;

MARKER_NAMES = { ...
    'RASI',...
    'RightHIP',...
    'RightKNEE',...
    'RightANKLE',...
    'RightMET',...
    'LASI'};

MARKER_TRC_NAMES = { ...
    'Right_Illiac',...
    'Right_Hip',...
    'Right_Knee',...
    'Right_Ankle',...
    'Right_Met',...
    'Left_Illiac'};

all_grf_cycles = {};

%% Main Loop

for d = 1:length(ACQUISITION_DATES)

    date = ACQUISITION_DATES{d};

    fprintf('\nProcessing acquisition date: %s\n',date);

    for m = 1:length(MOUSE_NAMES)

        mouseName = MOUSE_NAMES{m};
        
        if CAGE_NUMBER == 5
            filePrefix = sprintf('cage5%s%s',mouseName,date);
            folder = fullfile( ...
            char(date), ...
            ['cage5' char(mouseName)], ...
            'Vicon_data');
        else
            filePrefix = sprintf('cage6%s%s',mouseName,date);
            folder = fullfile( ...
            char(date), ...
            ['cage6' char(mouseName)], ...
            'Vicon_data');
        end

        disp(folder)

        trials = getFileNumbers(folder,filePrefix,'.c3d');

        fprintf('Found %d trials\n',length(trials));

        for t = 1:length(trials)

            trial = trials(t);

            c3dFile = fullfile(folder,...
                sprintf('%s%d.c3d',filePrefix,trial));

            baseName = sprintf('%s%d',filePrefix,trial);

            if ~isfile(c3dFile)
                warning('%s not found',c3dFile);
                continue
            end

            fprintf('Processing %s\n',c3dFile)

            %% Load markers

            xyz = loadMarkers(c3dFile,MARKER_NAMES);

            %% Load force plate

            [Fx,Fy,Fz,Mx,My,Mz] = ...
                loadForcePlateData(c3dFile);

            [Fx,Fy,Fz,Mx,My,Mz] = ...
                preprocessForcePlate(...
                Fx,Fy,Fz,Mx,My,Mz);

            %% Interpolate internal gaps

            markerNames = fieldnames(xyz);

            for k=1:length(markerNames)

                name = markerNames{k};

                xyz.(name) = ...
                    interpolateInternalNaNs(...
                    xyz.(name));

            end

            %% Marker processing

            xyz = processHindlimbMarkers(xyz);

            %% OpenSim model

            MODEL_OSIM_PATH = ...
                '../Model_data/Model_mouse_right_markers.osim';

            if CAGE_NUMBER == 5
                MODEL_OSIM_PATH = fullfile(char(date),['cage5' char(mouseName)],'Model_data', 'Model_mouse_right_markers.osim');
            else
                MODEL_OSIM_PATH = fullfile(char(date),['cage6' char(mouseName)],'Model_data', 'Model_mouse_right_markers.osim');
            end

            %% Detect stance

            framesR = detectStancePhasesFoot(...
                xyz,...
                SAMPLING_RATE,...
                MIN_SPEED);

            %% Export TRCs
            
            if CAGE_NUMBER == 5
                outputMotionFolder = fullfile(char(date),['cage5' char(mouseName)],'Model_data');
            else
                outputMotionFolder = fullfile(char(date),['cage6' char(mouseName)],'Model_data');
            end

            [Rlist,Tlist] = ...
                processStanceTrajectories(...
                xyz,...
                framesR,...
                MARKER_NAMES,...
                baseName,...
                MARKER_TRC_NAMES,...
                MODEL_OSIM_PATH,...
                SAMPLING_RATE,...
                outputMotionFolder,...
                MIN_SPEED);

            %% Export GRFs

            for c = 1:size(framesR,1)

                f0 = framesR(c,1);
                f1 = framesR(c,2);
                
                FyNorm = exportGRFCycle(...
                    baseName,...
                    c,...
                    f0,...
                    f1,...
                    Fx,Fy,Fz,...
                    Mx,My,Mz,...
                    Rlist{c},...
                    Tlist{c},...
                    outputMotionFolder,...
                    FORCE_RATE);

                if ~isempty(FyNorm)
                    all_grf_cycles{end+1} = FyNorm;
                end
            end
        end
    end
end

fprintf('\nFinished Successfully\n')
