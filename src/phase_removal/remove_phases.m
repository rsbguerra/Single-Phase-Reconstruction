function [single_ph_hologram] = remove_phases(original_hologram, info, rec_dist, channel)

    if strcmp(info.dataset, 'wut_disp_on_axis')
        si = size(original_hologram);
        original_hologram = fftshift(fft2(original_hologram));
        original_hologram = circshift(original_hologram, [0, round(si(2) / 4), 0]);
        original_hologram = ifft2(ifftshift(original_hologram));
    end

    %% Reconstruct original hologram
    disp('Reconstruct original hologram');

    obj_plane = num_rec(original_hologram, info, rec_dist);
    [amp, ph] = convert_to_amplitude_phase(obj_plane);

    ph_r = ph(:, :, channel);
    obj_plane = convert_to_complex(amp, ph_r);

    %% Backwards propagation of new hologram
    disp('Backwards propagation of new hologram');

    info.direction = 'inverse';
    single_ph_hologram = num_rec(obj_plane, info, rec_dist);
end
