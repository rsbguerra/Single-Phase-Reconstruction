clear; clc
%% script imports

addpath('../utils')
add_paths(root_dir, ['src/reconstruction'])

%% path definition

root_dir = working_dir()
save_dir = fullfile(root_dir, 'res/single_phase_holograms/');

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

%% hologram settings
channel = 1;
holograms = ["Lowiczanka_Doll"];

%% phase removal
for holo = holograms
    [original_hologram, info, rec_dist] = load_hologram(holo);
    single_ph_hologram = remove_phases(original_hologram, info, rec_dist, channel);

    save_path = sprintf('%s%s_%s.mat', save_dir, holo, channel2string(channel));
    save(save_path, 'single_ph_hologram', '-v7.3')
end
