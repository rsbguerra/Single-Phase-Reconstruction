clear; clc

%% Set Paths
add_paths(curr_dir, [
                     "res/nrsh"
                     "res/nrsh/core"
                     "res/nrsh/core/WUT_lib"
                     "src"
                     "src/holo_config"
                     "src/reconstruction"
                     "src/utils"
                     ])

%% Load hologram configuration
hologram_name = 'Lowiczanka_Doll';

rec_dists = [1.030, 1.060, 1.075];
h_pos = [-1 0 1];
v_pos = 0;

single_phase_rec(hologram_name, rec_dists, h_pos, v_pos, 1);
