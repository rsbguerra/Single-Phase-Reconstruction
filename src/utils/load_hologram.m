function [hologram, info] = load_hologram(hologram_name, channel)

    if nargin < 2
        channel = 0;
    end

    curr_dir = working_dir();
    config_dir = fullfile(curr_dir, 'data/config/single_phase_config/');

    switch hologram_name
        case "CGH_Biplane16k_rgb"
            vars = load(fullfile(config_dir, 'Biplane16k_config.mat'), 'hologram_path', 'single_phase_path', 'info');
            info = vars.info;

            if channel
                holo_path = sprintf(vars.single_phase_path, channel2string(channel));
                load(holo_path, 'hologram');
            else
                load(vars.hologram_path, 'CGH');
                hologram = CGH.Hol;
            end

        case "CGH_Venus"
            vars = load(fullfile(config_dir, 'CGH_Venus_config.mat'), 'hologram_path', 'single_phase_path', 'info');
            info = vars.info;

            if channel
                holo_path = sprintf(vars.single_phase_path, channel2string(channel));
                load(holo_path, 'hologram');
            else
                load(vars.hologram_path, 'CGH');
                hologram = CGH.Hol;
            end

        case "DeepDices16K"
            vars = load(fullfile(config_dir, 'DeepDices16K_config.mat'), 'hologram_path', 'single_phase_path', 'info');
            info = vars.info;

            if channel
                holo_path = sprintf(vars.single_phase_path, channel2string(channel));
                load(holo_path, 'hologram');
            else
                load(vars.hologram_path, 'data');
                hologram = single(data);
            end

        case "DeepDices2K"
            vars = load(fullfile(config_dir, 'DeepDices2K_config.mat'), 'hologram_path', 'single_phase_path', 'info');
            info = vars.info;

            if channel
                holo_path = sprintf(vars.single_phase_path, channel2string(channel));
                load(holo_path, 'hologram');
            else
                load(vars.hologram_path, 'data');
                hologram = single(data);
            end

        case "Lowiczanka_Doll"
            vars = load(fullfile(config_dir, 'Lowiczanka_Doll_config.mat'), 'hologram_path', 'single_phase_path', 'info');
            info = vars.info;

            if channel
                holo_path = sprintf(vars.single_phase_path, channel2string(channel));
                load(holo_path, 'hologram');
            else
                load(vars.hologram_path, 'dh');
                hologram = double(dh);
            end

        otherwise
            warning([hologram_name ' is not a valid hologram.'])
            return
    end

end
