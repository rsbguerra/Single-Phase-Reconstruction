function wut_single_ph_rec(rec_dists, h_pos, v_pos, channel)
    % setup needed paths
    hologram_name = 'Lowiczanka_Doll';
    curr_dir = working_dir();
    figure_dir = fullfile(curr_dir, 'data/output/single_phase_fig', hologram_name);
    
    [hologram, info] = load_hologram(hologram_name, channel);
    info.ap_sizes = [0 0];

    if ~exist(figure_dir, "dir")
        mkdir(figure_dir);
    end

    for d = rec_dists
        for h = h_pos
            for v = v_pos
                info.h_pos = h;
                info.v_pos = v;

                %% Apperture application
                [hologram] = aperture(hologram, ...
                    info.isFourierDH, ...
                    info.pixel_pitch, ...
                    d, h, v, ...
                    info.ap_sizes, ...
                    info.apod);

                hol_rendered_forward = num_rec(hologram, info, d);

                % Amplitude calculation
                hol_rendered_forward = abs(hol_rendered_forward);
                hol_rendered_forward = wut_filter(hol_rendered_forward, info);

                %% Clipping
                [hol_rendered_forward_clip, info.clip_min, info.clip_max] = clipping(hol_rendered_forward, ...
                    info.perc_clip, info.perc_value, info.hist_stretch, ...
                    info.clip_min, info.clip_max);

                imshow(hol_rendered_forward_clip)
                figure_name = sprintf('%s_%s_%g_[%gx%g].png', hologram_name, channel2string(channel), d, h, v);
                figure_path = fullfile(figure_dir, figure_name);
                imwrite(abs(hol_rendered_forward_clip), figure_path);
            end
        end
    end
end
