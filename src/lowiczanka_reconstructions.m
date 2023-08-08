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

    for a = 1:length(ap_sizes)

        for d = rec_dists

            for h = h_pos

                for v = v_pos
                    [hol_rendered, info] = reconstruct(hologram_name, d, h, v, ap_sizes{a}, c);
                    save_holo(hologram_name, hol_rendered, info, d, h, v, ap_sizes{a}, c, "png");

                    figure_name = sprintf("%s_%s_%g_[%dx%d]_[%gx%g]_phase_diff.mat", hologram_name, ch_str, rec_dist, ...
                        ap_sizes{a}(1), ap_sizes{s}(2), h_pos, v_pos, format);
                    figure_path = fullfile(figure_dir, figure_name);

                    save(figure_path, "hol_rendered", "-v7.3")

                end

            end

        end

    end

end
