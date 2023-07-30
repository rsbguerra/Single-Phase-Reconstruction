%% Load hologram configuration
hologram_name = 'CGH_Venus';

rec_dists = 0.2955;
h_pos = 0;
v_pos = 0;
channel = 1;

ap_sizes = {[2048 2048] [2000 2000]};

reconstruct(hologram_name, rec_dists, h_pos, v_pos, ap_sizes, channel);
