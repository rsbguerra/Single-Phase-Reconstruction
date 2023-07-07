function PostProcMetrics(fname, outfold)
    % Takes a Metrics.mat file as input, updates the file with BD-(P)SNR values and writes scores as *.xls file.
    %
    % INPUT:
    % outfold@char-array...     ouput folder for all spreadsheets, default: ./xls/
    % fname contains at least M@struct and cell-array distLanchors.
    %   M@struct...         contains objective RD scores
    %   M.(plane).(dist).bitrateMap@table...    map requested to achieved bitrates and evtl. QP values etc.
    %                   .ref@struct array...    results of objective metrics per bitrate wrt. float value GT
    %                   .ref(1).{snr_hol, ssim_hol, ussim_hol}@numeric(1,ncolors)... metric values per color channel
    %                   .ref(1).view_results(nviews,1)@table(nviews+1,7)... table of metrics per reconstruction viewpoint, last line avg.
    %                   .deg@struct array...    like ref, but wrt. quantized GT (only for anchor codecs)
    %
    % OUTPUT:
    % Added fields to M:
    %                   .ref_bdsnr@struct(1)...                         struct with one field per dist in distLanchors
    %                   .ref_bdsnr.(<distAnchor>_<plane>)@numeric(1, ncolors)...  Bjontegard SNR evaluation based on SNR in hologram plane wrt. float GT on anchor
    %                   .ref_view_results_bdpsnr@struct(1)...           struct with one field per dist in distLanchors
    %                   .ref_view_results_bdpsnr.(<distAnchor>_<plane>).numeric(nviews+1,1)...  Bjontegard PSNR evaluation based on PSNR per reconstruction for all bitrates
    %                                                                       wrt. float GT on anchor
    %
    % Objective test:
    %
    %
    % Subjective test:
    %       'results_bdpsnr_DISTjpeg_pleno_holo_etro_holo_wrt_ref.xls'
    %       'results_reconstruction_holo_METRICall_wrt_deg.xls'
    %       'results_reconstruction_holo_METRICall_wrt_ref.xls'
    %       'results_reconstruction_obj_METRICall_wrt_deg.xls'
    %       'results_reconstruction_obj_METRICall_wrt_ref.xls'
    %
    % For subjective test use as:
    %    fl = dir('Rating_OutData\JPEG_Pleno_subj\'); fl = {fl.name}; fl([1:2]) = [];
    %    for f = fl, PostProcMetrics(fullfile('Rating_OutData\JPEG_Pleno_subj\\', f{1}, 'MetricsSubj.mat'), fullfile('SubjectiveTest_Data_Excel\', f{1})), end
    %
    % Version 2.00
    % 02.10.2021, Tobias Birnbaum

    if (nargin < 2), outfold = './xls/'; end

    try
        mkdir(outfold)
    catch me
    end

    %% 1) Load data
    dat = load(fname);
    doSubjTest = (~isfield(dat, 'M') && isfield(dat, 'Msubj'));
    doCE = isempty(intersect(dat.distL, dat.distLanchors));
    % Could also test: dat.M.(plane).(dist).(gt)(bId).pipelineType for Subjective
    if (doSubjTest)
        dat.M = dat.Msubj;
    end

    planeL = fieldnames(dat.M).';
    distL = fieldnames(dat.M.(planeL{1})).';
    ncolors = size(dat.M.(planeL{1}).(distL{1}).bitrateMap, 2) / 2 - 1;
    nviews = size(dat.M.(planeL{1}).(distL{1}).ref(1).view_results, 1) - 1;
    clear distL;

    %% 2) Gather anchor distortions + rates
    distPlaneLanchors = cell(0, 1);

    if (~doCE)

        for planeC = planeL
            planeStr = planeC{1};
            distL = fieldnames(dat.M.(planeStr)).';

            if (numel(intersect(distL, dat.distLanchors)) ~= numel(dat.distLanchors))
                warning('PostProcMetrics:insufficient_anchor_data', ['Not all anchors specified in distLanchors (' cell2str(dat.distLanchors) ') are present in ' planeStr ' plane. Continuing only with: ' cell2str(distL)])
            end

            %% 2.1) Obtain anchor data
            gtStr = 'ref'; % Reference against float GT
            % gtStr = 'deg';  % Reference against quantized GT
            for distC = dat.distLanchors(:).'
                distStr = distC{1};
                distPlaneStr = [distStr, '_', planeStr];
                distPlaneLanchors(end + 1) = {distPlaneStr};

                [rate, dist, distView] = gatherRD(dat, planeStr, distStr, gtStr, ncolors, doSubjTest);

                rateAnchor.(distPlaneStr) = rate;
                distAnchor.(distPlaneStr) = dist;
                distViewAnchor.(distPlaneStr) = distView;
            end

        end

    end

    %% 3) Obtain proponent data + calculate BDSNR
    planeStr = 'holo'; % Proponents are only evaluated in holo plane
    gtStr = 'ref'; % Proponents are only evaluated wrt. float GT
    distL = fieldnames(dat.M.(planeStr)).';

    for distC = distL
        distStr = distC{1};
        isAnchor = ~isempty(intersect(dat.distLanchors, distC));
        if (isAnchor), continue, end

        %% 3.1) Gather achieved bitrates + snr_hol + view_results per proponent
        [rate, dist, distView] = gatherRD(dat, planeStr, distStr, gtStr, ncolors, doSubjTest);
        rateProponent.(distStr) = rate;
        distProponent.(distStr) = dist;
        distViewProponent.(distStr) = distView;

        if (~doCE)
            %% 3.2) Calculate BD-(P)SNR per anchor codec incl. plane
            dat.M.(planeStr).(distStr).ref_bdsnr = struct();
            dat.M.(planeStr).(distStr).ref_view_results_bdpsnr = struct();

            for distPlaneC = distPlaneLanchors
                dpAStr = distPlaneC{1}; % == distPlaneAnchorStr

                if (~doSubjTest)
                    %% 3.2.1) Calculate BD-SNR of hologram based on snr in hologram plane
                    try

                        for color = ncolors:-1:1
                            dat.M.(planeStr).(distStr).ref_bdsnr.(dpAStr)(color) = bjontegaard2(rateAnchor.(dpAStr)(:, color), distAnchor.(dpAStr)(:, color), rate(:, color), dist(:, color), 'dsnr');
                        end

                    catch me
                        warning('ObjEvaluateCompressedHolograms:bjontegaard', 'Calculation of BD-SNR based on snr_hol failed. Potential reasons: too similar rate points, insufficient rate points.')
                        me
                    end

                end

                %% 3.2.2) Calculate BS-PSNR per viewpoint based on PSNR of reconstructions
                if (size(rate, 1) <= 3)
                    disp(['BD-(P)SNR calculation will be not unique with ' num2str(size(rate, 1)) ' rate points and polynomial fit of degree 3!'])
                end

                try

                    for ii = nviews:-1:1

                        for color = ncolors:-1:1
                            dat.M.(planeStr).(distStr).ref_view_results_bdpsnr.(dpAStr)(ii, color) = bjontegaard2(rateAnchor.(dpAStr)(:, color), distViewAnchor.(dpAStr)(ii, :, color), rate(:, color), distView(ii, :, color), 'dsnr');
                        end

                    end

                catch me
                    warning('ObjEvaluateCompressedHolograms:bjontegaard', 'Calculation of BD-SNR based on snr_hol failed. Potential reasons: too similar rate points, insufficient rate points.')
                    me
                end

            end

        end

    end

    %% 4) Write out XLS files
    if (doSubjTest), outname = 'MetricsSubj.xls'; else, outname = 'Metrics.xls'; end
    %% 4.1) Write out all metrics per distortion
    for planeC = planeL
        plane = planeC{1};

        for distC = fieldnames(dat.M.(plane)).'
            dist = distC{1};

            metricsL = {};

            if (~doSubjTest)
                metricsL = fieldnames(dat.M.(plane).(dist).ref).';
                metricsL = setdiff(metricsL, {'view_results', 'totBitrate'});
            end

            metricsL = setdiff(metricsL, {'pipelineType'});

            isAnchor = ~isempty(intersect(dist, dat.distLanchors));
            if (~isAnchor && ~strcmpi(plane, 'holo')), continue, end % Skip: Obj plane for non-anchors

            %% Process all metrics except for view_results, bd(p)snr
            gtL = {'ref'};
            if (isAnchor), gtL = [gtL, {'deg'}]; end

            if (~isempty(metricsL))

                for gtC = gtL
                    gt = gtC{1};
                    nbitrates = numel(dat.M.(plane).(dist).(gt));

                    for metricsC = metricsL
                        metrics = metricsC{1};
                        clear tmp;
                        tmp = []; % Format: Bitrate requested, bitrateAchievedTot, bitrateC1, .. bitrateCncolors, metricC1, metricC2, ...

                        for bId = nbitrates:-1:1
                            tmp(bId, ncolors + 3:3 + ncolors * 2 - 1) = dat.M.(plane).(dist).(gt)(bId).(metrics);

                            idx = dat.M.(plane).(dist).bitrateMap.bppRequestedTot == dat.M.(plane).(dist).(gt)(bId).totBitrate; %find();
                            tmp(bId, 1:ncolors + 2) = dat.M.(plane).(dist).bitrateMap(idx, [1, 2:2:2 * (ncolors + 1)]).Variables;
                        end

                        if (ncolors == 1)
                            tab = table(tmp(:, 1), tmp(:, 2), tmp(:, 3), tmp(:, 4));
                            tab.Properties.VariableNames = {'bppRequested', 'bppAchievedTot', 'bppAchievedC1', [metrics 'C1']};
                        else
                            tab = table(tmp(:, 1), tmp(:, 2), tmp(:, 3), tmp(:, 4), tmp(:, 5), tmp(:, 6), tmp(:, 7), tmp(:, 8));
                            tab.Properties.VariableNames = {'bppRequested', 'bppAchievedTot', 'bppAchievedC1', 'bppAchievedC2', 'bppAchievedC3', [metrics 'C1'], [metrics 'C2'], [metrics 'C3']};
                        end

                        writetable(tab, fullfile(outfold, ['results_DIST', dist, '_' plane, '_METRICall_wrt_' gt '.xls']), 'Sheet', metrics, 'WriteMode', 'overwritesheet')
                        %writetable(tab, fullfile(outfold, outname), 'Sheet', ['DIST', dist, '_' plane '_wrt_' gt '_METRIC' metrics], 'WriteMode', 'overwritesheet')
                    end

                end

            end

            %% Process all metrics for view_results
            gtL = {'ref'};
            if (isAnchor), gtL = [gtL, {'deg'}]; end

            for gtC = gtL
                gt = gtC{1};
                nbitrates = numel(dat.M.(plane).(dist).(gt));

                for bId = 1:nbitrates
                    writetable(dat.M.(plane).(dist).(gt)(bId).view_results, fullfile(outfold, ['results_reconstruction''_' dist, '_' plane, '_METRICall_wrt_' gt '.xls']), 'Sheet', ['bppReq', num2str(dat.M.(plane).(dist).(gt)(bId).totBitrate)], 'WriteMode', 'overwritesheet')
                    %writetable(dat.M.(plane).(dist).(gt)(bId).view_results, fullfile(outfold, outname), 'Sheet', ['Recon_' plane '_wrt_' gt '_METRICall_bppReq', num2str(dat.M.(plane).(dist).(gt)(bId).totBitrate)], 'WriteMode', 'overwritesheet')
                end

            end

            %% Process all bd(p)snr scores
            if (strcmpi(plane, 'holo') && ~isAnchor && ~doCE)

                if (~doSubjTest)
                    %% BDSNR
                    fL = fieldnames(dat.M.holo.(dist).ref_bdsnr);
                    evalStr = 'tab = table(';
                    varNames = {};

                    for ii = 1:numel(fL)
                        evalStr = [evalStr, ['dat.M.holo.' dist '.ref_bdsnr.' fL{ii} ', ']];
                        varNames{ii} = [fL{ii} '_RGB'];
                    end

                    evalStr(end - 1:end) = ');';
                    tab = table();
                    eval(evalStr)
                    tab.Properties.VariableNames = varNames;

                    writetable(tab, fullfile(outfold, ['results_bdsnr_DIST', dist, '_wrt_' gt '.xls']))
                    % writetable(tab, fullfile(outfold, outname), 'Sheet', ['bdsnr_DIST', dist, '_wrt_' gt], 'WriteMode', 'overwritesheet')

                end

                %% BDPSNR
                fL = fieldnames(dat.M.holo.(dist).ref_view_results_bdpsnr);
                evalStr = 'tab = table(';
                varNames = {};

                for ii = 1:numel(fL)
                    evalStr = [evalStr, ['dat.M.holo.' dist '.ref_view_results_bdpsnr.' fL{ii} ', ']];
                    varNames{ii} = fL{ii};
                end

                evalStr(end - 1:end) = ');';
                tab = table();
                eval(evalStr)
                tab.Properties.VariableNames = varNames;

                writetable(tab, fullfile(outfold, ['results_bdpsnr_DIST', dist, '_holo_wrt_' gt '.xls']))
                %writetable(tab, fullfile(outfold, outname), 'Sheet', ['Recon_bdpsnr_DIST', dist, '_holo_wrt_' gt], 'WriteMode', 'overwritesheet')
            end

        end

    end

    %% 4.2) Write out all bitrates per distortion
    outname = 'Bitrates.xls';
    sumL = [4, 6, 8];

    for planeC = planeL
        plane = planeC{1};

        for distC = fieldnames(dat.M.(plane)).'
            dist = distC{1};
            isAnchor = ~isempty(intersect(dist, dat.distLanchors));
            if (~isAnchor && ~strcmpi(plane, 'holo')), continue, end
            tab = dat.M.(plane).(dist).bitrateMap;
            tab(:, 2).Variables = sum(tab(:, sumL(1:ncolors)).Variables, 2);
            writetable(tab, fullfile(outfold, outname), 'Sheet', [plane '_' dist], 'WriteMode', 'overwritesheet');
        end

    end

end

function res = cell2str(x)
    % Converts cell arrays to comma separted char arrays.

    res = ''; %zeros(numel(char(x{:}))+2*(numel(x)-1), 1);

    for ii = 1:numel(x) - 1
        res = [res, x{ii}, ', '];
    end

    res = [res, x{end}];
end

function [rate, dist, distView] = gatherRD(dat, planeStr, distStr, gtStr, ncolors, doSubjTest)
    % INPUT:
    %   dat@struct...       containing M, RA
    %   planeStr@char...    name of compression plane to gather from
    %   distStr@char...     name of distortion to gather from
    %   gtStr@char...       name of groundtruth type to gather from; Possible values for anchors: {'ref', 'deg'}
    %   doSubjTest@boolean..signals if doSubjTest is active or not (limited set of bitrates)
    %
    % OUTPUT:
    %   rate@numeric(nrates, ncolors)...    achieved bitrates per color channel
    %   dist@numeric(nrates, ncolors)...    hologram SNR score per color channel/bitrate
    %   distView@numeric(nrates, nviews,ncolors)...reconstruction PSNR scores per view /bitrate

    if (doSubjTest)
        idxMask = arrayfun(@(x) any(dat.Hsubj.bitrateL == x), dat.M.(planeStr).(distStr).bitrateMap(:, 1).Variables);
    else
        idxMask = ones(size(dat.M.(planeStr).(distStr).bitrateMap(:, 1).Variables));
    end

    idx = find(idxMask);
    nrates = numel(idx);

    rate = zeros(nrates, ncolors);

    for color = ncolors:-1:1
        rate(:, color) = dat.M.(planeStr).(distStr).bitrateMap(idxMask, 2 + 2 * color).Variables;
    end

    idx2 = idx;

    for jj = 1:numel(idx)

        for ii = 1:numel(dat.M.(planeStr).(distStr).(gtStr))

            if (dat.M.(planeStr).(distStr).(gtStr)(ii).totBitrate == dat.M.(planeStr).(distStr).bitrateMap(idx(jj), 1).Variables)
                idx2(jj) = ii;
            end

        end

    end

    dist = zeros(nrates, ncolors);

    if (~doSubjTest)

        for bId = numel(idx):-1:1
            dist(bId, 1:ncolors) = dat.M.(planeStr).(distStr).(gtStr)(idx2(bId)).snr_hol;
        end

    end

    nviews = size(dat.M.(planeStr).(distStr).(gtStr)(1).view_results, 1) - 1;
    distView = zeros(nrates, nviews, ncolors); % Format: nbpp x nviews x ncolors

    for bId = nrates:-1:1
        distView(bId, 1:nviews, 1:ncolors) = dat.M.(planeStr).(distStr).(gtStr)(idx2(bId)).view_results.PSNR(1:nviews, 1:ncolors);
    end

    distView = permute(distView, [2, 1, 3]); % New format: nrates, nviews, ncolors
end
