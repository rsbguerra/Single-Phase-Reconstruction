function res = SURiter(distortionTarget, bppReq, holorawfile, enc_configfile, holo_configfile, codecexe, stashfold)
    id = randi(2 ^ 53 - 1);
    outfile = fullfile(stashfold, [num2str(id, '%016.0f') '.jpl']);

    while (isFiles(id))
        id = randi(2 ^ 53 - 1);
        outfile = fullfile(stashfold, [num2str(id, '%016.0f') '.jpl']);
    end

    touch(outfile); % Touch to reserve the spot
    outrawfile = [fullfile(stashfold, [num2str(id, '%016.0f') 'dec.bin'])];

    cmd = [codecexe, ' -i ' holorawfile ' -o ' outfile ...
               ' -e ' enc_configfile ' -c ' holo_configfile ...
               ' -d ' num2str(distortionTarget)];
    [status, ~] = system(cmd, '-echo');

    if (status)
        warning([holorawfile ' with ' holo_configfile ' failed.'])
    end

    logfile = strrep(outfile, '.jpl', '.log');
    [bpp, snr] = parse();
    %     appendDistReq();

    %movefile(logfile, fullfile(currentholofolder, ['stash_' num2str(bppReq, '%05.2f')], [num2str(bpp, '%5.3fbpp_') num2str(id, '%016.0f.log')]));
    %movefile(outfile, fullfile(currentholofolder, ['stash_' num2str(bppReq, '%05.2f')], [num2str(bpp, '%5.3fbpp_') num2str(id, '%016.0f.bin')]));

    Fval = abs(bpp - bppReq); % Simple to enforce 5 % bound
    res = struct('Fval', Fval, 'bppAchieved', bpp, 'snrAchieved', snr, ...
        'snrReq', distortionTarget, 'id', id, 'temp_outfile', outfile, 'temp_outrawfile', ...
        outrawfile, 'logfile', logfile);

    %     function appendDistReq()
    %         fid = fopen(logfile, 'a');
    %         try
    %             fprintf(fid, 'DistortionReq : %f\n', distortionTarget);
    %         catch me
    %         end
    %         if(fid > 0), fclose(fid); end
    %     end

    function touch(fname)
        fid = fopen(fname, 'w');
        if (fid > 0), fclose(fid); end
    end

    function res2 = isFiles(id)
        fl = dir(fullfile(stashfold, '*.jpl'));
        fl = {fl.name};
        fl = cellfun(@(x) uint64(str2double(strrep(x, '.jpl', ''))), fl);
        res2 = any(fl == id);
    end

    function [bpp, snr] = parse()
        fid = fopen(logfile, 'r');

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
        %         buf = readlines(logfile);
        %         bpp = strsplit(buf(1), ':');
        %         bpp = str2double(bpp{2});
        %         snr = strsplit(buf(2), ':');
        %         snr = str2double(snr{2});
    end

end
