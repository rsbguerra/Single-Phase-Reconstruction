holo_config.name = 'astronaut';
holo_config.mat.path = '../res/holograms/Astronaut_Hol_v2.mat';
holo_config.mat.var = 'u1';

load(holo_config.mat.path, holo_config.mat.var);
holo_config.data = u1

interfere_Cfg_path = 'InterfereCodecCfg'

enc_config.file = fullfile(interfere_Cfg_path, holo_config.name, 'holo_001.txt');

[holo_config.tile_size, holo_config.transform_size, ...
     holo_config.cb_size, holo_config.qb_size] = ...
    readInterfereCfg(enc_config.file);

holo_config

enc_config.maxCoeffBitDepth = 11
enc_config.bs_max_iter = 100
enc_config.gs_max_iter = 10

generate_inputs(holo_config, enc_config)
