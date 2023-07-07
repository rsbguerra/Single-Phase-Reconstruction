function [mat] = subarray_yx(mat, n_yx, shiftq_yx, padval)
    % [mat] = frame2d (mat, n_yx, shiftq_yx, padval)
    %
    % Extract a shifted sub-array, fill unknown regions with padval
    %
    % %%%%%%%%% INPUT
    %   mat       - 2D array
    %   n_yx      = [noy,nox] output frame size;
    %               set NaN for one of sizes to keep it fixed;
    %               set [] to keep original size intact
    % %%%%%%%%% <optional>
    %   shiftq_yx = [qy,qx] relative frame position with respect to
    %               input array center, in units of size(mat)
    %   padval    - (default=0) padding value/method for padarray()
    %
    % ----------------------------------------
    % mat = [[1 2 3 4 5 6];  [1 2 3 4 5 6].*10]
    % n_yx = [4 4];
    % shiftq_yx = [-1.0 -0.5];
    % padval = NaN;
    % ----------------------------------------
    % -------------------------------------------------------------------------
    % Code developed by Tomasz Kozacki*, Weronika Zaperty*, Hyon-Gon Choo**
    %
    % *
    % Institute of Micromechanics and Photonics
    % Faculty of Mechatronics
    % Warsaw University of Technology
    %
    % **
    % Electronics and Telecommunications Research Institute
    % 1110-6 Oryong-dong, Buk-gu, Kwangju, Korea Po�udniowa
    %
    % Contact: t.kozacki@mchtr.pw.edu.pl
    % -------------------------------------------------------------------------
    % Copyright (c) 2019, Warsaw University of Technology
    % All rights reserved.
    %
    % Redistribution and use in source and binary forms, with or without
    % modification, are permitted provided that the following conditions are met:
    %
    % 1. Redistribution and use in source and binary forms, with or without
    % modification, are permitted for standardization and academic purpose only
    %
    % 2. Redistributions of source code must retain the above copyright notice, this
    %   list of conditions.
    %
    % 3. Redistributions in binary form must reproduce the above copyright notice,
    %   this list of conditions in the documentation and/or other materials
    %   provided with the distribution
    %
    % -------------------------------------------------------------------------

    [ny, nx] = size(mat);

    if nargin < 4; padval = 0; end
    if nargin < 3 || isempty(shiftq_yx); shiftq_yx = [0 0]; end

    if isempty(n_yx)
        noy = ny;
        nox = nx;
    elseif length(n_yx) < 2
        error('Argument must be a list: n_yx=[noy,nox] ')
    elseif isnan(n_yx(1)) && isnan(n_yx(2))
        error('Only one of n_yx=[noy, nox] can be NaN')
    else
        if isnan(n_yx(1)); n_yx(1) = size(u, 1); end
        if isnan(n_yx(2)); n_yx(2) = size(u, 2); end
        noy = n_yx(1);
        nox = n_yx(2);
    end

    % floor: compatibility with fft2padscale
    y = floor(ny / 2 - noy / 2 + (1:noy) + shiftq_yx(1) * ny);
    x = floor(nx / 2 - nox / 2 + (1:nox) + shiftq_yx(2) * nx);

    py1 = length(y(y < 1));
    py2 = length(y(y > ny));
    px1 = length(x(x < 1));
    px2 = length(x(x > nx));

    y = y(y >= 1); y = y(y <= ny);
    x = x(x >= 1); x = x(x <= nx);

    if length(y) == 0; warning('No content left with shiftq_y=%d', round(shiftq_yx(1))); end
    if length(x) == 0; warning('No content left with shiftq_x=%d', round(shiftq_yx(2))); end

    mat = mat(y, x);
    mat = padarray(mat, [py1 0], padval, 'pre');
    mat = padarray(mat, [py2 0], padval, 'post');
    mat = padarray(mat, [0 px1], padval, 'pre');
    mat = padarray(mat, [0 px2], padval, 'post');
