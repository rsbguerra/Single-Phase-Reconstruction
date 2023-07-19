hologram_path = '../../../data/input/holograms/DeepChess.mat';
config_path = '../../../data/config/nrsh_config/interfereIV/deepchess2_000.txt';

load(hologram_path)

info = getSettings('cfg_file', config_path, ...
    'apertureinpxmode', true, ...
    'ap_sizes', [2048 2048], ...
    'h_pos', [0 1], ...
    'v_pos', [0]);

nrsh(double(dh), 0.3964, info)
