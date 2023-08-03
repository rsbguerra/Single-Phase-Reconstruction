function [] = print_setup(cfg_path, rec_par_cfg, rec_dists, h_pos, ...
        v_pos, ap_sizes)
    %PRINT_SETUP Prints current settings informations (user input & cfg file)
    %
    %   Inputs:
    %    cfg_path          - path to configuration file
    %    rec_param_cfg     - reconstruction parameters (from config. file)
    %    rec_dists         - reconstruction distance(s)
    %    h_pos             - horizontal positions at which the synthetic
    %                        aperture will be placed.
    %    v_pos             - vertical positions at which the synthetic
    %                        aperture will be placed.
    %    ap_sizes          - synthetic aperture sizes
    %

    %% PARAMETERS FROM CONFIG. FILE

    disp(repmat('*', 1, 90));
    disp(strcat(repmat('*', 1, 26), 'Parameters set from configuration file', ...
        repmat('*', 1, 26)));
    disp(repmat('*', 1, 90));

    fprintf('\nConfiguration file in use: %s\n\n', cfg_path);

    fields_list = ["wlen [m]", "pixel_pitch [m]", "method", "apod (0:off, 1:on)", ...
                     "zero_pad (0:off, 1:on)", "perc_clip (0:off, 1:on)", ...
                     "perc_value", ...
                     "hist_stretch (0:off, 1:on)", ...
                     "save_intensity (0:off, 1:on)", ...
                     "save_as_mat (0:off, 1:on)", ...
                     "show (0:off, 1:on)", ...
                     "save_as_image (0:off, 1:on)", ...
                     "ref_wave_rad [m]", ...
                     "shift_yx_R [m]", "shift_yx_G [m]", "shift_yx_B [m]", ...
                     "recons_img_size [pixel]", "DC_filter_type", "DC_filter_size", ...
                     "img_flt", "saturate_gray (0:off, 1:on)"];

    for names = fieldnames(rec_par_cfg).'
        field = names{1};
        match = contains(fields_list, field, 'IgnoreCase', true);
        field2print = fields_list(match);

        if ~(field2print == "")
            fprintf('\t %30s : %s\n', field2print, num2str(rec_par_cfg.(field)));
        end

    end

    %% PARAMETERS PASSED AS FUNCTION INPUT

    disp(repmat('*', 1, 90));
    disp(strcat(repmat('*', 1, 34), 'Parameters manually set', ...
        repmat('*', 1, 33)));
    disp(repmat('*', 1, 90));

    fprintf('\t %30s : %s\n', 'Reconstruction distance(s) [m]', num2str(rec_dists));

    if iscell(ap_sizes)

        fprintf('\t %30s : %s\n', 'Horizontal positions:', num2str(h_pos));

        fprintf('\t %30s : %s\n', 'Vertical positions:', num2str(v_pos));

        fprintf('\t %30s : %s\n', 'Aperture size [pixel]', strrep(mat2str((ap_sizes{1, 1})), ' ', 'x'));

        if size(ap_sizes, 2) > 1

            for idx = 2:size(ap_sizes, 2)
                fprintf('\t %30s : %s\n', ' ', strrep(mat2str((ap_sizes{1, idx})), ' ', 'x'));
            end

        end

    else

        fprintf('\t %30s : %s\n', 'Horizontal angle(s) [deg]', num2str(h_pos));

        fprintf('\t %30s : %s\n', 'Vertical angle(s) [deg]', num2str(v_pos));

        fprintf('\t %30s : %s\n', 'DOF angle(s) [deg]', num2str(ap_sizes));
    end

end
