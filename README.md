# Mouse-Gait-OpenSim-Pipeline
MATLAB pipeline for preprocessing mouse gait data and generating OpenSim-compatible OSIM, TRC, MOT, and XML files from Vicon C3D recordings, and running multi-body dynamic simulations.

## Features

Register segmented mouse hindlimb bones and marker 3D model to a template opensim model

Update model marker coordinates

Import Vicon C3D files

Clean and filter marker trajectories

Detect stance phases automatically

Align experimental markers to a mouse OpenSim model

Export normalized .trc files

Process force plate data

Export OpenSim-compatible .mot and .xml files

Prepare inputs for inverse kinematics and inverse dynamics

Run the inverse kinematics

Run multi-body dynamic simulations to estimate muscle and joint forces

## Requirements

MATLAB R2022b or newer

OpenSim 4.4 or newer

BTK Toolbox for MATLAB 0.3.0 or newer

## Installation

Clone the repository

git clone https://github.com/YOURNAME/Mouse-Gait-OpenSim-Pipeline.git

Add BTK and OpenSim to the MATLAB path.

Open MATLAB in the repository folder.

## Running the pipeline

registration_CT_opensim

main

inverse_kinematic

MBD_simulations

## Outputs

*.osim - updated opensim model with personalised marker coordinates 

*.trc — normalized marker trajectories

*.mot — ground reaction forces

*.xml — OpenSim external loads

*.mot - joint angles from inverse kinematic

*.sto muscle and joint forces

## Citation

If you use this pipeline, please cite the repository DOI (generated via Zenodo).

## License

Released under the MIT License.
