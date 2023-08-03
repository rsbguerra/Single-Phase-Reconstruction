function [recons] = rec_fresnel(hol, pitch, wlen, rec_dist, direction)
    %REC_FRESNEL Frensnel Method implementation.
    %
    %   Inputs:
    %    hol               - input hologram to reconstruct
    %    pitch             - pixel pitch in meters
    %    wlen              - wavelength in meters.
    %    rec_dist          - reconstruction distance in meters
    %    direction         - reconstruction direction. It should be one of
    %                        the following char. arrays: forward (propagation
    %                        towards the object plane) or inverse (propagation
    %                        towards the hologram plane)
    %
    %   Output:
    %    recons            - reconstructed field (complex magnitude)
    %

    k = 2 * pi / wlen;
    [rows, cols] = size(hol);

    persistent F

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

    if strcmpi(direction, 'forward')
        recons = ((-1i / (wlen * rec_dist)) * exp((1i * k / (2 * rec_dist)) * F)) .* hol;
        recons = ifftshift(ifft2(recons));
    else
        recons = fft2(fftshift(hol));
        recons = ((- (wlen * rec_dist) / 1i) * exp(- (1i * k / (2 * rec_dist)) * F)) .* recons;
    end
