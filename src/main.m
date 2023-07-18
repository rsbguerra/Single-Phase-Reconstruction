clear; clc
addpath('./utils');
% Get absolute path to project
curr_dir = working_dir();

%% Set Paths
add_paths(curr_dir, ["res/nrsh/" ...
                     "res/nrsh/core/" ...
                     "res/nrsh/core/WUT_lib/" ...
                     "src/" ...
                     "src/reconstruction/" ...
                     "src/utils/"
                     ])

%% Load hologram configuration
hologram_name = "Lowiczanka_Doll";

rec_dists = 1.030;
h_pos = 0;
v_pos = 0;
channel = [0];

info.ap_sizes = {[2000 3000]};
info.targetres = [2016 2016];

single_phase_rec(hologram_name, rec_dists, h_pos, v_pos, channel);
