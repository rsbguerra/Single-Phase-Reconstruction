function info = read_render_cfg(info)
    %READ_RENDER_CFG Reads rendering parameters from configuration file
    %    info       - Rendering parameters structure
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
