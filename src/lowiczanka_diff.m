clear; clc
addpath('./utils');

% Get absolute path to project
curr_dir = working_dir();

%% Set Paths
add_paths(curr_dir, ["res/nrsh/" ...
                         "res/nrsh/core/" ...
                         "res/nrsh/core/WUT_lib/" ...
                         "src/" ...
                         "src/hologram/" ...
                         "src/utils/"
                     ])

%% Load hologram configuration
hologram_name = "Lowiczanka_Doll";

rec_dists = [1.030 1.06 1.075];
h_pos = [-1 0 1];
v_pos = 0;
channel = [1 2 3];
ap_sizes = {[2000 3000] [2000 6000] [2016 2016] [0 0]};

for c = channel

    fprintf("Loading hologram %s...\n", hologram_name)
    [original_hologram, info] = load_hologram(hologram_name, channel);

    for a = 1:length(ap_sizes)

        for d = rec_dists

            for h = h_pos

                for v = v_pos

                    [hol_rendered, info] = reconstruct(hologram_name, d, h, v, ap_sizes{a}, c);
                    [am_diff, ph_diff] = reconst_diff(original_hologram, hol_rendered);


                end

            end

        end

    end

end
