function H = diff_resize2(H, varargin)
    % function H = diff_resize2(H, pp, tau)
    % function H = diff_resize2(H, ratio)
    %
    %   Fourier resizing reconstructions based on diffraction limited resolution of a given hologram.
    %   Using pp and effective bandwidth tau.
    %
    %   Based on work presented to JPEG Pleno on Holography by D. Blinder and T. Birnbaum.
    %
    % INPUT:
    %   H@numeric...            absolute value of reconstructed hologram, to be resized
    %   ratio@numeric(1,2)...   resolution wrt. org., e.g. 1.5 == 150% resolution of H
    %     or numeric(2,1)
    %
    %   or
    %
    %   pp@numeric(1,2)...      pixel pitch in m
    %    or numeric(2,1)
    %   tau@numeric(1,2)...		effective bandwidth
    %    or @numeric(2,1)
    %
    % OUTPUT:
    %   H@numeric...            resized, absolute value of reconstructed hologram
    %
    %   Version 2.0
    %   01.12.2020, T. Birnbaum

    verbose = 0;

    if (nargin == 2)
        ratio = varargin{1};
        ratio = ratio(:).' .* [1, 1];
    else
        tau = varargin{1};
        pp = varargin{2};
        tau = tau(:).' .* [1, 1];
        pp = pp(:) .* [1; 1];
        ratio = tau(:) .* pp(:);
    end

    res = size(H);
    res = res(1:2).';
    % ncolors = size(H, 3);
    c = class(H);

    %% Compute diffraction limited resolution
    disp(['Maximal ratio: ' num2str(ratio(:).')])
    diffRes = ceil(res(:) .* ratio(:));
    disp(['Maximal resolution: ' num2str(diffRes(:).')])

    if (all(abs(diffRes - res) < 1)), return, end % Early exit

    H = double(H);

    %% Implement Fourier resize
    n = numel(H(:, :, 1));

    if (verbose)
        norm1 = norm(double(H(:)), 'fro');
        m1 = max(H(:));
    end

    H = fftshift(1 / sqrt(n) * fft2(ifftshift(H)));

    if (all(ratio < 1))
        H = centercrop(H, diffRes);
    elseif (all(ratio > 1))
        H = borderpad(H, diffRes);
    else

        if (ratio(1) < 1)
            H = centercrop(H, [diffRes(1), res(2)]);
        elseif (ratio(1) > 1)
            H = borderpad(H, [diffRes(1), res(2)]);
        end

        if (ratio(2) < 1)
            H = centercrop(H, [res(1), diffRes(2)]);
        elseif (ratio(2) > 1)
            H = borderpad(H, [res(1), diffRes(2)]);
        end

    end

    n2 = prod(diffRes(1:2));
    H = abs(fftshift(sqrt(n2) * ifft2(ifftshift(H))));

    if (verbose)
        norm2 = norm(double(H(:)), 'fro');
        m2 = max(H(:));
    end

    %% Adjust datatype
    switch (c)
        case 'uint8'
            H = uint8(double(intmax('uint8')) * mat2gray(H));
        case 'uint16'
            H = uint16(double(intmax('uint16')) * mat2gray(H));
        case {'double', 'single'}
            H = mat2gray(H);
    end

    if (verbose)
        disp('Fourier resize statistics: ')
        disp(['    Changed resolution from:      ' mat2str(res(1:2)) ' px   to: ' mat2str(diffRes(1:2).') ' px'])
        disp(['    Maximal value from:           ' num2str(m1, '%12.1f') ' to: ' num2str(m2, '%12.1f')])
        disp(['    Norm preserved approximately: ' num2str(norm2 / norm1, '%4.2f%%') ' of GT Frobenius norm'])
    end

end

function X = centercrop(X, S)
    % function Y = centercrop(X, S)
    %
    %   Crops at center of image X (i.e. first 2 dims) with size S. If image is nD array,
    %   shape will be preserved, apart from cropping the first two dimensions.
    %
    %   v2.00
    %   17.09.2020, Tobias Birnbaum

    s = size(X);
    %     rowEnd = min(ceil((s(1)+S(1))/2), s(1));
    %     colEnd = min(ceil((s(2)+S(2))/2), s(2));
    %     rowStart = max(rowEnd-S(1), 0);
    %     colStart = max(colEnd-S(2), 0);
    colStart = max(floor((s(2) - S(2)) / 2), 0); % Correct also for odd numbers
    rowStart = max(floor((s(1) - S(1)) / 2), 0);
    rowEnd = min(s(1), rowStart + S(1));
    colEnd = min(s(2), colStart + S(2));
    s(1:2) = [S(1), S(2)];
    X = reshape(X(rowStart + 1:rowEnd, colStart + 1:colEnd, :), s);

end

function Y = borderpad(X, S, val)
    % function Y = borderpad(X, S, val)
    %
    %   adds black borders to image X until such that it has dimensions S
    %
    %   v1.10
    %   11.02.2020, Tobias Birnbaum

    if (nargin < 3), val = 0; end

    s = size(X);
    s(1:numel(S)) = S;

    if (val == 0)
        Y = zeros(s);
    else
        Y = val * ones(s);
    end

    xs = floor((s(2) - size(X, 2)) / 2);

    if S(1) == 1
        ys = 0;
    else
        ys = floor((s(1) - size(X, 1)) / 2);
    end

    Y(ys + 1:ys + size(X, 1), xs + 1:xs + size(X, 2), :) = X;
end
