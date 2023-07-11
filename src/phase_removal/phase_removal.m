clear; clc
%% script imports

addpath('../utils')
root_dir = working_dir();
add_paths(root_dir, "src/reconstruction");

%% path definition

save_dir = fullfile(root_dir, 'data/input/single_phase_holograms/');

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

%% hologram settings
channels = 1;
holograms = ["Lowiczanka_Doll"];

%% phase removal
for holo = holograms

    for c = channels
        [original_hologram, info] = load_hologram(holo);
        hologram = remove_phases(original_hologram, info, info.default_rec_dist(1), c);

        save_path = sprintf('%s%s_%s.mat', save_dir, holo, channel2string(c));
        save(save_path, 'hologram', '-v7.3')
    end

end
