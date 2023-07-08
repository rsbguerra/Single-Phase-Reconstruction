clear; clc

curr_dir = working_dir();

%% Set Paths
add_paths(curr_dir, ["res/nrsh/" ...
                     "res/nrsh/core/" ...
                     "res/nrsh/core/WUT_lib/" ...
                     "src/" ...
                     "src/holo_config/" ...
                     "src/reconstruction/" ...
                     "src/utils/"
                     ])

%% Load hologram configuration
hologram_name = 'DeepDices2K';

rec_dists = 0.086;
h_pos = [-1 0 1];
v_pos = 0;
channel = 1;

% Testing if the reconstruction function is being used correctly
% After testing, single_phase_rec will be used
reconstruct(hologram_name, rec_dists, h_pos, v_pos);

% single_phase_rec(hologram_name, rec_dists, h_pos, v_pos, channel);
