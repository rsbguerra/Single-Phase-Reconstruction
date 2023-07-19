hologram_path = '../../../data/input/holograms/DeepCornellBox_16K.mat';
config_path = '../../../data/config/nrsh_config/interfereV/DeepCornellBox_16K_000.txt';

load(hologram_path)

info = getSettings('cfg_file', config_path, ...
    'apertureinpxmode', true, ...
    'ap_sizes', [4096 4096], ...
    'h_pos', [0 1], ...
    'v_pos', [0 1]);

nrsh(double(H), 0.250, info)
