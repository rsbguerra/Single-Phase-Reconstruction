function single_phase_rec(hologram_name, rec_dist, h_pos, v_pos, channel)
    curr_dir = working_dir();
    config_dir = fullfile(curr_dir, 'data/config/single_phase_config/');

    %% Load config
    disp('Loading config');

    switch hologram_name

        case 'Biplane16k'
            load([config_dir 'Biplane16k_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'CGH');
            original_hologram = CGH.Hol;

        case 'CGH_Venus'
            load([config_dir 'CGH_Venus_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'CGH');
            original_hologram = CGH.Hol;

        case 'DeepDices16K'
            load([config_dir 'DeepDices16K_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'data');
            original_hologram = single(data);

        case 'DeepDices2K'
            load([config_dir 'DeepDices2K_config.mat'], 'info', 'hologram_path');
            load(hologram_path, 'data');
            original_hologram = single(data);

        case 'Lowiczanka_Doll'
            wut_reconstruction(rec_dist, h_pos, v_pos);
            wut_single_ph_rec(rec_dist, h_pos, v_pos, channel);
            return

        otherwise
            return
    end

    figure_dir = fullfile(curr_dir, 'data/output/single_phase_fig', hologram_name);

    if ~exist(figure_dir, "dir")
        mkdir(figure_dir);
    end

    % reconstruction distance is not used in this case,
    % so only the first distance is sent
    single_ph_holo = remove_phases(original_hologram, rec_dist(1), info, channel);

    % save single_ph_holo
    info.direction = 'forward';

    for d = rec_dist

        for h = h_pos

            for v = v_pos
                info.h_pos = h;
                info.v_pos = v;

                %% Apperture application
                % [hologram] = aperture(single_ph_holo, ...
                %     true, ...
                %     info.pixel_pitch, ...
                %     d, h, v, ...
                %     info.ap_sizes, ...
                %     info.apod);

                hol_rendered_forward = num_rec(single_ph_holo, info, d);

                figure_name = sprintf('%s_%s_%d_[%dx%d]', hologram_name, channel2string(channel), d*1000, h, v);
                figure_path = fullfile(figure_dir, figure_name);
                holo_abs = abs(hol_rendered_forward);

                try
                    imwrite(holo_abs, [figure_path '.png']);
                catch
                    holo_abs = imresize(holo_abs, 0.25);
                    imwrite(holo_abs, [figure_path '.png']);
                end
            end

        end

    end

end
