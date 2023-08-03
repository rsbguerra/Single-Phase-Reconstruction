hologram_path = '/mnt/data/code/Single-Phase-Reconstruction/data/input/holograms/opt_Warsaw_Lowiczanka_Doll.mat';
config_path = '/mnt/data/code/Single-Phase-Reconstruction/data/config/nrsh_config/wut/lowiczanka_doll_000.txt';

load(hologram_path);

nrsh(dh, 'wut_disp_on_axis', config_path, 1.06, {[2000 6000] [2000 3000]}, 0, 0);
