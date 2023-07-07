clear; clc

curr_dir = working_dir();

%% Set Paths
add_paths(curr_dir, ["res/nrsh" ...
                     "res/nrsh/core" ...
                     "res/nrsh/core/WUT_lib" ...
                     "src" ...
                     "src/holo_config" ...
                     "src/reconstruction" ...
                     "src/utils"
                     ])

%% Load hologram configuration
hologram_name = 'CGH_Venus';

rec_dists = 0.2955;
h_pos = [-1 0 1];
v_pos = 0;

single_phase_rec(hologram_name, rec_dists, h_pos, v_pos, 1);
