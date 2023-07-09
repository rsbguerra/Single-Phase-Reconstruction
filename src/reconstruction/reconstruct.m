function reconstruct(hologram_name, rec_dist, h_pos, v_pos)
    curr_dir = working_dir();
    config_dir = fullfile(curr_dir, 'data/config/single_phase_config/');

    %% Load config
    disp('Loading config');

    switch hologram_name

        case 'Biplane16k'
            load([config_dir 'Biplane16k_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'CGH');
            original_hologram = CGH.Hol;
            clearvars CGH

        case 'CGH_Venus'
            load([config_dir 'CGH_Venus_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'CGH');
            original_hologram = CGH.Hol;
            clearvars CGH

        case 'DeepDices16K'
            load([config_dir 'DeepDices16K_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'data');
            original_hologram = single(data);
            clearvars data

        case 'DeepDices2K'
            load([config_dir 'DeepDices2K_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'data');
            original_hologram = single(data);
            clearvars data

        case 'DeepDices8K4K'
            load([config_dir 'DeepDices8K4K_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'data');
            original_hologram = single(data);
            clearvars data

        case 'Lowiczanka_Doll'
            wut_single_ph_rec(rec_dist, h_pos, v_pos, channel);
            return

        otherwise
            warning('Hologram not recognized. Exiting script.')
            return
    end

    figure_dir = fullfile(curr_dir, 'data/output/reconstruction', hologram_name);

    if ~exist(figure_dir, "dir")
        mkdir(figure_dir);
    end

    for d = rec_dist

        for h = h_pos

            for v = v_pos
                info.h_pos = h;
                info.v_pos = v;

                %% Apperture application
                [original_hologram] = aperture(original_hologram, ...
                    true, ...
                    info.pixel_pitch, ...
                    d, h, v, ...
                    [4320 4320], ...
                    info.apod);

                hol_rendered = num_rec(original_hologram, info, d);

                figure_name = sprintf('%s_%d_[%dx%d]', hologram_name, d * 1000, h, v);
                figure_path = fullfile(figure_dir, figure_name);
                holo_abs = abs(hol_rendered);

                try
                    imwrite(holo_abs, [figure_path '.png']);
                    disp(['Figure saved as ' [figure_path '.png.']])
                catch
                    warning('Image size too big, resizing by 0.25')
                    holo_abs = imresize(holo_abs, 0.25);
                    imwrite(holo_abs, [figure_path '.png']);
                end

            end

        end

    end

end
