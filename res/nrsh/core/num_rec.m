function [hol_rendered] = num_rec(hologram, info, rec_dist, isLast)
    %NUM_REC reconstructs a hologram belonging to Pleno DB.
    %
    %   Inputs:
    %    hologram          - hologram to reconstruct
    %    info              - reconstruction parameters
    %    rec_dist          - reconstruction distance [m]
    %
    %   Output:
    %    hol_rendered      - hologram reconstruction.
    %

    %% RECONSTRUCTION
    colors = size(hologram, 3);
    hol_rendered = hologram;
    clear hologram;
    if (rec_dist == 0), return, end % Early exit
    if (nargin < 4), isLast = false; end

    switch lower(info.method)

        case 'asm'

            for idx = 1:colors
                hol_rendered(:, :, idx) = rec_asm(hol_rendered(:, :, idx), ...
                    info.pixel_pitch, ...
                    info.wlen(idx), rec_dist, ...
                    info.zero_pad, info.direction, isLast);
            end

        case 'fresnel'

            if (contains(info.dataset, 'emergimg'))
                fun = @(dh, p, wlen, z, pad, dir, isLast) rec_fresnel_deprecated(dh, p, wlen, z, pad, dir, isLast);
            else
                fun = @(dh, p, wlen, z, pad, dir, isLast) rec_fresnel(dh, p, wlen, z, pad, dir, isLast);
            end

            for idx = 1:colors
                hol_rendered(:, :, idx) = fun(hol_rendered(:, :, idx), ...
                    info.pixel_pitch, ...
                    info.wlen(idx), -rec_dist, ...
                    info.zero_pad, info.direction, isLast);
            end

        case 'fourier-fresnel'
            [rows_ev, cols_ev, ~] = size(hol_rendered);

            %hologram dimensions forced to be even
            if (mod(rows_ev, 2) ~= 0)
                rows_ev = rows_ev - 1;
                hol_rendered = hol_rendered(1:rows_ev, :, :);
            end

            if (mod(cols_ev, 2) ~= 0)
                cols_ev = cols_ev - 1;
                hol_rendered = hol_rendered(:, 1:cols_ev, :);
            end

            for idx = 1:colors
                hol_rendered(:, :, idx) = rec_fresnel(hol_rendered(:, :, idx), ...
                    info.pixel_pitch, ...
                    info.wlen(idx), rec_dist, ...
                    info.zero_pad, info.direction, info.ref_wave_rad, isLast);
            end

        otherwise
            error('nrsh:num_rec:method', 'Error in nrsh: %s: unknown reconstruction method.', info.method)
    end

end
