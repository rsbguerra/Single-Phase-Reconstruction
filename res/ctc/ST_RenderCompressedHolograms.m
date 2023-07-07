function Msubj = ST_RenderCompressedHolograms(Folders, Mobj, H, si, cmin, cmax, plane, doLowResSubjTest, distL, distLanchors, targetLsubj, doSubjTestRatingOnly, doCoreVerification)
    % function ST_RenderCompressedHolograms(Folders, Mobj, H, cmin, cmax, plane, doLowResSubjTest, distL, distLanchors)
    %   Uses NRSH to reconstruct views for subjective test.
    %
    % INPUT:
    %   Folders@struct...   contains folder structure
    %   Mobj@struct...      structure from Subj_Pipeline_Compress, containing bitrate/QPN maps, to identify best suited files
    %   H@struct...         structure from holoread_PL; contains hologram specifics + reconstruction points
    %                           + contains doVideo flag -> subj. test video
    %                           or fixed view points
    %   si@numerics(1,3)... size of original hologram
    %   cmin/cmax@numerics(#viewpoints)... cmin, cmax from ground truth to be used for this specific viewpoint set
    %   plane@char...       {'obj', 'holo'}, plane of compression;
    %                       dis-/enables backpropagation of compressed data prior to reconstruction: + reconstruction prefix
    %   doLowResSubjTest... Enable diffraction limited resizing for the subj. test
    %   distL@cell...       cell array list of codecs to be tested
    %   distLanchors@cell...cell array list of anchor codecs to be tested (Dequantization+BP will be skipped for proponents)
    %   targetLsubj@numerics()...array list of all bitrates or distortion targets to test (depending on doSNR)
    %   doSubjTestRatingOnly@boolean... switches reconstructions off, if true
    %   doCoreVerification@bool(1)... flag for signaling core-experiment mode (no high-res reconstructions and rating thereof)
    %
    % OUTPUT:
    %   Files of reconstructions in pwd()/figures/*H.cfg_name*/{HEVC_, JPEG2000_, distStr}*.png for the specified viewpoints.
    %   Msubj@struct...         contains objective RD scores
    %   Msubj.(plane).(dist).bitrateMap@table...    map requested to achieved bitrates and evtl. QP values etc.
    %                   .ref@struct array...    results of objective metrics per bitrate wrt. float value GT
    %                   .ref(1).{snr_hol, ssim_hol, ussim_hol}@numeric(1,ncolors)... metric values per color channel
    %                   .ref(1).view_results(nviews,1)@table(nviews+1,7)... table of metrics per reconstruction viewpoint, last line avg.
    %                   .ref(1).pipelineType == 'objective'
    %                   .deg@struct array...    like ref, but wrt. quantized GT (only for anchor codecs)
    %
    % NOTE: Msubj (e.g. Msubj.{hm, j2k, ...}) is assumed to be completely generated within this script, i.e. potentially empty. Its supposed to be assigned to Msubj.(plane) in main_degrade.
    %
    % Created by T. Birnbaum, 26.02.2022, Version 2.7

    %% Early exit
    Msubj = struct();

    if (isempty(fieldnames(Mobj)) || isempty(fieldnames(Mobj.(distL{1}))))
        return
    end

    if (nargin < 9)
        distL = {'hm', 'j2k'};
    end

    res = H.size;

    % Layman's check for octave compatible mode
    isOctave = false;

    try
        a = datetime; clear a;
        contains('abc', 'a');
        isOctave = false;
    catch me
        isOctave = true;
    end

    %% 0) Load additional quantization information for dequantization
    if (~isempty(intersect(distL, distLanchors)))
        load(fullfile(Folders.plenofolder, ['QuantInfo_' plane 'Plane.mat']), 'Xpoi', 'quantmethod', 'L');
    end

    %% 1) Prepare compressed data
    targetStr = Mobj.(distL{1}).bitrateMap.Properties.VariableNames{1};
    doSNR = contains(targetStr, 'distortionReq');

    if (doSNR)
        prefixStr = 'dist_';
        postfixStr = 'dB_';
    else
        prefixStr = 'rate_';
        postfixStr = 'bpp_';
    end

    if (nargin < 10)

        if (isOctave)

            if (isfield(Mobj, 'hm'))
                targetReqTotL = Mobj.hm.bitrateMap{:, 1};
            else
                targetReqTotL = Mobj.(distL{1}).bitrateMap{:, 1};
            end

        else

            if (isfield(Mobj, 'hm'))
                targetReqTotL = Mobj.hm.bitrateMap.(targetStr);
            else
                %% Find first anchor, in case of obj. plane compression, otherwise consult first codec
                if (strcmpi(plane, 'obj'))
                    dist = intersect(distL, distLanchors);

                    if (~isempty(dist))
                        dist = dist{1};
                    else
                        % Nothing left to do, end
                        disp([mfilename ' was skipped in object plane mode because of missing anchors.'])
                        return
                    end

                else
                    dist = distL{1};
                end

                targetReqTotL = Mobj.(dist).bitrateMap.(targetStr);
                clear dist;
            end

        end

    else
        targetReqTotL = targetLsubj;
    end

    ncolors = numel(H.lambda);

    for distC = distL
        distStr = distC{1};
        isAnchor = ~isempty(intersect(distLanchors, {distStr}));

        if (~isfield(Msubj, distStr)), Msubj.(distStr) = struct('bitrateMap', table()); end

        if (~isAnchor && strcmpi(plane, 'obj')), continue, end % Don't evaluate proponents in object plane

        if (isAnchor)
            frame = complex(zeros(si, 'uint16'));
        else
            frame = complex(zeros(si, 'single'));
        end

        %% 2) Reconstruction loop
        for tID = 1:numel(targetReqTotL)
            targetReqTot = targetReqTotL(tID);
            if (targetReqTot == 0), continue, end

            %% *) Assign bitrateMap
            tmpBMP = Mobj.(distStr).bitrateMap;
            Msubj.(distStr).bitrateMap(end + 1, :) = tmpBMP(tmpBMP(:, 1).Variables == targetReqTot, :);
            clear tmpBMP;

            if (~doSubjTestRatingOnly)
                %% 2.1) Load data
                switch (distStr)
                    case 'hm'

                        for c = ncolors:-1:1

                            if (isOctave)
                                ttID = Mobj.(distStr).bitrateMap(:, 1) == targetReqTot;
                                qpn = Mobj.(distStr).bitrateMap{ttID, 2 + 2 * (c - 1) + 1};
                            else
                                ttID = find(Mobj.(distStr).bitrateMap(:, 1).Variables == targetReqTot);
                                qpn = Mobj.(distStr).bitrateMap(ttID, 2 + 2 * (c - 1) + 1).Variables;
                            end

                            fnameMat = fullfile(Folders.forkfolder, 'hm', ['qpn' num2str(qpn, '%03d') '_c' num2str(c) '.mat']);
                            dat = load(fnameMat, 'Qcodechat');
                            frame(:, :, c) = dat.Qcodechat(1:si(1), 1:si(2), :);
                        end

                    case 'j2k'

                        for c = ncolors:-1:1
                            fnameMat = fullfile(Folders.forkfolder, 'j2k', ['rate_' strrep(num2str(targetReqTot), '.', 'dot') '_c' num2str(c) '.mat']);
                            dat = load(fnameMat, 'Qcodechat');
                            frame(:, :, c) = dat.Qcodechat(1:si(1), 1:si(2), :);
                        end

                    case 'jxl'

                        for c = ncolors:-1:1
                            fnameMat = fullfile(Folders.forkfolder, 'jxl', ['rate_' strrep(num2str(targetReqTot), '.', 'dot') '_c' num2str(c) '.mat']);
                            dat = load(fnameMat, 'Qcodechat');
                            frame(:, :, c) = dat.Qcodechat(1:si(1), 1:si(2), :);
                        end

                    case 'proponentTemplate'
                        fnameMat = fullfile(Folders.forkfolder, distStr, ['rate_' strrep(num2str(targetReqTot), '.', 'dot') '.mat']);
                        dat = load(fnameMat, 'Qcodechat');
                        frame = dat.Qcodechat(1:si(1), 1:si(2), :);
                    case 'interfere'

                        for c = ncolors:-1:1
                            fnameMat = fullfile(Folders.forkfolder, distStr, [prefixStr strrep(num2str(targetReqTot), '.', 'dot') '_holo_001_c' num2str(c) '.mat']);
                            dat = load(fnameMat, 'Qcodechat');
                            frame(:, :, c) = dat.Qcodechat(1:si(1), 1:si(2), :);
                        end

                    otherwise
                        error('ST_RenderCompressedHolograms:unsupported_codec', ['Please add support for ' distStr ' to subjective testing pipeline.'])
                end

                clear dat;

                if (isAnchor)
                    %% 2) Dequantize
                    frame = Dequantize_PL(frame, Xpoi, L, quantmethod);

                    if (strcmpi(plane, 'obj'))
                        %% 3) Back-propagate from object to hologram plane
                        zeropad = false; % Faciliate: nopad approach for anchors, see wg1m89073
                        info = getSettings('dataset', H.dataset, 'zero_pad', zeropad, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'usagemode', 'complex', 'direction', 'inverse');
                        frame = nrsh(frame, H.obj_dist, info);
                    end

                end

            end

            %% 4) Reconstruct
            switch (distStr)
                case 'hm'
                    prefix = ['SubjTest_' plane '_HEVC'];
                case 'j2k'
                    prefix = ['SubjTest_' plane '_JPEG2000'];
                otherwise
                    %warning('ObjEvaluateCompressedHolograms:unsupported_codec', [distStr ' not fully supported yet in objective testing pipeline.'])
                    prefix = ['SubjTest_' plane '_' distStr];
            end

            name_prefix = [prefix '_' strrep(num2str(targetReqTot), '.', 'dot') postfixStr];

            info = getSettings('dataset', H.dataset, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'outfolderpath', Folders.nrshOutFolderDist, 'name_prefix', name_prefix, 'resize_fun', '');
            if (isfield(H, 'ap_sizes')), info = getSettings(info, 'ap_sizes', H.ap_sizes); end
            if (isfield(H, 'fps')), info = getSettings(info, 'fps', H.fps); end

            if (doLowResSubjTest)
                info = getSettings(info, 'resize_fun', 'dr');
                info = getSettings(info, 'targetres', H.targetRes);
            end

            if (~doSubjTestRatingOnly)
                nrsh(frame, H.rec_dists, info, usagemodeFun(H.doDynamic, H.doIndividual), [], H.h_pos, H.v_pos, cmin, cmax);
            end

            %% 5) Rate each specified viewpoint
            cfg_name = strsplit(H.cfg_file, filesep);
            cfg_name = strrep(cfg_name{end}, '.txt', '');

            if (H.doLowResolution) % Overwrite ap_sizes based on target_resolution request for diffraction limited resize
                % This line should match NRSH behaviour
                if (~strcmp(info.method, 'Fourier-Fresnel'))
                    H.ap_sizes = calcApSizeSimple(info.pixel_pitch, info.wlen, info.targetres, res(1:2), H.rec_dists(:));

                else % Fourier DH
                    H.ap_sizes = min(info.targetres, min(H.size(1:2)));
                end

                if (~iscell(H.ap_sizes)), H.ap_sizes = {H.ap_sizes}; end
            end

            suffixL = {'', '_LR'};
            suffix = suffixL{H.doLowResolution + 1};

            nz = numel(H.rec_dists);
            nap = numel(H.ap_sizes);
            nhpos = numel(H.h_pos);
            nvpos = numel(H.v_pos);

            if (H.doDynamic || (isfield(H, 'doIndividual') && H.doIndividual))
                nTotal = max([nz, nap, nhpos, nvpos]);
                if (nz < nTotal), H.rec_dists = repmat(H.rec_dists, [nTotal, 1]); end
                if (nap < nTotal), H.ap_sizes = repmat(H.ap_sizes, [nTotal, 1]); end
                if (nhpos < nTotal), H.h_pos = repmat(H.h_pos, [nTotal, 1]); end
                if (nvpos < nTotal), H.v_pos = repmat(H.v_pos, [nTotal, 1]); end
            else
                nTotal = numel(H.rec_dists) * numel(H.ap_sizes) * numel(H.h_pos) * numel(H.v_pos);
            end

            resultsRef = cell(nTotal + 1, 7); % Format: #viewpoints x [z, ap, hpos, vpos, ...
            %             PSNR, SSIM, VIFq]
            resultsQRef = cell(nTotal + 1, 7); % Format: #viewpoints x [z, ap, hpos, vpos, ...
            %             PSNR, SSIM, VIFq]

            if (H.doDynamic || (isfield(H, 'doIndividual') && H.doIndividual))

                for resID = 1:nTotal
                    %% 5.1) Load images
                    fnameCompressed = sprintf('%s%s_%g_%g_%s_%g%s.png', name_prefix, cfg_name, ... % from nrsh.m
                    H.h_pos(resID), H.v_pos(resID), strrep(mat2str(H.ap_sizes{resID}), ' ', 'x'), ...
                        H.rec_dists(resID), suffix);
                    disp(['Load & Rate: ' fnameCompressed])

                    fnameRef = sprintf('%s%s_%g_%g_%s_%g%s.png', ['SubjTest_' plane '_GT_'], cfg_name, ... % from nrsh.m
                        H.h_pos(resID), H.v_pos(resID), strrep(mat2str(H.ap_sizes{resID}), ' ', 'x'), ...
                        H.rec_dists(resID), suffix);

                    fnameQRef = sprintf('%s%s_%g_%g_%s_%g%s.png', ['SubjTest_' plane '_GT16bit_'], cfg_name, ... % from nrsh.m
                        H.h_pos(resID), H.v_pos(resID), strrep(mat2str(H.ap_sizes{resID}), ' ', 'x'), ...
                        H.rec_dists(resID), suffix);

                    recCompressed = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameCompressed));
                    ref = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameRef));

                    if (isAnchor)
                        qref = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameQRef));
                    end

                    %% 5.2) Rate wrt. ground truth
                    RD = rateDistMetrics_Obj_PL(recCompressed, ref, doCoreVerification);

                    if (doCoreVerification)
                        RD.ssim_obj = zeros(size(RD.psnr_obj));
                    end

                    % Format: #viewpoints x [z, ap, hpos, vpos, PSNR, SSIM, VIFq]
                    resultsRef(resID, :) = {H.rec_dists(resID), H.ap_sizes{resID}, H.h_pos(resID), H.v_pos(resID), RD.psnr_obj, RD.ssim_obj, RD.vifp_obj};

                    if (isAnchor)
                        %% 5.3) Rate wrt. quantized ground truth
                        RD = rateDistMetrics_Obj_PL(recCompressed, qref, doCoreVerification);

                        if (doCoreVerification)
                            RD.ssim_obj = zeros(size(RD.psnr_obj));
                        end

                        % Format: #viewpoints x [z, ap, hpos, vpos, PSNR, SSIM, VIFq]
                        resultsQRef(resID, :) = {H.rec_dists(resID), H.ap_sizes{resID}, H.h_pos(resID), H.v_pos(resID), RD.psnr_obj, RD.ssim_obj, RD.vifp_obj};
                    end

                end

            else

                for zID = 1:nz

                    for apID = 1:nap

                        for hID = 1:nhpos

                            for vID = 1:nvpos
                                resID = (zID - 1) * nap * nhpos * nvpos + (apID - 1) * nhpos * nvpos + (hID - 1) * nvpos + vID;
                                %% 5.1) Load images
                                fnameCompressed = sprintf('%s%s_%g_%g_%s_%g%s.png', name_prefix, cfg_name, ... % from nrsh.m
                                H.h_pos(hID), H.v_pos(vID), strrep(mat2str(H.ap_sizes{apID}), ' ', 'x'), ...
                                    H.rec_dists(zID), suffix);

                                fnameRef = sprintf('%s%s_%g_%g_%s_%g%s.png', ['SubjTest_' plane '_GT_'], cfg_name, ... % from nrsh.m
                                    H.h_pos(hID), H.v_pos(vID), strrep(mat2str(H.ap_sizes{apID}), ' ', 'x'), ...
                                    H.rec_dists(zID), suffix);

                                fnameQRef = sprintf('%s%s_%g_%g_%s_%g%s.png', ['SubjTest_' plane '_GT16bit_'], cfg_name, ... % from nrsh.m
                                    H.h_pos(hID), H.v_pos(vID), strrep(mat2str(H.ap_sizes{apID}), ' ', 'x'), ...
                                    H.rec_dists(zID), suffix);

                                recCompressed = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameCompressed));
                                ref = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameRef));

                                %% 5.2) Rate wrt. ground truth
                                RD = rateDistMetrics_Obj_PL(recCompressed, ref, doCoreVerification);

                                if (doCoreVerification)
                                    RD.ssim_obj = zeros(size(RD.psnr_obj));
                                end

                                % Format: #viewpoints x [z, ap, hpos, vpos, PSNR, SSIM, VIFq]
                                resultsRef(resID, :) = {H.rec_dists(zID), H.ap_sizes{apID}, H.h_pos(hID), H.v_pos(vID), RD.psnr_obj, RD.ssim_obj, RD.vifp_obj};

                                if (isAnchor)
                                    %% 5.1) Load images pt. 2
                                    ref = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameQRef)); %Overwrite ref to lower memory impact

                                    %% 5.3) Rate wrt. quantized ground truth
                                    RD = rateDistMetrics_Obj_PL(recCompressed, ref, doCoreVerification);

                                    if (doCoreVerification)
                                        RD.ssim_obj = zeros(size(RD.psnr_obj));
                                    end

                                    % Format: #viewpoints x [z, ap, hpos, vpos, PSNR, SSIM, VIFq]
                                    resultsQRef(resID, :) = {H.rec_dists(zID), H.ap_sizes{apID}, H.h_pos(hID), H.v_pos(vID), RD.psnr_obj, RD.ssim_obj, RD.vifp_obj};
                                end

                            end

                        end

                    end

                end

            end

            clear recCompressed ref;

            %% 5.3) Add average scores over all viewpoints
            resultsRef(end, :) = {NaN, NaN * [1, 1], NaN, NaN, mean(cell2mat(resultsRef(:, 5)), 1) .* ones(1, ncolors), mean(cell2mat(resultsRef(:, 6)), 1) .* ones(1, ncolors), mean(cell2mat(resultsRef(:, 7)), 1) .* ones(1, ncolors)};

            if (isAnchor)
                resultsQRef(end, :) = {NaN, NaN * [1, 1], NaN, NaN, mean(cell2mat(resultsQRef(:, 5)), 1) .* ones(1, ncolors), mean(cell2mat(resultsQRef(:, 6)), 1) .* ones(1, ncolors), mean(cell2mat(resultsQRef(:, 7)), 1) .* ones(1, ncolors)};
            end

            %% 5.4) Save results
            if (isOctave)
                resultsRefTab = [resultsRef(:, 1), resultsRef(:, 2), resultsRef(:, 3), resultsRef(:, 4), resultsRef(:, 5), resultsRef(:, 6), resultsRef(:, 7)];

                if (isAnchor)
                    resultsQRefTab = [resultsQRef(:, 1), resultsQRef(:, 2), resultsQRef(:, 3), resultsQRef(:, 4), resultsQRef(:, 5), resultsQRef(:, 6), resultsQRef(:, 7)];
                end

            else
                resultsRefTab = table(cell2mat(resultsRef(:, 1)), cell2mat(resultsRef(:, 2)), cell2mat(resultsRef(:, 3)), cell2mat(resultsRef(:, 4)), cell2mat(resultsRef(:, 5)), cell2mat(resultsRef(:, 6)), cell2mat(resultsRef(:, 7)));
                resultsRefTab.Properties.VariableNames = {'z', 'ap_size', 'hpos', 'vpos', 'PSNR', 'SSIM', 'VIFq'};

                if (isAnchor)
                    resultsQRefTab = table(cell2mat(resultsQRef(:, 1)), cell2mat(resultsQRef(:, 2)), cell2mat(resultsQRef(:, 3)), cell2mat(resultsQRef(:, 4)), cell2mat(resultsQRef(:, 5)), cell2mat(resultsQRef(:, 6)), cell2mat(resultsQRef(:, 7)));
                    resultsQRefTab.Properties.VariableNames = {'z', 'ap_size', 'hpos', 'vpos', 'PSNR', 'SSIM', 'VIFq'};
                end

            end

            if (~isfield(Msubj.(distStr), 'ref')), Msubj.(distStr).ref(tID) = struct(); end

            Msubj.(distStr).ref(tID).view_results = resultsRefTab;
            Msubj.(distStr).ref(tID).totBitrate = targetReqTot; % Kept, just in case pipeline is rerun, and bitrate table is updated with a few additional bitrates
            Msubj.(distStr).ref(tID).pipelineType = 'subjective';

            if (isAnchor)
                if (~isfield(Msubj.(distStr), 'deg')), Msubj.(distStr).deg(tID) = struct(); end
                Msubj.(distStr).deg(tID).view_results = resultsQRefTab;
                Msubj.(distStr).deg(tID).totBitrate = targetReqTot; % Kept, just in case pipeline is rerun, and bitrate table is updated with a few additional bitrates
                Msubj.(distStr).deg(tID).pipelineType = 'subjective';
            end

        end

    end

end
