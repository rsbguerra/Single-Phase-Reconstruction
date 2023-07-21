hologram_path = '../../../data/input/holograms/opt_Warsaw_Lowiczanka_Doll.mat';
config_path = '../../../data/config/nrsh_config/wut/lowiczanka_doll_000.txt';

load(hologram_path)

info = getSettings('cfg_file', config_path, ...
    'apertureinpxmode', true, ...
    'ap_sizes', {[2016 2016]}, ...
    'h_pos', [0 1], ...
    'v_pos', [0]);

nrsh(double(dh), 1.06, info)