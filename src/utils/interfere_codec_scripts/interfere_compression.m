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

    bitrateMap = M.(distStr).bitrateMap.Variables;

    % Eliminate already determined targets from targetL
    targetL = setdiff(targetL, bitrateMap(:, 1));
    if (isempty(targetL)), return, end

    if (isOctave)
        M.(distStr).bitrateMap = {bitrateMap};
    else
        M.(distStr).bitrateMap.Variables = bitrateMap;
    end

    % Make room for new results
    bitrateMap = [zeros(numel(targetL), 2 + 2 * ncolors); bitrateMap];

    holname = strrep(Folders.holofile, '.mat', '');

    %% 2) Parametrization setup

    [tile_size, transform_size, cb_size, qb_size] = readInterfereCfg(fullfile(Folders.interfereCfg, lower(Folders.holoname), 'holo_001.txt'));

    maxCoeffBitDepth = 11; % Choose any number <=15
    bs_max_iter = 100;
    gs_max_iter = 10;
    iscpx = iscomplex(Qcodec);

    % foldTmp = Folders.encfolder;
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
