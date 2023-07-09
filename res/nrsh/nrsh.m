function [hol_rendered, clip_min, clip_max] = nrsh(hol, rec_dists, info, varargin)
    % function [hol_rendered, clip_min, clip_max] = nrsh(hol, rec_dists, info, usagemode, ap_sizes, h_pos, v_pos, clip_min, clip_max)
    % function [hol_rendered, clip_min, clip_max] = nrsh(hol, rec_dists, info, usagemode, ap_sizes, h_pos, v_pos)
    % function [hol_rendered, clip_min, clip_max] = nrsh(hol, rec_dists, info, usagemode, ap_sizes)
    % function [hol_rendered, clip_min, clip_max] = nrsh(hol, rec_dists, info, usagemode)
    % function [hol_rendered, clip_min, clip_max] = nrsh(hol, rec_dists, info)
    %
    % Function Name: nrsh
    % This function reconstructs a medium resolution hologram from several
    % viewpoints or at specified reconstruction distances
    %
    % INPUTS:
    %	hol@string or char-array or numeric(Nx,Ny) (mandatory)
    %               - Hologram to reconstruct. It can be a matrix that has been
    %                 previously loaded in the workspace or a path to a folder
    %                 where the hologram is stored. If left empty, the hologram
    %                 is loaded manually through the GUI.
    %                 Binary holograms have to be stored/provided as logical datatype.
    %	rec_dists@numeric(N,1) or numeric(1,N) or numeric(1) (mandatory)
    %               - Reconstruction distance(s) [m]. It can be a single value
    %                 or a row or column vector of values.
    %   info@struct (mandatory)
    %               - Reconstruction parameters, initialized with getSettings
    %                 via info = getSettings(*Option name*, *option value*, ...),
    %                 where any option of the infoStruct may be specified here.
    %                 (see below)
    %
    %   The user can also overwrite parameters defined in configuration files
    %   or in structure info by passing them in this specific order as additional
    %   input parameters through varargin: usagemode, ap_sizes, h_pos, v_pos,
    %   clip_min, clip_max
    %
    %   info always contains info.isInfoStruct=1. It may also contain following
    %   parameters, initialized via getSettings:
    %
    %	usagemode@char-array (optional, default is 'exhaustive')
    %               - Usage mode of nrsh. It can take four different values:
    %                   'exhaustive':   use combination of all possible viewpoints
    %                   'individual':   use individual viewpoints as listed
    %                   'dynamic':      use individual viewpoints as listed and
    %                                   save them as a video
    %                   'complex':      reconstruct the complex light field in
    %                                   the object plane, and disable non-invertible
    %                                   transforms (apertures, clipping, filters)
    %	ap_sizes@cell(1,N) or cell(N, 1) or numeric(1,2) or numeric(1) or numeric(2,1)
    %               (optional, default is empty)
    %               - Synthetic aperture size. It can be a single value, a row
    %                 or column vector of values. If more than one reconstruction
    %                 is specified use a cell array with one entry per view.
    %                 Meaning depends on info.apertureinpxmode flag: angle-based
    %                 aperture or pixel-based aperture. Will be ignored, if
    %                 resize_fun=='DR' and targetres is specified.
    %	h_pos@numeric(N,1) or numeric(1,N) or numeric(1)
    %               (optional, default is 0)
    %               - If the synthetic aperture declaration is expressed as angles,
    %                 it represents the horizontal angles, in degrees, at which
    %                 the synthetic aperture will be placed. If the synthetic
    %                 aperture declaration is expressed in pixels, it represents
    %                 the horizontal position at which the synthetic aperture
    %                 will be placed, expressed in the range [-1, 1] where -1
    %                 is the leftmost position, while 1 is the rightmost position.
    %                 In both cases (angle or pixel based) it can be a single value
    %                 or a row or column vector of values.
    %	v_pos@numeric(N,1) or numeric(1,N) or numeric(1)
    %               (optional, default is 0)
    %               - If the synthetic aperture declaration is expressed as angles,
    %                 it represents the vertical angles, in degrees, at which
    %                 the synthetic aperture will be placed. If the synthetic
    %                 aperture declaration is expressed in pixels, it represents
    %                 the vertical position at which the synthetic aperture
    %                 will be placed, expressed in the range [-1, 1] where -1
    %                 is the leftmost position, while 1 is the rightmost position.
    %                 In both cases (angle or pixel based) it can be a single value
    %                 or a row or column vector of values.
    %   apertureinpxmode@boolean (optional, default is true)
    %               - True to use pixel-based apertures, false for angle-based.
    %	clip_min@numeric(N,1) or numeric(1) (optional, default is empty)
    %               - Minimal intensity value for clipping. It can be a single
    %                 value or a row or column vector of values (one value per
    %                 reconstuction).
    %	clip_max@numeric(N,1) or numeric(1) (optional, default is empty)
    %               - Maximal intensity value for clipping. It can be a single
    %                 value or a row or column vector of values (one value per
    %                 reconstuction).
    %   use_first_frame_reference@boolean (optional, default is true)
    %               - True to use the computed absolute clipping values of the
    %                 first reconstruction for the next ones, false otherwise.
    %   dataset@char-array (optional, default is empty)
    %               - Dataset to which hol belongs. It should be empty or one of
    %                 the following char. arrays: bcom8, bcom32, bcom32_bin,
    %                 interfere, interfere_bin, interfere4, interfere4_bin,
    %                 emergimg, emergimg_bin, wut_disp, wut_disp_on_axis,
    %                 wut_disp_on_axis_bin.
    %   cfg_file@char-array (optional, default is empty)
    %               - Path to configuration file. If left, empty, alternatively
    %                 required fields: wlen, pixel_pitch and method (see below)
    %   name_prefix@char-array (optional, default is empty)
    %               - Output file name prefix
    %   outfolderpath@char-array (optional, default is './figures')
    %               - Path to the output folder for figures
    %   direction@char-array (optional, default is 'forward')
    %               - Propagation direction. It has effect only if usagemode = 'complex',
    %                 and should take one of the following values:
    %                   'forward': forward transform (propagation towards the object plane)
    %                   'inverse': inverse transform (propagation towards the hologram plane)
    %   resize_fun@char-array or function handle (optional, default is empty)
    %               - Resize/clipping/down-sampling function handle to use on
    %                 reconstructions. If 'DR' is provided, diffraction-limited
    %                 reconstruction is performed using phase-space bandwidth
    %                 limitation to reduce the resolution of reconstructed
    %                 image. If left empty, no resizing is performed.
    %   targetres@numeric(1,2) or numeric(2,1) (optional, default is empty)
    %               - Target resolution of the final video, when using resize_fun = 'DR'.
    %                 No frame will have higher resolution. A single aperture size
    %                 will be calculated for all frames. If left empty and
    %                 resize_fun = 'DR', the diffraction-limited reconstruction
    %                 will be based on the input aperture size ap_sizes.
    %   fps@numeric(1) (optional, default is 10)
    %               - Frame rate of final video. It has effect only if
    %                 usagemode = 'dynamic'.
    %   verbosity@logical(1) (optional, default is true)
    %               - Allows to disable command line output, except for warnings and errors.
    %   orthographic@logical(1) (optional, default is false)
    %               - Allows to obtain orthographic reconstruction
    %
    %   Additionally, any of the following fields may overwrite cfg_file options:
    %       wlen@numeric(1) or numeric(1,3) or numeric(3, 1)
    %       pixel_pitch@numeric(1,2) or numeric(2,1) or numeric(1)
    %       method@char-array
    %       zero_pad@boolean(1)
    %       apod@boolean(1)
    %       perc_clip@boolean(1)
    %       perc_value@numeric(1) in [0, 1]
    %       hist_stretch@boolean(1)
    %       save_intensity@boolean(1)
    %       save_as_mat@boolean(1)
    %       save_as_image@boolean(1)
    %       show@boolean(1)
    %       bit_depth@numeric(1)
    %       reffronorm@numeric(1) or numeric(1,3) or numeric(3, 1)
    %       offaxisfilter@char-array
    %       ref_wave_rad@numeric(1)
    %       dc_filter_type@char-array
    %       dc_filter_size@numeric(1) in [0, 1]
    %       img_flt@char-array
    %       shift_yx_r@numeric(2, 1) or numeric(1, 2)
    %       shift_yx_g@numeric(2, 1) or numeric(1, 2)
    %       shift_yx_b@numeric(2, 1) or numeric(1, 2)
    %
    % Parameter sources with decreasing precedence:
    %   nrsh input parameters > info struct > config file
    %   Overwrite only, if not empty.
    %
    % OUTPUTS:
    %	hol_rendered@numeric(Nx,Ny)
    %               - Reconstruction of the input hologram, returned as standard
    %                 unsigned integer image (8 or 16 bpp). Note that in case of
    %                 multiple reconstructions, hol_rendered is the last reconstruction
    %                 performed.
    %	clip_min@numeric(N,1)
    %               - Minimal intensity of the numerical reconstructions. In case
    %                 of multiple reconstructions, one value per reconstruction is returned.
    %	clip_max@numeric(N,1)
    %               - Maximal intensity of the numerical reconstructions. In case
    %                 of multiple reconstructions, one value per reconstruction is returned.
    %
    %-------------------------------------------------------------------------

    %% Initialization
    addpath(genpath('./core'));
    avg_rec_time = 0; %average reconstruction time (all reconstructions)

    %% Check number of arguments
    if nargin < 3
        error('nrsh:input_args', 'Error in nrsh: not enough input arguments.')
    end

    %% Layman's check for octave compatible mode
    isOctave = false;

    try
        a = datetime; clear a;
        contains('abc', 'a');
        isOctave = false;
    catch me
        pkg load signal;
        isOctave = true;
    end

    %% Parse additional varargin, overwriting default info struct entries.
    fieldnameList = {'usagemode', 'ap_sizes', 'h_pos', 'v_pos', 'clip_min', 'clip_max'};

    for ii = 1:(numel(varargin))
        info.(fieldnameList{ii}) = varargin{ii};
    end

    %% Load hologram
    if isempty(hol)
        [hol, info.dataset] = load_data();
    elseif (isstring(hol) || ischar(hol))
        [hol, info.dataset] = load_data_auto(hol); %load hologram from folder
    end

    %% Set default settings
    %rec_dists = nonzeros(rec_dists); % Breaks currently Breakdancer
    rec_dists = rec_dists(:).';
    info = defaultSettings(hol, rec_dists, info);

    %% Validate settings
    validateSettings(hol, info);

    %% Info fields are completed until here ------------------------------------------
    info = orderfields(info);

    %% Print settings
    if (info.verbosity)
        print_setup(rec_dists, info);
    end

    %% Create reconstructions savepath
    [~, cfg_name] = fileparts(info.cfg_file);
    figures_path = fullfile(info.outfolderpath, cfg_name);
    if (~exist(figures_path, 'dir')), mkdir(figures_path); end

    %% Check FFMPEG install
    if strcmpi(info.usagemode, 'dynamic')
        ffmpegBin = strsplit(mfilename('fullpath'), filesep);
        ffmpegBin = fullfile(ffmpegBin{1:end - 1}, 'ffmpeg/ffmpeg.exe');

        if (ispc && ~exist(ffmpegBin, 'file'))
            error('nrsh:ffmpeg', ['Error in nrsh: please ensure that an ffmpeg binary is present at: ' strrep(ffmpegBin, '\', '\\')])
        elseif (ismac || isunix)
            ffmpegBin = 'ffmpeg';
            [status, out] = system(['which ' ffmpegBin]);

            if (status || isempty(out))
                error('nrsh:ffmpeg', ['Error in nrsh: Please ensure that ffmpeg is installed and in the path. ' out])
            end

        end

        logfile = fullfile(figures_path, [info.name_prefix '_VideoLog.txt']);
        fh = fopen(logfile, 'w+');
    end

    %% Remove _bin suffix from dataset name
    if ((numel(info.dataset) > 3) && strcmpi(info.dataset(end - 4:end), '_bin'))
        info.dataset = info.dataset(1:end - 4);
    end

    %% Check usage mode
    if strcmpi(info.usagemode, 'complex')
        nbRecons = numel(rec_dists);
    else

        if strcmpi(info.usagemode, 'individual') || strcmpi(info.usagemode, 'dynamic')
            % Get number of reconstructions
            nbRecons = max([numel(rec_dists); numel(info.ap_sizes); numel(info.h_pos); numel(info.v_pos)]);
            rec_par_idx = ones(4, nbRecons) * spdiags([1:nbRecons].', 0, nbRecons, nbRecons);

            if (info.apertureinpxmode ~= 0 && max(rec_par_idx(4, :)) > numel(info.ap_sizes))
                rec_par_idx(4, :) = numel(info.ap_sizes);
            end

            % Pad reconstruction parameter lists
            if (numel(rec_dists) > 1)

                if (numel(rec_dists) < nbRecons)
                    error('nrsh:invalid_input', 'Error in nrsh: mismatch in parameter list lengths, wrt. rec_dists.');
                end

            else
                rec_dists = repmat(rec_dists, [1, nbRecons]);
            end

            if (numel(info.h_pos) > 1)

                if (numel(info.h_pos) < nbRecons)
                    error('nrsh:invalid_input', 'Error in nrsh: mismatch in parameter list lengths, wrt. h_pos.');
                end

            else
                info.h_pos = repmat(info.h_pos, [1, nbRecons]);
            end

            if (numel(info.v_pos) > 1)

                if (numel(info.v_pos) < nbRecons)
                    error('nrsh:invalid_input', 'Error in nrsh: mismatch in parameter list lengths, wrt. v_pos.');
                end

            else
                info.v_pos = repmat(info.v_pos, [1, nbRecons]);
            end

            if (numel(info.ap_sizes) > 1)

                if (numel(info.ap_sizes) < nbRecons)
                    error('nrsh:invalid_input', 'Error in nrsh: mismatch in parameter list lengths, wrt. ap_sizes.');
                end

            else
                info.ap_sizes = repmat(info.ap_sizes, [1, nbRecons]);
            end

        else
            % Get number of reconstructions
            nbRecons = numel(rec_dists) * numel(info.ap_sizes) * numel(info.h_pos) * numel(info.v_pos);

            % Get reconstruction parameters combination
            rec_par_idx = combvec_alternative(rec_dists, info.h_pos, info.v_pos, info.ap_sizes);
        end

        % Pad clip min and max values
        if (numel(info.clip_min) > 1)

            if (numel(info.clip_min) < nbRecons)
                error('nrsh:invalid_input', 'Error in nrsh: mismatch in parameter list lengths, wrt. clip_min.');
            end

        else
            info.clip_min = repmat(info.clip_min, [1, nbRecons]);
        end

        if (numel(info.clip_max) > 1)

            if (numel(info.clip_max) < nbRecons)
                error('nrsh:invalid_input', 'Error in nrsh: mismatch in parameter list lengths, wrt. clip_max.');
            end

        else
            info.clip_max = repmat(info.clip_max, [1, nbRecons]);
        end

        % Check apertures
        if ~strcmpi(info.lowresmode, 'targetres')

            if info.apertureinpxmode == 0
                % TODO: Add equivalent check to: if(info.isBinary && any(cellfun(@(x)any(x>size(hol(:,:,1))),  repmat(ap_sizes, [2,1]))))
                rec_par_idx = aperture_angle_checker(size(hol, 1), size(hol, 2), rec_par_idx, ...
                    rec_dists, info.ap_sizes, ...
                    info.h_pos, info.v_pos, info.pixel_pitch);
            else

                if (info.isBinary && any(cellfun(@(x)any(x > size(hol(:, :, 1))), info.ap_sizes)))

                    if strcmpi(info.offaxisfilter, 'h')
                        warning('nrsh:aperture', 'Warning in nrsh: the aperture may only be half the horizontal size of the binary hologram, due to its generation.')
                    else
                        warning('nrsh:aperture', 'Warning in nrsh: the aperture may only be half the vertical size of the binary hologram, due to its generation.')
                    end

                end

                rec_par_idx = aperture_pixel_checker(size(hol, 1), size(hol, 2), rec_par_idx, ...
                    info.ap_sizes, info.verbosity);
            end

        end

        % Update number of reconstructions
        nbRecons = size(rec_par_idx, 2);
    end

    %% Check errors during reconstruction
    try
        %% Pre-process binary holograms
        if info.isBinary && ~strcmpi(info.usagemode, 'complex')
            si = size(hol);
            hol = single(hol);

            if strcmpi(info.offaxisfilter, 'v')
                [RX, ~] = meshgrid(single(((-si(2) / 2:si(2) / 2 - 1) + 0.5) / si(2)), single(((-si(1) / 2:si(1) / 2 - 1) + 0.5) / si(1)));
                % bandlimit horizontally the hologram (because we will illuminate it later with off-axis vertical fringes)
                % simulate an incident off-axis planar illumination above the hologram (create vertical fringes)
                RX = single(exp(2i * pi * RX * si(2) / 4)); % off-axis phase modulation
                % filter conjugated orders + DC
                hol = ifftshift(fft2(fftshift(hol .* RX)));
                clear RX;
                hol(:, [1:si(2) / 4, si(2) * 3/4 + 1:end], :) = [];
                hol = ifftshift(ifft2(fftshift(hol)));
            else
                [~, RY] = meshgrid(single(((-si(2) / 2:si(2) / 2 - 1) + 0.5) / si(2)), single(((-si(1) / 2:si(1) / 2 - 1) + 0.5) / si(1)));
                % bandlimit vertically the hologram (because we will illuminate it later with off-axis horizontal fringes)
                % simulate an incident off-axis planar illumination above the hologram (create horizontal fringes)
                RY = single(exp(2i * pi * RY * si(1) / 4)); % off-axis phase modulation
                % filter conjugated orders + DC
                hol = ifftshift(fft2(fftshift(hol .* RY)));
                clear RY;
                hol([1:si(1) / 4, si(1) * 3/4 + 1:end], :, :) = [];
                hol = ifftshift(ifft2(fftshift(hol)));
            end

            % re-normalize DH to ensure dynamic range comparable with complex-valued pendants
            for color = size(hol, 3):-1:1
                hol(:, :, color) = hol(:, :, color) / norm(hol(:, :, color), 'fro') * info.reffronorm(color);
            end

        end

        %% Convert on-axis to off-axis holograms
        if contains(info.dataset, '_on_axis') % e.g. wut_disp_on_axis

            if (info.verbosity)
                disp('Performing on- to off-axis conversion.')
            end

            if ~strcmpi(info.usagemode, 'complex')
                si = size(hol);
                hol = fftshift(fft2(hol));
                hol = circshift(hol, [0, round(si(2) / 4), 0]);
                hol = ifft2(ifftshift(hol));
            end

            info.dataset = strrep(info.dataset, '_on_axis', ''); % From hereon reconstruct like off_axis: e.g. wut_disp
        end

        %% Initialize resize functions
        if strcmpi(info.lowresmode, 'targetres') && ~strcmpi(info.usagemode, 'complex')
            % Worst case computation
            % if(pix_mode), mode = 'px'; resTarget = cell2mat(resTarget); else, mode = 'angle'; end
            res = size(hol(:, :, 1));

            % Set DiffractionLimited resize fun + ap_size
            if info.isFourierDH
                info.ap_sizes = min(res) * [1, 1];

                if (any(info.ap_sizes < info.targetres))
                    warning('nrsh:aperture', 'Warning in nrsh: effective resolution is smaller than requested due to insufficent aperture size.');
                end

                info.ap_sizes = min(info.ap_sizes, info.targetres);
                resize_fun = @(hol_rendered) diff_resize2(hol_rendered, info.targetres ./ info.ap_sizes);
            else
                [info.ap_sizes, tau] = calcApSizeSimple(info.pixel_pitch, info.wlen, info.targetres, res, rec_dists(rec_par_idx(1, :))); % Uses assumption for max. resolution, i.e. independent of hpos, vpos
                resize_fun = @(hol_rendered) diff_resize2(hol_rendered, info.pixel_pitch, tau);
            end

            info.ap_sizes = repmat({info.ap_sizes}, [1, nbRecons]);
        end

        %% Loop over reconstructions
        for idx = 1:nbRecons

            if strcmpi(info.usagemode, 'complex')
                % Print message
                if (info.verbosity)
                    fprintf('\nCalculating rec_dist=%g ... ', rec_dists(idx));
                end

                t = tic();

                % Numerical reconstruction
                [hol_rendered] = num_rec(hol, info, rec_dists(idx));

                % Get reconstruction time
                actual_rec_time = toc(t); %reconstruction time (this reconstruction)
                avg_rec_time = avg_rec_time + actual_rec_time;

                if (info.verbosity)
                    fprintf('done in %.2f seconds.\n', actual_rec_time);
                end

                % Save as .mat file
                savename = sprintf('%s%s_%g', info.name_prefix, cfg_name, rec_dists(idx));

                if (info.save_as_mat)
                    save(fullfile(figures_path, [savename, '.mat']), 'hol_rendered', '-v7.3');
                end

            else
                % Print message
                if (info.verbosity)
                    fprintf('\nCalculating h_pos=%g v_pos=%g apert_size=%s rec_dist=%g ... ', ...
                        info.h_pos(rec_par_idx(2, idx)), info.v_pos(rec_par_idx(3, idx)), ...
                        strrep(mat2str(info.ap_sizes{rec_par_idx(4, idx)}), ' ', 'x'), ...
                        rec_dists(rec_par_idx(1, idx)));
                end

                t = tic();

                % Apperture application - pt. 1
                if (info.orthographic == false) % i.e. perspective
                    [hol_rendered] = aperture(hol, info.isFourierDH, ...
                        info.pixel_pitch, ...
                        rec_dists(rec_par_idx(1, idx)), ...
                        info.h_pos(rec_par_idx(2, idx)), ...
                        info.v_pos(rec_par_idx(3, idx)), ...
                        info.ap_sizes{rec_par_idx(4, idx)}, ...
                        info.apod);
                else
                    hol_rendered = hol;
                end

                % Numerical reconstruction
                [hol_rendered] = num_rec(hol_rendered, info, ...
                    rec_dists(rec_par_idx(1, idx)), idx == nbRecons);

                % DC filter
                if strcmpi(info.dataset, 'wut_disp')
                    hol_rendered = dc_filter(hol_rendered, ...
                        info.dc_filter_size, ...
                        info.dc_filter_type);
                end

                % Apperture application - pt. 2
                %   TODO: Rework loop over reconstructions in orthographic case, to avoid redundant propagations.
                if (info.orthographic == true)
                    hol_rendered = fftshift(fft2(ifftshift(hol_rendered)));

                    [hol_rendered] = aperture(hol_rendered, info.isFourierDH, ...
                        info.pixel_pitch, ...
                        rec_dists(rec_par_idx(1, idx)), ...
                        info.h_pos(rec_par_idx(2, idx)), ...
                        info.v_pos(rec_par_idx(3, idx)), ...
                        info.ap_sizes{rec_par_idx(4, idx)}, ...
                        info.apod);

                    hol_rendered = ifftshift(ifft2(fftshift(hol_rendered)));
                end

                % Amplitude calculation
                hol_rendered = abs(hol_rendered);

                % Color alignment
                if (strcmpi(info.dataset, 'wut_disp'))
                    hol_rendered = wut_filter(hol_rendered, info);
                end

                % Diffraction limited or custom resizing
                if strcmpi(info.lowresmode, 'targetres')
                    hol_rendered = resize_fun(hol_rendered);
                elseif strcmpi(info.lowresmode, 'aperture')
                    hol_rendered = diff_resize(hol_rendered, info.pixel_pitch, ...
                        min(info.wlen), rec_dists(rec_par_idx(1, idx)), ...
                        info.ap_sizes{rec_par_idx(4, idx)});
                elseif strcmpi(info.lowresmode, 'custom')
                    hol_rendered = info.resize_fun(hol_rendered);
                end

                % Intensity calculation
                if info.save_intensity == 1
                    hol_rendered = hol_rendered .^ 2;
                end

                % Clipping
                [hol_rendered, info.clip_min(idx), info.clip_max(idx)] = clipping(hol_rendered, ...
                    info.perc_clip, info.perc_value, info.hist_stretch, ...
                    info.clip_min(idx), info.clip_max(idx));

                if (info.use_first_frame_reference)
                    info.clip_min = info.clip_min(1) * ones(1, nbRecons);
                    info.clip_max = info.clip_max(1) * ones(1, nbRecons);
                end

                % Get reconstruction time
                actual_rec_time = toc(t); %reconstruction time (this reconstruction)
                avg_rec_time = avg_rec_time + actual_rec_time;

                if (info.verbosity)
                    fprintf('done in %.2f seconds.\n', actual_rec_time);
                end

                % Get file name
                if strcmpi(info.usagemode, 'dynamic')
                    % Update log file with positions
                    fprintf(fh, [sprintf('%s_%s_%g_%g_%s_%g', num2str(idx, 'fID%04.0f'), cfg_name, ...
                                     info.h_pos(rec_par_idx(idx)), ...
                                     info.v_pos(rec_par_idx(idx)), ...
                                     strrep(mat2str(info.ap_sizes{rec_par_idx(idx)}), ' ', 'x'), ...
                                     rec_dists(rec_par_idx(idx))) '\n']);
                    savename = [info.name_prefix num2str(idx, 'fID%04.0f')];
                else
                    savename = sprintf('%s%s_%g_%g_%s_%g', ...
                        info.name_prefix, cfg_name, ...
                        info.h_pos(rec_par_idx(2, idx)), ...
                        info.v_pos(rec_par_idx(3, idx)), ...
                        strrep(mat2str(info.ap_sizes{rec_par_idx(4, idx)}), ' ', 'x'), ...
                        rec_dists(rec_par_idx(1, idx)));
                    if ~strcmpi(info.lowresmode, 'disable'), savename = [savename '_LR']; end
                end

                % Save as .mat file
                if info.save_as_mat == 1
                    save(fullfile(figures_path, [savename, '.mat']), ...
                        'hol_rendered', '-v7.3');

                    if (info.verbosity)
                        disp(['Wrote to file: ' fullfile(figures_path, [savename, '.mat'])])
                    end

                end

                hol_rendered = real2uint(hol_rendered, info.bit_depth); %also if png will not be saved: safer imshow behaviour

                % Show absolute value
                if info.show == 1
                    figure()
                    imshow(hol_rendered)
                    title(sprintf('%s %s h_pos=%g v_pos=%g apert_size=%s rec_dist.=%g', ...
                        info.name_prefix, cfg_name, ...
                        info.h_pos(rec_par_idx(2, idx)), ...
                        info.v_pos(rec_par_idx(3, idx)), ...
                        strrep(mat2str(info.ap_sizes{rec_par_idx(4, idx)}), ' ', 'x'), ...
                        rec_dists(rec_par_idx(1, idx))), 'Interpreter', 'none');
                end

                % Save as .png image
                if info.save_as_image == 1

                    if (isOctave)
                        imwrite(hol_rendered, fullfile(figures_path, [savename, '.png'])); % Bitdepth is implicitly respected
                    else
                        imwrite(hol_rendered, fullfile(figures_path, [savename, '.png']), 'BitDepth', info.bit_depth);
                    end

                    if (info.verbosity)
                        disp(['Wrote to file: ' fullfile(figures_path, [savename, '.png'])])
                    end

                end

            end

        end

        if strcmpi(info.usagemode, 'dynamic')
            % Display message
            if (info.verbosity)
                disp(['Logfile with viewpoints encoded as nrsh filenames written to: ' logfile])
            end

            % Make video with ffmpeg
            if ~strcmpi(info.lowresmode, 'disable')
                suffix = '_LR';
            else
                suffix = '';
            end

            videonam = [info.name_prefix cfg_name, '_nFrames' num2str(nbRecons) '_at' num2str(info.fps) 'FPS' suffix '.mp4'];
            [status, out] = system([ffmpegBin ' -y -r ' num2str(info.fps) ' -i ' fullfile(figures_path, [info.name_prefix 'fID%04d.png']) ' -c:v libx264 -qp 0  -r ' num2str(info.fps) ' -f mp4 ' fullfile(figures_path, videonam)]);
            if (status), error('nrsh:ffmpeg', out); end

            if (info.verbosity)
                disp(['Video written to: ' fullfile(figures_path, videonam)])
            end

            % Clean up individual frames
            fl = dir(fullfile(figures_path, 'f*.png')); fl = {fl.name};

            for f = fl

                try
                    delete(fullfile(figures_path, f{1}))
                catch me
                    warning('nrsh:aperture', ['Warning in nrsh: File: ' fullfile(figures_path, f{1}) ' could not be deleted properly.'])
                end

            end

            % Close file
            fclose(fh);
        end

        %% Clean up
        if (nargout == 0), hol_rendered = []; end
    catch msg_err

        if (strcmpi(info.usagemode, 'dynamic') && fh > -1)
            fclose(fh);
        end

        persistent_sweeper(info.method);
        rethrow(msg_err)
    end

    %% Save output clip values
    clip_min = info.clip_min;
    clip_max = info.clip_max;
    avg_rec_time = avg_rec_time / nbRecons;

    if (info.verbosity)
        fprintf('\nAverage reconstruction time (%d reconstruction(s)): %.2f seconds.\n', ...
            nbRecons, avg_rec_time);
    end

    persistent_sweeper(info.method);

end
