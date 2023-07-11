clear; clc
addpath('../../src/utils');

% Get absolute path to project
curr_dir = working_dir();

%% Set Paths
add_paths(curr_dir, ["res/nrsh/" ...
                         "res/nrsh/core/" ...
                         "res/nrsh/core/WUT_lib/" ...
                         "src/" ...
                         "src/reconstruction/" ...
                         "src/phase_removal" ...
                         "src/utils/" 
                     ])

%% Load hologram configuration
hologram_name = 'CGH_Venus';

rec_dists = [0.2955];
h_pos = 0;
v_pos = 0;
channel = 1;

single_phase_rec(hologram_name, rec_dists, h_pos, v_pos, channel);
