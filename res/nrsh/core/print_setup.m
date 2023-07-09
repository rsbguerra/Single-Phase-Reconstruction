function [] = print_setup(rec_dists, info)
    %PRINT_SETUP Prints current settings informations (user input & cfg file)
    %
    %   Inputs:
    %       rec_dists   - reconstruction distance(s)
    %       info        - reconstruction parameters
    %

    %% Layman's check for octave compatible mode
    isOctave = false;

    try
        a = datetime; clear a;
        contains('abc', 'a');
        isOctave = false;
    catch me
        isOctave = true;
    end

    %% Print configuration
    disp(repmat('*', 1, 90));
    disp(strcat(repmat('*', 1, 26), 'Configuration setup: ', repmat('*', 1, 26)));
    disp(repmat('*', 1, 90));

    % Valid field names
    validFieldnameList = {'usagemode', 'apertureinpxmode', 'ap_sizes', 'h_pos', 'v_pos', ...
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
                              'segmentsres', 'subsegmentsres', 'spectrumscale', 'isBinary', 'isFourierDH', 'orthoscopic'};

    fprintf('\t %30s : %s\n', 'rec_dists', num2str(rec_dists));

    try

        for names = fieldnames(info).'
            fieldname = names{1};

            if ((~isOctave && any(contains(validFieldnameList, fieldname))) || (isOctave && any(~cellfun('isempty', strfind(validFieldnameList, fieldname)))))
                fprintf('\t %30s : ', fieldname);

                if iscell(info.(fieldname))

                    for i = 1:numel(info.(fieldname))

                        if isnumeric(info.(fieldname){i}) || islogical(info.(fieldname){i})
                            fprintf('%s ', num2str(info.(fieldname){i}));
                        else
                            fprintf('%s ', info.(fieldname){i});
                        end

                        if i < numel(info.(fieldname))
                            fprintf('; ');
                        end

                    end

                    fprintf('\n');
                elseif isnumeric(info.(fieldname)) || islogical(info.(fieldname))
                    fprintf('%s\n', num2str(info.(fieldname)));
                elseif isa(info.(fieldname), 'function_handle')
                    fprintf('%s\n', strrep(char(info.(fieldname)), '@(x)', ''));
                else
                    fprintf('%s\n', info.(fieldname));
                end

            end

        end

    catch me
        disp('foo')
    end

end
