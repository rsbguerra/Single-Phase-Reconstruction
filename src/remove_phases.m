function remove_phases(hologram_list, channel_list)
    clc
    %% script imports

    addpath('./utils')
    root_dir = working_dir();
    add_paths(root_dir, "src/reconstruction");

    %% path definition

    save_dir = fullfile(root_dir, 'data/input/single_phase_holograms/');

    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end

    for holo = hologram_list

        for c = channel_list
            [original_hologram, info] = load_hologram(holo);
            hologram = phase_removal(original_hologram, info, info.default_rec_dist(1), c);

            save_path = sprintf('%s%s_%s.mat', save_dir, holo, channel2string(c));
            save(save_path, 'hologram', '-v7.3')
        end

    end

    function [single_ph_hologram] = phase_removal(original_hologram, info, rec_dist, channel)

        if strcmp(info.dataset, 'wut_disp_on_axis')
            si = size(original_hologram);
            original_hologram = fftshift(fft2(original_hologram));
            original_hologram = circshift(original_hologram, [0, round(si(2) / 4), 0]);
            original_hologram = ifft2(ifftshift(original_hologram));
        end

        %% Reconstruct original hologram
        disp('Reconstruct original hologram');

        obj_plane = num_rec(original_hologram, info.dataset, info.rec_par_cfg, rec_dist, info.direction);
        [amp, ph] = convert_to_amplitude_phase(obj_plane);

        ph_r = ph(:, :, channel);
        obj_plane = convert_to_complex(amp, ph_r);

        %% Backwards propagation of new hologram
        disp('Backwards propagation of new hologram');

        info.direction = 'inverse';
        obj_plane = num_rec(original_hologram, info.dataset, info.rec_par_cfg, rec_dist, info.direction);

        function [x] = convert_to_complex(am, ph)
            x = complex(zeros(size(am), 'single'), 0);

            for i = 1:3
                x(:, :, i) = am(:, :, i) .* exp(1j .* ph);
            end

        end

        function [amp, ph] = convert_to_amplitude_phase(c)
            amp = abs(c);
            ph = angle(c);
        end

    end

end
