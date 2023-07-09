function info = defaultSettings(hol, rec_dists, info)
    sErrSender = 'nrsh:invalid_input';

    %% Check hologram, reconstruction distances, and infoStruct (superfically)
    validateattributes(hol, {'numeric', 'logical'}, {'nonempty'}, 'nrsh', 'hol', 1);
    validateattributes(rec_dists, {'numeric'}, {'nonempty'}, 'nrsh', 'rec_dists', 2);
    validateattributes(info, {'struct'}, {'nonempty'}, 'nrsh', 'info', 3);

    if (~isfield(info, 'isInfoStruct') || info.isInfoStruct ~= 1)
        error(sErrSender, 'Error in nrsh: ''info'' is not a valid info struct. Please add info.isInfoStruct = 1 by using getSettings.m.')
    end

    %% Set default values
    if ~isfield(info, 'usagemode') || isempty(info.usagemode)
        info.usagemode = 'exhaustive';
    end

    if ~isfield(info, 'apertureinpxmode') || isempty(info.apertureinpxmode)
        info.apertureinpxmode = true;
    end

    if ~isfield(info, 'ap_sizes') || isempty(info.ap_sizes)

        if info.apertureinpxmode ~= 0
            info.ap_sizes = {[0 0]};
        else
            info.ap_sizes = {0};
        end

    end

    if ~isfield(info, 'h_pos') || isempty(info.h_pos)
        info.h_pos = 0;
    end

    if ~isfield(info, 'v_pos') || isempty(info.v_pos)
        info.v_pos = 0;
    end

    if ~isfield(info, 'clip_min') || isempty(info.clip_min)
        info.clip_min = -1;
    end

    if ~isfield(info, 'clip_max') || isempty(info.clip_max)
        info.clip_max = -1;
    end

    if ~isfield(info, 'use_first_frame_reference') || isempty(info.use_first_frame_reference)
        info.use_first_frame_reference = true;
    end

    if ~isfield(info, 'dataset')
        info.dataset = '';
    end

    if ~isfield(info, 'cfg_file')
        info.cfg_file = '';
    end

    if ~isfield(info, 'name_prefix')
        info.name_prefix = '';
    end

    if ~isfield(info, 'outfolderpath') || isempty(info.outfolderpath)
        info.outfolderpath = './figures';
    end

    if ~isfield(info, 'direction') || isempty(info.direction) || ~strcmpi(info.usagemode, 'complex')
        info.direction = 'forward';
    end

    if ~isfield(info, 'resize_fun')
        info.resize_fun = '';
    end

    if ~isfield(info, 'targetres')
        info.targetres = '';
    end

    if ~isfield(info, 'fps') || isempty(info.fps)
        info.fps = 10;
    end

    if ~isfield(info, 'verbosity')
        info.verbosity = true;
    end

    if ~isfield(info, 'orthographic')
        info.orthographic = false;
    end

    if isa(info.resize_fun, 'function_handle')
        info.lowresmode = 'custom';
        info.targetres = size(hol(:, :, 1));
    elseif isempty(info.resize_fun)
        info.resize_fun = '';
        info.lowresmode = 'disable';

        if (contains(info.method, 'Fourier-Fresnel')) % No resizing necessary for Fourier DHs
            info.targetres = info.ap_sizes{1};
        else
            info.targetres = size(hol(:, :, 1));
        end

    elseif strcmpi(info.resize_fun, 'dr')

        if info.apertureinpxmode == 0
            info.apertureinpxmode = true;
            info.ap_sizes = {size(hol(:, :, 1))};
            info.h_pos = 0;
            info.v_pos = 0;
            warning(sErrSender, 'Warning in nrsh: in diffraction-limited resizing mode, angle-based apertures are ignored.');
        end

        if ~isempty(info.targetres)
            validateattributes(info.targetres, {'numeric'}, {'row', 'nonempty', 'integer', 'positive', 'numel', 2}, 'nrsh', 'targetres');
            info.lowresmode = 'targetres';
            info.ap_sizes = {[0 0]};
        else
            info.lowresmode = 'aperture';
            info.targetres = size(hol(:, :, 1));
        end

    else
        error(sErrSender, 'Error in nrsh: expected resize_fun to be empty, a function handle or ''DR''.');
    end

    if ~isfield(info, 'wlen') || isempty(info.wlen)
        error(sErrSender, 'Error in nrsh: the wavelength (wlen) was not defined')
    end

    if ~isfield(info, 'pixel_pitch') || isempty(info.pixel_pitch)
        error(sErrSender, 'Error in nrsh: the pixel pitch (pixel_pitch) was not defined')
    end

    if ~isfield(info, 'method') || isempty(info.method)
        error(sErrSender, 'Error in nrsh: the propagation method (method) was not defined')
    end

    if ~isfield(info, 'apod') || isempty(info.apod)
        info.apod = false;
    end

    if ~isfield(info, 'zero_pad') || isempty(info.zero_pad) || strcmpi(info.usagemode, 'complex')
        info.zero_pad = false;
    end

    if ~isfield(info, 'perc_clip') || isempty(info.perc_clip)
        info.perc_clip = false;
    end

    if ~isfield(info, 'perc_value') || isempty(info.perc_value)
        info.perc_value = 100;
    end

    if ~isfield(info, 'hist_stretch') || isempty(info.hist_stretch)
        info.hist_stretch = false;
    end

    if ~isfield(info, 'save_intensity') || isempty(info.save_intensity)
        info.save_intensity = false;
    end

    if ~isfield(info, 'save_as_mat') || isempty(info.save_as_mat) || strcmpi(info.usagemode, 'dynamic')
        info.save_as_mat = false;
    end

    if ~isfield(info, 'save_as_image') || isempty(info.save_as_image) || strcmpi(info.usagemode, 'dynamic')
        info.save_as_image = true;
    end

    if ~isfield(info, 'show') || isempty(info.show) || strcmpi(info.usagemode, 'dynamic')
        info.show = false;
    end

    if ~isfield(info, 'bit_depth') || isempty(info.bit_depth)
        info.bit_depth = 8;
    end

    if ~isfield(info, 'reffronorm') || isempty(info.reffronorm)
        info.reffronorm = ones(1, size(hol, 3));
    end

    if ~isfield(info, 'offaxisfilter') || isempty(info.offaxisfilter)
        info.offaxisfilter = 'h';
    end

    %% Set additional program flow parameters
    info.isBinary = islogical(hol); % Check binary hologram
    info.isFourierDH = contains(info.method, 'fourier', 'IgnoreCase', true);

    %% Continue verification
    if strcmpi(info.method, 'fourier-fresnel')

        if ~isfield(info, 'ref_wave_rad')
            error(sErrSender, 'Error in nrsh: the reference wave (ref_wave_rad) was not defined')
        end

    end

    if any(strcmpi(info.dataset, {'wut_disp', 'wut_disp_on_axis', 'wut_disp_on_axis_bin'}))

        if ~isfield(info, 'dc_filter_type') || isempty(info.dc_filter_type)
            info.dc_filter_type = 'wut';
        end

        if ~isfield(info, 'dc_filter_size') || isempty(info.dc_filter_size)
            info.dc_filter_size = 0.5;
        end

        if ~isfield(info, 'img_flt')
            info.img_flt = '';
        end

        if ~isfield(info, 'shift_yx_r') || isempty(info.shift_yx_r)
            info.shift_yx_r = [0 0];
        end

        if ~isfield(info, 'shift_yx_g') || isempty(info.shift_yx_g)
            info.shift_yx_g = [0 0];
        end

        if ~isfield(info, 'shift_yx_b') || isempty(info.shift_yx_b)
            info.shift_yx_b = [0 0];
        end

    end

    if any(strcmpi(info.dataset, {'bcom_print', 'etri_print'}))

        if ~isfield(info, 'hologramname') || isempty(info.hologramname)
            error(sErrSender, 'Error in nrsh: the hologram name (hologramname) was not defined')
        end

        if ~isfield(info, 'format') || isempty(info.format)
            error(sErrSender, 'Error in nrsh: the hologram format (format) was not defined')
        end

        if ~isfield(info, 'segmentsnum') || isempty(info.segmentsnum)
            error(sErrSender, 'Error in nrsh: the hologram segments number (segmentsnum) was not defined')
        end

        if ~isfield(info, 'segmentsres') || isempty(info.segmentsres)
            error(sErrSender, 'Error in nrsh: the hologram segments resolution (segmentsres) was not defined')
        end

        if ~isfield(info, 'subsegmentsres') || isempty(info.subsegmentsres)
            info.subsegmentres = info.segmentres;
        end

        if ~isfield(info, 'spectrumscale') || isempty(info.spectrumscale)
            info.spectrumscale = 1;
        end

    end

    %% Convert ap_sizes to cell
    if ~iscell(info.ap_sizes)
        info.ap_sizes = {info.ap_sizes};
    end

    %% Convert matrices to row vectors
    info.ap_sizes = info.ap_sizes(:).';
    info.h_pos = info.h_pos(:).';
    info.v_pos = info.v_pos(:).';
    info.clip_min = info.clip_min(:).';
    info.clip_max = info.clip_max(:).';
end
