function [original_hologram, info] = load_hologram(hologram_name)

working_dir = regexp(pwd, '\S*(?=single_phase_rec\/phase_removal)', 'match');
config_dir = fullfile(working_dir{1}, 'single_phase_rec/holo_config/');

    switch hologram_name
        case "CGH_Biplane16k_rgb"
            vars = load(fullfile(config_dir, 'Biplane16k_config.mat'), 'hologram_path', 'rec_dist', 'info');
            info = vars.info;
            load(vars.hologram_path, 'CGH');
            original_hologram = CGH.Hol;

        case "CGH_Venus"
            vars = load(fullfile(config_dir,'CGH_Venus_config.mat'), 'hologram_path', 'rec_dist', 'info');
            info = vars.info;
            load(vars.hologram_path, 'CGH');
            original_hologram = CGH.Hol;

        case "DeepDices16K"
            vars = load(fullfile(config_dir, 'DeepDices16K_config.mat'), 'hologram_path', 'rec_dist', 'info');
            info = vars.info;
            load(vars.hologram_path, 'data');
            original_hologram = single(data);

        case "DeepDices2K"
            vars = load(fullfile(config_dir, 'DeepDices2K_config.mat'), 'hologram_path', 'rec_dist', 'info');
            info = vars.info;
            load(vars.hologram_path, 'data');
            original_hologram = single(data);

        case "Lowiczanka_Doll"
            vars = load(fullfile(config_dir, 'Lowiczanka_Doll_config.mat'), 'hologram_path', 'rec_dist', 'info');
            info = vars.info;
            load(vars.hologram_path, 'dh');
            original_hologram = double(dh);
        otherwise
            warning([hologram_name ' is not a valid hologram.'])
            return
    end
end
