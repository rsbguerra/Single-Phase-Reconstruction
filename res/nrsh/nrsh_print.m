function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info, varargin)
    % function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info, hologramname, format, segmentsnum, segmentsres, subsegmentsres, spectrumscale, clip_min, clip_max)
    % function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info, hologramname, format, segmentsnum, segmentsres, subsegmentsres, spectrumscale)
    % function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info, hologramname, format, segmentsnum, segmentsres, subsegmentsres)
    % function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info, hologramname, format, segmentsnum, segmentsres)
    % function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info, hologramname, format, segmentsnum)
    % function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info, hologramname, format)
    % function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info, hologramname)
    % function [hol_rendered, clip_min, clip_max] = nrsh_print(hol, viewpoints, info)
    %
    % Function Name: nrsh_print
    % This function reconstructs a high resolution hologram from several viewpoints
    %
    % INPUTS:
    %   hol@char-array (mandatory)
    %               - Folder path in which the hologram segments can be found
    %   viewpoints@numeric(N,3) (mandatory)
    %               - User viewpoints, in normalized coordinates in the range
    %                 ([-1, 1], [-1, 1], [0, inf]), where -1 is the leftmost or
    %                 lowermost position, and +1 is the rightmost or uppermost
    %                 position. It should be a matrix of size [n 3], with one
    %                 viewpoint per row.
    %   info@struct (mandatory)
    %               - Reconstruction parameters, initialized with getSettings
    %                 via info = getSettings(*Option name*, *option value*, ...),
    %                 where any option of the infoStruct may be specified here.
    %                 (see below)
    %
    %   The user can also overwrite parameters defined in configuration files
    %   or in structure info by passing them in this specific order as additional
    %   input parameters through varargin: hologramname, format, segmentsnum,
    %   segmentsres, subsegmentsres, spectrumscale, clip_min, clip_max
    %
    %   info always contains info.isInfoStruct=1. It may also contain following
    %   parameters, initialized via getSettings:
    %
    %   hologramname@char-array (mandatory)
    %               - Hologram name
    %   format@char-array (mandatory)
    %               - Hologram format, should be 'bilevel' or 'complex'
    %   segmentsnum@numeric(1,2) or numeric(2,1) (mandatory)
    %               - Number of hologram segments (numeric(1,2) or numeric(2,1))
    %   segmentsres@numeric(1,2) or numeric(2,1) (mandatory)
    %               - Resolution of hologram segments
    %   subsegmentsres@numeric(1,2) or numeric(2,1) (optional, default is segmentsres)
    %               - Resolution of hologram subsegments
    %   spectrumscale@numeric(1) (optional, default is 1)
    %               - Fourier spectrum scale
    %	clip_min@numeric(N,1) or numeric(1) (optional, default is empty)
    %               - Minimal intensity value for clipping. It can be a single
    %                 value or a row or column vector of values (one value per
    %                 reconstuction).
    %	clip_max@numeric(N,1) or numeric(1) (optional, default is empty)
    %               - Maximal intensity value for clipping. It can be a single
    %                 value or a row or column vector of values (one value per
    %                 reconstuction).
    %   dataset@char-array (optional, default is empty)
    %               - Dataset to which hol belongs. It should be one of the
    %                 following char. arrays: bcom_print, etri_print.
    %   cfg_file@char-array (optional, default is empty)
    %               - Path to configuration file. If left, empty, alternatively
    %                 required fields: wlen, pixel_pitch and method (see below)
    %   name_prefix@char-array (optional, default is empty)
    %               - Output file name prefix
    %   outfolderpath@char-array (optional, default is './figures')
    %               - Path to the output folder for figures
    %
    %   Additionally, any of the following fields may overwrite cfg_file options:
    %       wlen@numeric(1) or numeric(1,3) or numeric(3, 1)
    %       pixel_pitch@numeric(1,2) or numeric(2,1) or numeric(1)
    %       perc_clip@boolean(1)
    %       perc_value@numeric(1) in [0, 100]
    %       hist_stretch@boolean(1)
    %       save_intensity@boolean(1)
    %       save_as_mat@boolean(1)
    %       save_as_image@boolean(1)
    %       show@boolean(1)
    %       bit_depth@numeric(1)
    %
    % Parameter sources with decreasing precedence:
    %   nrsh_print input parameters > info struct > config file
    %   Overwrite only, if not empty.
    %
    % OUTPUTS:
    %   hol_rendered	- reconstructions of the input hologram, returned as
    %                     a four dimensional array of standard unsigned integer
    %                     images (8 or 16 bpp), with a size of [height, width,
    %                     nbColors, nbViewpoints].
    %   clip_min    	- minimal intensity of the numerical reconstructions.
    %                     In case of multiple reconstructions, one value per
    %                     reconstruction is returned
    %   clip_max    	- maximal intensity of the numerical reconstructions.
    %                     In case of multiple reconstructions, one value per
    %                     reconstruction is returned
    %
    % Authors:      Antonin GILLES, Patrick GIOIA
    %               Institute of Research & Technology b<>com
    % -------------------------------------------------------------------------

    %% Initialization
    addpath(genpath('./core'));

    %% Check number of arguments
    if nargin < 3
        error('nrsh_print:input_args', 'Error in nrsh_print: not enough input arguments.')
    end

    %% Parse additional varargin, overwriting default info struct entries.
    fieldnameList = {'hologramname', 'format', 'segmentsnum', 'segmentsres', 'subsegmentsres', 'spectrumscale', 'clip_min', 'clip_max'};

    for ii = 1:(numel(varargin))
        info.(fieldnameList{ii}) = varargin{ii};
    end

    %% Set default settings
    info = defaultSettings(zeros(1, 1, numel(info.wlen)), 0, info);

    %% Validate and print settings
    validateSettings(zeros(1, 1, numel(info.wlen)), info);
    print_setup(0, info);

    %% Create reconstructions savepath
    [~, cfg_name] = fileparts(info.cfg_file);
    figures_path = fullfile(info.outfolderpath, cfg_name);
    if (~exist(figures_path, 'dir')), mkdir(figures_path); end

    %% Check clip_min and clip_max
    nbRecons = size(viewpoints, 1);

    if (numel(info.clip_min) > 1)

        if (numel(info.clip_min) < nbRecons)
            error('nrsh_print:invalid_input', 'Error in nrsh_print: mismatch in parameter list lengths, wrt. clip_min.');
        end

    else
        info.clip_min = repmat(info.clip_min, [1, nbRecons]);
    end

    if (numel(info.clip_max) > 1)

        if (numel(info.clip_max) < nbRecons)
            error('nrsh_print:invalid_input', 'Error in nrsh_print: mismatch in parameter list lengths, wrt. clip_max.');
        end

    else
        info.clip_max = repmat(info.clip_max, [1, nbRecons]);
    end

    %% Check subSegmentRes
    if info.subsegmentsres(1) > info.segmentsres(1) || ...
            info.subsegmentsres(2) > info.segmentsres(2)
        info.subsegmentsres = info.segmentsres;
    end

    %% Initialiaze output
    subsegmentsnum = floor(info.segmentsres ./ info.subsegmentsres);
    totsegmentsnum = info.segmentsnum .* subsegmentsnum;
    spectrumres = info.spectrumscale .* info.subsegmentsres;
    hol_rendered = zeros([totsegmentsnum numel(info.wlen) size(viewpoints, 1)]);
    scale = 1 / sqrt(spectrumres(1) * spectrumres(2));
    ratio = info.subsegmentsres(2) / info.subsegmentsres(1);

    % Loop over segments
    for m = 1:info.segmentsnum(1)

        for n = 1:info.segmentsnum(2)

            % Load segment
            segment = load_segment(hol, info, m, n);
            subRecons = zeros([subsegmentsnum numel(info.wlen) size(viewpoints, 1)]);

            % Loop over subsegments
            for mm = 1:subsegmentsnum(1)

                for nn = 1:subsegmentsnum(2)

                    % Load subsegment
                    jminIn = (mm - 1) * info.subsegmentsres(1) + 1;
                    jmaxIn = mm * info.subsegmentsres(1);
                    iminIn = (nn - 1) * info.subsegmentsres(2) + 1;
                    imaxIn = nn * info.subsegmentsres(2);
                    subSegment = segment(jminIn:jmaxIn, iminIn:imaxIn, :);

                    % Get segment position
                    subSegmentCoordJ = (m - 1) * subsegmentsnum(1) + mm - 1;
                    subSegmentCoordI = (n - 1) * subsegmentsnum(2) + nn - 1;
                    subSegmentPosY = 1 - 2 * (subSegmentCoordJ + 0.5) / totsegmentsnum(1);
                    subSegmentPosX = ratio * (2 * (subSegmentCoordI + 0.5) / totsegmentsnum(2) - 1);

                    % Loop over colors
                    for k = 1:numel(info.wlen)
                        % Compute 2D Fourier Transform
                        fourierSpectrum = fftshift(fft2(subSegment(:, :, k), spectrumres(1), spectrumres(2)));

                        % Loop over positions
                        for p = 1:size(viewpoints, 1)
                            % Compute angles
                            angleX = atan((subSegmentPosX - viewpoints(p, 1)) / viewpoints(p, 3));
                            angleY = atan((subSegmentPosY - viewpoints(p, 2)) / viewpoints(p, 3));

                            % Get frequency coordinates
                            freqX = sin(angleX) / info.wlen(k);
                            freqY = sin(angleY) / info.wlen(k);
                            freqCoordI = floor((info.pixel_pitch * freqX + 0.5) * spectrumres(2)) + 1;
                            freqCoordJ = floor((0.5 - info.pixel_pitch * freqY) * spectrumres(1)) + 1;

                            % Get frequency component
                            if freqCoordI > 0 && freqCoordI < spectrumres(2) + 1 && ...
                                    freqCoordJ > 0 && freqCoordJ < spectrumres(1) + 1
                                subRecons(mm, nn, k, p) = scale * fourierSpectrum(freqCoordJ, freqCoordI);
                            end

                        end

                    end

                end

            end

            %% Copy to recons
            jminIn = (m - 1) * subsegmentsnum(1) + 1;
            jmaxIn = m * subsegmentsnum(1);
            iminIn = (n - 1) * subsegmentsnum(2) + 1;
            imaxIn = n * subsegmentsnum(2);
            hol_rendered(jminIn:jmaxIn, iminIn:imaxIn, :, :) = subRecons;
        end

    end

    %% Keep intensity
    hol_rendered = abs(hol_rendered);

    if info.save_intensity == 1
        hol_rendered = hol_rendered .* hol_rendered;
    end

    %% Loop over positions
    for p = 1:size(viewpoints, 1)
        [hol_rendered(:, :, :, p), info.clip_min(p), info.clip_max(p)] = ...
            clipping(hol_rendered(:, :, :, p), info.perc_clip, info.perc_value, ...
            info.hist_stretch, info.clip_min(p), info.clip_max(p));
        recons = hol_rendered(:, :, :, p);
        savename = sprintf('%s%s_%s', info.name_prefix, cfg_name, . ...
            strrep(mat2str(viewpoints(p, :)), ' ', '_'));

        %save abs as .mat file
        if info.save_as_mat == 1
            save(fullfile(figures_path, [savename, '.mat']), 'recons', '-v7.3');
        end

        recons = real2uint(recons, info.bit_depth); %also if png will not be saved: safer imshow behaviour

        %show abs
        if info.show == 1
            figure()
            imshow(recons)
            title(sprintf('%s viewpoint=%s', cfg_name, ...
                mat2str(viewpoints(p, :)), 'Interpreter', 'none'));
        end

        %save abs as png image
        if info.save_as_image == 1
            imwrite(recons, fullfile(figures_path, [savename, '.png']), ...
                'BitDepth', info.bit_depth);
        end

    end

    hol_rendered = real2uint(hol_rendered, info.bit_depth); %also if png will not be saved: safer imshow behaviour
    clip_min = info.clip_min;
    clip_max = info.clip_max;

end
