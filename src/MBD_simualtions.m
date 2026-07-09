clear; close all; clc

% Import the OpenSim API
import org.opensim.modeling.*

% Mouse number
mouse_age = "22weeks";
mouse_name = "Cage51L";

%% --- File names ---
model_name = strcat(mouse_age,'/',mouse_name,'/Model_data/Model_mouse_right_markers.osim');
kin_mot_name = strcat(mouse_age,'/',mouse_name,'/Model_data/ik_results_output.mot');
grf_mot_name = strcat(mouse_age,'/',mouse_name,'/Model_data/grf_output.mot');
grf_xml_name = strcat(mouse_age,'/',mouse_name,'/Model_data/grf_output.xml');
act_name = strcat(mouse_age,'/',mouse_name,'/Model_data/Mouse_hindlimb_2019_actuators.xml');

% Metrics
cutoff = 20; % filtering frequency
frequency = 120; % kinematic signal
frequency_GRF = 960; % force signal

% Kinematic data
kinematic_data = TimeSeriesTable(kin_mot_name);
time = osimVecToArray(kinematic_data.getIndependentColumn());
Hip_Flexion_Angle = osimVecToArray(kinematic_data.getDependentColumn('Hip_flexion_r'));
Knee_Flexion_Angle = osimVecToArray(kinematic_data.getDependentColumn('Knee_extension_r'));
Ankle_Flexion_Angle = osimVecToArray(kinematic_data.getDependentColumn('Ankle_flexion_r'));

% Filters
[b,a] = butter(4,cutoff/frequency,'low');
Hip_Flexion_Angle = filtfilt(b,a,Hip_Flexion_Angle);
Knee_Flexion_Angle = filtfilt(b,a,Knee_Flexion_Angle);
Ankle_Flexion_Angle = filtfilt(b,a,Ankle_Flexion_Angle);

% GRF data
GRF_data = TimeSeriesTable(grf_mot_name);
GRF_x = osimVecToArray(GRF_data.getDependentColumn('x1_ground_force_vx')); % Anteroposterior
GRF_y = osimVecToArray(GRF_data.getDependentColumn('x1_ground_force_vy')); % Vertical
GRF_z = osimVecToArray(GRF_data.getDependentColumn('x1_ground_force_vz')); % Mediolateral

%% --- Load and initialize model ---
model = Model(model_name);

% % Modify maximal isometric force 
% muscles = model.getMuscles();
% for i = 0:muscles.getSize()-1
%     m = muscles.get(i);
%     fmax_old = m.getMaxIsometricForce();
%     m.setMaxIsometricForce(2 * fmax_old);
% end
% 
% model.print("Model_mouse_right_markers_Fmax2.osim");
% model_name = "Model_mouse_right_markers_Fmax2.osim";
% model = Model(model_name);
% 
% 
% state = model.initSystem();

%% --- Inverse Dynamics Tool ---
id_tool = InverseDynamicsTool();
start_time = time(1);
end_time = time(end);
id_tool.setStartTime(start_time);
id_tool.setEndTime(end_time);
id_tool.setModel(model);
id_tool.setCoordinatesFileName(kin_mot_name);
id_tool.setExternalLoadsFileName(grf_xml_name);
id_tool.setLowpassCutoffFrequency(cutoff);

% Exclude muscles from ID
exclude = ArrayStr();
exclude.append('Muscles');
id_tool.setExcludedForces(exclude);

% Run inverse dynamics
id_tool.run();

%% --- Static Optimization ---
so = StaticOptimization();
so.setActivationExponent(2);
so.setUseMusclePhysiology(false);
so.setStartTime(start_time);
so.setEndTime(end_time);

% AnalyzeTool for Static Optimization
so_analyze_tool = AnalyzeTool();
so_analyze_tool.setName('SO');
so_analyze_tool.setModelFilename(model_name);
so_analyze_tool.setCoordinatesFileName(kin_mot_name);
so_analyze_tool.setExternalLoadsFileName(grf_xml_name);

% Add actuators
forceSet_files = ArrayStr();
forceSet_files.append(act_name);
so_analyze_tool.setForceSetFiles(forceSet_files);

% Add analysis
so_analyze_tool.updAnalysisSet().cloneAndAppend(so);

% Configure and run
so_analyze_tool.setReplaceForceSet(false);
so_analyze_tool.setStartTime(start_time);
so_analyze_tool.setFinalTime(end_time);
so_analyze_tool.setResultsDir('Output_files');
so_analyze_tool.setLowpassCutoffFrequency(cutoff)
so_analyze_tool.print('SO_AnalyzeTool_setup.xml');

% Run Static Optimization
so_analyze_tool = AnalyzeTool('SO_AnalyzeTool_setup.xml', true);
so_analyze_tool.run();

%% --- Joint Reaction Analysis ---
joint_reaction = JointReaction();
joint_reaction.setName('condition');

% Joints to analyze
joint_names = ArrayStr();
joint_names.append('Knee_r');
joint_names.append('Ankle_r');
joint_reaction.setJointNames(joint_names);

% Apply on parent/child bodies
apply_on_bodies = ArrayStr();
apply_on_bodies.append('child');
apply_on_bodies.append('parent');
joint_reaction.setOnBody(apply_on_bodies);

% Express in frame
express_in_frame = ArrayStr();
express_in_frame.append('child');
express_in_frame.append('parent');
joint_reaction.setInFrame(express_in_frame);

% AnalyzeTool for Joint Reactions
jr_tool = AnalyzeTool();
jr_tool.setName('Joint');
jr_tool.setModelFilename(model_name);
jr_tool.setCoordinatesFileName(kin_mot_name);
jr_tool.setExternalLoadsFileName(grf_xml_name);

% Load Static Optimization results
states_storage = Storage('Output_files/SO_StaticOptimization_force.sto');
jr_tool.setStatesStorage(states_storage);

joint_reaction.setForcesFileName('Output_files/SO_StaticOptimization_force.sto');

% Add actuator set if necessary
forceSet_files = ArrayStr();
forceSet_files.append(act_name);
jr_tool.setForceSetFiles(forceSet_files);

% Set times and results directory
jr_tool.setStartTime(start_time);
jr_tool.setFinalTime(end_time);
jr_tool.updAnalysisSet().cloneAndAppend(joint_reaction);
jr_tool.setResultsDir('Output_files');

% Print setup XML and run
jr_tool.print('JointReaction_AnalyzeTool_setup.xml');
jr_tool = AnalyzeTool('JointReaction_AnalyzeTool_setup.xml', true);
jr_tool.run();

%% --- Extract results ---
result_file_path = 'Output_files/Joint_condition_ReactionLoads.sto';
table_joints = TimeSeriesTable(result_file_path);
table_muscles = TimeSeriesTable('Output_files/SO_StaticOptimization_force.sto');
table_moments = TimeSeriesTable('inverse_dynamics.sto');

% Extract net joint moments
moment_hip = osimVecToArray(table_moments.getDependentColumn('Hip_flexion_r_moment'));
moment_knee = osimVecToArray(table_moments.getDependentColumn('Knee_extension_r_moment'));
moment_ankle = osimVecToArray(table_moments.getDependentColumn('Ankle_flexion_r_moment'));

% Extract reaction forces (example: Knee & Ankle)
knee_force_x = osimVecToArray(table_joints.getDependentColumn('Knee_r_on_Leg_r_in_Leg_r_fx'));
knee_force_y = osimVecToArray(table_joints.getDependentColumn('Knee_r_on_Leg_r_in_Leg_r_fy'));
knee_force_z = osimVecToArray(table_joints.getDependentColumn('Knee_r_on_Leg_r_in_Leg_r_fz'));
ankle_force_x = osimVecToArray(table_joints.getDependentColumn('Ankle_r_on_Leg_r_in_Leg_r_fx'));
ankle_force_y = osimVecToArray(table_joints.getDependentColumn('Ankle_r_on_Leg_r_in_Leg_r_fy'));
ankle_force_z = osimVecToArray(table_joints.getDependentColumn('Ankle_r_on_Leg_r_in_Leg_r_fz'));

% Extract muscle forces and actuators
muscle_names = {'FDL','EDL','ST','SM','GA','TA','RF','VM','VL','VI','GP','CF',...
                'BFP_cranial','BFP_mid','BFP_caudal','POP','EHL','SOL','TP',...
                'PL','PT','PB','PDQA','PDQI'};

actuator_names = {'Hip_flexion_r','Knee_extension_r','Ankle_flexion_r'};

% Plots

% Muscles
figure
hold on
for i = 1:length(muscle_names)
    eval([muscle_names{i} ' = osimVecToArray(table_muscles.getDependentColumn(muscle_names{i}));']);
    plot(osimVecToArray(table_muscles.getDependentColumn(muscle_names{i})))
end
legend(muscle_names)
xlabel('Stance phase (%)')
ylabel('Force (N)')
title('Tibia muscle forces')

% Joints
figure
hold on
plot(knee_force_x)
plot(knee_force_y)
plot(knee_force_z)
plot(ankle_force_x)
plot(ankle_force_y)
plot(ankle_force_z)
legend({'Knee_x', 'Knee_y', 'Knee_z', 'Ankle_x', 'Ankle_y', 'Ankle_z'})
xlabel('Stance phase (%)')
ylabel('Force (N)')
title('Tibia joint forces')

% Actuators
figure
hold on
for i = 1:length(actuator_names)
    eval([actuator_names{i} ' = osimVecToArray(table_muscles.getDependentColumn(actuator_names{i}));']);
    plot(1000*osimVecToArray(table_muscles.getDependentColumn(actuator_names{i})))
end
legend(actuator_names)
xlabel('Stance phase (%)')
ylabel('Moment (N.mm)')
title('Reserve actuators')

% Joint angles
figure
hold on
plot(Hip_Flexion_Angle)
plot(Knee_Flexion_Angle)
plot(Ankle_Flexion_Angle)
xlabel('Stance phase (%)')
ylabel ('Angle (°)')
legend({'Hip','Knee','Ankle'})
title('Joint kinematic')

% GRF
figure
hold on
plot(GRF_x)
plot(GRF_y)
plot(GRF_z)
xlabel('Stance phase (%)')
ylabel ('Force (N)')
legend({'Anteroposterior','Vertical','Mediolateral'})
title('Ground Reaction Force')

%% --- Helper function: convert Vec to numeric array ---
function arr = osimVecToArray(vec)
    n = vec.size();
    arr = zeros(n,1);
    for i = 0:n-1
        arr(i+1) = vec.get(i);
    end
end

% Copy the outpus file
muscleForcesFile = 'Output_files/SO_StaticOptimization_force.sto';
jointForcesFile = 'Output_files/Joint_condition_ReactionLoads.sto';
newMuscleForcesFile = strcat(mouse_age,'/',mouse_name,'/Model_data/muscle_forces.sto');
newJointForcesFile = strcat(mouse_age,'/',mouse_name,'/Model_data/joint_forces.sto');
copyfile(muscleForcesFile, newMuscleForcesFile);
copyfile(jointForcesFile, newJointForcesFile);
