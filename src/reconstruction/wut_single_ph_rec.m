function wut_single_ph_rec(rec_dist, h_pos, v_pos, channel)
    load('holo_config/Lowiczanka_Doll_config.mat');
    load(hologram_path);
    hologram_name = 'Lowiczanka_Doll'
    figure_dir = fullfile('/mnt/data/code/holography-ctc/single_phase_rec/figures', hologram_name);

    X = double(dh);

    if ~exist(figure_dir, "dir")
        mkdir(figure_dir);
    end

    %% Convert on-axis to off-axis holograms
    si = size(X);
    X = fftshift(fft2(X));
    X = circshift(X, [0, round(si(2) / 4), 0]);
    X = ifft2(ifftshift(X));

    for d = rec_dist
        for h = h_pos
            for v = v_pos
                info.h_pos = h;
                info.v_pos = v;

                %% Apperture application
                [hologram] = aperture(X, ...
                    info.isFourierDH, ...
                    info.pixel_pitch, ...
                    d, h, v, ...
                    info.ap_sizes, ...
                    info.apod);

                hol_rendered_inverse = remove_phases(hologram, d, info, channel);

                info.direction = 'forward';
                hol_rendered_forward = num_rec(hol_rendered_inverse, info, d);

                % Amplitude calculation
                hol_rendered_forward = abs(hol_rendered_forward);
                hol_rendered_forward = wut_filter(hol_rendered_forward, info);

                %% Clipping
                [hol_rendered_forward_clip, info.clip_min, info.clip_max] = clipping(hol_rendered_forward, ...
                    info.perc_clip, info.perc_value, info.hist_stretch, ...
                    info.clip_min, info.clip_max);

                figure_name = sprintf('%s_%s_%g_%d_%d.png', holo_name, channel2string(channel), d * 1000, h, v);
                figure_path = fullfile(figure_dir, figure_name);
                imwrite(abs(hol_rendered_forward_clip), figure_path);
            end
        end
    end
end
