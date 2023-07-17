function [recons_ali] = rgb_align(recons, info)
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

    %recons=uint8(recons.*255);%recons should be the out. of the stretch.

    %channel shifts: m to pixel conversion
    recons_img_size = size(recons(:, :, 1));

    shift_yx_R = (info.shift_yx_r) .* (recons_img_size) ./ ...
        (info.wlen(1)) / (info.ref_wave_rad) * ...
        (info.pixel_pitch);
    shift_yx_G = (info.shift_yx_g) .* (recons_img_size) ./ ...
        (info.wlen(2)) / (info.ref_wave_rad) * ...
        (info.pixel_pitch);
    %NOT USED, for now:
    %shift_yx_B=(rec_par_cfg.shift_yx_b) .* (rec_par_cfg.out_size) ./...
    %            (rec_par_cfg.wlen(3)) / (rec_par_cfg.ref_wave_rad) *...
    %            (rec_par_cfg.pixel_pitch);

    Nyx_R = ceil(info.wlen(1) / info.wlen(3) * recons_img_size);
    Nyx_G = ceil(info.wlen(2) / info.wlen(3) * recons_img_size);

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

    %%saturate
    %for ch=1:3
    %    recons_ali(:,:,ch)=saturate_gray(recons_ali(:,:,ch),[],1,info.bit_depth);
    %end

    %restore user-defined output size
    recons_ali = recons_ali((Nyx_R(1) / 2 - recons_img_size(1) / 2) + 1: ...
        (Nyx_R(1) / 2 + recons_img_size(1) / 2), ...
        (Nyx_R(2) / 2 - recons_img_size(2) / 2) + 1: ...
        (Nyx_R(2) / 2 + recons_img_size(2) / 2), :);

end
