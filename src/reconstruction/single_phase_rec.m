function single_phase_rec(hologram_name, rec_dist, h_pos, v_pos, channel)

    if hologram_name == "Lowiczanka_Doll"
        wut_single_ph_rec(rec_dist, h_pos, v_pos, channel)
        return
    end

    curr_dir = working_dir();

    %% Load config
    disp('Loading config');

    [single_ph_holo, info] = load_hologram(hologram_name, channel);

    figure_dir = fullfile(curr_dir, 'data/output/single_phase_fig', hologram_name);

    if ~exist(figure_dir, "dir")
        mkdir(figure_dir);
    end

    % info.direction = 'forward';

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
                holo_abs = abs(hol_rendered_forward);

                if channel
                    ch_str = channel2string(channel);
                else
                    ch_str = 'rgb';
                end

                figure_name = sprintf('%s_%s_%g_[%dx%d]_[%gx%g].png', hologram_name, ch_str, d, info.ap_sizes(1), info.ap_sizes(2), h, v);
                figure_path = fullfile(figure_dir, figure_name);

                try
                    imwrite(holo_abs, figure_path);
                catch
                    holo_abs = imresize(holo_abs, 0.25);
                    imwrite(holo_abs, figure_path);
                end

            end

        end

    end

end
