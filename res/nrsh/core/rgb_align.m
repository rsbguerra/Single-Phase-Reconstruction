function [recons_ali] = rgb_align(recons, rec_par_cfg)
    %RGB_ALIGN aligns the three color channels, necessary for WUT display RGB
    % holograms after the reconstruction process.
    %
    %
    %   Inputs:
    %    recons            - reconstructed RGB hologram
    %    rec_par_cfg       - structure with rendering parameters, read from
    %                        configuration file
    %   Output:
    %    recons_ali        - reconstructed RGB hologram with the three color
    %                        channels aligned. The dimension is equal to that
    %                        specified in the configuration file.
    %

    recons_img_size = size(recons(:, :, 1));

    %channel shifts: m to pixel conversion
    shift_yx_R = (rec_par_cfg.shift_yx_R) .* (recons_img_size) ./ ...
        (rec_par_cfg.wlen(1)) / (rec_par_cfg.ref_wave_rad) * ...
        (rec_par_cfg.pixel_pitch);
    shift_yx_G = (rec_par_cfg.shift_yx_G) .* (recons_img_size) ./ ...
        (rec_par_cfg.wlen(2)) / (rec_par_cfg.ref_wave_rad) * ...
        (rec_par_cfg.pixel_pitch);
    %NOT USED, for now:
    %shift_yx_B=(rec_par_cfg.shift_yx_B) .* (rec_par_cfg.out_size) ./...
    %            (rec_par_cfg.wlen(3)) / (rec_par_cfg.ref_wave_rad) *...
    %            (rec_par_cfg.pixel_pitch);

    Nyx_R = ceil(rec_par_cfg.wlen(1) / rec_par_cfg.wlen(3) * recons_img_size);
    Nyx_G = ceil(rec_par_cfg.wlen(2) / rec_par_cfg.wlen(3) * recons_img_size);

    %force even dimensions
    Nyx_R = Nyx_R + (mod(Nyx_R, 2) ~= 0);
    Nyx_G = Nyx_G + (mod(Nyx_G, 2) ~= 0);

    %RGB channels scale and padding to equal size
    recons_ali = zeros(Nyx_R(1), Nyx_R(2), 3);

    %R channel
    ch_temp = fftshift(fft2(recons(:, :, 1)));
    ch_temp_pad = padarray(ch_temp, [(Nyx_R(1) - recons_img_size(1)) / 2, (Nyx_R(2) - recons_img_size(2)) / 2]);
    ch_temp_pad = ifft2(ifftshift(ch_temp_pad));
    recons_ali(:, :, 1) = abs(real(ch_temp_pad));
    recons_ali(:, :, 1) = subarray_yx(recons_ali(:, :, 1), [], -shift_yx_R ./ size(ch_temp_pad));

    %G channel
    ch_temp = fftshift(fft2(recons(:, :, 2)));
    ch_temp_pad = padarray(ch_temp, [(Nyx_G(1) - recons_img_size(1)) / 2, (Nyx_G(2) - recons_img_size(2)) / 2]);
    ch_temp_pad = ifft2(ifftshift(ch_temp_pad));
    ch_temp_pad = padarray(ch_temp_pad, [(Nyx_R(1) - Nyx_G(1)) / 2, (Nyx_R(2) - Nyx_G(2)) / 2]);
    recons_ali(:, :, 2) = abs(real(ch_temp_pad));
    recons_ali(:, :, 2) = subarray_yx(recons_ali(:, :, 2), [], -shift_yx_G ./ size(ch_temp_pad));

    %B channel
    recons_ali(:, :, 3) = padarray(recons(:, :, 3), [(Nyx_R(1) - recons_img_size(1)) / 2, ...
                                                         (Nyx_R(2) - recons_img_size(2)) / 2]);

    %restore user-defined output size
    recons_ali = recons_ali((Nyx_R(1) / 2 - recons_img_size(1) / 2) + 1: ...
        (Nyx_R(1) / 2 + recons_img_size(1) / 2), ...
        (Nyx_R(2) / 2 - recons_img_size(2) / 2) + 1: ...
        (Nyx_R(2) / 2 + recons_img_size(2) / 2), :);

end
