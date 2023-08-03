function [apResOutList, tauList, idxWC] = calcApSizeSimple(arg1, arg2, resTarget, si, z)
    % function [apResOutList, tauList, idxWC] = calcApSizeSimple(arg1, arg2, resTarget, si, z)
    %   Calculates aperture size with least-square difference (in pixel) to resolution target for
    %   perspective diffraction limited reconstructions - operates in worst case limit resolution is evaluated on-axis with aperture center.
    %
    %   Based on work presented to JPEG Pleno on Holography by D. Blinder and T. Birnbaum.
    %
    %   Tests all permutations of viewpoints.
    %
    % INPUT:
    %   arg1@string...              dataset name...
    %     or char array                 ...or...
    %     or numeric(1)             pixel pitch in m
    %     or numeric(1,2)
    %     or numeric(2,1)
    %   arg2@string...              nrsh config fille...
    %     or char array                 ...or....
    %     or numeric(1)             wavelength in m
    %     or numeric(1,3)
    %     or numeric(3,1)
    %   resTarget@numeric(1)...     targeted resolution in px (will be used for worst case estimates)
    %     or numeric(1,2)
    %     or numeric(2,1)
    %   si@numeric(1)...            hologram resolution in px
    %     or numeric(1,2)
    %     or numeric(2,1)
    %   z@numeric(nViews, 1)...     reconstruction distance per viewpoint in m
    %
    % OUTPUT:
    %   apResOutList@numeric(nViews,2)...list of aperture sizes per viewpoint provided resTarget
    %       or if nargout < 3: numeric(1,2)...       worst case; I.e. least aperture size usuable for all viewpoints (worst case resolution of reconstruction is at most resTarget.)
    %
    %   tauList@numeric(nViews,2)...list of effective bandwidths per viewpoint for vert, horz direction
    %       or if nargout < 3: numeric(1,2)...        worst case tau's, if only 2 output arguments are requested
    %
    %   idxWC@numeric(idx)...       list index for worst case scenario, usable for apResOutList and tauList
    %
    % Version 2.5
    % 23.11.2020, Tobias Birnbaum

    verbose = false;

    %% Input sanitization
    if (isscalar(si)), si = si .* [1, 1]; else, si = si(1:2); end
    si = si(:).';
    if (isscalar(resTarget)), resTarget = resTarget .* [1, 1]; else, resTarget = resTarget(1:2); end
    resTarget = resTarget(:).';

    if (isnumeric(arg1) && isnumeric(arg2))
        pp = arg1;
        wlen = arg2;
    else
        %% Load config file
        rec_par_cfg = read_render_cfg(arg2, arg1); %read configuration file
        pp = rec_par_cfg.pixel_pitch;
        wlen = rec_par_cfg.wlen;
    end

    pp = pp(:).' .* [1, 1];

    %% Aperture size may not exceed hologram size
    si = si(1:2);
    resTarget = min(si, resTarget(1:2));
    npxTarget = prod(resTarget);

    %% Select smallest wavelength, i.e. worst-case
    wlen = min(wlen);

    %% Calculate number of viewpoints
    numViews = numel(z);
    if (numViews == 0), apResOutList = []; tauList = []; idxWC = 0; warning('calcApSize:empty_input', '0 valid view points provided.'); end

    %% Verify that resizing without vignetting is possible
    if (any(resTarget ./ si > 1)), apResOutList = si; tauList = [1, 1]; idxWC = 1; return, end

    minZ = min(abs(z(:)));
    theta = asin(min(wlen ./ pp / 2, 1));
    zMinReqOrg = (abs(pp .* si / 2 ./ tan(theta))); % Convergence to point
    zMinReq = max(abs(pp .* (si - resTarget) / 2 ./ tan(theta))); % Convergence at the most to resTarget
    resTargetMin = ceil([max(zMinReqOrg(1) - minZ, 0), max(zMinReqOrg(2) - minZ, 0)] .* tan(theta) * 2 ./ pp);
    %resTargetMin = floor(tan(asin(min(wlen./pp/2, 1))) * min(abs(z-zMinReq)) ./ pp)
    maxDHres = resTarget + floor(tan(theta) * minZ ./ pp);
    if (minZ < zMinReq), error('calcApSizeSimple:DiffractionLimitation', ['Insufficient diffraction given DH resolution=' num2str(si) ' px, pp=' num2str(pp) ' px, min. wlen=' num2str(wlen) ' nm, min. z=' num2str(min(z(:))) ' m to achieve target resolution: ' num2str(resTarget) ' px. Change either one:\n a) Minimal reconstruction distance z to >= ' num2str(zMinReq) ' m.\n b) Requested target resolution >= ' num2str(resTargetMin) ' px.\n c) DH resolution to <= ' num2str(maxDHres) ' px.']); end

    %% Start search for minimal required aperture size, s.t. resolution anywhere in reconstruction < targetRes
    if (nargout > 2)

        for id = numViews:-1:1
            [apResOutList(id, 1:2), tauList(id, 1:2)] = eq(z(id));
        end

        [~, idxWC] = min(apResOutList(:, 1) .* apResOutList(:, 2));
    else
        [apResOutList, tauList] = eq(min(abs(z)));
    end

    %% Auxiliary function
    function [apResFinal, tau] = eq(z)
        tau = resTarget ./ si ./ pp;
        tau = min(tau, 1 ./ pp);

        if (z < max(zMinReqOrg))
            apResFinal = si;
            %apResFinal = floor((wlen * tau .* 2.*(zMinReqOrg-z) ./ (sqrt(4-wlen^2*tau.^2)))./pp);
        else
            apResFinal = floor((wlen * tau * z ./ (sqrt(4 - wlen ^ 2 * tau .^ 2))) ./ pp);
        end

    end

end
