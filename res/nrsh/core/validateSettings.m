function validateSettings(hol, info)
    sErrSender = 'nrsh:invalid_input';

    % Layman's check for octave compatible mode
    isOctave = false;

    try
        a = datetime; clear a;
        contains('abc', 'a');
        isOctave = false;
    catch me
        pkg load image;
        confirm_recursive_rmdir(0);
        isOctave = true;
    end

    %% Validate attributes
    if (~isOctave)
        validateattributes(info.usagemode, {'char', 'string'}, {'scalartext'}, 'nrsh', 'usagemode');
    else
        validateattributes(info.usagemode, {'char', 'string'}, {}, 'nrsh', 'usagemode');
    end

    if ~strcmpi(info.usagemode, {'exhaustive', 'individual', 'dynamic', 'complex'})
        error(sErrSender, 'Error in nrsh: expected usagemode to be one of the following char. array: ''exhaustive'', ''individual'', ''dynamic'', ''complex''.')
    end

    validateattributes(info.resize_fun, {'function_handle', 'char', 'string'}, {}, 'nrsh', 'resize_fun');
    validateattributes(info.apertureinpxmode, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'apertureinpxmode');
    validateattributes(info.ap_sizes, {'cell'}, {'row'}, 'nrsh', 'ap_sizes');

    if info.apertureinpxmode ~= 0

        for i = 1:numel(info.ap_sizes)
            validateattributes(info.ap_sizes{i}, {'numeric'}, {'row', 'nonnegative', 'numel', 2}, 'nrsh', 'ap_sizes');
        end

        validateattributes(info.h_pos, {'numeric'}, {'>=', -1, '<=', 1, 'row'}, 'nrsh', 'h_pos');
        validateattributes(info.v_pos, {'numeric'}, {'>=', -1, '<=', 1, 'row'}, 'nrsh', 'v_pos');
    else

        for i = 1:numel(info.ap_sizes)
            validateattributes(info.ap_sizes{i}, {'numeric'}, {'row', 'nonnegative', 'numel', 1}, 'nrsh', 'ap_sizes');
        end

        validateattributes(info.h_pos, {'numeric'}, {'row'}, 'nrsh', 'h_pos');
        validateattributes(info.v_pos, {'numeric'}, {'row'}, 'nrsh', 'v_pos');
    end

    validateattributes(info.clip_min, {'numeric'}, {'row'}, 'nrsh', 'clip_min');
    validateattributes(info.clip_max, {'numeric'}, {'row'}, 'nrsh', 'clip_max');
    validateattributes(info.use_first_frame_reference, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'use_first_frame_reference');

    if (~isOctave)
        validateattributes(info.direction, {'char', 'string'}, {'scalartext', 'nonempty'}, 'nrsh', 'direction');
    else
        validateattributes(info.direction, {'char', 'string'}, {'nonempty'}, 'nrsh', 'direction');
    end

    if ~strcmpi(info.direction, {'forward', 'inverse'})
        error(sErrSender, 'Error in nrsh: expected direction to be one of the following char. array: ''forward'', ''inverse''.')
    end

    if (~isOctave)
        validateattributes(info.dataset, {'char', 'string'}, {'scalartext'}, 'nrsh', 'dataset');
        validateattributes(info.cfg_file, {'char', 'string'}, {'scalartext'}, 'nrsh', 'cfg_file');
        validateattributes(info.name_prefix, {'char', 'string'}, {'scalartext'}, 'nrsh', 'name_prefix');
        validateattributes(info.outfolderpath, {'char', 'string'}, {'scalartext'}, 'nrsh', 'outfolderpath');
        validateattributes(info.lowresmode, {'char', 'string'}, {'scalartext', 'nonempty'}, 'nrsh', 'lowresmode');
    else
        validateattributes(info.dataset, {'char', 'string'}, {}, 'nrsh', 'dataset');
        validateattributes(info.cfg_file, {'char', 'string'}, {}, 'nrsh', 'cfg_file');
        validateattributes(info.name_prefix, {'char', 'string'}, {}, 'nrsh', 'name_prefix');
        validateattributes(info.outfolderpath, {'char', 'string'}, {}, 'nrsh', 'outfolderpath');
        validateattributes(info.lowresmode, {'char', 'string'}, {'nonempty'}, 'nrsh', 'lowresmode');
    end

    if strcmpi(info.usagemode, 'dynamic')
        validateattributes(info.fps, {'numeric'}, {'nonempty', 'scalar', 'positive', 'integer'}, 'nrsh', 'fps');
    end

    validateattributes(info.wlen, {'numeric'}, {'nonempty', 'row', 'numel', size(hol, 3)}, 'nrsh', 'wlen');

    if (isscalar(info.pixel_pitch))
        validateattributes(info.pixel_pitch, {'numeric'}, {'scalar', 'nonempty'}, 'nrsh', 'pixel_pitch');
    else
        validateattributes(info.pixel_pitch, {'numeric'}, {'numel', 2}, 'nrsh', 'pixel_pitch');
    end

    if (~isOctave)
        validateattributes(info.method, {'char', 'string'}, {'scalartext', 'nonempty'}, 'nrsh', 'method');
    else
        validateattributes(info.method, {'char', 'string'}, {'nonempty'}, 'nrsh', 'method');
    end

    validateattributes(info.apod, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'apod');
    validateattributes(info.zero_pad, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'zero_pad');
    validateattributes(info.perc_clip, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'perc_clip');

    if info.perc_clip ~= 0
        validateattributes(info.perc_value, {'numeric'}, {'scalar', 'nonnegative', 'nonempty', '<=', 100}, 'nrsh', 'perc_value');
    end

    validateattributes(info.hist_stretch, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'hist_stretch');
    validateattributes(info.save_intensity, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'save_intensity');
    validateattributes(info.save_as_mat, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'save_as_mat');
    validateattributes(info.save_as_image, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'save_as_image');
    validateattributes(info.show, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'show');

    if info.save_as_image ~= 0
        validateattributes(info.bit_depth, {'numeric'}, {'integer', 'positive', 'scalar', 'nonempty'}, 'nrsh', 'bit_depth');

        if ((~isequal(info.bit_depth, 8)) && (~isequal(info.bit_depth, 16)))
            error(sErrSender, 'Error in nrsh: expected bit_depth to be equal to 8 or 16.')
        end

    end

    if ((~isOctave && contains(info.dataset, 'bin')) || (isOctave && ~isempty(strfind(lower(info.dataset), 'bin'))))
        validateattributes(info.reffronorm, {'numeric'}, {'nonempty', 'row', 'numel', size(hol, 3)}, 'nrsh', 'reffronorm');

        if (~isOctave)
            validateattributes(info.offaxisfilter, {'char', 'string'}, {'scalartext', 'nonempty'}, 'nrsh', 'offaxisfilter');
        else
            validateattributes(info.offaxisfilter, {'char', 'string'}, {'nonempty'}, 'nrsh', 'offaxisfilter');
        end

        if ~strcmpi(info.offaxisfilter, {'v', 'h'})
            error(sErrSender, 'Error in nrsh: expected offaxisfilter to be one of the following char. array: ''v'', ''h''.')
        end

    end

    if any(strcmpi(info.dataset, {'wut_disp', 'wut_disp_on_axis', 'wut_disp_on_axis_bin', 'interfere4', 'interfere4_bin'}))
        validateattributes(info.ref_wave_rad, {'numeric'}, {'scalar', 'nonempty'}, 'nrsh', 'ref_wave_rad');
    end

    if any(strcmpi(info.dataset, {'wut_disp', 'wut_disp_on_axis', 'wut_disp_on_axis_bin'}))

        if (~isOctave)
            validateattributes(info.dc_filter_type, {'char', 'string'}, {'scalartext', 'nonempty'}, 'nrsh', 'dc_filter_type');
            validateattributes(info.img_flt, {'char', 'string'}, {'scalartext'}, 'nrsh', 'img_flt');
        else
            validateattributes(info.dc_filter_type, {'char', 'string'}, {'nonempty'}, 'nrsh', 'dc_filter_type');
            validateattributes(info.img_flt, {'char', 'string'}, {}, 'nrsh', 'img_flt');
        end

        validateattributes(info.dc_filter_size, {'numeric'}, {'scalar', 'nonnegative', 'nonempty'}, 'nrsh', 'dc_filter_size');

        if ((~strcmpi(info.img_flt, 'r')) && (~strcmpi(info.img_flt, 'l')) && ~isempty(info.img_flt))
            error(sErrSender, 'Error in nrsh: expected img_flt to be R or L. ')
        end

        validateattributes(info.shift_yx_r, {'numeric'}, {}, 'Configuration File', 'shift_yx_R');
        validateattributes(info.shift_yx_g, {'numeric'}, {}, 'Configuration File', 'shift_yx_G');
        validateattributes(info.shift_yx_b, {'numeric'}, {}, 'Configuration File', 'shift_yx_B');
    end

    if any(strcmpi(info.dataset, {'bcom_print', 'etri_print'}))

        if (~isOctave)
            validateattributes(info.hologramname, {'char', 'string'}, {'scalartext', 'nonempty'}, 'nrsh', 'hologramname');
            validateattributes(info.format, {'char', 'string'}, {'scalartext', 'nonempty'}, 'nrsh', 'format');
        else
            validateattributes(info.hologramname, {'char', 'string'}, {'nonempty'}, 'nrsh', 'hologramname');
            validateattributes(info.format, {'char', 'string'}, {'nonempty'}, 'nrsh', 'format');
        end

        validateattributes(info.segmentsnum, {'numeric'}, {'nonempty', 'nonnan', 'integer', 'positive', 'numel', 2}, 'nrsh', 'segmentsnum');
        validateattributes(info.segmentsres, {'numeric'}, {'nonempty', 'nonnan', 'integer', 'positive', 'numel', 2}, 'nrsh', 'segmentsres');
        validateattributes(info.subsegmentsres, {'numeric'}, {'nonempty', 'nonnan', 'integer', 'positive', 'numel', 2}, 'nrsh', 'subsegmentsres');
        validateattributes(info.spectrumscale, {'numeric'}, {'nonempty', 'nonnan', 'integer', 'positive', 'scalar'}, 'nrsh', 'spectrumscale');
    end

    validateattributes(info.verbosity, {'logical'}, {'scalar', 'nonempty'}, 'nrsh', 'verbosity');
    validateattributes(info.orthographic, {'logical'}, {'scalar', 'nonempty'}, 'nrsh', 'orthographic');

    %% Sanity checks
    validateattributes(info.isBinary, {'logical'}, {'scalar', 'nonempty'}, 'nrsh', 'isBinary');
    validateattributes(info.isFourierDH, {'logical'}, {'scalar', 'nonempty'}, 'nrsh', 'isFourierDH');
end
