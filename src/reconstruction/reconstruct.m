function reconstruct(hologram_name, rec_dist, h_pos, v_pos)
    curr_dir = working_dir();
    figure_dir = fullfile(curr_dir, 'data/output/reconstruction', hologram_name);

    %% Load config
    disp('Loading config');

    [original_hologram, info] = load_hologram(hologram_name);

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
