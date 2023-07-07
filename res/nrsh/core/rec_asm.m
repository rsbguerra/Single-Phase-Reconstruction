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
    %-------------------------------------------------------------------------

    %% 0) Initialization
    % Initialize missing arguments
    if nargin < 6
        direction = 'forward';

        if nargin < 5
            zero_pad = false;

            if nargin < 4
                error('nrsh:rec_asm:input_args', 'Error in rec_asm: not enough input arguments.')
            end

        end

    end

    % Check if propagation has to happen
    do_propag = (abs(rec_dist) > eps('single'));

    % Zero-pad only if propagation is happening
    zero_pad = zero_pad && do_propag;

    % Keep pixel pitch in memory
    pitch = pitch(:) .* [1; 1];
    persistent pp

    if isempty(pp)
        pp = pitch;
    end

    %% 1) Zero-padding
    [Ny, Nx] = size(hol);

    if (zero_pad)
        recons = zeros(Ny * 2, Nx * 2, 'single');
        recons(Ny / 2 + 1:Ny / 2 + Ny, Nx / 2 + 1:Nx / 2 + Nx) = single(hol);
        Ny = Ny * 2;
        Nx = Nx * 2;
    else
        recons = single(hol);
    end

    %% 2) Initialize frequency grid
    persistent F

    if (do_propag && (isempty(F) || (Ny ~= size(F, 1)) || (Nx ~= size(F, 2)) || pp(1) ~= pitch(1) || pp(2) ~= pitch(2)))
        % Update pixel pitch
        pp = pitch;

        % Update frequency grid
        Lx = 1 / (pitch(1));
        dx = Lx / Nx;
        fx = single(-Lx / 2:dx:Lx / 2 - dx);

        if isequal(Nx, Ny) && isequal(pitch(1), pitch(2))
            [F, ~] = meshgrid(fx);
            F = ifftshift(F .^ 2 + F' .^ 2);
            clearvars Lx dx fx;
        else
            Ly = 1 / (pitch(2));
            dy = Ly / Ny;
            fy = single(-Ly / 2:dy:Ly / 2 - dy);
            [F, F_temp] = meshgrid(fx, fy);
            F = ifftshift(F .^ 2 + F_temp .^ 2);
            clearvars Lx Ly dx dy fx fy F_temp;
        end

    end

    %% 3) Propagate
    % Flip reconstruction distance sign if direction is inverse
    if strcmpi(direction, 'inverse')
        rec_dist = -rec_dist;
    end

    % Perform propagation
    if (do_propag)
        % Compute propagation kernel
        H = exp(-2i * pi * sqrt(max(0, (1 / wlen) ^ 2 - F)) * rec_dist);
        H(H == 1) = 0;

        % Forward Fourier transform
        recons = fft2(recons);

        % Apply kernel
        recons = recons .* H;

        % Inverse Fourier transform
        recons = ifft2(recons);
    end

    %% 4) Undo zero-padding
    if (zero_pad)
        Ny = Ny / 2;
        Nx = Nx / 2;
        recons = recons(Ny / 2 + 1:Ny / 2 + Ny, Nx / 2 + 1:Nx / 2 + Nx, :);
    end

end
