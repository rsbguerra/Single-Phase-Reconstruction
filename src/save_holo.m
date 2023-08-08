function save_holo(hologram_name, hol_rendered, ...
        info, rec_dist, h_pos, v_pos, ...
        ap_sizes, channel, format)

    curr_dir = working_dir();

    if channel
        ch_str = channel2string(channel);
    else
        ch_str = 'rgb';
    end

    figure_dir = sprintf('%sdata/output/single_phase_fig/%s/%s', curr_dir, hologram_name, ch_str);

    if ~exist(figure_dir, "dir")
        mkdir(figure_dir);
    end

    figure_name = sprintf("%s_%s_%g_[%dx%d]_[%gx%g].%s", hologram_name, ch_str, rec_dist, ...
        ap_sizes(1), ap_sizes(2), h_pos, v_pos, format);
    figure_path = fullfile(figure_dir, figure_name);

    fprintf('Saving hologram %s as %s file to:\n%s\n\n', hologram_name, format, figure_path)

    switch format
        case "mat"
            save(figure_path, "hol_rendered", "-v7.3")
        case "png"

            if hologram_name == "Lowiczanka_Doll"

                hol_rendered = dc_filter(hol_rendered, ...
                    info.rec_par_cfg.DC_filter_size, ...
                    info.rec_par_cfg.DC_filter_type);

                hol_rendered = abs(hol_rendered);
                hol_rendered = imresize(hol_rendered, info.rec_par_cfg.recons_img_size, 'bilinear');

                holo_abs = wut_filter(hol_rendered, info.rec_par_cfg);

                %% Clipping
                [holo_abs, info.clip_min, info.clip_max] = clipping(holo_abs, ...
                    info.rec_par_cfg, ...
                    info.clip_min, info.clip_max);
            else
                holo_abs = abs(hol_rendered);
            end

            try
                imwrite(holo_abs, figure_path);
            catch
                holo_abs = imresize(holo_abs, 0.25);
                imwrite(holo_abs, figure_path);
            end

        otherwise
            warning([format ' is not a valid format option.'])
            return
    end
    fprintf("Figure saved as %s.\n\n", format)
end
