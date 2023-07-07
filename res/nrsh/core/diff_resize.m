function H = diff_resize(H, pp, wlen, z, ap_size)
    % function H = diff_resize(H, pp, wlen, z, ap_size)
    %   Resizing reconstructions based on diffraction limited resolution of a given hologram.
    %   Using z, min(wlen), and a center perspective, the worst case, highest resolution possible
    %   is calculated and all other color channels/perspectives are to be matched to this resolution.
    %
    %   Based on work presented to JPEG Pleno on Holography by D. Blinder and T. Birnbaum.
    %
    % INPUT:
    %    H@numeric...            complex-valued wavefield of reconstructed hologram, to be resized
    %    pp@numeric(1,2)...        pixel pitch in m
    %     or numeric(2,1)
    %    wlen@numeric(1)...        wavelength(s) in m
    %     or @numeric(3)
    %    z@numeric(1)...            distance of wavefield from org. hologram plane in m1
    %    ap_size@numeric(1,2)...    aperture size used for reconstruction in px
    %        or @numeric(2,1)
    %
    %   Version 1.50
    %   19.11.2020, T. Birnbaum

    verbose = 0;

    res = size(H);
    res = res(1:2);
    % ncolors = size(H, 3);
    pp = pp(:) .* [1; 1];
    c = class(H);

    %% Compute diffraction limited resolution
    freqFun = @(x, y, wlen, z) (x + y) / (wlen * sqrt(x .^ 2 + y .^ 2 + z .^ 2));
    bwFun = @(x0, a, wlen, z, pp) min(abs(freqFun(x0(1) + a(1) / 2, x0(2) + a(2) / 2, wlen, z) - freqFun(x0(1) - a(1) / 2, x0(2) - a(2) / 2, wlen, z)) * pp / 2, 1);
    %     freqFun = @(x, wlen, z) x/(wlen*sqrt(x.^2 + z.^2));
    %     bwFun = @(x0, a, wlen, z, pp) min(abs(freqFun(x0+a/2, wlen, z) - freqFun(x0-a/2, wlen, z))*pp/2, 1);

    wlenMin = min(wlen);
    ratio = [bwFun(0 * pp, ap_size .* pp, wlenMin, z, pp(1)), ...
                 bwFun(0 * pp, ap_size .* pp, wlenMin, z, pp(2))];
    disp(' ')
    disp(['Maximal ratio: ' num2str(ratio(:).')])
    diffRes = ceil(res(:) .* ratio(:));
    disp(['Maximal resolution: ' num2str(diffRes(:).')])

    H = double(H);

    %% Implement Fourier resize
    if (verbose)
        norm1 = norm(double(H(:)), 'fro');
        m1 = max(H(:));
    end

    H = diff_resize2(abs(H), pp, ratio(:) ./ pp);

    if (verbose)
        norm2 = norm(double(H(:)), 'fro');
        m2 = max(H(:));
    end

    %     %% Adjust datatype
    %     switch(c)
    %         case 'uint8'
    %             H = uint8(double(intmax('uint8'))*mat2gray(H));
    %         case 'uint16'
    %             H = uint16(double(intmax('uint16'))*mat2gray(H));
    %         case {'double', 'single'}
    %             H = mat2gray(H);
    %     end

    if (verbose)
        disp('Fourier resize statistics: ')
        disp(['    Downsize from:                ' mat2str(res(1:2)) ' px   to: ' mat2str(diffRes(1:2).') ' px'])
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
