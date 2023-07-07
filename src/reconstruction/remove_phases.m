function [hol_rendered_inverse] = remove_phases(original_hologram, rec_dist, info, channel)

    %% Reconstruct original hologram
    disp('Reconstruct original hologram');

    obj_plane = num_rec(original_hologram, info, rec_dist);
    [amp, ph] = convert_to_amplitude_phase(obj_plane);

    ph_r = ph(:, :, channel);
    obj_plane = convert_to_complex(amp, ph_r);

    %% Backwards propagation of new hologram
    disp('Backwards propagation of new hologram');

    info.direction = 'inverse';
    hol_rendered_inverse = num_rec(obj_plane, info, rec_dist);
end
