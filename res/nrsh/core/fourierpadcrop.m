function r = fourierpadcrop(r, facFreq, facSpat)
    % function r = fourierpadcrop(r, facFreq, facSpat)
    %
    %   Implements padding/cropping in Fourier and spatial domain.
    %
    % V1.00
    % 02.06.2022, Tobias Birnbaum

    si = size(r(:, :, 1));
    if (nargin < 3), facSpat = 1; end
    if (facSpat == 1 && facFreq == 1), return, end

    if (facSpat > 1)
        r = borderpad(r, round(facSpat * si));
        si = round(si * facSpat);
    end

    if (facFreq > 1)
        r = fftshift(ifft2(ifftshift(borderpad(fftshift(fft2(ifftshift(r))), round(facFreq * si))))) * facFreq;
    else
        r = fftshift(ifft2(ifftshift(centercrop(fftshift(fft2(ifftshift(r * facFreq))), round(facFreq * si)))));
    end

    if (facSpat < 1)
        r = centercrop(r, round(facFreq * facSpat * si));
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
