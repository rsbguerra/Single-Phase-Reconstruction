function wut_reconstruction(rec_dist, h_pos, v_pos)
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

                %% Apperture application - pt. 1
                [hologram] = aperture(X, ...
                    info.isFourierDH, ...
                    info.pixel_pitch, ...
                    d, h, v, ...
                    info.ap_sizes, ...
                    info.apod);

                %% Numerical reconstruction
                hol_rendered = num_rec(hologram, info, d);

                % Amplitude calculation
                hol_rendered_abs = abs(hol_rendered);
                hol_rendered_abs = wut_filter(hol_rendered_abs, info);

                %% Clipping
                [hol_rendered_abs_clip, info.clip_min, info.clip_max] = clipping(hol_rendered_abs, ...
                    info.perc_clip, info.perc_value, info.hist_stretch, ...
                    info.clip_min, info.clip_max);

                figure_name = sprintf('%s_%g_%d_%d.png', hologram_name, d * 1000, h, v);
                figure_path = fullfile(figure_dir, figure_name);
                imwrite(abs(hol_rendered_abs_clip), figure_path);
            end
        end
    end
end
