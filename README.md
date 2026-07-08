# Mouse-Gait-OpenSim-Pipeline
MATLAB pipeline for preprocessing mouse gait data and generating OpenSim-compatible TRC, MOT, and XML files from Vicon C3D recordings.

## Features

Import Vicon C3D files

Clean and filter marker trajectories

Detect stance phases automatically

Align experimental markers to a mouse OpenSim model

Export normalized .trc files

Process force plate data

Export OpenSim-compatible .mot and .xml files

Prepare inputs for inverse kinematics and inverse dynamics

## Requirements

MATLAB R2022b or newer

OpenSim

BTK Toolbox for MATLAB

## Installation

Clone the repository

git clone https://github.com/YOURNAME/Mouse-Gait-OpenSim-Pipeline.git

Add BTK and OpenSim to the MATLAB path.

Open MATLAB in the repository folder.

## Running the pipeline

main

## Outputs

*.trc — normalized marker trajectories

*.mot — ground reaction forces

*.xml — OpenSim external loads

## Citation

If you use this pipeline, please cite the repository DOI (generated via Zenodo).

## License

Released under the MIT License.
