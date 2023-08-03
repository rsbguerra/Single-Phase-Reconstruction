hologram_path = '/mnt/data/code/Single-Phase-Reconstruction/data/input/holograms/opt_Warsaw_Lowiczanka_Doll.mat';
config_path = '/mnt/data/code/Single-Phase-Reconstruction/data/config/nrsh_config/wut/lowiczanka_doll_000.txt';

load(hologram_path)

nrsh(dh, 'wut_disp', config_path, 1.06, [0 0], 1, 0)
