function [hol_rendered, info] = reconstruct(hologram_name, rec_dist, h_pos, v_pos, ap_size, channel)

    curr_dir = working_dir();

    % Load config
    disp('Loading config');

    figure_dir = fullfile(curr_dir, 'data/output/single_phase_fig', hologram_name);

    if ~exist(figure_dir, "dir")
        mkdir(figure_dir);
    end

    fprintf("Loading hologram %s...\n", hologram_name)
    [hologram, info] = load_hologram(hologram_name, channel);

    if hologram_name == "Lowiczanka_Doll"
        si = size(hologram);
        hologram = fftshift(fft2(hologram));
        hologram = circshift(hologram, [0, round(si(2) / 4), 0]);
        hologram = ifft2(ifftshift(hologram));
    end

    % Apperture application
    fprintf("Applying aperture [%gx%g], to %s...\n", ap_size(1), ap_size(2), hologram_name)
    [hologram] = aperture(hologram, ...
        info.dataset, ...
        info.rec_par_cfg, ...
        rec_dist, h_pos, v_pos, ...
        ap_size);

    fprintf("Reconstructing hologram %s at %gm...\n", hologram_name, rec_dist)
    hol_rendered = num_rec(hologram, info.rec_par_cfg, rec_dist, info.direction);
    fprintf("Reconstruction done.\n")

end
