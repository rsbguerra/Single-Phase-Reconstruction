function avg_diff = bjontegaard2(R1, PSNR1, R2, PSNR2, mode, deg)
    % function avg_diff = bjontegaard2(R1,PSNR1,R2,PSNR2,mode,deg)
    %   bjontegaard2    Bjontegaard metric calculation
    %   Bjontegaard's metric allows to compute the average gain in PSNR or the
    %   average per cent saving in bitrate between two rate-distortion
    %   curves [1].
    %   Differently from the avsnr software package or VCEG Excel [2] plugin this
    %   tool enables Bjontegaard's metric computation also with more than 4 RD
    %   points.
    %   Fixed integration interval in version 2.
    %
    %   R1,PSNR1 - RD points for curve 1
    %   R2,PSNR2 - RD points for curve 2
    %   mode -
    %       'dsnr' - average PSNR difference
    %       'rate' - percentage of bitrate saving of data set 2 given
    %                data set 1
    %
    %   avg_diff - the calculated Bjontegaard metric ('dsnr' or 'rate')
    %
    %   (c) 2010 Giuseppe Valenzise
    %
    %% Bugfix 20130515
    %   Original script contained error in calculation of integration interval.
    %   It was fixed according to description and figure 3 in original
    %   publication [1]. Script was verifyed using data presented in [3].
    %   Fixed lines labeled as "(fixed 20130515)"
    %
    %   (c) 2013 Serge Matyunin
    %%
    %
    %   References:
    %
    %   [1] G. Bjontegaard, Calculation of average PSNR differences between
    %       RD-curves (VCEG-M33)
    %   [2] S. Pateux, J. Jung, An excel add-in for computing Bjontegaard metric and
    %       its evolution
    %   [3] VCEG-M34. http://wftp3.itu.int/av-arch/video-site/0104_Aus/VCEG-M34.xls
    %
    % convert rates in logarithmic units
    lR1 = log(R1);
    lR2 = log(R2);
    if (nargin < 6), deg = 3; end % Degree of polynomial interpolation

    switch lower(mode)
        case 'dsnr_spline'
            % PSNR method
            [~, idxUnique1] = unique(lR1, 'last');
            [~, p] = sort(idxUnique1, 'ascend');
            idxUnique1 = idxUnique1(p);
            lR1u = lR1(idxUnique1);
            PSNR1u = PSNR1(idxUnique1);

            [~, idxUnique2] = unique(lR2, 'last');
            [~, p] = sort(idxUnique2, 'ascend');
            idxUnique2 = idxUnique2(p);
            lR2u = lR2(idxUnique2);
            PSNR2u = PSNR2(idxUnique2);

            p1 = spline(lR1u, PSNR1u);
            p2 = spline(lR2u, PSNR2u);

            % integration interval (fixed 20130515)
            min_int = max([min(lR1u); min(lR2u)]);
            max_int = min([max(lR1u); max(lR2u)]);

            % find integral
            cnew = zeros(size(p1.coefs, 1), 7);

            for ii = 1:size(p1.coefs, 1)
                cnew(ii, :) = conv(p1.coefs(ii, :), p1.coefs(ii, :));
            end

            p1.coefs = cnew;
            p1.order = 7;

            cnew = zeros(size(p2.coefs, 1), 7);

            for ii = 1:size(p2.coefs, 1)
                cnew(ii, :) = conv(p2.coefs(ii, :), p2.coefs(ii, :));
            end

            p2.coefs = cnew;
            p2.order = 7;

            p_int1 = fnint(p1);
            p_int2 = fnint(p2);

            int1 = diff(fnval(p_int1, [min_int, max_int]));
            int2 = diff(fnval(p_int2, [min_int, max_int]));

            % find avg diff
            avg_diff = (int2 - int1) / (max_int - min_int);

        case 'dsnr'
            % PSNR method
            p1 = polyfit(lR1, PSNR1, deg);
            p2 = polyfit(lR2, PSNR2, deg);

            % integration interval (fixed 20130515)
            min_int = max([min(lR1); min(lR2)]);
            max_int = min([max(lR1); max(lR2)]);

            % find integral
            p_int1 = polyint(p1);
            p_int2 = polyint(p2);

            int1 = polyval(p_int1, max_int) - polyval(p_int1, min_int);
            int2 = polyval(p_int2, max_int) - polyval(p_int2, min_int);

            % find avg diff
            avg_diff = (int2 - int1) / (max_int - min_int);

        case 'rate_spline'
            % rate method
            [~, idxUnique1] = unique(PSNR1, 'last');
            [~, p] = sort(idxUnique1, 'ascend');
            idxUnique1 = idxUnique1(p);
            PSNR1u = PSNR1(p);
            lR1u = lR1(idxUnique1);

            [~, idxUnique2] = unique(PSNR2, 'last');
            [~, p] = sort(idxUnique2, 'ascend');
            idxUnique2 = idxUnique2(p);
            PSNR2u = PSNR2(p);
            lR2u = lR2(idxUnique2);

            p1 = spline(PSNR1u, lR1u);
            p2 = spline(PSNR2u, lR2u);

            % integration interval (fixed 20130515)
            min_int = max([min(PSNR1); min(PSNR2)]);
            max_int = min([max(PSNR1); max(PSNR2)]);

            % find integral
            cnew = zeros(size(p1.coefs, 1), 7);

            for ii = 1:size(p1.coefs, 1)
                cnew(ii, :) = conv(p1.coefs(ii, :), p1.coefs(ii, :));
            end

            p1.coefs = cnew;
            p1.order = 7;

            cnew = zeros(size(p2.coefs, 1), 7);

            for ii = 1:size(p2.coefs, 1)
                cnew(ii, :) = conv(p2.coefs(ii, :), p2.coefs(ii, :));
            end

            p2.coefs = cnew;
            p2.order = 7;

            p_int1 = fnint(p1);
            p_int2 = fnint(p2);

            int1 = diff(fnval(p_int1, [min_int, max_int]));
            int2 = diff(fnval(p_int2, [min_int, max_int]));

            % find avg diff
            avg_exp_diff = (int2 - int1) / (max_int - min_int);
            avg_diff = (exp(avg_exp_diff) - 1) * 100;

        case 'rate'
            % rate method
            p1 = polyfit(PSNR1, lR1, deg);
            p2 = polyfit(PSNR2, lR2, deg);

            % integration interval (fixed 20130515)
            min_int = max([min(PSNR1); min(PSNR2)]);
            max_int = min([max(PSNR1); max(PSNR2)]);

            % find integral
            p_int1 = polyint(p1);
            p_int2 = polyint(p2);

            int1 = polyval(p_int1, max_int) - polyval(p_int1, min_int);
            int2 = polyval(p_int2, max_int) - polyval(p_int2, min_int);

            % find avg diff
            avg_exp_diff = (int2 - int1) / (max_int - min_int);
            avg_diff = (exp(avg_exp_diff) - 1) * 100;
    end
