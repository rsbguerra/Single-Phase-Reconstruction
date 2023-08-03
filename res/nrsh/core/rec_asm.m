function [recons] = rec_asm(hol, pitch, wlen, rec_dist, zero_pad, direction)
    %REC_ASM Angular Spectrum Method implementation
    %
    %   Inputs:
    %    hol               - input hologram to reconstruct
    %    pitch             - pixel pitch in meters
    %    wlen              - wavelength in meters.
    %    rec_dist          - reconstruction distance in meters
    %    zero_pad          - zero pad the original hologram before
    %                        reconstruction
    %    direction         - reconstruction direction. It should be one of
    %                        the following char. arrays: forward (propagation
    %                        towards the object plane) or inverse (propagation
    %                        towards the hologram plane)
    %   Output:
    %    recons            - reconstructed field (complex magnitude)
    %

    switch nargin
        case 5
            direction = 'forward';
        case 4
            direction = 'forward';
            zero_pad = 0;
        case {1, 2, 3}
            error("Not enough input arguments.")
    end

    if strcmpi(direction, 'inverse')
        rec_dist = -rec_dist;
    end

    [Ny, Nx, ~] = size(hol);

    if zero_pad == 1
        recons = zeros(Ny * 2, Nx * 2, 'single');
        recons(Ny / 2 + 1:Ny / 2 + Ny, Nx / 2 + 1:Nx / 2 + Nx) = single(hol);
        Ny = Ny * 2;
        Nx = Nx * 2;
    else
        recons = single(hol);
    end

    persistent F

    if (isempty(F))
        dx = 1 / (Nx * pitch);
        fx = single(-1 / (2 * pitch):dx:1 / (2 * pitch) - dx);

        if isequal(Nx, Ny)
            [F, ~] = meshgrid(fx);
            F = ifftshift(F .^ 2 + F' .^ 2);
        else
            dy = 1 / (Ny * pitch);
            fy = single(-1 / (2 * pitch):dy:1 / (2 * pitch) - dy);
            [F, F_temp] = meshgrid(fx, fy);
            F = ifftshift(F .^ 2 + F_temp .^ 2);
            clearvars F_temp;
        end

    end

    H = exp(-2i * pi * sqrt(max(0, (1 / wlen) ^ 2 - F)) * rec_dist);
    H(H == 1) = 0;

    recons = fft2(recons);
    recons = recons .* H;
    recons = ifft2(recons);

    if zero_pad == 1
        Ny = Ny / 2;
        Nx = Nx / 2;
        recons = recons(Ny / 2 + 1:Ny / 2 + Ny, Nx / 2 + 1:Nx / 2 + Nx, :);
    end

end
