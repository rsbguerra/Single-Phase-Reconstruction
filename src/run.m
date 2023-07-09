clear; clc

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
hologram_name = 'DeepDices8K4K';

rec_dists = 0.331;
h_pos = [-0.5 0.5];
v_pos = [-0.75 0.75];
channel = 1;

%% Testing if the reconstruction function is being used correctly
% After testing, single_phase_rec will be used

reconstruct_nrsh(hologram_name, rec_dists, h_pos, v_pos)
% reconstruct(hologram_name, rec_dists, h_pos, v_pos);
% single_phase_rec(hologram_name, rec_dists, h_pos, v_pos, channel);
