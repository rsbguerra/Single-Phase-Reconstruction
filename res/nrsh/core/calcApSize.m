function [apResOutList, tauList, idxWC] = calcApSize(arg1, arg2, resTarget, si, z, hpos, vpos, mode)
    % function [apResOutList, tauList, idxWC] = calcApSize(arg1, arg2, resTarget, si, z, hpos, vpos, mode)
    %   Calculates aperture size with least-square difference (in pixel) to resolution target for
    %   2D perspective diffraction limited reconstructions.
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
    %   z@numeric(nVies, 1)...      reconstruction distance per viewpoint in m
    %   hpos@numeric(nViews)...     relative horizontal position of aperture center per viewpoint
    %   vpos@numeric(nViews)...     relative vertical position of aperture center per viewpoint
    %   mode@char array...          Calculation mode of aperture position. Allowed values are:
    %                               'px'...     pixel based aperture positioning mode
    %                               'angle'...  angle based aperture positioning mode
    %
    % OUTPUT:
    %   apResOutList@numeric(nViews,2)...list of aperture sizes per viewpoint provided resTarget
    %       or if nargout < 3: numeric(1,2)...       worst case; I.e. least aperture size usuable for all viewpoints (worst case resolution of reconstruction is at most resTarget.)
    %
    %   tauList@numeric(nViews,2)...list of effective bandwidths per viewpoint for vert, horz direction
    %       or if nargout < 3: numeric(1,2)...        worst case tau's, if only 2 output arguments are requested
    %
    %   worstCaseIdx@numeric(idx)...    list index for worst case scenario, usable for apResOutList and tauList

    %
    % Version 1.00
    % 06.11.2020, Tobias Birnbaum

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

    switch (lower(mode))
        case 'px'
            midH = @(ap_size, v_pos, ~) round(si(1) / 2 + (si(1) / 2 - ap_size(1) / 2) * v_pos);
            midV = @(ap_size, h_pos, ~) round(si(2) / 2 + (si(2) / 2 - ap_size(2) / 2) * h_pos);

            %positions in pixel
            %     start_row = max(1, round(hol_rows/2 + (hol_rows/2 - ap_size(1)/2 ) * v_pos - ap_size(1)/2 ) );
            %     end_row = min(hol_rows, round(hol_rows/2 + (hol_rows/2 - ap_size(1)/2 ) * v_pos + ap_size(1)/2 ) );
            %     start_col= max(1, round(hol_cols/2 + (hol_cols/2 - ap_size(2)/2 ) * h_pos - ap_size(2)/2 ) );
            %     end_col= min(hol_cols, round(hol_cols/2 + (hol_cols/2 - ap_size(2)/2 ) * h_pos + ap_size(2)/2 ) );
        case 'angle'
            midH = @(ap_size, v_pos, z) 1;
            midV = @(ap_size, h_pos, z) 1;
            error('TODO: Implement, given the code below.')

            % h_angle=deg2rad(h_angle);
            % v_angle=deg2rad(v_angle);
            % dof_angle=deg2rad(dof_angle);
            %
            % %positions
            % x_a=abs(rec_dist) * ( tan(h_angle) - tan(dof_angle) );
            % x_b=abs(rec_dist) * ( tan(h_angle) + tan(dof_angle) );
            % y_a=abs(rec_dist) * ( tan(v_angle) - tan(dof_angle) );
            % y_b=abs(rec_dist) * ( tan(v_angle) + tan(dof_angle) );
            %
            % %positions in pixel
            % start_row=(hol_rows/2)-ceil(y_b/pp);
            % start_row=fix(start_row);%useful if hol dim. is odd
            % if start_row==0 %shadow approx
            %     start_row=1;
            % end
            %
            %
            % end_row=(hol_rows/2)-floor(y_a/pp);
            % end_row=fix(end_row);
            % if end_row==hol_rows+1 %shadow approx
            %     end_row=end_row-1;
            % end
            %
            % start_col=floor(x_a/pp)+(hol_cols/2);
            % start_col=fix(start_col);
            % if start_col==0 %shadow approx
            %     start_col=start_col+1;
            % end
            %
            %
            % end_col=ceil(x_b/pp)+(hol_cols/2);
            % end_col=fix(end_col);
            % if end_col==hol_cols+1 %shadow approx
            %     end_col=end_col-1;
            % end
            %
            % size_V=end_row-start_row+1;
            % size_H=end_col-start_col+1;
            %
            % if ( (size_V-size_H) == 1 )
            %     end_col=end_col-1;
            % elseif ( (size_H-size_V) == 1 )
            %     end_row=end_row-1;
            % end
        otherwise
            error('nrsh:calcApSize:invalid_mode', 'Error in nrsh: invalid aperture positioning mode. Valid values are: ''px'', ''angle''.')
    end

    %% Aperture size may not exceed hologram size
    si = si(1:2);
    resTarget = min(si, resTarget(1:2));
    npxTarget = prod(resTarget);

    %% Select smallest wavelength, i.e. worst-case
    wlen = min(wlen);

    %% Set frequency bound functions
    % x.. (scene) position of resolution evaluation chosen to be fixed at x = 0, as scenes are usually axis aligned
    % xa... center position of aperture in m
    % a... size of aperture in m
    fupFun0 = @(x, xa, a, z) sum((x - (xa + a / 2)) ./ (wlen * sqrt(sum((x - (xa + a / 2)) .^ 2, 2) + z .^ 2)), 2);
    fdownFun0 = @(x, xa, a, z) sum((x - (xa - a / 2)) ./ (wlen * sqrt(sum((x - (xa - a / 2)) .^ 2, 2) + z .^ 2)), 2);

    fupFun = @(xa, a, z) fupFun0(0, xa, a, z);
    fdownFun = @(xa, a, z) fdownFun0(0, xa, a, z);

    %% Calculate number of viewpoints
    numViews = max([numel(z), numel(hpos), numel(vpos)]);
    if (numViews == 0), apResOutList = []; tauList = []; idxWC = 0; warning('nrsh:calcApSize:empty_input', 'Warning in nrsh: 0 valid view points provided.'); end

    %% Start binary search for best apperture size for each viewpoint in z, hpos, vpos
    ApSiList = unique(round([linspace(1, si(1), min(si)).', linspace(1, si(2), min(si)).']), 'rows');
    nASi = size(ApSiList, 1);

    for id = numViews:-1:1
        [apResOutList(id, 1:2), tauList(id, 1:2)] = bs(z(id), hpos(id), vpos(id));
    end

    [~, idxWC] = min(apResOutList(:, 1) .* apResOutList(:, 2));

    if (nargout < 3)
        tauList = tauList(idxWC, :);
        apResOutList = apResOutList(idxWC, :);
    end

    %% Auxiliary functions
    function [apResFinal, tau] = bs(z, h, v)
        resTmp = zeros(0, 5); % Format: targetSi(1:2), apSiId, tau(1:2)

        loId = 1;
        [loTres, tau] = calcAp(z, ApSiList(loId, :), h, v);
        resTmp(loId, :) = [loTres, loId, tau];
        if (verbose), disp(['ID: ' num2str(loId), ' apSi: ' num2str(ApSiList(loId, :)) ' | Achieved target resolution: : ' num2str(loTres)]), end
        if (npxTarget < prod(loTres)), apResFinal = ApSiList(loId, :); return; end % Early exit

        hiId = nASi;
        [hiTres, tau] = calcAp(z, ApSiList(hiId, :), h, v);
        resTmp(hiId, :) = [hiTres, hiId, tau];
        if (verbose), disp(['apSi: ' num2str(ApSiList(hiId, :)) ' | Achieved target resolution: : ' num2str(hiTres)]), end
        if (prod(hiTres) < npxTarget), apResFinal = ApSiList(hiId, :); return; end % Early exit

        while (loId < hiId)
            curId = floor(0.5 * (loId + hiId));
            apSi = ApSiList(curId, :);
            [tresLoc, tau] = calcAp(z, apSi, h, v);
            if (verbose), disp(['apSi: ' num2str(apSi) ' | Achieved target resolution: : ' num2str(tresLoc)]), end
            resTmp(curId, :) = [tresLoc, curId, tau];

            if (prod(tresLoc) < npxTarget)
                loId = curId + 1;
            else
                hiId = curId - 1;
            end

        end

        [~, idx] = min((resTmp(:, 1) .* resTmp(:, 2) - npxTarget) .^ 2);
        curId = resTmp(idx, 3);
        tau = resTmp(idx, 4:5);
        apResFinal = ApSiList(curId, :);
        if (verbose), disp(['Best apSi: ' num2str(ApSiList(curId, :)) ' | Achieved target resolution: ' num2str(resTmp(idx, 1:2)) ' versus requested ' num2str(resTarget)]), end
    end

    function [tres, tau] = calcAp(z, apSi, h, v)
        apSiMod = apSi .* pp .* (-1) .^ ([sign(h), sign(v)] + 1);
        hpx = midH(apSi, h, z);
        vpx = midV(apSi, v, z);

        pos = ([hpx, vpx] - si / 2) .* pp;
        fup = fupFun(pos, apSiMod, z);
        fdown = fdownFun(pos, apSiMod, z);
        %         hh = (hpx - si(1)/2) .* pp(1);
        %         vv = (vpx - si(2)/2) .* pp(2);
        %
        %         fup   = fupFun([hh, vv], apSiMod, z);
        %         fdown = fdownFun([hh, vv], apSiMod, z);

        tau = abs(fup - fdown);
        tau = [min(tau, 1 ./ pp(1)), min(tau, 1 ./ pp(2))];
        tres = round((pp .* tau) .* si);
    end

end
