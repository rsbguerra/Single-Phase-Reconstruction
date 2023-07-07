function [dataHat, bppAchieved, fsizebits, distAchieved, resultTotalList] = CfPbpp(data, bppReq, transform_size, cb_size, qb_size, colorId, Folders, resultTotalList)
    % [dataHat, bppAchieved, fsizebits, distAchieved, resultTotalList] = CfPbpp(data, bppReq, transform_size, cb_size, qb_size, colorId, Folders, resultTotalList)
    %   Performs search for best suiting SNR for Verification Model software (interfere codec)
    %   for a given bitrate.
    %   Suitable for the compression of non-binary content.
    %   Uses a parpool and semi-random surrogate_search to solve
    %   optimization problem efficiently in parallel.
    %   Requires GlobalOptimization Matlab toolbox.
    %
    % INPUT:
    %   data@numeric...                 digital hologram to compress (1 color channel)
    %   bppReq@numeric(1)...            requrested bitrate
    %   transform_size@numeric(2,1)...  size of the STFT transform to use
    %              or @numeric(1,2)
    %   cb_size@numeric(4,1)...         size of codeblock
    %       or @numeric(1,4)
    %   qb_size@numeric(4,1)...         size of quantization block
    %       or @numeric(1,4)
    %   colorId@numeric(1)...           id of color channel
    %   Folders@struct...               extended struct of char arrays from
    %                                   main_degrade.m, used for
    %                                   codecfolder, foldTmp and foldOut parsing.
    %   resultTotalList@numeric(x,14)...table of previous candidate compressions.
    %                                   Format: bppReq, bppAchieved, distAchieved, distReq, [tb_x, tb_y], [cb_fx, cb_fy, cb_sx, cb_sy], [qb_fx, qb_fy, qb_x, qb_y]
    %
    % OUTPUT:
    %   dataHat@numeric...              compressed DH with highest SNR for requested
    %                                   bitrate
    %   bppAchieved@numeric(1)...       achieved bitrate of copressed DH (is accurate wrt. unpadded data)
    %   fsizebits@numeric(1)...         compressed file size in bit
    %   distAchieved@numeric(1)...      best distortion achieved (may be slighly inaccurate, as it is computed with internal padding)
    %   resultTotalList@numeric(x,14)...table of candidate compressions,
    %                                   for more efficient future searches.
    %
    % Version 2.00
    % 26.02.2022, Tobias Birnbaum
    stashfold = fullfile(Folders.foldTmp, num2str(colorId));

    try
        mkdir(fullfile(stashfold))
    catch me
    end

    Folders.forkfolder = Folders.foldTmp;

    if (nargin < 8), error('CfPbpp:missing_arguments', 'Missing Folders struct and eventually other arguments!'); end
    if (nargin < 9 || size(resultTotalList, 2) < 14), resultTotalList = zeros(0, 14); end % Format: bppReq, bppAchieved, distAchieved, distReq, [tb_x, tb_y], [cb_fx, cb_fy, cb_sx, cb_sy], [qb_fx, qb_fy, qb_x, qb_y]
    % Used for choosing appropriate bounds

    dimLlong = [transform_size, cb_size, qb_size];
    dim2str = @(x) strrep(num2str(x(:).', 'tb%5.0f-%5.0f_cb%5.0f-%5.0f-%5.0f-%5.0f_qb%5.0f-%5.0f-%5.0f-%5.0f'), ' ', '');

    fname_RTL = fullfile(Folders.foldOut, ['TBtot_' dim2str(dimLlong) num2str(colorId, '_cId%1.0f') '.mat']);

    if (isempty(resultTotalList)) % try to load former resultTotalList (RTL)

        try

            if (exist(fname_RTL, 'file'))
                tmp = load(fname_RTL);
                tmp = tmp.tab;
                resultTotalList = tmp.Variables;
            else
                fname_RTL = strrep(fname_RTL, '.mat', '.xls');

                if (exist(fname_RTL, 'file'))
                    tmp = readtable(fname_RTL);
                    resultTotalList = tmp.Variables;
                end

            end

        catch me
            % No load possible
        end

    end

    % Retain only valid dimensions
    if (~isempty(resultTotalList))
        resultTotalList = resultTotalList(all(resultTotalList(:, 5:14) == dimLlong, 2), :);
    end

    %% Initalize algorithm
    maxCoeffBitDepth = 11; % Choose any number <=15
    bs_max_iter = 100;
    gs_max_iter = 10;
    iscpx = iscomplex(data);
    rateMatchPerc = 0.05;
    p = gcp('nocreate');

    if (isempty(p))
        p = parpool;
    end

    maxsteps = max(3 * p.NumWorkers, 36); %3*feature('numcores'); % max #steps involving calculations / per BD for restarted search
    % max #steps*3 for freshstart

    n = @(x) num2str(x);

    si = size(data);
    si(3) = size(data, 3);
    tile_size = ceil(si(1:2) ./ transform_size) .* transform_size;

    if (si(3) > 1), error('Color wrapper not implemented yet.'), end
    holname_c = 'dummy'; c = 1;
    bppAchieved = 0;

    encexe = fullfile(Folders.codecfolder, 'interfere_codec.exe');
    decexe = encexe;

    %% Write configs, if not present yet
    auxInfo.tmpHolo_cfg = fullfile(stashfold, ['holo_001.txt']);
    %if(~exist(auxInfo.tmpHolo_cfg, 'file'))
    jpeg_pleno_holo_etro_write_holocfg(auxInfo.tmpHolo_cfg, si(1:2), tile_size, transform_size, cb_size, qb_size);
    %end
    auxInfo.tmpEnc_cfg = fullfile(stashfold, ['enc_001.txt']);
    %if(~exist(auxInfo.tmpEnc_cfg, 'file'))
    jpeg_pleno_holo_etro_write_enccfg(auxInfo.tmpEnc_cfg, maxCoeffBitDepth, bs_max_iter, gs_max_iter);
    %end

    %% Write input file
    auxInfo.tmpInfile = fullfile(Folders.forkfolder, [holname_c '.bin']);
    %if(~exist(auxInfo.tmpInfile, 'file'))
    %% Write data
    write_matrices(data(:, :, c), auxInfo.tmpInfile, iscpx)
    clear dataPad data;
    %end
    auxInfo.outfile = fullfile(Folders.foldTmp, ['holodec_001' num2str(colorId, '_cId%1.0f_') num2str(bppReq, '%5.2fdB'), '.bin']);
    auxInfo.tmpBitstreamFilenameBest = fullfile(Folders.foldTmp, ['out_holoconfig_001' num2str(colorId, '_cId%1.0f_') num2str(bppReq, '%5.2fdB'), '_bestFit.jpl']);

    %               tmpBitstreamFilename ==  out_file = fullfile(currentholofolder,strcat('out_holoconfig_', num2str(i2count,'%03d'), num2str(bppReq,'_%4.2fbpp'), '.jpl'));

    %% Compress
    [distAchieved, resultTotalList] = compressBpp(bppReq, auxInfo, resultTotalList);

    %% Write out resultTotalList
    try
        tab = table(resultTotalList(:, 1), resultTotalList(:, 2), resultTotalList(:, 3), resultTotalList(:, 4), resultTotalList(:, 5), resultTotalList(:, 6), resultTotalList(:, 7) ...
            , resultTotalList(:, 8), resultTotalList(:, 9), resultTotalList(:, 10), resultTotalList(:, 11), resultTotalList(:, 12), resultTotalList(:, 13), resultTotalList(:, 14));
        tab.Properties.VariableNames = {'bppRequested', 'bppAchieved', 'snrAchieved', 'snrTargetBS', 'transform_x', 'transform_y', 'cb_fx', 'cb_fy', 'cb_x', 'cb_y', 'qb_fx', 'qb_fy', 'qb_x', 'qb_y'};
        writetable(tab, strrep(fname_RTL, '.mat', '.xls'));
    catch me
        save(fname_RTL, 'resultTotalList')
    end

    %% Decompress final tmpBitstreamFile
    cmd = [decexe, ' -i ' auxInfo.tmpBitstreamFilenameBest ' -o ' auxInfo.outfile];
    [status, ~] = system(cmd, '-echo');

    if (status)
        warning(['Decompression of ' auxInfo.tmpBitstreamFilenameBest ' with ' auxInfo.tmpHolo_cfg ' failed at ' num2str(bppReq) '.'])
    end

    if (status) % Early exit for parallelization
        dataHat = zeros(si(1:2));
        bppAchieved = 0;
        fsizebits = 0;
        distAchieved = inf;
        return;
    end

    %% Read file
    dataHat = read_matrices(auxInfo.outfile, si(1:2), iscpx);

    %% Parse bitrate
    filesize = dir(auxInfo.tmpBitstreamFilenameBest);
    fsizebits = filesize.bytes * 8;
    bpc = fsizebits / (prod(si(1:2))); %Bitrate wrt. unpadded
    disp(['Achieved BPP: ' num2str(bpc)])

    % Save compressed hologram
    bppAchieved = bppAchieved + bpc;

    %% Clean up
    try
        rmdir(stashfold, 's');
    catch me
    end

    %% JPEG_Pleno_Holo_ETRO helper functions
    function jpeg_pleno_holo_etro_write_holocfg(tmpHolo_cfg, si, tile_size, transform_size, cb_size, qb_size)
        fid = fopen(tmpHolo_cfg, 'w');
        strCpx = {'real', 'complex'};
        strCpx2 = {'binary', 'float'};
        strCpx = strCpx{1 + iscomplex(data)};
        strCpx2 = strCpx2{1 + iscomplex(data)};
        fprintf(fid, '#Format specifics\n');
        fprintf(fid, 'representation : "%s"\n', strCpx); % Because we use write_matrices only for now
        fprintf(fid, 'datatype	: "%s"\n', strCpx2); % Because we use write_matrices only for now
        fprintf(fid, 'dimension	: [%d,%d]\n', si(1), si(2));

        fprintf(fid, '#HOLOGRAM SPLITTING\n');
        fprintf(fid, 'tile_size       : [%d,%d]\n', tile_size(1), tile_size(2));
        fprintf(fid, 'transform_block_size 	: [%d,%d]\n', transform_size(1), transform_size(2));
        fprintf(fid, '# Format 4D: fx, fy, x, y\n');
        fprintf(fid, 'code_block_size:  [%d,%d,%d,%d]\n', cb_size(1), cb_size(2), cb_size(3), cb_size(4));
        fprintf(fid, 'quantization_block_size: [%d,%d,%d,%d]\n', qb_size(1), qb_size(2), qb_size(3), qb_size(4));

        % These parameters are not in use for now %TODO: Fixme later
        fprintf(fid, '#RECONSTRUCTION PARAMETERS\n');
        fprintf(fid, 'wlen       : [%d]\n', 1e-4);
        fprintf(fid, 'pixel_pitch        	: ([%d])\n', 1e-1);
        fclose(fid);
    end

    function jpeg_pleno_holo_etro_write_enccfg(tmpEnc_cfg, maxCoeffBitDepth, bs_max_iter, gs_max_iter)
        fid = fopen(tmpEnc_cfg, 'w');

        if (iscomplex(data)) %TODO: Adapt for real-valued non-binary compression
            fprintf(fid, '#Optimization aux. parameters \n');
            fprintf(fid, 'out_bitdepth_max 	: %d\n', maxCoeffBitDepth);
            fprintf(fid, 'bs_max_iter  	: %d\n', bs_max_iter);
            fprintf(fid, 'gs_max_iter : %d\n', gs_max_iter);
            fprintf(fid, 'opt_target_tolerance : 0.1\n');

            fprintf(fid, '#Optimization control parameters\n');
            fprintf(fid, 'mode : "SNR"\n');
            fprintf(fid, 'opt_target : 0\n');
        end

        fprintf(fid, '#PROGRAMFLOW PARAMETERS\n');
        fprintf(fid, 'doObjectPlaneCompression : false\n');
        fprintf(fid, 'doTransform : true\n');
        fclose(fid);
    end

    function [bpp, snr, snrReq] = parseFile(fname)
        fid = fopen(fname, 'r');
        if (fid < 0), error('CfPbpp:file_io', ['Failed to parse logfile ' strrep(fname, '\', '\\') ' .']); end

        buf = fgetl(fid);
        bpp = strsplit(buf, ':');
        bpp = str2double(bpp{2});

        buf = fgetl(fid);
        snr = strsplit(buf, ':');
        snr = str2double(snr{2});

        try
            buf = fgetl(fid);
            snrReq = strsplit(buf, ':');
            snrReq = str2double(snrReq{2});
        catch me
            snrReq = snr;
        end

        if (fid > 0), fclose(fid); end
    end

    function [snrBest, resultTotalList] = compressBpp(bppReq, auxInfo, resultTotalList)
        idx = abs(resultTotalList(:, 2) - bppReq) / bppReq <= rateMatchPerc;

        if (any(idx ~= 0))
            %% Early exit, check if good result is know already
            [~, idx] = min(abs(resultTotalList(:, 2) - bppReq));
            distReq = resultTotalList(idx(1), 4);
            [bppBest, snrBest, res] = doRecomputeSingleIter(distReq, bppReq, auxInfo);
        else
            %% otherwise, calculate via surrogate search
            % Set some default values
            if (~exist('snrBest', 'var')), snrBest = 100; end
            ub = snrBest; % Last achieved distortion is upper bound for next lower bitrate
            lb = min(0);

            if (~isempty(resultTotalList)) % Refine if possible
                %% lb: Find largest candidate smaller than bppReq
                idx = resultTotalList(:, 2) - bppReq <= 0;
                tmpSubsel = resultTotalList(idx, :);
                [~, idx] = max(tmpSubsel(:, 2));

                if (~isempty(idx))
                    lb = tmpSubsel(idx(1), 4);
                    disp([n(bppReq) ' bpp: Reuse lb: ' n(lb) ' corresponding to ' n(tmpSubsel(idx(1), 2)) ' bpp'])
                end

                %% ub: Find smallest candidate larger than bppReq
                idx = resultTotalList(:, 2) - bppReq >= 0;
                tmpSubsel = resultTotalList(idx, :);
                [~, idx] = min(tmpSubsel(:, 2));

                if (~isempty(idx))
                    ub = tmpSubsel(idx(1), 4);
                    disp([n(bppReq) ' bpp: Reuse ub: ' n(ub) ' corresponding to ' n(tmpSubsel(idx(1), 2)) ' bpp'])
                end

            end

            %                     %% Refine using resultTotalList, if possible
            %                     [minval, idx] = min(abs(resultTotalList(:, 2)-bppReq)/bppReq);
            %                     if(minval <= 0.15) % Use proximal lb, ub, if closer than 15%
            %
            %                     end
            %% Optimize
            [bppBest, snrBest, res] = surrogate_search(bppReq, ub, lb); % Multiple iteration surrogate search; fills resultTotalList
        end

        resultTotalList = [[res.resTab, repmat(dimLlong, [size(res.resTab, 1), 1])]; resultTotalList];

        %% If only logfile exists, redo computation
        if (~exist(res.temp_outfile, 'file'))
            [~, ~, res] = doRecomputeSingleIter(res.snrReq, bppReq, auxInfo);
        end

        %% Move result in place
        movefile(res.temp_outfile, auxInfo.tmpBitstreamFilenameBest)
        copyfile(strrep(res.temp_outfile, '.jpl', '.log'), strrep(auxInfo.tmpBitstreamFilenameBest, '.jpl', '.log'))
        %         try
        %             %delete(res.logfile)
        %             movefile(res.temp_outrawfile, out_rawfile)
        %         catch me
        %         end

        %% Remove all temporary jpl files
        fl = dir(fullfile(stashfold, '*.jpl'));
        fl = {fl.name};
        warning('off', 'MATLAB:DELETE:FileNotFound')

        for f = fl

            try
                delete(fullfile(stashfold, f{1}))
            catch me
            end

        end

        warning('on', 'MATLAB:DELETE:FileNotFound')

    end

    function [bppBest, snrBest, res] = doRecomputeSingleIter(distReq, bppReq, auxInfo)
        res = SURiter(distReq, bppReq, auxInfo.tmpInfile, auxInfo.tmpEnc_cfg, auxInfo.tmpHolo_cfg, encexe, stashfold);
        bppBest = res.bppAchieved;
        snrBest = res.snrAchieved;
        res.snrReq = distReq;
        res.resTab = [bppReq, bppBest, snrBest, distReq];
    end

    %     function bpp = compressDist(distReq)
    %         cmd = [encexe, ' -i ' auxInfo.tmpInfile ' -o ' auxInfo.tmpBitstreamFilename ...
    %        ' -e ' auxInfo.tmpEnc_cfg ' -c ' auxInfo.tmpHolo_cfg  ...
    %        ' -d ' num2str(distReq)]; % TODO: Fixme.. make into variable bpp once rate targets have been integrated
    %         [status, ~] = system(cmd, '-echo');
    %         if(status)
    %            warning(['Compression of ' auxInfo.tmpBitstreamFilename ' with ' auxInfo.tmpHolo_cfg ' failed at ' num2str(distReq) '.'])
    %         end
    % %         if(status) % Early exit for parallelization
    % %             dataHat = zeros(si(1:2));
    % %             bppAchieved = 0;
    % %             fsizebits = 0;
    % %             distAchieved = inf;
    % %             return;
    % %         end
    %         logfile = strrep(auxInfo.tmpBitstreamFilename, '.jpl', '.log');
    %         [bpp, distAchieved] = parse(logfile); % bpp == bpc
    %     end

    function [bppBest, snrBest, resultBest] = surrogate_search(bppReq, ub, lb)
        %% Prepare optimization
        problem = struct('solver', 'surrogateopt');
        problem.objective = @(dist) SURiter(dist, bppReq, auxInfo.tmpInfile, auxInfo.tmpEnc_cfg, auxInfo.tmpHolo_cfg, encexe, stashfold);

        %cpfile = fullfile(stashfold, num2str(bppReq, '%5.2fbpp.mat'));

        isFreshStart = isempty(ub) || isempty(lb);

        if (isFreshStart)
            maxstepsLoc = maxsteps * 5;
        else
            maxstepsLoc = maxsteps;
        end

        sver = version;

        if (contains(sver, 'R2020'))
            problem.options = optimoptions('surrogateopt', 'MaxFunctionEvaluations', maxstepsLoc, 'UseParallel', true, 'ObjectiveLimit', rateMatchPerc * bppReq); %,'CheckpointFile', cpfile
        else
            problem.options = optimoptions('surrogateopt', 'MaxFunctionEvaluations', maxstepsLoc, 'UseParallel', true, 'UseVectorized', false, 'ObjectiveLimit', rateMatchPerc * bppReq); %,'CheckpointFile', cpfile
        end

        if (isempty(lb))
            resLow = problem.objective(-20);
            problem.lb = max(0, resLow.snrAchieved);
        else
            problem.lb = lb;
        end

        if (isempty(ub))
            resHigh = problem.objective(100);
            highPerc = 0.6;

            problem.ub = highPerc * resHigh.snrAchieved;
        else
            problem.ub = ub;
        end

        if (isFreshStart)
            problem.InitialPoints = linspace(sqrt(problem.lb), sqrt(problem.ub), ceil(feature('numcores') * 1.3)) .^ 2;
        else
            problem.InitialPoints = linspace(problem.lb, problem.ub, ceil(feature('numcores') * 1.3));
        end

        %[snrReqBest, bestBppDelta, exitflag, optStruct, trials]  = surrogateopt(problem);
        [~, ~, ~, optStruct, trials] = surrogateopt(problem);

        %% Post proc
        % Either search through all logfiles or
        fl = dir(fullfile(stashfold, '*.log'));
        fl = {fl.name};
        resTab = zeros(numel(fl), 4);

        for fId = 1:numel(fl)
            [bpp, snr, snrReq] = parseFile(fullfile(stashfold, fl{fId}));
            resTab(fId, :) = [bppReq, bpp, snr, snrReq];
        end

        [~, idx] = min(abs(resTab(:, 2) - bppReq));
        idx = idx(1);
        bppBest = resTab(idx, 2);
        snrBest = resTab(idx, 3);
        snrReqBest = resTab(idx, 4);
        resultBest.logfile = fullfile(stashfold, fl{idx});
        resultBest.temp_outfile = strrep(resultBest.logfile, '.log', '.jpl');
        resultBest.temp_outrawfile = strrep(resultBest.logfile, '.log', 'dec.bin');
        resultBest.resTab = resTab;
        resultBest.snrReq = snrReqBest;
        resultBest.snrBest = snrBest;
        resultBest.bppBest = bppBest;

        % do one more run with snrReqBest
        % % Final iteration
        %resultBest = problem.objective(snrReqBest); % 1 iteration
        %bppBest = resBest.bppAchieved;
        %snrBest = resBest.snrReq;

        %         %% Find best result
        %         [~, idxBest] = min(abs(resultTotalList(:, 2)-bppReq));
        %         bppBest = resultTotalList(idxBest, 2);
        %         distReq = resultTotalList(idxBest, 4);
        %         if(bppBest > bppReq*1.05) % Safe guard to match 5%
        %             tmp = resultTotalList(:, 2);
        %             tmp(tmp>bppReq) = -inf;
        %             [~, idxBest] = max(tmp);
        %             distReq2 = resultTotalList(idxBest, 4);
        %             if(~isempty(distReq2))
        %                 distReq = distReq2;
        %             end
        %         end

        disp(num2str(['BS final solution in: ' n(optStruct.funccount), ' steps and ' n(optStruct.elapsedtime) ' s for bppReq: ' n(bppReq), ' is bpp: ' n(bppBest), ' with snr: ' n(snrBest)]))
        %disp(['Minimal bpp deviation found: ' num2str(bestBppDelta)])
        disp(optStruct.message)
        disp('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------')
    end

end
