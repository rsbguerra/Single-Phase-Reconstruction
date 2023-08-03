function reconstruct(hologram_name, rec_dist, h_pos, v_pos, ap_sizes, channel)

    curr_dir = working_dir();

    % Load config
    disp('Loading config');

    figure_dir = fullfile(curr_dir, 'data/output/single_phase_fig', hologram_name);

    if ~exist(figure_dir, "dir")
        mkdir(figure_dir);
    end

    for c = channel
        fprintf("Loading hologram %s...", hologram_name)
        [single_ph_holo, info] = load_hologram(hologram_name, c);

        if hologram_name == "Lowiczanka_Doll"
            si = size(single_ph_holo);
            hol = single(hol);
            [X, ~] = meshgrid(((-si(2) / 2:si(2) / 2 - 1) + 0.5) / si(2), ((-si(1) / 2:si(1) / 2 - 1) + 0.5) / si(1));
            R = exp(2i * pi * X * si(2) / 4);
            clear X;

            single_ph_holo = ifftshift(fft2(fftshift(single_ph_holo .* R)));
            clear R;
            single_ph_holo(:, [1:si(2) / 4, si(2) * 3/4 + 1:end], :) = [];
            single_ph_holo = ifftshift(ifft2(fftshift(single_ph_holo)));
        end

        for d = rec_dist

            for a = 1:length(ap_sizes)

                for h = h_pos

                    for v = v_pos

                        % Apperture application
                        fprintf("Applying aperture to %s...", hologram_name)
                        [single_ph_holo] = aperture(single_ph_holo, ...
                            info.dataset, ...
                            info.rec_par_cfg, ...
                            d, h, v, ...
                            [ap_sizes{a}]);

                        hol_rendered = num_rec(single_ph_holo, info.rec_par_cfg, d, info.direction);

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

                        if c
                            ch_str = channel2string(c);
                        else
                            ch_str = 'rgb';
                        end

                        figure_name = sprintf('%s_%s_%g_[%dx%d]_[%gx%g].png', hologram_name, ch_str, d, ap_sizes{a}(1), ap_sizes{a}(2), h, v);
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

    end

end
