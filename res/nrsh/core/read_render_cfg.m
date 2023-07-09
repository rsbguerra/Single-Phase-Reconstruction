function info = read_render_cfg(info)
    %READ_RENDER_CFG Reads rendering parameters from configuration file
    %    info       - Rendering parameters structure
    %


    % Valid field names
    validFieldnameNum = {'wlen', 'pixel_pitch', 'apod', 'zero_pad', ...
                         'perc_clip', 'perc_value', 'hist_stretch', ...
                             'save_intensity', 'save_as_mat', 'save_as_image', ...
                             'show', 'bit_depth', 'reffronorm', ...
                             'ref_wave_rad', 'dc_filter_size', ...
                             'shift_yx_r', 'shift_yx_g', 'shift_yx_b', ...
                             'segmentsnum', 'segmentsres', 'subsegmentsres', ...
                         'spectrumscale'}; %To be completed.
    validFieldnameStr = {'method', 'dc_filter_type', 'img_flt', ...
                             'hologramname', 'format', 'offaxisfilter'}; %To be completed.
    validFieldnameList = [validFieldnameNum, validFieldnameStr];
    printFieldnameList = [cell2mat(cellfun(@(x) [x, ', '], validFieldnameList(1:end - 1), 'UniformOutput', false)), validFieldnameList{end}];

    % Layman's check for octave compatible mode
    isOctave = false;

    try
        a = datetime; clear a;
        contains('abc', 'a');
        isOctave = false;
    catch me
        pkg load signal;
        isOctave = true;
    end

    info.isOctave = isOctave;

    % Data loading from file
    if isfield(info, 'cfg_file')
        % Open file
        fid = fopen(strrep(info.cfg_file, '\', '/'));

        if fid < 0
            error('nrsh:cfg_file', ['Error in nrsh: cannot open rendering configuration file ' strrep(info.cfg_file, '\', '/')])
        end

        % Parse file
        while ~feof(fid)
            line = strtrim(fgetl(fid));

            if ~isempty(line) && ~all(isspace(line)) && ~strncmp(line, '#', 1)
                key_value = regexp(line(~isspace(line)), ':', 'split');
                fieldname = lower(key_value{1});

                if ((~isOctave && any(contains(validFieldnameNum, fieldname))) || (isOctave && any(~cellfun('isempty', strfind(validFieldnameNum, fieldname)))))

                    if (~isfield(info, fieldname))
                        info.(fieldname) = str2num(key_value{2});
                    end

                elseif ((~isOctave && any(contains(validFieldnameStr, fieldname))) || (isOctave && any(~cellfun('isempty', strfind(validFieldnameStr, fieldname)))))

                    if (~isfield(info, fieldname))
                        info.(fieldname) = key_value{2};
                    end

                else
                    warning('nrsh:cfg_file:input_skipped', ['Warning in nrsh: ' fieldname ' is not a valid field name. Valid field names are: ' printFieldnameList])
                end

            end

        end

        % Close file
        fclose(fid);
    end

end
