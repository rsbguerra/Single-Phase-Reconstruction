function [I, qsat0] = saturate_gray(I, qsat, crop, bit_depth)
    % [img, qsat0] = img_saturate (img, qsat, crop)
    %
    %	Saturates bright spots in grayscale image by taking
    %	global average as reference level.
    %
    %	Optimal parameter `qsat` depends on image content;
    %	if not provided, a hardcoded value is applied to the
    %	bright region in the image (automatically segmented)
    %
    % %%%%% INPUT
    %	I      - 2D array (any format)
    % %%%%% <optional>
    %	qsat   = [qsat] or [] (full-auto);
    %	         if>0: absolute saturation parameter = multiplicity of
    %	               average brightness for the upper saturation level,
    %	         if<0: relative brightness parameter = inverse quotient
    %	               correcting automatically estimated saturation level;
    %	crop   - image part (centered) for averaging, scalar in range (0..1)
    % %%%%% OUTPUT
    %	I      - uint8 (0..255)
    %	qsat0  - argument qsat reproducing full-auto result for given crop
    %
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
    %
    % University of Cagliari (UNICA), Department of Electrical and Electronic
    % Engineering, Italy had made a minor modification to the original
    % implementation, adding also the "bit_depth" input parameter.
    % Changes/additions have been clearly marked.
    %

    if nargin < 3; crop = 1; end
    if nargin < 2; qsat = []; end
    if size(I, 3) > 1; error('I: not a 2D array'); end
    % if ~isa(I,'uint8')
    % 	error('I: not a gray scale image. Need absolute values in a given dynamic range.');
    % end
    qsat0 = qsat;

    % averaging region
    [ny, nx] = size(I);
    y_block = round((ny - ny * crop) / 2 + (1:ny * crop));
    x_block = round((nx - nx * crop) / 2 + (1:nx * crop));
    % averaging mask
    if nargin < 2 || isempty(qsat) || qsat < 0
        fullauto = true;
        block = mat2gray(I(y_block, x_block)); % --> (0..1) relative
        % 	block = min(1, block/0.3); % saturate before thresholding (BAD!!)
        mask = block > graythresh(block); %*0.999;
        mask = bwareaopen(mask, ceil(numel(mask) / 1e2));
        mask = imfill(mask, 'holes');
        mask = imdilate(mask, strel('disk', ceil(min(size(I)) / 40)));

        if qsat < 0
            qsat = -3 / qsat; % hardcoded modified
        else
            qsat = 4; % hardcoded
        end

        % 	figure; imagesc(mask); axis image
    else
        fullauto = false;
        mask = true(length(y_block), length(x_block));
    end

    I = double(I);
    I = I / max(I(:)); % --> (0..1) absolute-zero
    I0 = I;

    block = I(y_block, x_block) .* double(mask);
    av = sum(block(:)) / sum(mask(:)); % average within mask

    if qsat0 < 0 % manual balance
        lev = av * qsat; % upper saturation level (0..) allows dimming
    else
        lev = min(1, av * qsat); % (0..1) no dimming: white stays white
    end

    if isnan(lev); % do not saturate enpty channel
        lev = 1;
    end

    I = min(1, I / lev); % (0..1) saturation

    %%%%%% START UNICA EDIT %%%%%%
    % if bit_depth==8
    %     I = uint8(round( 255*I )); % (0..255)
    % else
    %     I = uint16(round( 65535*I ));
    % end
    %%%%%% END UNICA EDIT %%%%%%

    % argument qsat reproducing full-auto result
    if nargout > 1

        if fullauto
            av0 = sum(sum(I0(y_block, x_block))) / numel(I0(y_block, x_block));

            if isnan(av) % enpty channel
                qsat0 = 1;
            else
                qsat0 = (av * qsat) / av0;
            end

        else
            qsat0 = qsat;
        end

    end

    % figure(66); imagesc(block.*double(mask)); axis image; colormap gray
    % title('saturate gray')
    % % waitforbuttonpress
