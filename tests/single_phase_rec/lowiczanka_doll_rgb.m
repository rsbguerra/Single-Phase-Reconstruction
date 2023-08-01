%% Load hologram configuration
hologram_name = 'Lowiczanka_Doll';

rec_dists = [1.030 1.06 1.075];
h_pos = 0;
v_pos = 0;
ap_size = {[2000 2000] [2000 3000]};
channel = [1 2 3 0];

reconstruct(hologram_name, rec_dists, h_pos, v_pos, ap_size, channel);
