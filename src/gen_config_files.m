%% Set Paths
clear; clc
addpath('./utils')

working_dir = working_dir();

add_paths(working_dir, ["src/" "res/nrsh/" "res/nrsh/core/"]);

cfg_dir = [working_dir 'data/config/nrsh_config/'];
save_dir = [working_dir 'data/config/single_phase_config/'];
hologram_dir = [working_dir 'data/input/holograms/'];
single_phase_dir = [working_dir 'data/input/single_phase_holograms/'];

holograms = ["Lowiczanka_Doll"];

for holo_name = holograms
    fprintf(1, 'Creating %s configuration...\n', holo_name)

    switch holo_name
        case "CGH_Biplane16k_rgb"

            hologram_path = [hologram_dir 'CGH_Biplane16k_rgb.mat'];
            single_phase_path = [single_phase_dir 'CGH_Biplane16k_rgb_%s.mat'];
            cfg_file = [cfg_dir 'interfereIII/biplane16kETRO_000.txt'];

            %% Load config

            dataset = 'interfere';
            zero_pad = false;
            usagemode = 'individual';
            h_pos = 0;
            v_pos = 0;
            ap_sizes = [16384 16384];
            target_res = [16384 16384];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', true, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');

            info.default_rec_dist = 0.0455;
            save_path = [save_dir 'Biplane16k_config.mat'];

        case "CGH_Venus"
            hologram_path = [hologram_dir 'CGH_Venus.mat'];
            single_phase_path = [single_phase_dir 'CGH_Venus_%s.mat'];
            cfg_file = [cfg_dir 'interfereIII/venus_000.txt'];

            %% Load config
            info.dataset = 'interfere';
            info.direction = 'forward'
            info.rec_par_cfg = read_render_cfg(cfg_file, dataset);

            info.default_rec_dist = 0.2957;

            save_path = [save_dir 'CGH_Venus_config.mat'];

        case "DeepDices16K"
            hologram_path = [hologram_dir 'DeepDices16K.mat'];
            single_phase_path = [single_phase_dir 'DeepDices16K_%s.mat'];
            cfg_file = [cfg_dir 'bcom/DeepDices2k_000.txt'];

            %% Load config

            dataset = 'bcom32';
            zero_pad = false;
            usagemode = 'individual';
            h_pos = 0;
            v_pos = 0;
            ap_sizes = [16384 16384];
            target_res = [16384 16384];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', true, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');
            info.default_rec_dist = 0.0185;

            save_path = [save_dir 'DeepDices16K_config.mat'];

        case "DeepDices2K"
            hologram_path = [hologram_dir 'deepDices2k.mat'];
            single_phase_path = [single_phase_dir 'DeepDices2K_%s.mat'];
            cfg_file = [cfg_dir 'bcom/DeepDices2k_000.txt'];

            %% Load config

            dataset = 'bcom32';
            zero_pad = false;
            usagemode = 'individual';
            h_pos = 0;
            v_pos = 0;
            ap_sizes = [2048 2048];
            target_res = [2048 2048];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', true, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');
            info.default_rec_dist = 0.087;

            save_path = [save_dir 'DeepDices2K_config.mat'];

        case "DeepDices8K4K"
            hologram_path = [hologram_dir 'deepDices8k4k.mat'];
            single_phase_path = [single_phase_dir 'DeepDices8K4K_%s.mat'];
            cfg_file = [cfg_dir 'bcom/DeepDices8k4k_000.txt'];

            %% Load config

            dataset = 'bcom32';
            zero_pad = false;
            usagemode = 'individual';
            h_pos = 0;
            v_pos = 0;
            ap_sizes = [4320 7680];
            target_res = [4096 4096];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', true, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'targetres', target_res, ...
                'direction', 'forward', ...
                'resize_fun', 'DR');
            info.default_rec_dist = 0.3;

            save_path = [save_dir 'DeepDices8K4K_config.mat'];

        case "Lowiczanka_Doll"
            hologram_path = [hologram_dir 'opt_Warsaw_Lowiczanka_Doll.mat'];
            single_phase_path = [single_phase_dir 'Lowiczanka_Doll_%s.mat'];
            cfg_file = [cfg_dir 'wut/lowiczanka_doll_000.txt'];

            %% Load config

            dataset = 'wut_disp_on_axis';
            zero_pad = false;
            usagemode = 'individual';
            h_pos = [-1 0 1];
            v_pos = 0;
            ap_sizes = [2016 2016];
            target_res = [2016 2016];

            info = getSettings('dataset', dataset, ...
                'zero_pad', zero_pad, ...
                'cfg_file', cfg_file, ...
                'usagemode', usagemode, ...
                'ap_sizes', ap_sizes, ...
                'apertureinpxmode', true, ...
                'h_pos', h_pos, ...
                'v_pos', v_pos, ...
                'direction', 'forward', ...
                'resize_fun', @(x) imresize(x, target_res, 'bilinear'));

            info.default_rec_dist = [1.060 1.030 1.075];
            info.isFourierDH = 1;
            info.clip_max = -1;
            info.clip_min = -1;

            save_path = sprintf("%s%s_config.mat", save_dir, holo_name);

        otherwise
            E = MException('gen_config_files:InvalidHologram', ...
                'Hologram %s not recognized', holo_name);
            throw(E)
    end

    if ~exist(save_dir, "dir")
        mkdir(save_dir);
    end

    save(save_path, ...
        'info', ...
        'single_phase_path', ...
    'hologram_path');

    fprintf(1, 'Configuration file saved as %s.\n\n', save_path)

end
