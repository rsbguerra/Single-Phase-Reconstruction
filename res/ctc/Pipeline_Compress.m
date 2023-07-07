function M = Pipeline_Compress(Folders, RA, distL, M, SNRceL, doCoreVerification)
    % function M = Pipeline_Compress(Folders, RA, distL, M, SNRceL, doCoreVerification)
    %
    %   Compression pipeline_fast (in any plane, depending on quantref + forkfolder)
    %   Will write hologram after the encode-decode operation as mat files
    %   into the work folder mentioned in plenofolder.
    %   Performs a binary QP search on H.265 (Fraunhofer implementation) to find best
    %   matches the provided overall bitrates RA/num_colors per channel.
    %   Different QP values may be used for all color channels.
    %   J2K will be used on exactly the same bitrates as H.265.
    %   Added JPEG-XL support.
    %
    % INPUT:
    %   Folders@struct...   Folder structure for test experiment
    %       .codecfolder@char... Folder containing codec executable.
    %       .plenofolder@char... Folder for input.mat + results.
    %       .forkfolder@char... Folder for quantref.mat and temporary data.
    %   RA@double...        array of overall target bitrates
    %   distL@cell...       cell array list of codecs to be tested
    %   M@struct...         optional: see below in output; may be supplied as input,
    %                       if e.g. 'hm' compression should be skipped
    %   SNRceL@numeric(N,1).list of target distortions for distortion controlled proposal
    %   doCoreVerification@bool(1)... flag for signaling core-experiment mode (no removal of interim bitstreams)
    %
    % OUTPUT:
    %   M@struct...         bitrateMaps
    %    .(distStr).bitrateMap@table...    contains requested total bitrates, achieved total bitrated + per channel, closest QP values per channel
    %                               will be used in reconstruction script
    %    .(distStr).qpnMap@table...        contains QP value and achieved bitrates per channel + achieved bitrate in case of constant QP value
    %    .j2k.bitrateMap@table...   contains requested total bitrates, achieved total bitrates + per channel
    %                               has filler columns n, [nn, nnn] to provide compatibility with hevc
    %                               will be used in reconstruction script
    %
    %
    % Created by T. Birnbaum, 01.06.2021, Version 2.4
    % Based on Pipeline_HoloPlane Version 1.4 by
    %                   K.M. Raees, 21.04.2020
    %               and T. Birnbaum

    if (nargin < 5), SNRceL = []; end

    debug = true;
    doSNR = ~isempty(SNRceL);

    if (doSNR)
        prefixStr = 'dist_';
    else
        prefixStr = 'rate_';
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

    if (isOctave)
        save73 = {'-hdf5'};
    else
        save73 = {'-v7.3', '-nocompression'};
    end

    if (nargin < 4), M = struct(); end

    if (nargin < 3)
        distL = {'hm', 'j2k', 'jxl'};
    else
        % if( (~isOctave && any(contains(distL, 'hm'))) || (isOctave && any(~cellfun('isempty', strfind(distL, 'hm')))))
        %     distL = unique(['hm', distL], 'stable'); % Make sure HM is done first
        % end
    end

    tempfolder = fullfile(Folders.forkfolder, 'Temp');
    makefolder(tempfolder);

    for distC = distL
        distStr = distC{1};

        %% Make subfolders for results
        makefolder(fullfile(Folders.forkfolder, distStr));

        switch (distStr)
            case 'hm'
                % Load 16bit quantized Ground truth
                load(fullfile(Folders.forkfolder, 'quantref.mat'), 'Qcodec');
                si = size(Qcodec); si(3) = size(Qcodec, 3);
                ncolors = si(3);

                hevcCompression()
            case 'j2k'
                % Load 16bit quantized Ground truth
                load(fullfile(Folders.forkfolder, 'quantref.mat'), 'Qcodec');
                si = size(Qcodec); si(3) = size(Qcodec, 3);
                ncolors = si(3);

                j2kCompression()
            case 'jxl'
                % Load 16bit quantized Ground truth
                load(fullfile(Folders.forkfolder, 'quantref.mat'), 'Qcodec');
                si = size(Qcodec); si(3) = size(Qcodec, 3);
                ncolors = si(3);

                jxlCompression()
            case 'proponentTemplate'
                % Load non-quantized Ground truth
                load(fullfile(Folders.plenofolder, 'input.mat'), 'X');
                Qcodec = X; clear X;
                si = size(Qcodec); si(3) = size(Qcodec, 3);
                ncolors = si(3);

                proponentTemplateCompression()
            case 'interfere'
                % Load non-quantized Ground truth
                load(fullfile(Folders.plenofolder, 'input.mat'), 'X');
                Qcodec = X; clear X;
                si = size(Qcodec); si(3) = size(Qcodec, 3);
                ncolors = si(3);

                interfere_Compression()
            otherwise
                error('Pipeline_Compress:unsupported_codec', ['Please add support for ' distStr ' to objective testing pipeline.'])
        end

    end

    %% Auxilliary functions -- shared context
    function hevcCompression()
        RAloc = sort(RA(:).');
        bitrateEps = 0.05; % Bitrate matching accuracy 5 % of bitrate per color
        strRGB = 'RGB';

        %% HM compression (16 bit)
        % Version 1.6
        % 21.09.2020,
        % Tobias Birnbaum
        % Modified: Raees K.M.
        %
        % - Do all colors with same QPN value
        % - Do Binary search for QP values closest to specified bitrates
        %%

        auxInfo.tmpBitstreamFilename = fullfile(Folders.forkfolder, 'Temp', 'HEVC.bst');
        auxInfo.outfile = fullfile(Folders.forkfolder, 'Temp', 'HEVC_out.yuv');
        auxInfo.specificConfigFilename = fullfile(Folders.forkfolder, 'Temp', 'HEVC_specConf.cfg');
        auxInfo.generalConfigFilename = fullfile(Folders.forkfolder, 'Temp', 'HEVC_genConf.cfg');

        writeGeneralConfig(auxInfo.generalConfigFilename)

        %% File Padding
        if (mod(si(1), 8) == 0)
            pad(1) = 0;
        else
            pad(1) = 8 - mod(si(1), 8);
        end

        if (mod(si(2), 8) == 0)
            pad(2) = 0;
        else
            pad(2) = 8 - mod(si(2), 8);
        end

        Qcodec = padarray(Qcodec, [pad(1), pad(2)], 'post');

        if (isOctave)
            Qcodec = complex(uint16(real(Qcodec)), uint16(imag(Qcodec)));
        else
            Qcodec = uint16(Qcodec);
        end

        auxInfo.siPad = si + [pad, 0];

        %% Compute compression tiles b/c
        % HM16 Supports around 4GB per variable in total
        hmconstant = (44 * 1024) ^ 2;

        if (prod(auxInfo.siPad) > hmconstant)
            tiley = sqrt(hmconstant * auxInfo.siPad(1) / auxInfo.siPad(2));
            tiley = floor(tiley);
            tiley = tiley - mod(tiley, 8);
            tiley(tiley == 0) = 8;
            tilex = hmconstant / tiley;
            tilex = floor(tilex);
            tilex = tilex - mod(tilex, 8);
            tilex(tilex == 0) = 8;
        else
            tiley = auxInfo.siPad(1);
            tilex = auxInfo.siPad(2);
        end

        auxInfo.siTile = [tiley, tilex];

        % HM Binary search QP values
        if (~isfield(M, distStr) || ~isfield(M.(distStr), 'qpnMap') || ~isfield(M, distStr) || ~isfield(M.(distStr), 'bitrateMap'))
            qpnMap = zeros(52, 2 + ncolors); % Format: qpn, bppAchievedTot, bpc(1)[, bpc(2), bpc(3)]
            qpnMap(:, 1) = [0:51];

            bitrateMap = zeros(numel(RAloc), 2 + 2 * ncolors); %Format: bitrateReqTot bitrateAchievedTot QP_R bitrateAchieved_R [QP_G bitrateAchieved_G, QP_B bitrateAchieved_B]
        else

            if (isOctave)
                bitrateMap = cell2mat(M.(distStr).bitrateMap);
            else
                bitrateMap = M.(distStr).bitrateMap.Variables;
            end

            %% Eliminate already determined rates from RAloc
            RAloc = setdiff(RAloc, bitrateMap(:, 1));

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap};
            else
                M.(distStr).bitrateMap.Variables = bitrateMap;
            end

            % If old bitrates should not be recomputed please uncomment the following
            %             RAnotdet = setdiff(RAloc, bitrateMap(:, 1));
            %             % make sure bitrate map only include those values for the current
            %             % RA, not all the available values from the past and the
            %             % present.
            %             bitrateMap = bitrateMap(ismember(bitrateMap(:,1),RAloc),:);
            %             M.(distStr).bitrateMap(~ismember(M.(distStr).bitrateMap(:,1).Variables,bitrateMap(:,1)),:) = [];
            %             RAloc = RAnotdet;
            %% Make room for new results
            if (isOctave)
                qpnMap = cell2mat(M.(distStr).qpnMap);
            else
                qpnMap = M.(distStr).qpnMap.Variables;
            end

            bitrateMap = [zeros(numel(RAloc), 2 + 2 * ncolors); bitrateMap];
        end

        disp('BS init 1')
        qpnLstart = 51;

        if (all(qpnMap(qpnLstart + 1, 2:end) == 0))
            [qpnMap(qpnLstart + 1, 2), qpnMap(qpnLstart + 1, 3:end)] = qpnCompress(qpnLstart, [1:ncolors], auxInfo);
        end

        disp('BS init 2')
        qpnHstart = 0;

        if (all(qpnMap(qpnHstart + 1, 2:end) == 0))
            [qpnMap(qpnHstart + 1, 2), qpnMap(qpnHstart + 1, 3:end)] = qpnCompress(qpnHstart, [1:ncolors], auxInfo);
        end

        for bId = 1:numel(RAloc)
            bitrateReqTot = RAloc(bId);
            bitrateMap(bId, 1) = bitrateReqTot;
            bitrateReqPcolor = bitrateReqTot / ncolors;

            for c = ncolors:-1:1
                qpnL = qpnLstart;
                qpnH = qpnHstart;

                %% Early exit check
                if (bitrateReqPcolor < qpnMap(qpnL + 1, 2 + c))
                    bitrateMap(bId, 2 + 2 * (c - 1) + 1:2 + 2 * c) = qpnMap(qpnL + 1, [1, 2 + c]);
                    continue;
                end

                if (bitrateReqPcolor > qpnMap(qpnH + 1, 2 + c))
                    bitrateMap(bId, 2 + 2 * (c - 1) + 1:2 + 2 * c) = qpnMap(qpnH + 1, [1, 2 + c]);
                    continue;
                end

                iter = 3;

                while (qpnH < qpnL)
                    qpn = floor((qpnL + qpnH) / 2);
                    disp(['BitrateTot: ' num2str(bitrateReqTot) ' Color: ' strRGB(c) '  QP search iter: ' num2str(iter) ' current QP candidate: ' num2str(qpn)])

                    % disp(['Debug: RA=' num2str(bitrateReq) ' QP=' num2str(qpn) ' qpnL=' num2str(qpnL) ' qpnH=' num2str(qpnH)])

                    if (qpnMap(qpn + 1, 2 + c) == 0)
                        [~, qpnMap(qpn + 1, 2 + c)] = qpnCompress(qpn, c, auxInfo);
                    end

                    if (abs(qpnMap(qpn + 1, 2 + c) - bitrateReqPcolor) <= bitrateEps * bitrateReqPcolor)
                        break;
                    end

                    if (qpnMap(qpn + 1, 2 + c) < bitrateReqPcolor)
                        qpnL = qpn - 1;
                    elseif (qpnMap(qpn + 1, 2 + c) > bitrateReqPcolor)
                        qpnH = qpn + 1;
                    end

                    %% Ensure new anchor points are already computed
                    qpn = qpnL;

                    if (qpnMap(qpn + 1, 2 + c) == 0)
                        [~, qpnMap(qpn + 1, 2 + c)] = qpnCompress(qpn, c, auxInfo);
                    end

                    qpn = qpnH;

                    if (qpnMap(qpn + 1, 2 + c) == 0)
                        [~, qpnMap(qpn + 1, 2 + c)] = qpnCompress(qpn, c, auxInfo);
                    end

                    %% Finish iteration
                    iter = iter + 1;
                end

                %% Least squares optimization - bitrate per channel
                qpnTmp = qpnMap(:, [1, 2 + c]);
                qpnTmp(qpnTmp(:, 2) == 0, :) = [];
                qpnTmp(:, 2) = (qpnTmp(:, 2) - bitrateReqPcolor) .^ 2;
                [~, idx] = min(qpnTmp(:, 2));
                qpn = qpnTmp(idx);

                % Record final bitrate
                bitrateMap(bId, 2 + 2 * (c - 1) + 1:2 + 2 * c) = [qpn, qpnMap(qpn + 1, 2 + c)];
            end

            bitrateMap(bId, 2) = sum(bitrateMap(bId, 4:2:end));
        end

        qpnMap(:, 2) = sum(qpnMap(:, 3:end), 2);

        %% Keep results
        if (ncolors > 1)

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8)};
                M.(distStr).qpnMap = {qpnMap(:, 1), qpnMap(:, 2), qpnMap(:, 3), qpnMap(:, 4), qpnMap(:, 5)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8));
                M.(distStr).bitrateMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTot', 'QP_c1', 'bpp_c1', 'QP_c2', 'bpp_c2', 'QP_c3', 'bpp_c3'};
                M.(distStr).qpnMap = table(qpnMap(:, 1), qpnMap(:, 2), qpnMap(:, 3), qpnMap(:, 4), qpnMap(:, 5));
                M.(distStr).qpnMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTotWconstQP', 'bpp_c1', 'bpp_c2', 'bpp_c3'};
            end

        else

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4)};
                M.(distStr).qpnMap = {qpnMap(:, 1), qpnMap(:, 2), qpnMap(:, 3)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4));
                M.(distStr).bitrateMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTot', 'QP_c1', 'bpp_c1'};
                M.(distStr).qpnMap = table(qpnMap(:, 1), qpnMap(:, 2), qpnMap(:, 3));
                M.(distStr).qpnMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTotWconstQP', 'bpp_c1'};
            end

        end

        save(fullfile(Folders.forkfolder, distStr, [distStr '_bitrateMap_interim.mat']), '-v6', 'M'); % Better safe than sorry

        %% Clean up
        warning('off', 'MATLAB:DELETE:FileNotFound')
        delete(fullfile(Folders.forkfolder, 'Temp', 'real_*.yuv'));
        delete(fullfile(Folders.forkfolder, 'Temp', 'imag_*.yuv'));
        delete(fullfile(Folders.forkfolder, 'Temp', 'HEVC*'));
        warning('on', 'MATLAB:DELETE:FileNotFound')
        %         qpnDelete = setdiff(qpnMap(qpnMap(:, 1) > 0,1) - 1, bitrateMap(:, 2));
        %         for qpn = qpnDelete(:).'
        %             delete(fullfile(Folders.forkfolder,'Temp', ['qpn' num2str(qpn) '.mat']));
        %         end
        clear bitrateMap qpnMap;

        %% Undo padding eventually to retrieve unchanged Qcodec
        Qcodec = Qcodec(1:si(1), 1:si(2), :);
    end

    function j2kCompression()
        RAloc = sort(RA(:));

        % Remove already processed bitrates
        if (~isfield(M, distStr) || ~isfield(M.(distStr), 'bitrateMap'))
            bitrateMap = zeros(numel(RAloc), 2 + 2 * ncolors); % Format: [bppTotReq., bppTotAchieved, ~, bpp_c1, ~, bpp_c2, ~, bpp_c3]
        else
            bitrateMap = M.(distStr).bitrateMap.Variables;

            %% Eliminate already determined rates from RAloc
            RAloc = setdiff(RAloc, bitrateMap(:, 1));
            M.(distStr).bitrateMap.Variables = bitrateMap;
            % If old bitrates should not be recomputed please uncomment the following
            %              RAnotdet = setdiff(RAloc, bitrateMap(:, 1));
            %             % make sure bitrate map only include those values for the current
            %             % RA, not all the available values from the past and the
            %             % present.
            %             bitrateMap = bitrateMap(ismember(bitrateMap(:,1),RAloc),:);
            %             M.(distStr).bitrateMap(~ismember(M.(distStr).bitrateMap(:,1).Variables,bitrateMap(:,1)),:) = [];
            %               RAloc = RAnotdet;

            %% Make room for new results
            bitrateMap = [zeros(numel(RAloc), 2 + 2 * ncolors); bitrateMap];
        end

        %% Start JPEG 2000, 16bit compression with Kakadu with retrieved HEVC bitrates per color-channel
        binEncode = fullfile(Folders.codecfolder, 'kdu_compress.exe');
        binDecode = fullfile(Folders.codecfolder, 'kdu_expand.exe');

        bstReal = fullfile(tempfolder, 'real.j2c');
        bstImag = fullfile(tempfolder, 'imag.j2c');

        decReal = fullfile(tempfolder, 'real_dec.pgm');
        decImag = fullfile(tempfolder, 'imag_dec.pgm');

        for bId = 1:numel(RAloc)
            bitrateReqTot = RAloc(bId);
            bitrateMap(bId, 1) = bitrateReqTot;

            for c = ncolors:-1:1
                % Obtain correct bitrates from HEVC
                if (isfield(M, 'hm'))
                    bitrateReqPcolor = M.hm.bitrateMap(bId, 2 + 2 * c).Variables;
                else
                    bitrateReqPcolor = bitrateReqTot / ncolors;
                end

                infileReal = fullfile(tempfolder, ['real_c' num2str(c) '.pgm']);
                infileImag = fullfile(tempfolder, ['imag_c' num2str(c) '.pgm']);

                if (~exist(infileReal, 'file')), imwrite(uint16(real(Qcodec(:, :, c))), infileReal); end
                if (~exist(infileImag, 'file')), imwrite(uint16(imag(Qcodec(:, :, c))), infileImag); end

                %% J2K - Compress Real part
                [status, out] = system([binEncode ' -i ' infileReal ' -o ' bstReal ' -precise -no_weights Qstep=' num2str(2 ^ -16, '%0.16f') ' -rate ' num2str(bitrateReqPcolor / 2)]);
                if (status), error(out); end

                %% J2K - Compress Imag part
                [status, out] = system([binEncode ' -i ' infileImag ' -o ' bstImag ' -precise -no_weights Qstep=' num2str(2 ^ -16, '%0.16f') ' -rate ' num2str(bitrateReqPcolor / 2)]);
                if (status), error(out); end

                [status, out] = system([binDecode ' -i ' bstReal ' -o ' decReal]);
                if (status), error(out); end

                [status, out] = system([binDecode ' -i ' bstImag ' -o ' decImag]);
                if (status), error(out); end

                %% Read bitrates
                filereal = dir(bstReal);
                fileimag = dir(bstImag);
                fsizebits = (filereal.bytes + fileimag.bytes) * 8;
                bpc = fsizebits / (numel(Qcodec(:, :, c, 1)));
                Qcodechat = complex(uint16(imread(decReal)), uint16(imread(decImag)));
                bitrateMap(bId, 2 + 2 * c) = bpc;

                %% Save compressed hologram
                bpp = bpc;
                fnameMat = fullfile(Folders.forkfolder, distStr, ['rate_' strrep(num2str(bitrateReqTot), '.', 'dot') '_c' num2str(c) '.mat']);
                save(fnameMat, save73{:}, 'Qcodechat', 'fsizebits', 'bpp');

                %% Delete output files
                warning('off', 'MATLAB:DELETE:FileNotFound')
                delete(bstReal);
                delete(bstImag);
                delete(decReal);
                delete(decImag);
                warning('on', 'MATLAB:DELETE:FileNotFound')
            end

            bitrateMap(bId, 2) = sum(bitrateMap(bId, 4:2:end));
        end

        %% Keep results
        if (ncolors > 1)

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8));
                M.(distStr).bitrateMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTot', 'n', 'bpp_c1', 'nn', 'bpp_c2', 'nnn', 'bpp_c3'};
            end

        else

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4));
                M.(distStr).bitrateMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTot', 'n', 'bpp_c1'};
            end

        end

        save(fullfile(Folders.forkfolder, distStr, [distStr '_bitrateMap_interim.mat']), '-v6', 'M'); % Better safe than sorry

        %% Delete input files
        for c = ncolors:-1:1
            infileReal = fullfile(tempfolder, ['real_c' num2str(c) '.pgm']);
            infileImag = fullfile(tempfolder, ['imag_c' num2str(c) '.pgm']);

            warning('off', 'MATLAB:DELETE:FileNotFound')
            delete(infileReal);
            delete(infileImag);
            warning('on', 'MATLAB:DELETE:FileNotFound')
        end

    end

    function proponentTemplateCompression()
        %% Gathering INPUTS - don't touch - start
        RAloc = sort(RA(:));

        % Remove already processed bitrates
        if (~isfield(M, distStr) || ~isfield(M.(distStr), 'bitrateMap'))
            bitrateMap = zeros(numel(RAloc), 2 + 2 * ncolors); % Format: [bppTotReq., bppTotAchieved, ~, bpp_c1, ~, bpp_c2, ~, bpp_c3]
        else

            if (isOctave)
                bitrateMap = cell2mat(M.(distStr).bitrateMap);
            else
                bitrateMap = M.(distStr).bitrateMap.Variables;
            end

            %% Eliminate already determined rates from RAloc
            RAloc = setdiff(RAloc, bitrateMap(:, 1));
            if (isempty(RAloc) && isOctave), return, end

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap};
            else
                M.(distStr).bitrateMap.Variables = bitrateMap;
            end

            % If old bitrates should not be recomputed please uncomment the following
            %              RAnotdet = setdiff(RAloc, bitrateMap(:, 1));
            %             % make sure bitrate map only include those values for the current
            %             % RA, not all the available values from the past and the
            %             % present.
            %             bitrateMap = bitrateMap(ismember(bitrateMap(:,1),RAloc),:);
            %             M.(distStr).bitrateMap(~ismember(M.(distStr).bitrateMap(:,1).Variables,bitrateMap(:,1)),:) = [];
            %               RAloc = RAnotdet;

            %% Make room for new results
            bitrateMap = [zeros(numel(RAloc), 2 + 2 * ncolors); bitrateMap];
        end

        %% Gathering INPUTS - don't touch - end

        %% Available variables for compression:
        % RAloc@numeric(1, n)...        List of total bitrates bit per complex valued pixel (for all color channels)

        %% Required output structure:
        % Need to write decoded bitstreams as mat files for further processing
        % bitrateMap@numeric(n, 2+2*ncolors) Format: [bppTotReq., bppTotAchieved, Aux_c1, bpp_c1, Aux_c2, bpp_c2, Aux_c3, bpp_c3]
        %   Necessary: bppTotReq, bppTotAchieved
        %
        %   Optional:
        %       bpp_c.. may be provided if color channels are encoded separately
        %       Aux_c.. is an optional auxiliary scalar number that may be saved together with the bpp. E.g. for HEVC/VTM it is the QP value.

        %% Example 1
        Qcodechat = [];

        for bId = 1:numel(RAloc)
            bitrateReqTot = RAloc(bId);
            bitrateMap(bId, 1) = bitrateReqTot;

            % Some encoder dummy
            Qcodechat = Qcodec + complex(randn(si), randn(si)) * max(abs(Qcodec(:))) * 1 / bitrateReqTot / 10;

            % Some bitrate parse dummy, see below for better examples
            bpp = bitrateReqTot / 2 + rand(1) * bitrateReqTot;
            fsizebits = bpp * prod(si);

            % Save compressed hologram
            fnameMat = fullfile(Folders.forkfolder, distStr, [prefixStr strrep(num2str(bitrateReqTot), '.', 'dot') '.mat']);
            save(fnameMat, save73{:}, 'Qcodechat', 'fsizebits', 'bpp')

            lcolor = [4, 6, 8];
            bitrateMap(bId, lcolor(1:ncolors)) = bpp / 3;
            bitrateMap(bId, 2) = sum(bitrateMap(bId, lcolor(1:ncolors))); % Bpp assignment to bppTotAchieved and bpp_cX is mandatory for future processing
        end

        clear Qcodechat;

        %% Clean up all temporary files here, *NOT* the decoded degraded DHs stored as fnameMat!
        warning('off', 'MATLAB:DELETE:FileNotFound')
        %delete(...)
        warning('on', 'MATLAB:DELETE:FileNotFound')

        %% Keep results
        if (ncolors > 1)

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8));
                M.(distStr).bitrateMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTot', 'n', 'bpp_c1', 'nn', 'bpp_c2', 'nnn', 'bpp_c3'};
            end

        else

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4));
                M.(distStr).bitrateMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTot', 'n', 'bpp_c1'};
            end

        end

        save(fullfile(Folders.forkfolder, distStr, [distStr '_bitrateMap_interim.mat']), '-v6', 'M'); % Better safe than sorry

        %% Delete input files
        for c = ncolors:-1:1
            infileReal = fullfile(tempfolder, ['real_c' num2str(c) '.pgm']);
            infileImag = fullfile(tempfolder, ['imag_c' num2str(c) '.pgm']);

            warning('off', 'MATLAB:DELETE:FileNotFound')
            delete(infileReal);
            delete(infileImag);
            warning('on', 'MATLAB:DELETE:FileNotFound')
        end

    end

    function interfere_Compression()
        %% 0) Initialize executables
        %binEncode = fullfile(Folders.codecfolder,'kdu_compress.exe');
        %binDecode = fullfile(Folders.codecfolder,'kdu_expand.exe');
        encexe = fullfile(Folders.codecfolder, 'interfere_codec.exe'); %'D:\PlenoExperiment\Binary\v2enc\interfere.exe';
        decexe = encexe; %fullfile(Folders.codecfolder,'interfere_codec.exe');

        %% 1) Gathering INPUTS
        if (doSNR)
            targetL = sort(SNRceL(:));
            targetColorFactor = 1;
            postStr = 'dB';
            firstColStr = 'distortionReq';
        else
            targetL = sort(RA(:));
            targetColorFactor = 1 / ncolors;
            postStr = 'bpp';
            firstColStr = 'bppRequestedTot';
        end

        % Remove already processed bitrates
        if (~isfield(M, distStr) || ~isfield(M.(distStr), 'bitrateMap'))
            bitrateMap = zeros(numel(targetL), 2 + 2 * ncolors); % Format: [target(Tot)Req., bppTotAchieved, distReq_c1, bpp_c1, distReq_c2, bpp_c2, distReq_c3, bpp_c3]
        else

            if (isOctave)
                bitrateMap = cell2mat(M.(distStr).bitrateMap);
            else
                bitrateMap = M.(distStr).bitrateMap.Variables;
            end

            % Eliminate already determined targets from targetL
            targetL = setdiff(targetL, bitrateMap(:, 1));
            if (isempty(targetL)), return, end

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap};
            else
                M.(distStr).bitrateMap.Variables = bitrateMap;
            end

            % If old targets should not be recomputed please uncomment the following %TODO: Verify functionality now
            %              targetLnotdet = setdiff(targetL, bitrateMap(:, 1));
            %             % make sure bitrate map only include those values for the current
            %             % targetL, not all the available values from the past and the
            %             % present.
            %             bitrateMap = bitrateMap(ismember(bitrateMap(:,1),targetL),:);
            %             M.(distStr).bitrateMap(~ismember(M.(distStr).bitrateMap(:,1).Variables,bitrateMap(:,1)),:) = [];
            %               targetL = targetLnotdet;

            % Make room for new results
            bitrateMap = [zeros(numel(targetL), 2 + 2 * ncolors); bitrateMap];
        end

        holname = strrep(Folders.holofile, '.mat', '');

        %% Interface:
        % INPUT:
        %   targetL@numeric(1, n)...        List of total bitrates/distortions in bit per complex valued pixel (for all color channels) or dB across all color
        %                                   channels
        % OUTPUT:
        %   Need to write decoded bitstreams as mat files for further processing.
        %   bitrateMap@numeric(n, 2+2*ncolors) Format: [bppTotReq., bppTotAchieved, Aux_c1, bpp_c1, Aux_c2, bpp_c2, Aux_c3, bpp_c3]
        %       Necessary: bppTotReq, bppTotAchieved
        %
        %   Optional:
        %       bpp_c.. may be provided if color channels are encoded separately
        %       Aux_c.. is an optional auxiliary scalar number that may be saved together with the bpp. E.g. for HEVC/VTM it is the QP value.

        %% 2) Parametrization setup
        % Reading settings from: Version20/lower(holoname)/holo_001.txt
        [tile_size, transform_size, cb_size, qb_size] = readInterfereCfg(fullfile(Folders.interfereCfg, lower(Folders.holoname), 'holo_001.txt'));

        maxCoeffBitDepth = 11; % Choose any number <=15
        bs_max_iter = 100;
        gs_max_iter = 10;
        iscpx = iscomplex(Qcodec);

        %         foldTmp = Folders.encfolder;
        foldTmp = fullfile(Folders.forkfolder, 'Temp');
        foldOut = fullfile(Folders.forkfolder, distStr);

        % Use distortion targets instead of bitrates

        %% 3) Start loop over targets
        for tId = 1:numel(targetL)
            targetReqTot = targetL(tId);
            bitrateMap(tId, 1) = targetReqTot;
            target_c = targetReqTot * targetColorFactor;
            bitrateAchieved = 0;
            targetAchieved = zeros(ncolors, 1);
            clear resultTotalList;

            for c = 1:ncolors

                if (ncolors > 1)
                    holname_c = [holname, '_' num2str(c)];
                else
                    holname_c = holname;
                end

                warning('off', 'MATLAB:MKDIR:DirectoryExists')

                try
                    mkdir(fullfile(foldTmp, holname_c))
                    mkdir(fullfile(Folders.forkfolder, 'Temp', holname_c))
                    mkdir(foldOut)
                end

                warning('on', 'MATLAB:MKDIR:DirectoryExists')

                auxInfo.outfileMat = fullfile(foldOut, [prefixStr strrep(num2str(targetReqTot), '.', 'dot'), '_holo_001_c' num2str(c), '.mat']);
                auxInfo.tmpBitstreamFilename = fullfile(foldTmp, holname_c, ['out_holoconfig_001_' num2str(target_c, ['%3.2f' postStr]), '.jpl']);
                auxInfo.outfile = fullfile(Folders.forkfolder, 'Temp', holname_c, ['holodec_001_' num2str(target_c, ['%3.2f' postStr]), '.bin']);
                if (~exist('resultTotalListMETA', 'var')), resultTotalListMETA = cell(ncolors, 1); end

                doSNR = true
                %% Compress
                if (doSNR) % Use distortion target
                    %% Write configs, if not present yet

                    auxInfo.tmpHolo_cfg = fullfile(foldOut, [holname_c '_holo_001.txt']);
                    disp(['Writing hologram configuraion to: ' auxInfo.tmpHolo_cfg])
                    interfere_write_holocfg(auxInfo.tmpHolo_cfg, si, tile_size, transform_size, cb_size, qb_size);

                    auxInfo.tmpEnc_cfg = fullfile(foldOut, [holname_c '_enc_001.txt']);
                    disp(['Writing hologram configuraion to: ' auxInfo.tmpEnc_cfg])
                    interfere_write_enccfg(auxInfo.tmpEnc_cfg, maxCoeffBitDepth, bs_max_iter, gs_max_iter);

                    %% Write input file
                    auxInfo.tmpInfile = fullfile(Folders.forkfolder, [holname_c '.bin']);
                    disp(['Writing input file: ' auxInfo.tmpInfile])

                    if (~exist(auxInfo.tmpInfile, 'file'))
                        %% Write data
                        write_matrices(Qcodec(:, :, c), auxInfo.tmpInfile, iscpx)
                        clear QcodePad;
                    end

                    %% Call executable
                    enccmd = [encexe, ...
                                ' -i ' auxInfo.tmpInfile ...
                                ' -o ' auxInfo.tmpBitstreamFilename ...
                                ' -e ' auxInfo.tmpEnc_cfg ...
                                ' -c ' auxInfo.tmpHolo_cfg ...
                                ' -d ' num2str(target_c)];

                    [status, ~] = system(enccmd, '-echo');

                    if (status)
                        disp(['Called with a problem: ' enccmd])
                        warning(['Compression of ' auxInfo.tmpBitstreamFilename ' with ' auxInfo.tmpHolo_cfg ' failed at ' num2str(target_c) ' ' postStr '.'])
                    end

                    logfile = auxInfo.tmpBitstreamFilename
                    [bppPad, distAchieved] = parse(logfile);
                    bitrateMap(tId, 1 + 2 * c) = distAchieved; % Keep distortion target

                else % Use rate target
                    if (~isempty(resultTotalListMETA{c})), resultTotalListMETA{c} = zeros(0, 14); end
                    Folders2 = Folders;
                    Folders2.foldOut = foldOut;
                    Folders2.foldTmp = fullfile(foldTmp, ['c' num2str(c)]);
                    [Qcodechat, bpc, fsizebits, distAchieved, resultTotalListMETA{c}] = CfPbpp(Qcodec(:, :, c), target_c, transform_size, cb_size, qb_size, c, Folders2, resultTotalListMETA{c});
                    bitrateMap(tId, 1 + 2 * c) = distAchieved; % Keep distortion target
                end

                if (doSNR)
                    %% Decompress
                    deccmd = [encexe, ' -i ' auxInfo.tmpBitstreamFilename ' -o ' auxInfo.outfile];
                    [status, ~] = system(deccmd, '-echo');

                    if (status)
                        disp(['Called with a problem: ' deccmd])
                        warning(['Decompression of ' auxInfo.tmpBitstreamFilename ' with ' auxInfo.tmpHolo_cfg ' failed at ' num2str(target_c) ' ' postStr '.'])
                    end

                    %% Read file
                    Qcodechat = read_matrices(auxInfo.outfile, si(1:2), iscpx);

                    %% Parse bitrate
                    filereal = dir(auxInfo.tmpBitstreamFilename);
                    fsizebits = filereal.bytes * 8;
                    bpc = fsizebits / (numel(Qcodec(:, :, c)));
                    if (debug), disp(['Achieved BPP: ' num2str(bpc)]), end
                else
                    % Nothing to do
                end

                bitrateMap(tId, 2 + 2 * c) = bpc;

                % Save compressed hologram
                bitrateAchieved = bitrateAchieved + bpc;

                if (doSNR)
                    targetAchieved = distAchieved;
                end

                bpp = bpc;
                save(auxInfo.outfileMat, save73{:}, 'Qcodechat', 'fsizebits', 'bpp', 'targetAchieved', 'bitrateAchieved', 'resultTotalListMETA')
                clear bpp;

                %% Retain codestreams
                if (doCoreVerification)
                    movefile(auxInfo.tmpBitstreamFilename, strrep(auxInfo.outfileMat, '.mat', '.jpl'));
                end

            end

            lcolor = [4, 6, 8];
            bitrateMap(tId, 2) = sum(bitrateMap(tId, lcolor(1:ncolors))); % Bpp assignment to bppTotAchieved and bpp_cX is mandatory for future processing
        end

        clear Qcodechat;

        %% Clean up all temporary files here, *NOT* the decoded degraded DHs stored as fnameMat!
        warning('off', 'MATLAB:DELETE:FileNotFound')

        try
            rmdir(foldTmp, 's')
        catch me

            try
                delete(fullfile(foldTmp, '*'))
            catch me
            end

            for c = 1:ncolors % Always delete at least input files
                holname_c = [holname, '_' num2str(c)];
                delete(fullfile(Folders.forkfolder, [holname_c '.bin']))
            end

        end

        warning('on', 'MATLAB:DELETE:FileNotFound')

        %% Keep results
        if (ncolors > 1)

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8));
                M.(distStr).bitrateMap.Properties.VariableNames = {firstColStr, 'bitrateAchievedTot', 'snrAchieved_c1', 'bpp_c1', 'snrAchieved_c2', 'bpp_c2', 'snrAchieved_c3', 'bpp_c3'};
            end

        else

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4));
                M.(distStr).bitrateMap.Properties.VariableNames = {firstColStr, 'bitrateAchievedTot', 'snrAchieved_c1', 'bpp_c1'};
            end

        end

        save(fullfile(Folders.forkfolder, distStr, [distStr '_bitrateMap_interim.mat']), '-v6', 'M'); % Better safe than sorry

        %% Delete input files
        for c = ncolors:-1:1

            if (ncolors > 1)
                holname_c = [holname, '_' num2str(c)];
            else
                holname_c = holname;
            end

            warning('off', 'MATLAB:DELETE:FileNotFound')
            delete(fullfile(Folders.forkfolder, [holname_c '.bin']));
            warning('on', 'MATLAB:DELETE:FileNotFound')
        end

    end

    function jxlCompression()
        RAloc = sort(RA(:));

        % Remove already processed bitrates
        if (~isfield(M, distStr) || ~isfield(M.(distStr), 'bitrateMap'))
            bitrateMap = zeros(numel(RAloc), 2 + 2 * ncolors); % Format: [bppTotReq., bppTotAchieved, ~, bpp_c1, ~, bpp_c2, ~, bpp_c3]
        else

            if (isOctave)
                bitrateMap = cell2mat(M.(distStr).bitrateMap);
            else
                bitrateMap = M.(distStr).bitrateMap.Variables;
            end

            %% Eliminate already determined rates from RAloc
            RAloc = setdiff(RAloc, bitrateMap(:, 1));
            if (isempty(RAloc) && isOctave), return, end

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap};
            else
                M.(distStr).bitrateMap.Variables = bitrateMap;
            end

            % If old bitrates should not be recomputed please uncomment the following
            %              RAnotdet = setdiff(RAloc, bitrateMap(:, 1));
            %             % make sure bitrate map only include those values for the current
            %             % RA, not all the available values from the past and the
            %             % present.
            %             bitrateMap = bitrateMap(ismember(bitrateMap(:,1),RAloc),:);
            %             M.(distStr).bitrateMap(~ismember(M.(distStr).bitrateMap(:,1).Variables,bitrateMap(:,1)),:) = [];
            %               RAloc = RAnotdet;

            %% Make room for new results
            bitrateMap = [zeros(numel(RAloc), 2 + 2 * ncolors); bitrateMap];
        end

        %% Start JPEG XL, 16bit compression per color-channel
        binEncode = fullfile(Folders.codecfolder, 'cjxl.exe');
        binDecode = fullfile(Folders.codecfolder, 'djxl.exe');

        bstReal = fullfile(tempfolder, 'real.jxl');
        bstImag = fullfile(tempfolder, 'imag.jxl');

        decReal = fullfile(tempfolder, 'real_dec.pgm');
        decImag = fullfile(tempfolder, 'imag_dec.pgm');

        for bId = 1:numel(RAloc)
            bitrateReqTot = RAloc(bId);
            bitrateMap(bId, 1) = bitrateReqTot;

            for c = ncolors:-1:1
                % Obtain correct bitrates from HEVC
                if (isfield(M, 'hm'))
                    bitrateReqPcolor = M.hm.bitrateMap(bId, 2 + 2 * c).Variables;
                else
                    bitrateReqPcolor = bitrateReqTot / ncolors;
                end

                infileReal = fullfile(tempfolder, ['real_c' num2str(c) '.pgm']);
                infileImag = fullfile(tempfolder, ['imag_c' num2str(c) '.pgm']);

                if (~exist(infileReal, 'file')), imwrite(uint16(real(Qcodec(:, :, c))), infileReal); end
                if (~exist(infileImag, 'file')), imwrite(uint16(imag(Qcodec(:, :, c))), infileImag); end

                %% JXL - Compress Real part
                if (debug), disp(['Target BPP: ' num2str(bitrateReqPcolor)]), end
                [status, out] = system([binEncode ' -e 1 --target_bpp=' num2str(bitrateReqPcolor / 2) ' ' infileReal ' ' bstReal]);
                if (status), error(out); end
                [status, out] = system([binDecode ' ' bstReal ' ' decReal]);
                if (status), error(out); end

                %% JXL - Compress Imag part
                [status, out] = system([binEncode ' -e 1 --target_bpp=' num2str(bitrateReqPcolor / 2) ' ' infileImag ' ' bstImag]);
                if (status), error(out); end
                [status, out] = system([binDecode ' ' bstImag ' ' decImag]);
                if (status), error(out); end

                %% Read bitrates
                filereal = dir(bstReal);
                fileimag = dir(bstImag);
                fsizebits = (filereal.bytes + fileimag.bytes) * 8;
                bpc = fsizebits / (numel(Qcodec(:, :, c)));
                if (debug), disp(['Achieved BPP: ' num2str(bpc)]), end
                Qcodechat = complex(uint16(imread(decReal)), uint16(imread(decImag)));
                bitrateMap(bId, 2 + 2 * c) = bpc;

                %% Save compressed hologram
                bpp = bpc;
                fnameMat = fullfile(Folders.forkfolder, distStr, ['rate_' strrep(num2str(bitrateReqTot), '.', 'dot') '_c' num2str(c) '.mat']);
                save(fnameMat, save73{:}, 'Qcodechat', 'fsizebits', 'bpp');

                %% Delete output files
                warning('off', 'MATLAB:DELETE:FileNotFound')
                delete(bstReal);
                delete(bstImag);
                delete(decReal);
                delete(decImag);
                warning('on', 'MATLAB:DELETE:FileNotFound')
            end

            bitrateMap(bId, 2) = sum(bitrateMap(bId, 3:2:end));
        end

        %% Keep results
        if (ncolors > 1)

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4), bitrateMap(:, 5), bitrateMap(:, 6), bitrateMap(:, 7), bitrateMap(:, 8));
                M.(distStr).bitrateMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTot', 'n', 'bpp_c1', 'nn', 'bpp_c2', 'nnn', 'bpp_c3'};
            end

        else

            if (isOctave)
                M.(distStr).bitrateMap = {bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4)};
            else
                M.(distStr).bitrateMap = table(bitrateMap(:, 1), bitrateMap(:, 2), bitrateMap(:, 3), bitrateMap(:, 4));
                M.(distStr).bitrateMap.Properties.VariableNames = {'bppRequestedTot', 'bitrateAchievedTot', 'n', 'bpp_c1'};
            end

        end

        save(fullfile(Folders.forkfolder, distStr, [distStr '_bitrateMap_interim.mat']), '-v6', 'M'); % Better safe than sorry

        %% Delete input files
        for c = ncolors:-1:1
            infileReal = fullfile(tempfolder, ['real_c' num2str(c) '.pgm']);
            infileImag = fullfile(tempfolder, ['imag_c' num2str(c) '.pgm']);

            warning('off', 'MATLAB:DELETE:FileNotFound')
            delete(infileReal);
            delete(infileImag);
            warning('on', 'MATLAB:DELETE:FileNotFound')
        end

    end

    %% interfere helper functions
    function interfere_write_holocfg(tmpHolo_cfg, siPad, tile_size, transform_size, cb_size, qb_size)
        fid = fopen(tmpHolo_cfg, 'w');
        strCpx = {'real', 'complex'};
        strCpx = strCpx{1 + iscomplex(Qcodec)};
        fprintf(fid, '#Format specifics\n');
        fprintf(fid, 'representation : "%s"\n', strCpx); % Because we use write_matrices only for now
        fprintf(fid, 'datatype	: "float"\n'); % Because we use write_matrices only for now
        fprintf(fid, 'dimension	: [%d,%d]\n', siPad(1), siPad(2));

        fprintf(fid, '#HOLOGRAM SPLITTING\n');
        fprintf(fid, 'tile_size       : [%d,%d]\n', tile_size(1), tile_size(2));
        fprintf(fid, 'transform_block_size 	: [%d,%d]\n', transform_size(1), transform_size(2));
        fprintf(fid, '# Format 4D: fx, fy, x, y\n');
        fprintf(fid, 'code_block_size:  [%d,%d,%d,%d]\n', cb_size(1), cb_size(2), cb_size(3), cb_size(4));
        fprintf(fid, 'quantization_block_size: [%d,%d,%d,%d]\n', qb_size(1), qb_size(2), qb_size(3), qb_size(4));

        % These parameters are not in use for now %TODO: Fixme later
        fprintf(fid, '#RECONSTRUCTION PARAMETERS\n');
        fprintf(fid, 'wlen       : [%f]\n', 1e-2);
        fprintf(fid, 'pixel_pitch        	: ([%f])\n', 1e-1);
        fclose(fid);
    end

    function interfere_write_enccfg(tmpEnc_cfg, maxCoeffBitDepth, bs_max_iter, gs_max_iter)
        fid = fopen(tmpEnc_cfg, 'w');

        fprintf(fid, '#Optimization aux. parameters \n');
        fprintf(fid, 'out_bitdepth_max 	: %d\n', maxCoeffBitDepth);
        fprintf(fid, 'bs_max_iter  	: %d\n', bs_max_iter);
        fprintf(fid, 'gs_max_iter : %d\n', gs_max_iter);
        fprintf(fid, 'opt_target_tolerance : 0.1\n'); %TODO: Enable passing and writing here

        % The parameters below are not in use for this pipeline, for now %TODO: fixme
        fprintf(fid, '#PROGRAMFLOW PARAMETERS\n');
        fprintf(fid, 'doLossless : false\n');
        fprintf(fid, 'doObjectPlaneCompression : false\n');
        fprintf(fid, 'doTransform : true\n');
        fprintf(fid, 'doAdaptiveQuantization	: false\n');

        fprintf(fid, '#Optimization control parameters\n');
        fprintf(fid, 'mode : "SNR"\n');
        fprintf(fid, 'opt_target : 0\n');
        fclose(fid);
    end

    function [bpp, snr] = parse(logfile)
        fid = fopen(logfile, 'r');
        if (fid < 0), error('Pipeline_compress:parse', ['Failed to open ' logfile '.']); end

        try
            buf = fgetl(fid);
            bpp = strsplit(buf, ':');
            bpp = str2double(bpp{2});
            buf = fgetl(fid);
            snr = strsplit(buf, ':');
            snr = str2double(snr{2});
        catch me
        end

        if (fid > 0), fclose(fid); end
    end

    function [siTile, siTrafo, siCB, siQB] = readInterfereCfg(cfg_fname)
        % Read cfg_fname
        [fh, errormsg] = fopen(cfg_fname, 'r');
        if (fh < 0), disp(errormsg), error('Pipeline_compress:readInterfereCfg', ['Failed to open ' strrep(cfg_fname, '\', '/') '. ']); end
        tmp = fgetl(fh);

        while (~feof(fh))

            if (contains(tmp, 'tile_size'))
                siTile = parseNumbers(tmp);
            elseif (contains(tmp, 'transform_block_size'))
                siTrafo = parseNumbers(tmp);
            elseif (contains(tmp, 'code_block_size'))
                siCB = parseNumbers(tmp);
            elseif (contains(tmp, 'quantization_block_size'))
                siQB = parseNumbers(tmp);
            end

            tmp = fgetl(fh);
        end

        fclose(fh);
    end

    function res = parseNumbers(str)
        str = strsplit(str, ':');
        str = strrep(strrep(str{2}, '[', ''), ']', '');
        str = strsplit(str, ',');
        res = zeros(1, numel(str));

        for ii = 1:numel(str)
            res(ii) = str2double(str{ii});
        end

    end

    %% HEVC helper functions
    function [bpp, bpc] = qpnCompress(qpn, colorList, auxInfo)
        ncolorsLoc = numel(colorList);
        bpc = zeros(1, ncolorsLoc);
        bpp = 0;

        for c2 = colorList(:).'
            [Qcodechat, bppTmp, fsizebits] = hm_comp(qpn, c2, auxInfo);
            bpp = bpp + bppTmp;
            fnameMat = fullfile(Folders.forkfolder, distStr, ['qpn' num2str(qpn, '%03d') '_c' num2str(c2) '.mat']);
            save(fnameMat, save73{:}, 'Qcodechat', 'fsizebits', 'bpp', 'qpn');

            if (ncolorsLoc == 1)
                bpc = bppTmp;
            else
                bpc(c2) = bppTmp;
            end

        end

    end

    function [Qcodechat, bpphm, fsizebitshm] = hm_comp(qpn, c3, auxInfo)
        fsizebitshm = 0;
        Qcodechat = complex(zeros(auxInfo.siPad(1:2), 'uint16'));

        for k = 1:ceil(auxInfo.siPad(1) / auxInfo.siTile(1)) % Loop over tiles if necessary

            for l = 1:ceil(auxInfo.siPad(2) / auxInfo.siTile(2))

                if (k ~= ceil(auxInfo.siPad(1) / auxInfo.siTile(1)))
                    K = (k - 1) * auxInfo.siTile(1) + 1:(k) * auxInfo.siTile(1);
                else
                    K = (k - 1) * auxInfo.siTile(1) + 1:auxInfo.siPad(1);
                end

                if (l ~= ceil(auxInfo.siPad(2) / auxInfo.siTile(2)))
                    L = (l - 1) * auxInfo.siTile(2) + 1:(l) * auxInfo.siTile(2);
                else
                    L = (l - 1) * auxInfo.siTile(2) + 1:auxInfo.siPad(2);
                end

                infilereal = fullfile(Folders.forkfolder, 'Temp', ['real_c' num2str(c3) '_k' num2str(k) '_l' num2str(l) '.yuv']);
                infileimag = fullfile(Folders.forkfolder, 'Temp', ['imag_c' num2str(c3) '_k' num2str(k) '_l' num2str(l) '.yuv']);

                if (~exist(infilereal, 'file')) % Only write out tiles once
                    fid = fopen(infilereal, 'w+');
                    fwrite(fid, permute(uint16(real(Qcodec(K, L, c3))), [2, 1]), 'uint16');
                    fclose(fid);
                end

                if (~exist(infileimag, 'file'))
                    fid = fopen(infileimag, 'w+');
                    fwrite(fid, permute(uint16(imag(Qcodec(K, L, c3))), [2, 1]), 'uint16');
                    fclose(fid);
                end

                %% Compress - Real
                writeSpecificConfig(auxInfo.specificConfigFilename, auxInfo.tmpBitstreamFilename, infilereal, auxInfo.outfile, qpn, auxInfo.siTile)
                compressCmd = [fullfile(Folders.codecfolder, 'TAppEncoder.exe') ' -c ' auxInfo.generalConfigFilename ' -c ' auxInfo.specificConfigFilename];
                [status, out] = system(compressCmd);

                if (status ~= 0)
                    error(out)
                end

                fid = fopen(auxInfo.outfile, 'r');
                Qrealhat = fread(fid, fliplr(auxInfo.siTile(:).'), 'uint16').';
                fclose(fid);

                %% Parse Bitrate - Real
                idxBeg = strfind(out, 'Bytes written to file: ') + numel('Bytes written to file: ');
                idxEnd = strfind(out(idxBeg:end), '(') + idxBeg - 2 - 1;
                bitsreal = str2double(out(idxBeg:idxEnd)) * 8;
                doAlternateBitrateParsing = false;

                if (isnan(bitsreal) || isinf(bitsreal) || isempty(bitsreal))
                    % Alternative bitrate parsing mode
                    doAlternateBitrateParsing = true;
                    filereal = dir(auxInfo.tmpBitstreamFilename);
                    fsizebits = filereal.bytes * 8;
                    bpc = fsizebits / (numel(Qcodec(:, :, c)));
                    if (debug), disp(['Achieved BPP: ' num2str(bpc)]), end
                    Qcodechat = complex(uint16(imread(decReal)), uint16(imread(decImag)));
                    bitrateMap(bId, 2 + 2 * c) = bpc;
                end

                %% Compress - Imag
                writeSpecificConfig(auxInfo.specificConfigFilename, auxInfo.tmpBitstreamFilename, infileimag, auxInfo.outfile, qpn, auxInfo.siTile)
                compressCmd = [fullfile(Folders.codecfolder, 'TAppEncoder.exe') ' -c ' auxInfo.generalConfigFilename ' -c ' auxInfo.specificConfigFilename];
                [status, out] = system(compressCmd);

                if (status ~= 0)
                    error(out)
                end

                fid = fopen(auxInfo.outfile, 'r');
                Qimaghat = fread(fid, fliplr(auxInfo.siTile(:).'), 'uint16').';
                fclose(fid);

                %% Parse Bitrate - Imag
                idxBeg = strfind(out, 'Bytes written to file: ') + numel('Bytes written to file: ');
                idxEnd = strfind(out(idxBeg:end), '(') + idxBeg - 2 - 1;
                bitsimag = str2double(out(idxBeg:idxEnd(1))) * 8;

                if (isnan(bitsreal) || isinf(bitsreal) || isempty(bitsreal))
                    % Alternative bitrate parsing mode
                    doAlternateBitrateParsing = true;
                    filereal = dir(auxInfo.tmpBitstreamFilename);
                    fsizebits = filereal.bytes * 8;
                    bpc = fsizebits / (numel(Qcodec(:, :, c)));
                    if (debug), disp(['Achieved BPP: ' num2str(bpc)]), end
                    Qcodechat = complex(uint16(imread(decReal)), uint16(imread(decImag)));
                    bitrateMap(bId, 2 + 2 * c) = bpc;
                end

                Qcodechat(K, L) = complex(Qrealhat, Qimaghat);
                fsizebitshm = fsizebitshm + bitsreal + bitsimag;
                bpphm = fsizebitshm / numel(Qcodec(:, :, c3, 1));
            end

        end

    end

    function writeGeneralConfig(generalConfigFilename)
        %Configuration General
        fid = fopen(generalConfigFilename, 'w+');
        if (fid < 0), error(['Unable to write to file: ' generalConfigFilename]), end
        fprintf(fid, '#======== Profile definition ==============\n');
        fprintf(fid, 'Profile                       : monochrome16   # Profile name to use for encoding. Use main (for FDIS main), main10 (for FDIS main10), main-still-picture, main-RExt, high-throughput-RExt, main-SCC\n');
        fprintf(fid, 'Tier                          : main        # Tier to use for interpretation of --Level (main or high only)"\n');
        fprintf(fid, '\n');
        fprintf(fid, '#======== Unit definition ================\n');
        fprintf(fid, 'MaxCUWidth                    : 64          # Maximum coding unit width in pixel\n');
        fprintf(fid, 'MaxCUHeight                   : 64          # Maximum coding unit height in pixel\n');
        fprintf(fid, 'MaxPartitionDepth             : 4           # Maximum coding unit depth\n');
        fprintf(fid, 'QuadtreeTULog2MaxSize         : 5           # Log2 of maximum transform size for\n');
        fprintf(fid, '                                            # quadtree-based TU coding (2...6)\n');
        fprintf(fid, 'QuadtreeTULog2MinSize         : 2           # Log2 of minimum transform size for\n');
        fprintf(fid, '                                            # quadtree-based TU coding (2...6)\n');
        fprintf(fid, 'QuadtreeTUMaxDepthInter       : 5\n');
        fprintf(fid, 'QuadtreeTUMaxDepthIntra       : 5\n');
        fprintf(fid, '\n');
        fprintf(fid, '#======== Coding Structure =============\n');
        fprintf(fid, 'IntraPeriod                   : 1           # Period of I-Frame ( -1 = only first)\n');
        fprintf(fid, 'DecodingRefreshType           : 0           # Random Accesss 0:none, 1:CRA, 2:IDR, 3:Recovery Point SEI\n');
        fprintf(fid, 'GOPSize                       : 1           # GOP Size (number of B slice = GOPSize-1)\n');
        fprintf(fid, '\n');
        fprintf(fid, '#=========== Misc. ============\n');
        fprintf(fid, 'InputColourSpaceConvert       : UNCHANGED\n');
        fprintf(fid, 'InputChromaFormat             : 400        # Ratio of luminance to chrominance samples\n');
        fprintf(fid, 'InternalBitDepth              : 16          # codec operating bit-depth\n');
        fprintf(fid, 'WaveFrontSynchro              : 1       # Enables the use of specific CABAC probabilities synchronization at the beginning\n');
        fprintf(fid, '                                        #    of each line of CTBs in order to produce a bitstream that can be encoded or decoded\n');
        fprintf(fid, '                                        #    using one or more cores.\n');
        fprintf(fid, 'SummaryVerboseness:1\n');
        fclose(fid);
    end

    function writeSpecificConfig(specificConfigFilename, tmpBitstreamFilename, infile, outfile, qpn, siTile)
        fid = fopen(specificConfigFilename, 'w+');
        if (fid < 0), error(['Unable to write to file: ' specificConfigFilename]), end
        fprintf(fid, 'InputFile: %s\n', infile);
        fprintf(fid, 'InputBitDepth: 16\n');
        fprintf(fid, 'BitstreamFile: %s\n', tmpBitstreamFilename);
        fprintf(fid, 'ReconFile: %s\n', outfile);
        fprintf(fid, '\n');
        fprintf(fid, 'Level: 8.5\n');
        fprintf(fid, 'QP: %i\n', qpn);
        %fprintf(fid,'RateControl: 1\n');
        %fprintf(fid,'TargetBitrate: %i\n', bpp*length(V)*size(V{1},1)*size(V{1},2)/2);
        fprintf(fid, 'SourceWidth: %i\n', siTile(2));
        fprintf(fid, 'SourceHeight: %i\n', siTile(1));
        fprintf(fid, 'FrameRate: 1\n');
        fprintf(fid, 'FrameSkip: 0\n');
        fprintf(fid, 'FramesToBeEncoded: %i\n', 1);
        fprintf(fid, '\n');
        fclose(fid);
    end

end
