function [recons] = rec_fourier_fresnel(hol, pitch, wlen, rec_dist, ref_wave_rad, direction)
    %REC_FOURIER_FRESNEL reconstructs a Fourier hologram.
    %
    %   Inputs:
    %    hol               - input hologram to reconstruct
    %    pitch             - pixel pitch in meters
    %    wlen              - wavelength in meters.
    %    rec_dist          - reconstruction distance in meters
    %    ref_wave_rad      - reference wave radius in meters
    %    direction         - reconstruction direction. It should be one of
    %                        the following char. arrays: forward (propagation
    %                        towards the object plane) or inverse (propagation
    %                        towards the hologram plane)
    %
    %   Output:
    %    hol               - reconstructed field (complex)
    %

    k = 2 * pi / wlen;
    [rows, cols, ~] = size(hol);
    recons = hol;

    persistent F

    if rec_dist ~= ref_wave_rad
        z = ref_wave_rad * rec_dist / (ref_wave_rad - rec_dist);

        if (isempty(F) || (rows ~= size(F, 1)) || (cols ~= size(F, 2)))
            Lx = cols * pitch;
            Ly = rows * pitch;

            if isequal(Lx, Ly)
                x = -Lx / 2:pitch:Lx / 2 - pitch;
                [F, ~] = meshgrid(x);
                F = F .^ 2 + F' .^ 2;
            else
                x = -Lx / 2:pitch:Lx / 2 - pitch;
                y = -Ly / 2:pitch:Ly / 2 - pitch;

                [F, F_temp] = meshgrid(x, y);
                F = F .^ 2 + F_temp .^ 2;
                clearvars F_temp
            end

        end

    end

    if strcmpi(direction, 'forward')

        if rec_dist ~= ref_wave_rad
            recons = recons .* exp(-1i * k * F / 2 / z);
        end

        recons = fftshift(fft2(recons));
    else
        recons = ifft2(ifftshift(recons));

        if rec_dist ~= ref_wave_rad
            recons = recons .* exp(1i * k * F / 2 / z);
        end

    end

end
