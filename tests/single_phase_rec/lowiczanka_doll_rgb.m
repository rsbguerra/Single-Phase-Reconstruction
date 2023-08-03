%% Load hologram configuration
hologram_name = 'Lowiczanka_Doll';

rec_dists = [1.030];
h_pos = 0;
v_pos = 0;
ap_size = {[2016 2016]};
channel = 0;

reconstruct(hologram_name, rec_dists, h_pos, v_pos, ap_size, channel);
