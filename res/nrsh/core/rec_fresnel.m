function [recons] = rec_fresnel(hol, pitch, wlen, rec_dist, zero_pad, direction, ref_wave_rad)
    %REC_FRESNEL Frensnel + Fourier Method implementation.
    %
    %   Inputs:
    %    hol               - input hologram to reconstruct
    %    pitch             - pixel pitch in meters
    %    wlen              - wavelength in meters.
    %    rec_dist          - reconstruction distance in meters
    %    zero_pad          - Enables interim zero_padding and kernel
    %                        band-wdith limitation, for more details on the latter
    %                        see [1]
    %    direction         - reconstruction direction. It should be one of
    %                        the following char. arrays: forward (propagation
    %                        towards the object plane) or inverse (propagation
    %                        towards the hologram plane)
    %    ref_wave_rad      - optional reference wave radius in meters
    %
    %   Output:
    %    recons            - reconstructed field (complex magnitude)
    %
    %   [1] Blinder, David, Tobias Birnbaum, and Peter Schelkens.
    %       "Pincushion point-spread function for computer-generated holography."
    %       Optics Letters 47.8 (2022): 2077-2080.


    %% 0) Initialization
    % Initialize missing arguments
    if nargin < 7
        ref_wave_rad = 0;

        if nargin < 6
            direction = 'forward';

            if nargin < 5
                zero_pad = false;

                if nargin < 4
                    error('nrsh:rec_fresnel:input_args', 'Error in rec_fresnel: not enough input arguments.')
                end

            end

        end

    end

    % Check if propagation has to happen
    doPropag = (abs(rec_dist - ref_wave_rad) > eps('single'));

    % Zero-pad only if propagation is happening
    zero_pad = zero_pad && doPropag;

    % Initialize other parameters
    super_res_fac = 2;
    k = 2 * pi / wlen;

    % Keep pixel pitch in memory
    persistent pitch_pers;

    if isempty(pitch_pers)
        pitch_pers = pitch;
    end

    %% 1) Zero-padding
    if (zero_pad == true)
        pitch = pitch / super_res_fac;
        hol = fourierpadcrop(hol, super_res_fac);
    end

    %% 2) Initialize frequency grid and mask
    [rows, cols] = size(hol);
    persistent F;
    recons = hol;

    Lx = cols * pitch(1);
    Ly = rows * pitch(end);

    doUpdateF = doPropag && (isempty(F) || cols ~= size(F, 1) || rows ~= size(F, 2) || abs(pitch(1) - pitch_pers(1)) > eps('single') || abs(pitch(end) - pitch_pers(end)) > eps('single'));
    isSameDim = isequal(cols, rows) && (abs(pitch(1) - pitch(end)) < eps('single'));
    pitch_pers = pitch;

    if (doUpdateF || zero_pad) % Need to compute mask or F
        % Can't reuse F as interim buffer, in general
        if (isSameDim)
            X = -Lx / 2:pitch_pers:Lx / 2 - pitch_pers;
            [X, ~] = meshgrid(X);
        else
            X = -Lx / 2:pitch_pers:Lx / 2 - pitch_pers;
            Y = -Ly / 2:pitch_pers:Ly / 2 - pitch_pers;
            [X, Y] = meshgrid(X, Y);
        end

    end

    if (doUpdateF) % Recompute F, only if needed

        if (isSameDim)
            F = X .^ 2 + X' .^ 2;
        else
            F = X .^ 2 + Y .^ 2;
        end

    end

    if (zero_pad) % Need to always compute mask, if zero_pad == true

        if (isSameDim)
            mask = abs(X) ./ sqrt(X .^ 2 + X.' .^ 2 + rec_dist ^ 2) < wlen / (2 * pitch_pers);
            %      & abs(X.')./sqrt(X.^2 + X.'.^2 + rec_dist^2) < wlen/(2*pitch_pers);
            mask = mask & mask.';
            mask = fftshift(mask);
        else
            mask = abs(X) ./ sqrt(X .^ 2 + Y .^ 2 + rec_dist ^ 2) < wlen / (2 * pitch_pers) & ...
                abs(Y) ./ sqrt(X .^ 2 + Y .^ 2 + rec_dist ^ 2) < wlen / (2 * pitch_pers);
            mask = fftshift(mask);
        end

    end

    clear Y X Y pitch; % Use pitch_pers instead of pitch

    %% 3) Propagate
    % Update propagation distance
    if (doPropag && ref_wave_rad ~= 0)
        z = ref_wave_rad * rec_dist / (ref_wave_rad - rec_dist);
    else
        z = rec_dist;
    end

    % Check propagation direction
    if strcmpi(direction, 'forward')
        % Apply Kernel
        if (doPropag)
            recons = recons .* exp(-1i * k * F / (2 * z));
        end

        % BW limit, if required
        if (zero_pad == true)
            recons = recons .* mask;
        end

        % Forward Fourier transform
        if (doPropag || ref_wave_rad ~= 0)
            recons = fftshift(fft2(recons));
        end

    else
        % Inverse Fourier transform
        if (doPropag || ref_wave_rad ~= 0)
            recons = ifft2(ifftshift(recons));
        end

        % Apply kernel
        if (doPropag)
            recons = recons .* exp(1i * k * F / (2 * z));
        end

        % BW limit, if required
        if (zero_pad == true)
            recons = recons .* mask;
        end

    end

    %% 4) Undo zero-padding
    if (zero_pad == true)
        recons = fourierpadcrop(recons, 1 / super_res_fac);
    end

end
