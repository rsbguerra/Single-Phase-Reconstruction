hologram_path = '../../data/input/holograms/Astronaut_Hol_v2.mat';
config_path = '../../data/config/nrsh_config/emergimg/astronaut_000.txt';

load(hologram_path)

info = getSettings('cfg_file', config_path, ...
    'apertureinpxmode', true, ...
    'ap_sizes', [1940 2588], ...
    'h_pos', 0, ...
    'v_pos', 0);

nrsh(double(data.u1), -0.172, info)
