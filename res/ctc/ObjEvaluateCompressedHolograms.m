function M = ObjEvaluateCompressedHolograms(Folders, M, H, X, Xqref, si, cmin, cmax, plane, distL, distLanchors, doCoreVerification)
    % function ObjEvaluateCompressedHolograms(Folders, M, H, X, Xqref, si, cmin, cmax, plane, distL, distLanchors, doCoreVerification)
    %   Uses NRSH to reconstruct views
    % INPUT:
    %   Folders@struct...   contains folder structure
    %   M@struct...         structure from Pipeline_Compress, containing bitrate/QPN maps, to identify best suited files
    %   H@struct...         structure from holoread_PL; contains hologram specifics + reconstruction points
    %   X@numeric...        ground truth hologram in hologram plane
    %   Xqref@numeric...    ground truth hologram after 16bit quant./dequantization in hologram plane (only used for anchors)
    %   si@numerics(1,3)... size of original hologram
    %   cmin/cmax@numerics(#viewpoints)... cmin, cmax from ground truth to be used for this specific viewpoint set
    %   plane@char...       {'obj', 'holo'}, plane of compression;
    %                       dis-/enables backpropagation of compressed data prior to reconstruction: + reconstruction prefix
    %   distL@cell...       cell array list of codecs to be tested
    %   distLanchors@cell...cell array list of anchor codecs to be tested (Dequantization+BP will be skipped for proponents)
    %   doCoreVerification@bool(1)... flag for signaling core-experiment mode (no high-res reconstructions and rating thereof)
    %
    % OUTPUT:
    %   Files of reconstructions in pwd()/figures/*H.cfg_name*/{HEVC_, JPEG2000_, distStr}*.png for the specified viewpoints.
    %   M@struct...         contains objective RD scores
    %   M.(plane).(dist).bitrateMap@table...    map requested to achieved bitrates and evtl. QP values etc.
    %                   .ref@struct array...    results of objective metrics per bitrate wrt. float value GT
    %                   .ref(1).{snr_hol, ssim_hol, ussim_hol}@numeric(1,ncolors)... metric values per color channel
    %                   .ref(1).view_results(nviews,1)@table(nviews+1,7)... table of metrics per reconstruction viewpoint, last line avg.
    %                   .ref(1).pipelineType == 'objective'
    %                   .deg@struct array...    like ref, but wrt. quantized GT (only for anchor codecs)
    %
    % NOTE: M (e.g. M.{hm, j2k, ...}) is assumed to be completed within this script, i.e. potentially the same as input M. Its supposed to be assigned to M.(plane) in main_degrade.
    %
    % Created by T. Birnbaum, 26.02.2022, Version 2.7
    % Based on ObjectiveTest Pipeline Version 1.4 by
    %   R. K. Muhamad, T. Birnbaum

    %% ScriptLocal Configparameters:
    doCleanDistorted = false; % Remove reconstructions from distorted holograms, after rating

    %% Early exit
    if (isempty(fieldnames(M)) || isempty(fieldnames(M.(distL{1}))))
        return
    end

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
    targetStr = M.(distL{1}).bitrateMap.Properties.VariableNames{1};
    doSNR = contains(targetStr, 'distortionReq');

    if (doSNR)
        prefixStr = 'dist_';
        postfixStr = 'dB_';
    else
        prefixStr = 'rate_';
        postfixStr = 'bpp_';
    end

    if (isOctave)

        if (isfield(M, 'hm'))
            targetReqTotL = M.hm.bitrateMap{:, 1};
        else
            targetReqTotL = M.(distL{1}).bitrateMap{:, 1};
        end

    else

        if (isfield(M, 'hm'))
            targetReqTotL = M.hm.bitrateMap.(targetStr);
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

            targetReqTotL = M.(dist).bitrateMap.(targetStr);
            clear dist;
        end

    end

    ncolors = numel(H.lambda);

    for distC = distL
        distStr = distC{1};
        isAnchor = ~isempty(intersect(distLanchors, {distStr}));
        if (~isAnchor && strcmpi(plane, 'obj')), continue, end % Don't evaluate proponents in object plane

        if (isAnchor)
            frame = complex(zeros(si, 'uint16'));
        else
            frame = complex(zeros(si, 'single'));
        end

        %% 2) Rating + Reconstruction loop
        for tID = 1:numel(targetReqTotL)
            targetReqTot = targetReqTotL(tID);
            if (targetReqTot == 0), continue, end

            %% 2.1) Load data
            switch (distStr)
                case 'hm'

                    for c = ncolors:-1:1

                        if (isOctave)
                            ttID = M.(distStr).bitrateMap(:, 1) == targetReqTot;
                            qpn = M.(distStr).bitrateMap{ttID, 2 + 2 * (c - 1) + 1};
                        else
                            ttID = find(M.(distStr).bitrateMap(:, 1).Variables == targetReqTot);
                            qpn = M.(distStr).bitrateMap(ttID, 2 + 2 * (c - 1) + 1).Variables;
                        end

                        fnameMat = fullfile(Folders.forkfolder, 'hm', ['qpn' num2str(qpn, '%03d') '_c' num2str(c) '.mat']);
                        dat = load(fnameMat, 'Qcodechat');
                        frame(:, :, c) = dat.Qcodechat(1:si(1), 1:si(2), :);
                    end

                case 'j2k'

                    for c = ncolors:-1:1
                        fnameMat = fullfile(Folders.forkfolder, 'j2k', [prefixStr strrep(num2str(targetReqTot), '.', 'dot') '_c' num2str(c) '.mat']);
                        dat = load(fnameMat, 'Qcodechat');
                        frame(:, :, c) = dat.Qcodechat(1:si(1), 1:si(2), :);
                    end

                case 'jxl'

                    for c = ncolors:-1:1
                        fnameMat = fullfile(Folders.forkfolder, 'jxl', [prefixStr strrep(num2str(targetReqTot), '.', 'dot') '_c' num2str(c) '.mat']);
                        dat = load(fnameMat, 'Qcodechat');
                        frame(:, :, c) = dat.Qcodechat(1:si(1), 1:si(2), :);
                    end

                case 'proponentTemplate'
                    fnameMat = fullfile(Folders.forkfolder, distStr, [prefixStr strrep(num2str(targetReqTot), '.', 'dot') '.mat']);
                    dat = load(fnameMat, 'Qcodechat');
                    frame = dat.Qcodechat(1:si(1), 1:si(2), :);
                case 'interfere'

                    for c = ncolors:-1:1
                        fnameMat = fullfile(Folders.forkfolder, distStr, [prefixStr strrep(num2str(targetReqTot), '.', 'dot') '_holo_001_c' num2str(c) '.mat']);
                        dat = load(fnameMat, 'Qcodechat');
                        frame(:, :, c) = dat.Qcodechat(1:si(1), 1:si(2), :);
                    end

                otherwise
                    error('ObjEvaluateCompressedHolograms:unsupported_codec', ['Please add support for ' distStr ' to objective testing pipeline.'])
            end

            clear dat;

            if (isAnchor)
                %% 2.2) Dequantize
                frame = Dequantize_PL(frame, Xpoi, L, quantmethod);

                if (strcmpi(plane, 'obj'))
                    %% 2.3) Back-propagate from object to hologram plane
                    zeropad = false; % Faciliate: nopad approach for anchors, see wg1m89073
                    info = getSettings('dataset', H.dataset, 'zero_pad', zeropad, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'usagemode', 'complex', 'direction', 'inverse');
                    frame = nrsh(frame, H.obj_dist, info);
                end

            end

            %% 3) Rate hologram plane
            %% 3.1) Compressed versus float GT
            % Obtain base scores + assign to output
            RD = rateDistMetrics_Hol_PL(frame, X, doCoreVerification);
            for fin = fieldnames(RD).', M.(distStr).ref(tID).(fin{1}) = RD.(fin{1}); end

            if (isAnchor)
                %% 3.2) Compressed versus 16bit GT
                RD = rateDistMetrics_Hol_PL(frame, Xqref, doCoreVerification);
                for fin = fieldnames(RD).', M.(distStr).deg(tID).(fin{1}) = RD.(fin{1}); end
            end

            %% Early exit - skip high res reconstructions and rating for doCoreVerification = true
            if (doCoreVerification), continue, end
            %% 3.3) Reconstruct each specified viewpoint using cmin, cmax of GT
            switch (distStr)
                case 'hm'
                    prefix = ['ObjTest_' plane '_HEVC'];
                case 'j2k'
                    prefix = ['ObjTest_' plane '_JPEG2000'];
                case 'jxl'
                    prefix = ['ObjTest_' plane '_JPEGXL'];
                case 'interfere'
                    prefix = ['ObjTest_' plane '_INTERFERE'];
                otherwise
                    warning('ObjEvaluateCompressedHolograms:unsupported_codec', [distStr ' not fully supported yet in objective testing pipeline.'])
                    prefix = ['ObjTest_' plane '_' distStr];
            end

            name_prefix = [prefix '_' strrep(num2str(targetReqTot), '.', 'dot') postfixStr];
            info = getSettings('dataset', H.dataset, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'outfolderpath', Folders.nrshOutFolderDist, 'name_prefix', name_prefix);
            nrsh(frame, H.rec_dists, info, usagemodeFun(H.doDynamic), H.ap_sizes, H.h_pos, H.v_pos, cmin, cmax);
            clear frame ans;

            %% 3.4) Rate each specified viewpoint
            cfg_name = strsplit(H.cfg_file, filesep);
            cfg_name = strrep(cfg_name{end}, '.txt', '');

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
                    %% 3.4.1) Load images
                    fnameCompressed = sprintf('%s%s_%g_%g_%s_%g.png', name_prefix, cfg_name, ... % from nrsh.m
                    H.h_pos(resID), H.v_pos(resID), strrep(mat2str(H.ap_sizes{resID}), ' ', 'x'), ...
                        H.rec_dists(resID));
                    disp(['Load & Rate: ' fnameCompressed])

                    fnameRef = sprintf('%s%s_%g_%g_%s_%g.png', ['ObjTest_' plane '_GT_'], cfg_name, ... % from nrsh.m
                        H.h_pos(resID), H.v_pos(resID), strrep(mat2str(H.ap_sizes{resID}), ' ', 'x'), ...
                        H.rec_dists(resID));

                    fnameQRef = sprintf('%s%s_%g_%g_%s_%g.png', ['ObjTest_' plane '_GT16bit_'], cfg_name, ... % from nrsh.m
                        H.h_pos(resID), H.v_pos(resID), strrep(mat2str(H.ap_sizes{resID}), ' ', 'x'), ...
                        H.rec_dists(resID));

                    recCompressed = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameCompressed));
                    ref = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameRef));

                    %% 3.4.2) Rate wrt. ground truth
                    RD = rateDistMetrics_Obj_PL(recCompressed, ref, doCoreVerification);
                    % Format: #viewpoints x [z, ap, hpos, vpos, PSNR, SSIM, VIFq]
                    resultsRef(resID, :) = {H.rec_dists(resID), H.ap_sizes{resID}, H.h_pos(resID), H.v_pos(resID), RD.psnr_obj, RD.ssim_obj, RD.vifp_obj};

                    if (isAnchor)
                        %% 3.4.1) Load images pt. 2
                        ref = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameQRef));

                        %% 3.4.3) Rate wrt. quantized ground truth
                        RD = rateDistMetrics_Obj_PL(recCompressed, ref, doCoreVerification);
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
                                %% 3.4.1) Load images
                                fnameCompressed = sprintf('%s%s_%g_%g_%s_%g.png', name_prefix, cfg_name, ... % from nrsh.m
                                H.h_pos(hID), H.v_pos(vID), strrep(mat2str(H.ap_sizes{apID}), ' ', 'x'), ...
                                    H.rec_dists(zID));

                                fnameRef = sprintf('%s%s_%g_%g_%s_%g.png', ['ObjTest_' plane '_GT_'], cfg_name, ... % from nrsh.m
                                    H.h_pos(hID), H.v_pos(vID), strrep(mat2str(H.ap_sizes{apID}), ' ', 'x'), ...
                                    H.rec_dists(zID));

                                fnameQRef = sprintf('%s%s_%g_%g_%s_%g.png', ['ObjTest_' plane '_GT16bit_'], cfg_name, ... % from nrsh.m
                                    H.h_pos(hID), H.v_pos(vID), strrep(mat2str(H.ap_sizes{apID}), ' ', 'x'), ...
                                    H.rec_dists(zID));

                                recCompressed = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameCompressed));
                                ref = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameRef));

                                %% 3.4.2) Rate wrt. ground truth
                                RD = rateDistMetrics_Obj_PL(recCompressed, ref, doCoreVerification);
                                % Format: #viewpoints x [z, ap, hpos, vpos, PSNR, SSIM, VIFq]
                                resultsRef(resID, :) = {H.rec_dists(zID), H.ap_sizes{apID}, H.h_pos(hID), H.v_pos(vID), RD.psnr_obj, RD.ssim_obj, RD.vifp_obj};

                                if (isAnchor)
                                    %% 3.4.1) Load images pt. 2
                                    ref = imread(fullfile(Folders.nrshOutFolderDist, cfg_name, fnameQRef)); %Overwrite ref to lower memory impact

                                    %% 3.4.3) Rate wrt. quantized ground truth
                                    RD = rateDistMetrics_Obj_PL(recCompressed, ref, doCoreVerification);
                                    % Format: #viewpoints x [z, ap, hpos, vpos, PSNR, SSIM, VIFq]
                                    resultsQRef(resID, :) = {H.rec_dists(zID), H.ap_sizes{apID}, H.h_pos(hID), H.v_pos(vID), RD.psnr_obj, RD.ssim_obj, RD.vifp_obj};
                                end

                            end

                        end

                    end

                end

            end

            clear recCompressed ref;

            %% 3.4.4) Remove distorted reconstructions
            if (doCleanDistorted)
                rmdir(fullfile(Folders.nrshOutFolderDist, cfg_name), 's');
            end

            %% 3.4.5) Add average scores over all viewpoints
            resultsRef(end, :) = {NaN, NaN * [1, 1], NaN, NaN, mean(cell2mat(resultsRef(:, 5)), 1) .* ones(1, ncolors), mean(cell2mat(resultsRef(:, 6)), 1) .* ones(1, ncolors), mean(cell2mat(resultsRef(:, 7)), 1) .* ones(1, ncolors)};

            if (isAnchor)
                resultsQRef(end, :) = {NaN, NaN * [1, 1], NaN, NaN, mean(cell2mat(resultsQRef(:, 5)), 1) .* ones(1, ncolors), mean(cell2mat(resultsQRef(:, 6)), 1) .* ones(1, ncolors), mean(cell2mat(resultsQRef(:, 7)), 1) .* ones(1, ncolors)};
            end

            %% 3.5) Save results
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

            if (~isfield(M.(distStr), 'ref')), M.(distStr).ref(tID) = struct(); end

            M.(distStr).ref(tID).view_results = resultsRefTab;
            M.(distStr).ref(tID).totBitrate = targetReqTot; % Kept, just in case pipeline is rerun, and bitrate table is updated with a few additional bitrates
            M.(distStr).ref(tID).pipelineType = 'objective';

            if (isAnchor)
                if (~isfield(M.(distStr), 'deg')), M.(distStr).deg(tID) = struct(); end
                M.(distStr).deg(tID).view_results = resultsQRefTab;
                M.(distStr).deg(tID).totBitrate = targetReqTot; % Kept, just in case pipeline is rerun, and bitrate table is updated with a few additional bitrates
                M.(distStr).deg(tID).pipelineType = 'objective';
            end

        end

    end

end
