info = getSettings('cfg_file', '../../data/config/nrsh_config/interfereII/chess8kd_000.txt', ...
    'apertureinpxmode', false, ...
    'ap_sizes', 7);

load('../../data/input/holograms/CGH_chess8KD.mat')

nrsh(CGH.Hol, (0.014:0.001:0.016), info);
