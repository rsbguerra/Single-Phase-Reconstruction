%% Set Paths
clear; clc
working_dir = working_dir();

add_paths(working_dir, ["res/nrsh/" "res/nrsh/core/"]);

cfg_dir  = [working_dir 'data/config/nrsh_config/'];
save_dir = [working_dir 'data/config/single_phase_config/'];

hologram_dir = '/mnt/data/Holograms/';
holograms = ["CGH_Biplane16k_rgb", "CGH_Venus", "DeepDices16K", "Lowiczanka_Doll", "DeepDices2K"];

for holo_name = holograms
    switch holo_name
        case "CGH_Biplane16k_rgb"
            disp("Creating CGH_Biplane16k_rgb")
            hologram_path = [hologram_dir 'Interfere/Interfere-III/CGH_Biplane16k_rgb.mat'];
            cfg_file = [cfg_dir 'interfereIII/biplane16kETRO_000.txt'];

            %% Load config

            dataset = 'interfere';
            zero_pad = false;
            ap_sizes = [16384 16384];
            usagemode = 'individual';
            h_pos = 0;
            v_pos = 0;
            target_res = [16384 16384];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', false, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');

            rec_dist = 0.0455;

            save([save_dir 'Biplane16k_config.mat'])

        case "CGH_Venus"
            hologram_path = [hologram_dir 'Interfere/Interfere-III/CGH_Venus.mat'];
            cfg_file = [cfg_dir 'interfereIII/venus_000.txt'];

            %% Load config

            dataset = 'interfere';
            zero_pad = false;
            ap_sizes = [2048 2048];
            usagemode = 'individual';
            h_pos = 0.5;
            v_pos = 0.5;
            target_res = [2048 2048];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', false, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');

            rec_dist = 0.2957;
            save([save_dir 'CGH_Venus_config.mat'])

        case "DeepDices16K"
            hologram_path = [hologram_dir 'bcom/DeepDices16K.mat'];
            cfg_file = [cfg_dir 'bcom/DeepDices2k_000.txt'];

            %% Load config

            dataset = 'bcom32';
            zero_pad = false;
            ap_sizes = [16384 16384];
            usagemode = 'individual';
            h_pos = 0;
            v_pos = 0;
            target_res = [16384 16384];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', false, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');

            rec_dist = 0.0185;
            save([save_dir 'DeepDices16K_config.mat'])

        case "DeepDices2K"
            hologram_path = [hologram_dir 'bcom/deepDices2k-AP/deepDices2k.mat'];
            cfg_file = [cfg_dir 'bcom/DeepDices2k_000.txt'];

            %% Load config

            dataset = 'bcom32';
            zero_pad = false;
            ap_sizes = [2048 2048];
            usagemode = 'individual';
            h_pos = 0;
            v_pos = 0;
            target_res = [2048 2048];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', false, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');

            rec_dist = 0.087;
            save([save_dir 'DeepDices2K_config.mat'])

        case "Lowiczanka_Doll"
            hologram_path = [hologram_dir 'wut/opt_Warsaw_Lowiczanka_Doll.mat'];
            cfg_file = [cfg_dir 'wut/lowiczanka_doll_000.txt'];

            %% Load config

            dataset = 'wut_disp_on_axis';
            zero_pad = false;
            ap_sizes = [2016 2016];
            usagemode = 'individual';
            h_pos = [-1 0 1];
            v_pos = 0;
            target_res = [2016 2016];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', false, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');
            info.isFourierDH = 1;
            info.clip_max = -1;
            info.clip_min = -1;

            rec_dist = [1.060 1.030 1.075];
            save([save_dir 'Lowiczanka_Doll_config.mat'])

        otherwise
            disp('Hologram config missing')
    end
end
