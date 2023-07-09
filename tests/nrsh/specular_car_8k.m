addpath('../../res/nrsh')
addpath('../../res/nrsh/core')


info = getSettings('cfg_file', '../../data/config/nrsh_config/bcom/specular_car8k_000.txt', ...
    'apertureinpxmode', false, ...
    'ap_sizes', 7, ...
    'h_pos', -10:10:10, ...
    'v_pos', -8:8:8);

load('../../data/input/holograms/specularCar8k.mat')

nrsh(data, 0.0023, info);
