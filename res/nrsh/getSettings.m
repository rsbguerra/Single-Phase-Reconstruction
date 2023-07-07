function info = getSettings(varargin)
% Function Name: getSettings
% This function initializes or modifies the reconstruction settings of nrsh
% through a structure called info
%
% Inputs:
%   varargin    - list of parameter name and value pairs
%
% Output:
%   info        - structure containing the hologram settings
%
% Usage:
%   This function takes as input a list of parameters name and value pairs,
%   such that
%       info = getSettings('OptionName1', OptionValue1, 'OptionName2', OptionValue2, ...)
%    
%   It returns the structure info with fields OptionName1 = OptionValue1, 
%   OptionName2 = OptionValue2, etc. 
%
%   This function can also be used to update a subset of parameters 
%   contained in an existing structure, such that
%       info = getSettings(info, 'OptionName1', OptionValue1, ...)
%	
%   Note:  Settings will be potentially overwritten from nrsh arguments, 
%   e.g. usagemode
%
%   Allowed parameters are the following:
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
%   orthoscopic@logical(1) (optional, default is false)
%               - Allows to obtain orthoscopic reconstruction
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
%-------------------------------------------------------------------------

    addpath(genpath('./core'));
    
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
    
    % Valid field names
    validFieldnameList = {'orthoscopic', 'verbosity', 'usagemode', 'apertureinpxmode', 'ap_sizes', 'h_pos', 'v_pos', ...
                          'clip_min', 'clip_max', 'use_first_frame_reference', ...
                          'dataset', 'cfg_file', 'name_prefix', 'outfolderpath', ...
                          'direction', 'resize_fun', 'targetres', 'fps', ...
                          'wlen', 'pixel_pitch', 'method', 'apod', 'zero_pad', ...
                          'perc_clip', 'perc_value', 'hist_stretch', ...
                          'save_intensity', 'save_as_mat', 'save_as_image', ...
                          'show', 'bit_depth', 'reffronorm', 'offaxisfilter', ...
                          'ref_wave_rad', 'dc_filter_type', 'dc_filter_size', 'img_flt', ...
                          'shift_yx_r', 'shift_yx_g', 'shift_yx_b', ...
                          'hologramname', 'format', 'segmentsnum', ...
                          'segmentsres', 'subsegmentsres', 'spectrumscale'};
    printFieldnameList = [cell2mat(cellfun(@(x) [x, ', '], validFieldnameList(1:end-1), 'UniformOutput', false)), validFieldnameList{end}];

    
    if(isstruct(varargin{1}) && isfield(varargin{1}, 'isInfoStruct'))
        info = varargin{1};
        varargin(1) = [];
    else
        % Initialize info struct
        info = struct('isInfoStruct', 1);
        
        % Parse verbosity first, if existent
        fieldname = 'verbosity';
        info.(fieldname) = false;
        idx = find(cellfun(@(x) strcmpi(x, fieldname), varargin(1:2:end))==1, 1, 'first');
        if(idx)
            info.(fieldname) = varargin{idx+1};
        else
            info.verbosity = true;
        end

        % Parse configuration file second, if existent
        fieldname = 'cfg_file';
        idx = find(cellfun(@(x) strcmpi(x, fieldname), varargin(1:2:end))==1, 1, 'first');
        if(idx)
            info.(fieldname) = varargin{2*idx};
            varargin(2*idx-1:2*idx) = [];

            %% Parse configuration file
            info = read_render_cfg(info);
            if(info.verbosity)
                disp('Config file parsed.')
            end
        end
    end
    
    if (mod(numel(varargin), 2))
        error('getSettings:input_args', 'Error in getSettings: Input should be paired up as "arg_name", "arg_value".')
    end
    
    % Parse remaining options, overwritting default options eventually
    for ii = 1:2:numel(varargin)
        fieldname = lower(varargin{ii});
        if((~isOctave && any(contains(validFieldnameList, fieldname))) || (isOctave && any(~cellfun('isempty', strfind(validFieldnameList, fieldname)))))
            info.(fieldname) = varargin{ii+1};
        else
            warning('getSettings:input_skipped', [fieldname ' is not a valid field name. Valid field names are: ' printFieldnameList])
        end
    end
end