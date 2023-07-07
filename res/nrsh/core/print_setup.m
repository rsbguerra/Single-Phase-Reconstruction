function [] = print_setup(rec_dists, info)
    %PRINT_SETUP Prints current settings informations (user input & cfg file)
    %
    %   Inputs:
    %       rec_dists   - reconstruction distance(s)
    %       info        - reconstruction parameters
    %
    %-------------------------------------------------------------------------
    % Copyright(c) 2019
    % University of Cagliari
    % Department of Electrical and Electronic Engineering
    % Italy
    % All Rights Reserved.
    %-------------------------------------------------------------------------
    %
    % The University of Cagliari - Department of Electrical and Electronic
    % Engineering hereby grants to ISO/IEC JTC1 SC29 WG1
    % (JPEG Committee) and each Member of ISO/IEC JTC1 SC29 WG1 (JPEG
    % Committee) who participate in the Working Group dedicated to the
    % standardization of JPEG Pleno, a non-exclusive, nontransferable,
    % worldwide, license under "University of Cagliari - Department of
    % Electrical and Electronic Engineering" copyrights
    % in this software to reproduce, distribute, display, perform and
    % create derivative works for the sole and exclusive purposes of
    % creating a hologram reconstruction software in the frame of
    % the JPEG Pleno standard.
    %
    % Modifications to this code shall be clearly indicated and
    % identified by the relevant copyright notice(s) of the party
    % generating these changes and/or derivative works.
    %
    % Nothing contained in this software shall, except as herein
    % expressly provided, be construed as conferring by implication,
    % estoppel or otherwise, any license or right under (i) any existing
    % or later issuing patent, whether or not the use of information in
    % this software necessarily employs an invention of any existing or
    % later issued patent, (ii) any copyright, (iii) any trademark, or
    % (iv) any other intellectual property right.
    %
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS "AS IS" AND
    % ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
    % TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
    % PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    % COPYRIGHT OWNER BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    % SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    % LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
    % USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
    % AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    % LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
    % IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
    % THE POSSIBILITY OF SUCH DAMAGE.
    %
    %-------------------------------------------------------------------------

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
