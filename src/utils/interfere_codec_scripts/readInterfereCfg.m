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

function res = parseNumbers(str)
    str = strsplit(str, ':');
    str = strrep(strrep(str{2}, '[', ''), ']', '');
    str = strsplit(str, ',');
    res = zeros(1, numel(str));

    for ii = 1:numel(str)
        res(ii) = str2double(str{ii});
    end

end
