clear;
clc;

isOctave = false;

tmain_degrade = tic();

try

    %% 0) Initialization
    %% 0.1) Set parameters

    testParams.compress = true;
    testParams.discardCompressedData = true;
    % ATTENTION:
    % Enable with caution. Will discard all previously gathered data in folder structure.
    % When replacing data of "original" DHs in place (without renaming) always enable.
    % Enable (at least for obj-plane compression) when modifying reference distances for object plane compression.

    testParams.SNRproposal = false;

    % Adapts dataset according to aggrement from 20.10.2021
    testParams.coreVerification = false;

    testParams.objTest = false;
    % Ensure that Hsubj is correctly set per dataset in holoread_PL.m
    testParams.subjTest = true;
    % Enable diffraction limited resizing for the subjective test; Attention: Need to specify Hsubj.targetRes!
    testParams.lowResSubjTest = false;
    % True: Only rate subj. test; False: Reconstruct + rate (should be default)
    testParams.subjTestRatingOnly = false;
    % Switches between nrsh and nrshVid in subjective test
    testParams.subjTestVideo = false;

    if (testParams.discardCompressedData && ~testParams.compress)
        error('main_degrade:insufficent_data', 'There will be no data to process. Either keep former cycles or compress new.'),
    end

    if ((testParams.objTest || testParams.subjTest) && isOctave)
        warning('main_degrade:ssim_octave', 'The original ssim implementation is not comparable with the proprietary Matlab implementation.'),
    end

    % Verification of core experiment settings
    if (testParams.SNRproposal ~= testParams.coreVerification)
        warning('main_degrade:core_experiment', 'testParams.SNRproposal was intended only for testParams.coreVerifications=true.'),
    end

    if ((~testParams.objTest || ~testParams.subjTest) && testParams.coreVerification)
        testParams.objTest = true;
        testParams.subjTest = true;
        warning('main_degrade:core_experiment', 'Automatically enabled restricted objective and subjective test.'),
    end

    if (~testParams.lowResSubjTest && testParams.coreVerification)
        testParams.lowResSubjTest = true;
        warning('main_degrade:core_experiment', 'Automatically enabled testParams.lowResSubjTest.'),
    end

    if (testParams.subjTestVideo && testParams.coreVerification)
        testParams.subjTestVideo = false;
        warning('main_degrade:core_experiment', 'Automatically disabled testParams.subjTestVideo.'),
    end

    disp(testParams)

    %% 0.2) Quantization description
    % Don't touch - start
    L = 2 ^ 16; % because of 16bit intermediate representation of anchor codec input
    quantmethod = 'MRQ';
    optmethod = 'Hybrid';
    % Don't touch - end

    %% 1) Configure test
    %% 1.1a) Specify bitrates to be tested
    % Don't modify - start
    %bitrates for the objective QA, set based on table 6 in the CTC document:
    RA1 = [0.1 0.25 0.5 1 2 4];
    RA3 = [0.3 0.75 1.5 3 6 12];
    % Don't modify - end

    %% 1.1b) Don't Modify - Start
    % bitrates for the subjective QA, set based on table 7 in the CTC document:
    RAsubj = {{'DeepCornellBox_16k', [0.1 0.5 2]}, ...
               {'DeepDices2k', [0.75 3 12]}, ...
                   {'Lowiczanka_doll', [0.75 3 6]}, ...
                   {'Astronaut', [0.1 0.25 0.5]}, ...
                   {'DeepChess', [0.1 0.5 2]}, ...
                   {'Biplane16k-1', [0.3 1.5 6]}, ...
                   {'Dices16k', [0.3 1.5 6]}, ...
                   {'Piano16k', [0.3 1.5 6]} ...
               };

    % distortions for proposal for the core experiments, set based on table xx in the CTC document:
    SNRceL = {{'DeepCornellBox_16k', [2.45, 5.02, 8.45, 14.19, 22.64, 32.13]}, ...
               {'DeepDices2k', [0.71, 1.74, 2.71, 5.19, 8.66, 15.55]}, ...
                   {'Lowiczanka_doll', [2.08, 3.85, 6.19, 12.32, 14.98, 30.04]}, ...
                   {'Astronaut', [3.32, 6.37, 10.46, 14.59, 18.82, 25.95]}, ...
                   {'DeepChess', [1.80, 3.22, 6.31, 12.95, 20.73, 28.33]}, ...
                   {'Dices4k', [2.12, 4.66, 7.31, 12.08, 19.35, 28.19]}, ...
                   {'Piano16kR', [3.50, 8.11, 14.54, 21.54, 27.19, 35.59]} ...
               };
    % Dont't modify - End

    %% 1.2) Specify codecs to be tested (implemented in Pipeline_Compress)
    % will be processed in obj + holo plane
    distLanchors = {'hm', 'j2k'};

    distLextra = {'interfere'}; % {'proponentTemplate'}; % will be processed in holo plane only
    % distL = [distLanchors, distLextra];
    distL = distLextra;
    if (testParams.SNRproposal && (numel(distL) > 1 || ~strcmp(distL{1}, 'interfere'))), error('main_degrade:invalid_configuration', 'doSNR = true may only be used for the interfere codec alone. Set distL = {''interfere''}!'), end

    %% 1.3) Set paths
    scriptPath = matlab.desktop.editor.getActiveFilename;
    tmp = strsplit(scriptPath, filesep);
    tmp = tmp{end};
    scriptPath = strrep(scriptPath, tmp, '');
    clear tmp;

    %Add nrsh base path
    addpath(genpath(fullfile(scriptPath, '../nrsh')))

    % Main inputs
    % Specify location of folder containing input holograms
    Folders.holofolder = '../res/holograms';

    % Specify location of NRSH config file location
    Folders.nrshfolder = fullfile(scriptPath, '../nrsh/config_files');

    % Specify location of HM executable
    Folders.codecfolder = fullfile(scriptPath, '../codecs');

    % Specify location for already encoded inputs, in case of doDecompression only
    Folders.encfolder = '../res/output/Rating_EncData';

    % Specify location for interfere holo_config files.
    Folders.interfereCfg = fullfile(scriptPath, 'InterfereCodecCfg');

    tmpfold = '../res/tmp';

    %Specify location of result
    plenofolder = fullfile('../res/output/Rating_OutData');

    % NRSH output folder for *distorted* reconstructions
    Folders.nrshOutFolderDist = fullfile(plenofolder, 'NrshOut');

    %Specify outer foldername of result, used as plenofolder/Outerfoldername
    Outerfoldername = 'JPEG_Pleno_ETRO';
    count = 1;

    %% 1.4) Uncomment filename(s) to be tested

    holofile(count).strng = 'DeepDices2K.mat';
    fragmentplenofolder2(count).strng = 'DeepDices2k';
    count = count + 1;

    if (testParams.coreVerification)
        count = 1;
        clear holofile;

        holofile(count).strng = 'Piano16KR.mat';
        fragmentplenofolder2(count).strng = 'Piano16kR';
        count = count + 1;

        holofile(count).strng = 'DeepDices2K.mat';
        fragmentplenofolder2(count).strng = 'DeepDices2k';
        count = count + 1;

        holofile(count).strng = 'Astronaut_Hol_v2.mat';
        fragmentplenofolder2(count).strng = 'Astronaut';
        count = count + 1;

        holofile(count).strng = 'Dices4K.mat';
        fragmentplenofolder2(count).strng = 'Dices4k';
        count = count + 1;

        holofile(count).strng = 'DeepChess.mat';
        fragmentplenofolder2(count).strng = 'DeepChess';
        count = count + 1;

        holofile(count).strng = 'DeepCornellBox_16K.mat';
        fragmentplenofolder2(count).strng = 'DeepCornellBox_16k';
        count = count + 1;

        holofile(count).strng = 'opt_Warsaw_Lowiczanka_Doll.mat';
        fragmentplenofolder2(count).strng = 'Lowiczanka_doll';
        count = count + 1;
    end

    %% Start the work
    distL = distL(:).';

    for j = 1:size(holofile, 2)
        %% 2) Setup up ground truth of chosen hologram
        %% 2.1) Set folder paths
        Folders.holoname = fragmentplenofolder2(j).strng;
        Folders.holofile = holofile(j).strng;
        Folders.plenofolder = fullfile(plenofolder, Outerfoldername, fragmentplenofolder2(j).strng);
        makefolder(Folders.plenofolder)
        Folders.esfolder = fullfile(Folders.plenofolder, 'plots');
        disp(['Processing ' Folders.holofile '...'])
        tLocHologram = tic();

        %% 2.2) Discard unquantized GT & TestCFG data & move metrics.mat
        if (testParams.discardCompressedData)
            fnameL = {fullfile(Folders.plenofolder, 'input.mat')};
            if (testParams.objTest), fnameL = [fnameL, {fullfile(Folders.plenofolder, 'CfgObjTest.mat')}]; end
            if (testParams.subjTest), fnameL = [fnameL, {fullfile(Folders.plenofolder, 'CfgSubjTest.mat')}]; end

            warning('off', 'MATLAB:DELETE:FileNotFound')

            for fnameC = fnameL

                try
                    fname = fnameC{1};
                    delete(fname)
                    disp([fname ' successfully deleted.'])
                catch me
                end

            end

            warning('on', 'MATLAB:DELETE:FileNotFound')

            try
                fname = fullfile(Folders.plenofolder, 'Metrics.mat');
                movefile(fname, strrep(fname, 'Metrics.mat', 'Metrics.old.mat'))
                disp([fname ' successfully moved to ' strrep(fname, 'Metrics.mat', 'Metrics.old.mat') '.'])
            catch me
            end

            clear fnameL fnameC fname;
        end

        %% 2.3) Read file from database
        [X, H] = holoread_PL(Folders);
        si = size(X);
        si(3) = size(X, 3);
        save(fullfile(Folders.plenofolder, 'CfgObjTest.mat'), 'H');
        clear M cminObjT cmaxObjT cminSubjT cmaxSubjT;

        %% 2.4) Assign bitrate depending on number of color channels + test configuration
        if (testParams.SNRproposal && testParams.coreVerification)
            RA = [];

            % Lookup core experiment target distortions
            idx = cellfun(@(x) strcmpi(x{1}, fragmentplenofolder2(j).strng), SNRceL);

            if (isempty(idx) || all(idx == 0))
                error('main_degrade:invalid_ce_dataset', ['The DH ''' fragmentplenofolder2(j).strng ''' is not part of the core experiment test. Please either comment dataset out or set testParams.coreVerification = false.'])
            end

            SNRceLoc = SNRceL{idx}{2};
        else
            if (si(3) == 1), RA = RA1; else, RA = RA3; end

            if (testParams.subjTest)
                % Lookup subjective test bitrates
                idx = cellfun(@(x) strcmpi(x{1}, fragmentplenofolder2(j).strng), RAsubj);

                if (isempty(idx) || all(idx == 0))
                    error('main_degrade:invalid_subj_dataset', ['The DH ''' fragmentplenofolder2(j).strng ''' is not part of the subjective test. Please either comment dataset out or set testParams.subjTest = false.'])
                end

                RAsubjLoc = RAsubj{idx}{2};

                if (testParams.objTest)
                    RA = unique([RA, RAsubjLoc]); % Combine subj. and obj. test bitrates
                else
                    RA = RAsubjLoc; % Replace obj. test bitrates with subj. test bitrates
                end

            end

            SNRceLoc = [];
        end

        %% Do the work
        % Pipeline fork 1 - Hologram plane compression -------------------------------------------
        % Pipeline fork 2 - Object plane compression ---------------------------------------------
        planeList = {'holo', 'obj'};
        if (testParams.SNRproposal && testParams.coreVerification), planeList = {'holo'}; end

        for planeC = planeList
            % Obj plane will be automatically skipped for non-anchor codecs, by modification of distLrun
            plane = planeC{1};
            Folders.forkfolder = fullfile(Folders.plenofolder, [plane 'Plane']);

            if (testParams.discardCompressedData)
                %% Clean up temporary files
                warning('off', 'MATLAB:DELETE:FileNotFound')

                for distC = distL
                    folder = fullfile(Folders.plenofolder, [plane 'Plane'], cell2mat(distC));

                    try
                        rmdir(folder, 's');
                        disp([folder ' successfully deleted.'])
                    catch me
                    end

                end

                folder = fullfile(Folders.plenofolder, [plane 'Plane'], 'temp');

                try
                    rmdir(folder, 's');
                catch me
                end

                disp([folder ' successfully deleted.'])

                try
                    delete(fullfile(Folders.plenofolder, [plane 'Plane'], 'quantref.mat'))
                catch me
                end

                warning('on', 'MATLAB:DELETE:FileNotFound')

                for ii = 1:2, disp(" "), end
            end

            try
                mkdir(Folders.forkfolder)
            catch me
            end

            disp(['Processing ' Folders.holofile ' in ' plane ' plane...'])
            tLocPlane = tic();

            %% 3) Compression
            %% 3.0) Load QPN/Bitrate maps from last compression cycle, if possible
            % if (exist(fullfile(Folders.plenofolder, 'Metrics.mat'), 'file'))
            %     datTmp = load(fullfile(Folders.plenofolder, 'Metrics.mat'), 'M', 'RA', 'H');
            %     M = datTmp.M;
            %
            % check, if all requested bitrates/distortions have been previously compressed
            %     if (~isempty(setdiff(RA, datTmp.RA)) && ~isempty(setdiff(fieldnames(M.(plane)), distL)) && ~testParams.compress)
            %         error('main_degrade:invalid_mode', 'Compression required, as new bitrates are requested.')
            %     end
            % end

            if (~exist('M', 'var'))
                M = struct();
            end

            if (testParams.compress)

                if (~isfield(M, plane))
                    M.(plane) = struct();
                end

                %% 3.0) Check quick exit: Skip object plane for non-anchors
                distLrun = distL;

                if (strcmpi(plane, 'obj'))
                    distLrun = intersect(distL, distLanchors);
                end

                %% 3.1) Load X if not already loaded (could be unloaded by subjTest in previous compression plane)
                if (~exist('X', 'var'))
                    [X, ~] = holoread_PL(Folders);
                end

                %% 3.2) Propagate to object plane evtl.
                if (strcmpi(plane, 'holo'))
                    Xmod = X;
                else
                    % Faciliate: nopad approach for anchors, see wg1m89073
                    zeropad = false;
                    info = getSettings('dataset', H.dataset, 'zero_pad', zeropad, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'usagemode', 'complex', 'direction', 'forward');
                    Xmod = nrsh(X, H.obj_dist, info);
                end

                %% 3.3) Quantize data + write quantized data to HDD
                if (~isempty(intersect(distL, distLanchors)) && (~exist(fullfile(Folders.plenofolder, ['QuantInfo_' plane 'Plane.mat']), 'file') || ~exist(fullfile(Folders.forkfolder, 'quantref.mat'), 'file')))

                    [Q, Xmod, Xpoi] = Quantize_PL(Xmod, L, quantmethod, optmethod);
                    save(fullfile(Folders.plenofolder, ['QuantInfo_' plane 'Plane.mat']), 'Xpoi', 'quantmethod', 'optmethod', 'L');

                    % Write quanitzed data, as input for compress functions
                    Quarefwrite_PL(Q, Xmod, Xpoi, L, quantmethod, Folders);

                    clear Q Xmod Xpoi;
                end

                %% 3.4) Compress
                M.(plane) = Pipeline_Compress(Folders, RA, distLrun, M.(plane), SNRceLoc, testParams.coreVerification);
                disp(['  Compression done in ' num2str(toc(tLocPlane)), ' s.'])

                %% 3.4) Save results (QPN/Bitrate map)
                save(fullfile(Folders.plenofolder, 'Metrics.mat'), '-v6', 'M', 'RA', 'H', 'distL', 'distLanchors');
            else
                distLtmp = fieldnames(M.(plane));

                for distC = distL(:).'
                    isAnchor = ~isempty(intersect(distLanchors, distC));
                    if (~isAnchor && strcmpi(plane, 'obj')), continue, end

                    if (sum(strcmpi(distLtmp, distC)) == 0)
                        error('main_degrade:compression_skip', [Folders.holofile ' was not compressed with ' distC{1} ' in ' plane ' plane. Need to enable compress on next run.'])
                    end

                end

            end

            %% 4) Perform objective test reconstruction, if enabled
            if (testParams.objTest)
                disp(['Processing ' Folders.holofile ' in ' plane ' plane - Objective Test - ...'])
                tLocObj = tic();

                Hobj = H;
                Hobj.doDynamic = false;

                %% Specify objective test viewpoints.
                % Modify "Hobj" here, if same viewpoints should be tested/reconstructed for all datasets.
                %             Hobj.rec_dists = Hobj.rec_dists;
                %             % Hobj.rec_dists = Hobj.rec_dists(round(end/2));
                %             Hobj.h_pos = [0, 1];
                %             Hobj.v_pos = [0, 1];
                %             Hobj.ap_sizes = {[size(X(:,:,1))/2]};
                %% End "Hobj" mofiy

                if (~exist('X', 'var')), X = holoread_PL(Folders); end

                %% 4.1) Reconstruct ground truth for cmin, cmax
                info = getSettings('dataset', Hobj.dataset, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'name_prefix', ['ObjTest_' plane '_GT_'], 'outfolderpath', Folders.nrshOutFolderDist);

                if (~testParams.coreVerification)
                    [~, cminObjT.(plane), cmaxObjT.(plane)] = nrsh(X, Hobj.rec_dists, info, usagemodeFun(Hobj.doDynamic), Hobj.ap_sizes, Hobj.h_pos, Hobj.v_pos);
                    %              load(fullfile(Folders.plenofolder, 'CfgSubjTest.mat'), 'cminSubjT', 'cmaxSubjT');
                    %              cminObjT = cminSubjT;
                    %              cmaxObjT = cmaxSubjT;
                else
                    cminObjT.(plane) = [];
                    cmaxObjT.(plane) = [];
                end

                save(fullfile(Folders.plenofolder, 'CfgObjTest.mat'), '-v6', 'cminObjT', 'cmaxObjT', 'Hobj', 'H');

                %% 4.2) Get quantized ground truth into memory, if anchor is present
                if (~isempty(intersect(distL, distLanchors)))
                    fname = fullfile(Folders.forkfolder, 'quantref.mat');
                    %% 4.2.a) Load quantized ground truth
                    if (exist(fname, 'file'))
                        Xqref = load(fname, 'Xqref');
                        Xqref = Xqref.Xqref;
                    else
                        %% 4.2.b) Redo quantization

                        %% 4.2.b.1) Propagate to object plane evtl.
                        if (strcmpi(plane, 'holo'))
                            Xmod = X;
                        else
                            zeropad = false; % Faciliate: nopad approach for anchors, see wg1m89073
                            info = getSettings('dataset', H.dataset, 'zero_pad', zeropad, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'usagemode', 'complex', 'direction', 'forward');
                            Xmod = nrsh(X, H.obj_dist, info);
                        end

                        fname = fullfile(Folders.plenofolder, ['QuantInfo_' plane 'Plane.mat']);

                        if (exist(fname, 'file'))
                            %% 4.2.b.1a) Redo quantization exactly using prior optimal clipping points
                            disp(['Objective testing: loaded quantization information from ' fname ' to redo quantization exactly.'])
                            load(fname, 'Xpoi', 'quantmethod', 'L');
                            [~, Xqref] = Quantize_PL(Xmod, L, quantmethod, Xpoi);
                        else
                            %% 4.2.b.1b) Redo quantization by recalculating optimal clipping points before
                            disp(['Objective testing: could not load quantization information from ' fname '. Redo quantization optimization.'])
                            [~, Xqref, Xpoi] = Quantize_PL(Xmod, L, quantmethod, optmethod);
                            save(fullfile(Folders.plenofolder, ['QuantInfo_' plane 'Plane.mat']), 'Xpoi', 'quantmethod', 'optmethod', 'L');
                        end

                        clear Xmod;
                    end

                    %% 4.3) Reconstruct quantized ground truth + BP quantized GT
                    info = getSettings('dataset', H.dataset, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'name_prefix', ['ObjTest_' plane '_GT16bit_'], 'outfolderpath', Folders.nrshOutFolderDist);

                    if (strcmpi(plane, 'obj'))
                        zeropad = false; % Faciliate: nopad approach for anchors, see wg1m89073
                        infoComplex = getSettings('dataset', H.dataset, 'zero_pad', zeropad, 'cfg_file', fullfile(Folders.nrshfolder, H.cfg_file), 'usagemode', 'complex', 'direction', 'inverse');

                        Xqref = nrsh(Xqref, H.obj_dist, infoComplex); % Propagate quantized GT from obj to holo plane
                        clear infoComplex;

                        if (~testParams.coreVerification)
                            nrsh(Xqref, Hobj.rec_dists, info, usagemodeFun(Hobj.doDynamic), Hobj.ap_sizes, Hobj.h_pos, Hobj.v_pos, cminObjT.(plane), cmaxObjT.(plane));
                        end

                    else

                        if (~testParams.coreVerification)
                            nrsh(Xqref, Hobj.rec_dists, info, usagemodeFun(Hobj.doDynamic), Hobj.ap_sizes, Hobj.h_pos, Hobj.v_pos, cminObjT.(plane), cmaxObjT.(plane));
                        end

                    end

                else
                    Xqref = [];
                end

                %% 4.4) Rate
                M.(plane) = ObjEvaluateCompressedHolograms(Folders, M.(plane), Hobj, X, Xqref, si, cminObjT.(plane), cmaxObjT.(plane), plane, distL, distLanchors, testParams.coreVerification);

                %% 4.5) Save results (QPN/Bitrate map + Rating Scores)
                save(fullfile(Folders.plenofolder, ['Metrics.mat']), '-v6', 'M', 'RA', 'distL', 'distLanchors');

                disp(['Processing ' Folders.holofile ' in ' plane ' plane - Objective Test - done in ' num2str(toc(tLocObj)), ' s.'])
            end

            %% 5) Perform subjective test, if enabled
            if (testParams.subjTest)
                disp(['Processing ' Folders.holofile ' in ' plane ' plane - Subjective Test - ...'])
                tLocSubj = tic();

                Hsubj = H.Hsubj;
                Hsubj.doLowResolution = testParams.lowResSubjTest;
                Hsubj.doDynamic = testParams.subjTestVideo;
                Hsubj.doIndividual = true; % By default only explicitly specified viewpoints should be reconstructed

                %% Modify "Hsubj" here, if same viewpoints/options should be set for all datasets. Otherwise, modify Hsubj in holoread_PL.m.
                Hsubj.fps = 10;
                %             nframes = 5;
                %             Hsubj.rec_dists = linspace(Hsubj.rec_dists(1), Hsubj.rec_dists(2), nframes);
                %             Hsubj.rec_dists = Hsubj.rec_dists(round(end/2));

                %             [AperX,AperY,RecZ] = ScanpathGen(Hsubj.rec_dists,fragmentplenofolder2(1).strng,Hsubj.doDynamic);
                %             Hsubj.rec_dists = RecZ;
                %             Hsubj.h_pos = AperX;
                %             Hsubj.v_pos = AperY;

                % Either leave targetRes empty or ap_sizes empty. If both are specified, targetRes will become the objective for low_resolution reconstruction.
                Hsubj.targetRes = 2028 * [1, 1]; % Target resolution for the subjective test
                Hsubj.ap_sizes = [];
                %             %set the aperture size for holograms which does not require LR
                %             %mode
                %                 Hsubj.ap_sizes = repmat({2028*[1,1]},1,numel(AperX));
                %% End "Hsubj" mofiy

                if (~(testParams.SNRproposal && testParams.coreVerification))
                    bitrateL = RAsubj{cellfun(@(x) strcmp(x{1}, Folders.holoname), RAsubj)};
                    Hsubj.bitrateL = bitrateL{2};
                    clear bitrateL;
                end

                %% 5.0) Load QPN/Bitrate maps from last subjTest cycle, if possible
                if (exist(fullfile(Folders.plenofolder, 'MetricsSubj.mat'), 'file'))
                    datTmp = load(fullfile(Folders.plenofolder, 'MetricsSubj.mat'), 'Msubj');

                    Msubj = datTmp.Msubj;

                    if (testParams.subjTestRatingOnly)
                        datTmp = load(fullfile(Folders.plenofolder, 'MetricsSubj.mat'), 'cminSubjT', 'cmaxSubjT');
                        cminSubjT = datTmp.cminSubjT; cmaxSubjT = datTmp.cmaxSubjT;
                    end

                end

                if (~exist('Msubj', 'var'))
                    Msubj = struct();

                    if (testParams.subjTestRatingOnly)
                        cminSubjT = [];
                        cmaxSubjT = [];
                    end

                end

                %% 5.1) Reconstruct ground truth for cmin, cmax
                info = getSettings('dataset', Hsubj.dataset, 'cfg_file', fullfile(Folders.nrshfolder, Hsubj.cfg_file), 'outfolderpath', Folders.nrshOutFolderDist, ...
                'name_prefix', ['SubjTest_' plane '_GT_'], 'resize_fun', '');
                if (isfield(Hsubj, 'ap_sizes')), info = getSettings(info, 'ap_sizes', Hsubj.ap_sizes); end
                if (isfield(Hsubj, 'fps')), info = getSettings(info, 'fps', Hsubj.fps); end

                if (Hsubj.doLowResolution)
                    info = getSettings(info, 'resize_fun', 'dr');
                    info = getSettings(info, 'targetres', Hsubj.targetRes);
                end

                if (~exist('X', 'var')), X = holoread_PL(Folders); end
                Hsubj.size = size(X);

                if (~testParams.subjTestRatingOnly)
                    [~, cminSubjT.(plane), cmaxSubjT.(plane)] = nrsh(X, Hsubj.rec_dists, info, usagemodeFun(Hsubj.doDynamic, Hsubj.doIndividual), ...
                        [], Hsubj.h_pos, Hsubj.v_pos);
                    save(fullfile(Folders.plenofolder, 'CfgSubjTest.mat'), 'cminSubjT', 'cmaxSubjT', 'Hsubj', 'H');

                    %% 5.2) Get quantized ground truth into memory, if anchor is present
                    if (~isempty(intersect(distL, distLanchors)))
                        fname = fullfile(Folders.forkfolder, 'quantref.mat');
                        %% 5.2.a) Load quantized ground truth
                        if (exist(fname, 'file'))
                            X = load(fname, 'Xqref');
                            X = X.Xqref;
                        else
                            %% 5.2.b) Redo quantization

                            %% 5.2.b.1) Propagate to object plane evtl.
                            if (~strcmpi(plane, 'holo'))
                                zeropad = false; % Faciliate: nopad approach for anchors, see wg1m89073
                                info = getSettings('dataset', Hsubj.dataset, 'zero_pad', zeropad, 'cfg_file', fullfile(Folders.nrshfolder, Hsubj.cfg_file), 'usagemode', 'complex', 'direction', 'forward');
                                X = nrsh(X, Hsubj.obj_dist, info);
                            end

                            fname = fullfile(Folders.plenofolder, ['QuantInfo_' plane 'Plane.mat']);

                            if (exist(fname, 'file'))
                                %% 5.2.b.1a) Redo quantization exactly using prior optimal clipping points
                                disp(['Objective testing: loaded quantization information from ' fname ' to redo quantization exactly.'])
                                load(fname, 'Xpoi', 'quantmethod', 'L');
                                [~, X] = Quantize_PL(X, L, quantmethod, Xpoi);
                            else
                                %% 5.2.b.1b) Redo quantization by recalculating optimal clipping points before
                                disp(['Objective testing: could not load quantization information from ' fname '. Redo quantization optimization.'])
                                [~, X, Xpoi] = Quantize_PL(X, L, quantmethod, optmethod);
                                save(fullfile(Folders.plenofolder, ['QuantInfo_' plane 'Plane.mat']), 'Xpoi', 'quantmethod', 'optmethod', 'L');
                            end

                        end

                        %% 5.3) Reconstruct quantized ground truth + BP quantized GT
                        info = getSettings('dataset', Hsubj.dataset, 'cfg_file', fullfile(Folders.nrshfolder, Hsubj.cfg_file), 'name_prefix', ['SubjTest_' plane '_GT16bit_'], 'outfolderpath', Folders.nrshOutFolderDist, 'resize_fun', '');

                        if (isfield(Hsubj, 'ap_sizes')), info = getSettings(info, 'ap_sizes', Hsubj.ap_sizes); end
                        if (isfield(Hsubj, 'fps')), info = getSettings(info, 'fps', Hsubj.fps); end

                        if (Hsubj.doLowResolution)
                            info = getSettings(info, 'resize_fun', 'dr');
                            info = getSettings(info, 'targetres', Hsubj.targetRes);
                        end

                        if (strcmpi(plane, 'obj'))
                            zeropad = false; % Faciliate: nopad approach for anchors, see wg1m89073
                            infoComplex = getSettings('dataset', Hsubj.dataset, 'zero_pad', zeropad, 'cfg_file', fullfile(Folders.nrshfolder, Hsubj.cfg_file), 'usagemode', 'complex', 'direction', 'inverse');

                            X = nrsh(X, Hsubj.obj_dist, infoComplex); % Propagate quantized GT from obj to holo plane
                            nrsh(X, Hsubj.rec_dists, info, usagemodeFun(Hsubj.doDynamic, Hsubj.doIndividual), Hsubj.ap_sizes, Hsubj.h_pos, Hsubj.v_pos, cminSubjT.(plane), cmaxSubjT.(plane));
                        else
                            nrsh(X, Hsubj.rec_dists, info, usagemodeFun(Hsubj.doDynamic, Hsubj.doIndividual), Hsubj.ap_sizes, Hsubj.h_pos, Hsubj.v_pos, cminSubjT.(plane), cmaxSubjT.(plane));
                        end

                        clear X;
                    else
                        clear X;
                    end

                end

                %% 5.4) Load Mobj==M, if not existent
                % Need to load Mobj eventually / used for obtaining bitrateMap per plane and dist and distL
                if (~exist('M', 'var'))
                    Mtmp = load(fullfile(Folders.plenofolder, 'Metrics.mat'), 'M');
                    M = Mtmp.M;
                    clear Mtmp;
                end

                %% 5.5) Reconstruct all compressed versions
                if (testParams.SNRproposal)
                    subjTargetL = M.holo.interfere.bitrateMap{:, 1};

                    if (istable(subjTargetL))
                        subjTargetL = subjTargetL.Variables;
                    end

                    Hsubj.subjTargetL = subjTargetL;
                else %if(~testParams.SNRproposal)
                    bitrateL = RAsubj{cellfun(@(x) strcmp(x{1}, Folders.holoname), RAsubj)};
                    subjTargetL = bitrateL;

                    Hsubj.bitrateL = bitrateL{2};
                end

                Msubj.(plane) = ST_RenderCompressedHolograms(Folders, M.(plane), Hsubj, si, cminSubjT.(plane), cmaxSubjT.(plane), plane, Hsubj.doLowResolution, distL, distLanchors, subjTargetL, testParams.subjTestRatingOnly, testParams.coreVerification);

                %% 5.5) Save results (QPN/Bitrate map + Rating Scores)
                save(fullfile(Folders.plenofolder, ['MetricsSubj.mat']), '-v6', 'Msubj', 'cminSubjT', 'cmaxSubjT', 'Hsubj', 'distL', 'distLanchors');
                disp(['Processing ' Folders.holofile ' in ' plane ' plane - Subjective Test - done in ' num2str(toc(tLocSubj)), ' s.'])
            end

            %% 6.1) Clean up
            try
                fname = fullfile(Folders.forkfolder, 'quantref.mat');
                if (exist(fname, 'file')), delete(fname); end

                for distC = distL
                    fname = fullfile(Folders.forkfolder, distC{1}, '*bitrateMap_interim.mat');
                    if (exist(fname, 'file')), delete(fname); end
                end

            catch me
                disp('Cleanup of some temporary data (quantref.mat, *bitrateMap_interim.mat) failed.')
            end

            disp(['Processing ' Folders.holofile ' in ' plane ' plane done in ' num2str(toc(tLocPlane)), ' s.'])
        end

        %% 6.2) Clean up
        try
            fname = fullfile(Folders.plenofolder, 'input.mat');
            if (exist(fname, 'file')), delete(fname); end
        catch me
            disp('Cleanup of some temporary data (input.mat) failed.')
        end

        disp(['Processing ' Folders.holofile ' in ' plane ' plane done in ' num2str(toc(tLocHologram)), ' s.'])
        for ii = 1:10, disp(" "), end
    end

catch me
    disp(['Crashed after ' num2str(toc(tmain_degrade)), ' s with...'])
    rethrow(me)
end

disp(['Finished after ' num2str(toc(tmain_degrade)), ' s.'])
