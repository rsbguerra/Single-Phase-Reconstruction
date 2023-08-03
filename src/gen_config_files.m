%% Set Paths
clear; clc
addpath('./utils')

working_dir = working_dir();

add_paths(working_dir, ["src/" "res/nrsh/" "res/nrsh/core/"]);

cfg_dir = [working_dir 'data/config/nrsh_config/'];
save_dir = [working_dir 'data/config/single_phase_config/'];
hologram_dir = [working_dir 'data/input/holograms/'];
single_phase_dir = [working_dir 'data/input/single_phase_holograms/'];

holograms = ["CGH_Venus" "CGH_Biplane16k_rgb" "DeepDices16K" "DeepDices2K" "DeepDices8K4K" "Lowiczanka_Doll"];

for holo_name = holograms
    fprintf(1, 'Creating %s configuration...\n', holo_name)

    switch holo_name
        case "CGH_Biplane16k_rgb"
            hologram_path = [hologram_dir 'CGH_Biplane16k_rgb.mat'];
            single_phase_path = [single_phase_dir 'CGH_Biplane16k_rgb_%s.mat'];
            cfg_file = [cfg_dir 'interfereIII/biplane16k_000.txt'];

            %% Load config

            info.dataset = 'interfere';
            info.rec_par_cfg = read_render_cfg(cfg_file, dataset);
            info.default_rec_dist = 0.0455;

            save_path = [save_dir 'Biplane16k_config.mat'];

        case "CGH_Venus"
            hologram_path = [hologram_dir 'CGH_Venus.mat'];
            single_phase_path = [single_phase_dir 'CGH_Venus_%s.mat'];
            cfg_file = [cfg_dir 'interfereIII/venus_000.txt'];

            %% Load config
            info.dataset = 'interfere';
            info.rec_par_cfg = read_render_cfg(cfg_file, dataset);
            info.default_rec_dist = 0.2957;

            save_path = [save_dir 'CGH_Venus_config.mat'];

        case "DeepDices16K"
            hologram_path = [hologram_dir 'DeepDices16K.mat'];
            single_phase_path = [single_phase_dir 'DeepDices16K_%s.mat'];
            cfg_file = [cfg_dir 'bcom/DeepDices2k_000.txt'];

            %% Load config
            info.dataset = 'bcom32';
            info.rec_par_cfg = read_render_cfg(cfg_file, dataset);
            info.default_rec_dist = 0.0185;

            save_path = [save_dir 'DeepDices16K_config.mat'];

        case "DeepDices2K"
            hologram_path = [hologram_dir 'deepDices2k.mat'];
            single_phase_path = [single_phase_dir 'DeepDices2K_%s.mat'];
            cfg_file = [cfg_dir 'bcom/DeepDices2k_000.txt'];

            %% Load config

            info.dataset = 'bcom32';
            info.rec_par_cfg = read_render_cfg(cfg_file, dataset);
            info.default_rec_dist = 0.087;

            save_path = [save_dir 'DeepDices2K_config.mat'];

        case "DeepDices8K4K"
            hologram_path = [hologram_dir 'deepDices8k4k.mat'];
            single_phase_path = [single_phase_dir 'DeepDices8K4K_%s.mat'];
            cfg_file = [cfg_dir 'bcom/DeepDices8k4k_000.txt'];

            %% Load config

            info.dataset = 'bcom32';
            info.rec_par_cfg = read_render_cfg(cfg_file, dataset);
            info.default_rec_dist = 0.3;

            save_path = [save_dir 'DeepDices8K4K_config.mat'];

        case "Lowiczanka_Doll"
            hologram_path = [hologram_dir 'opt_Warsaw_Lowiczanka_Doll.mat'];
            single_phase_path = [single_phase_dir 'Lowiczanka_Doll_%s.mat'];
            cfg_file = [cfg_dir 'wut/lowiczanka_doll_000.txt'];

            %% Load config

            info.dataset = 'wut_disp_on_axis';
            info.rec_par_cfg = read_render_cfg(cfg_file, dataset);
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

    info.direction = 'forward';

    save(save_path, ...
        'info', ...
        'single_phase_path', ...
    'hologram_path');

    fprintf(1, 'Configuration file saved as %s.\n\n', save_path)

end
