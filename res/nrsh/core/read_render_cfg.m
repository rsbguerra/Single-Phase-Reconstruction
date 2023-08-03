function [recons_param] = read_render_cfg(cfg_path, dataset)
    %READ_RENDER_CFG Reads rendering parameters from configuration file
    %
    %   Inputs:
    %    cfg               - path to configuration file
    %
    %   Output:
    %    recons_param      - Matlab structure containing rendering parameters
    %

    %% DATA LOADING FROM FILE

    fid = fopen(cfg_path);

    if fid < 0
        error('Cannot open rendering configuration file')
    end

    recons_param = struct;

    while ~feof(fid)
        line = strtrim(fgetl(fid));

        if isempty(line) || all(isspace(line)) || strncmp(line, '#', 1)
            %do nothing, skip this line
        else
            key_value = regexp(line(~isspace(line)), ':', 'split');

            switch lower(key_value{1}) %this is the key (the parameter)
                case 'wlen'
                    recons_param.wlen = str2num(key_value{2}); %this is the value
                case 'pixel_pitch'
                    recons_param.pixel_pitch = str2num(key_value{2});
                case 'method'
                    recons_param.method = key_value{2};
                case 'apod'
                    recons_param.apod = str2num(key_value{2});
                case 'zero_pad'
                    recons_param.zero_pad = str2num(key_value{2});
                case 'perc_clip'
                    recons_param.perc_clip = str2num(key_value{2});
                case 'perc_value'
                    recons_param.perc_value = str2num(key_value{2});
                case 'hist_stretch'
                    recons_param.hist_stretch = str2num(key_value{2});
                case 'save_intensity'
                    recons_param.save_intensity = str2num(key_value{2});
                case 'save_as_mat'
                    recons_param.save_as_mat = str2num(key_value{2});
                case 'show'
                    recons_param.show = str2num(key_value{2});
                case 'save_as_image'
                    recons_param.save_as_image = str2num(key_value{2});
                case 'bit_depth'
                    recons_param.bit_depth = str2num(key_value{2});
                    %WUT_DIPS or INTERFERE 4 only
                case 'ref_wave_rad' %WUT_DISP and INTERFERE4
                    recons_param.ref_wave_rad = str2num(key_value{2});
                case 'recons_img_size'
                    recons_param.recons_img_size = str2num(key_value{2});
                case 'dc_filter_type'
                    recons_param.DC_filter_type = key_value{2};
                case 'dc_filter_size'
                    recons_param.DC_filter_size = str2num(key_value{2});
                case 'img_flt'
                    recons_param.img_flt = key_value{2};
                case 'shift_yx_r'
                    recons_param.shift_yx_R = str2num(key_value{2});
                case 'shift_yx_g'
                    recons_param.shift_yx_G = str2num(key_value{2});
                case 'shift_yx_b'
                    recons_param.shift_yx_B = str2num(key_value{2});
                    %High-resolution holograms only
                case 'hologramname'
                    recons_param.hologramName = key_value{2};
                case 'format'
                    recons_param.format = key_value{2};
                case 'segmentsnum'
                    recons_param.segmentsNum = str2num(key_value{2});
                case 'segmentsres'
                    recons_param.segmentsRes = str2num(key_value{2});
                case 'subsegmentsres'
                    recons_param.subSegmentsRes = str2num(key_value{2});
                case 'spectrumscale'
                    recons_param.spectrumScale = str2num(key_value{2});

                otherwise
                    fclose(fid);
                    error('"%s" is not a known parameter. Double-check the configuration file.\n', key_value{1})
            end

        end

    end

    fclose(fid);

    %% CHECKS

    validateattributes(recons_param.wlen, {'numeric'}, {'nonempty'}, 'Configuration File', 'wlen'); %mandatory
    validateattributes(recons_param.pixel_pitch, {'numeric'}, {'scalar', 'nonempty'}, 'Configuration File', 'pixel_pitch'); %mandatory
    validateattributes(recons_param.method, {'char'}, {'nonempty'}, 'Configuration File', 'method'); %mandatory
    validateattributes(recons_param.apod, {'numeric'}, {'binary'}, 'Configuration File', 'apod');
    validateattributes(recons_param.zero_pad, {'numeric'}, {'binary'}, 'Configuration File', 'zero_pad');
    validateattributes(recons_param.perc_clip, {'numeric'}, {'binary', 'nonempty'}, 'Configuration File', 'perc_clip'); %mandatory

    if recons_param.perc_clip ~= 0
        validateattributes(recons_param.perc_value, {'numeric'}, {'nonnegative', 'nonempty'}, 'Configuration File', 'perc_value');
    end

    validateattributes(recons_param.hist_stretch, {'numeric'}, {'binary'}, 'Configuration File', 'hist_stretch');

    validateattributes(recons_param.save_intensity, {'numeric'}, {'binary', 'nonempty'}, 'Configuration File', 'save_intensity'); %mandatory
    validateattributes(recons_param.save_as_mat, {'numeric'}, {'binary', 'nonempty'}, 'Configuration File', 'save_as_mat'); %mandatory
    validateattributes(recons_param.show, {'numeric'}, {'binary', 'nonempty'}, 'Configuration File', 'show'); %mandatory
    validateattributes(recons_param.save_as_image, {'numeric'}, {'binary', 'nonempty'}, 'Configuration File', 'save_as_image'); %mandatory

    if ~isequal(recons_param.save_as_image, 0)
        validateattributes(recons_param.bit_depth, {'numeric'}, {'nonnegative', 'scalar', 'nonempty'}, 'Configuration File', 'bit_depth');

        if ((~isequal(recons_param.bit_depth, 8)) && (~isequal(recons_param.bit_depth, 16)))
            error('Error using Configuration File: Expected bit_depth to be equal to 8 or 16.')
        end

    end

    %WUT_DISP parameters
    if strcmpi(dataset, {'wut_disp', 'wut_disp_on_axis'})
        validateattributes(recons_param.ref_wave_rad, {'numeric'}, {'scalar', 'nonempty'}, 'Configuration File', 'ref_wave_rad');
        validateattributes(recons_param.recons_img_size, {'numeric'}, {'nonempty', 'numel', 2}, 'Configuration File', 'recons_img_size');
        validateattributes(recons_param.DC_filter_type, {'char'}, {'nonempty'}, 'Configuration File', 'DC_filter_type');
        validateattributes(recons_param.DC_filter_size, {'numeric'}, {'scalar', 'nonnegative', 'nonempty'}, 'Configuration File', 'DC_filter_size');
        validateattributes(recons_param.img_flt, {'char'}, {}, 'Configuration File', 'img_flt');

        if ((~strcmpi(recons_param.img_flt, 'r')) && (~strcmpi(recons_param.img_flt, 'l')) && ~isempty(recons_param.img_flt))
            error('Error using Configuration File: Expected img_flt to be R or L. ')
        end

        try
            validateattributes(recons_param.shift_yx_R, {'numeric'}, {}, 'Configuration File', 'shift_yx_R'); %grayscale samples don't use them
            validateattributes(recons_param.shift_yx_G, {'numeric'}, {}, 'Configuration File', 'shift_yx_G');
            validateattributes(recons_param.shift_yx_B, {'numeric'}, {}, 'Configuration File', 'shift_yx_B');
        catch
            fprintf('\nyx R/G/B shifts not found in the configuration file. If the hologram is not RGB, you can ignore this message.\n')
        end

    end

    %INTERFERE4 parameters
    if strcmpi(dataset, 'interfere4')
        validateattributes(recons_param.ref_wave_rad, {'numeric'}, {'scalar', 'nonempty'}, 'Configuration File', 'ref_wave_rad');
    end

    %High-resolution holograms parameters
    if strcmpi(dataset, {'bcom_print', 'etri_print'})
        validateattributes(recons_param.hologramName, {'char'}, {'nonempty'}, 'Configuration File', 'hologramName'); %mandatory
        validateattributes(recons_param.format, {'char'}, {'nonempty'}, 'Configuration File', 'format'); %mandatory
        validateattributes(recons_param.segmentsNum, {'numeric'}, {'nonempty', 'nonnan', 'integer', 'positive', 'numel', 2}, 'Configuration File', 'segmentsNum');
        validateattributes(recons_param.segmentsRes, {'numeric'}, {'nonempty', 'nonnan', 'integer', 'positive', 'numel', 2}, 'Configuration File', 'segmentsRes');
        validateattributes(recons_param.subSegmentsRes, {'numeric'}, {'nonempty', 'nonnan', 'integer', 'positive', 'numel', 2}, 'Configuration File', 'subSegmentsRes');
        validateattributes(recons_param.spectrumScale, {'numeric'}, {'nonempty', 'nonnan', 'integer', 'positive', 'scalar'}, 'Configuration File', 'spectrumScale');
    end

end
