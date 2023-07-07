function [hologram, dataset] = load_data()
    %========================================================================
    %LOAD_DATA load hologram to workspace
    %   Inputs:
    %    No input required. Supported datasets: Interfere (I,II,III,IV),
    %    EmergImg Holograil, B-com 8 bit (Am-Ph), B-com 32 bit (Re-Im),
    %    WUT Display.
    %
    %
    %   Output:
    %    hologram          - hologram data. It is always a matrix
    %                        (hologram's metadata discarded)
    %    dataset           - dataset info. It can be: 'bcom8', 'bcom32',
    %                        'interfere' (for Interfere I,II and III),
    %                        'interfere4' (for Interfere IV),
    %                        'emergimg', 'wut_disp'
    %
    %   Example:
    %
    %  [hologram, dataset]=load_data();
    %
    % For B-com 32bit exr files HDRITools is used:
    % https://bitbucket.org/edgarv/hdritools
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

    dataset_type = {'b<>com 8bit (Am-Ph)', 'b<>com 32bit (Re-Im)', ...
                    'b<>com binary', 'Interfere (I, II, III)', ...
                        'Interfere IV', 'EmergImg-HoloGrail', ...
                        'WUT Display (off-axis)', 'WUT Display (on-axis)'};

    [idx, tf] = listdlg('ListString', dataset_type, 'SelectionMode', 'single', ...
        'Name', 'Select Dataset Type', 'ListSize', [300, 100]);

    if tf == 0 %no user selection
        error('nrsh:load_data', 'Error in nrsh: you have to select a dataset type');
    end

    switch idx

        case 1 % B-com 8 bit
            dataset = 'bcom8';
            [filename, filepath] = uigetfile('*.bmp', 'Search Amplitude to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            am = im2double(imread([filepath, filename]));

            [filename, filepath] = uigetfile([filepath, '*.bmp'], 'Search Phase to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            ph = 2.0 * pi * im2double(imread([filepath, filename]));

            hologram = am .* exp(1i * ph);

        case 2 % B-com 32 bit
            dataset = 'bcom32';
            [filename, filepath] = uigetfile('*.exr', 'Search Real Part to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            info = exrinfo([filepath, filename]);
            hol_real = zeros(info.size(1), info.size(2), 3, 'single');
            hol_real(:, :, 1) = exrreadchannels([filepath, filename], 'R');
            hol_real(:, :, 2) = exrreadchannels([filepath, filename], 'G');
            hol_real(:, :, 3) = exrreadchannels([filepath, filename], 'B');

            [filename, filepath] = uigetfile([filepath, '*.exr'], 'Search Imaginary Part to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            hol_imag = zeros(size(hol_real), 'single');
            hol_imag(:, :, 1) = exrreadchannels([filepath, filename], 'R');
            hol_imag(:, :, 2) = exrreadchannels([filepath, filename], 'G');
            hol_imag(:, :, 3) = exrreadchannels([filepath, filename], 'B');

            hologram = complex(hol_real, hol_imag);

        case {3} % B-com binary
            dataset = 'bcom32_bin';
            [filename, filepath] = uigetfile('*.mat', 'Search hologram to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            hologram = load([filepath filename]);

            try
                hologram = hologram.Hbin; %bcom32_bin
            catch
                error('nrsh:load_data', 'Error in nrsh: cannot load hologram')
            end

        case {4} %InterfereI,II,III
            dataset = 'interfere';
            [filename, filepath] = uigetfile('*.mat', 'Search hologram to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            hologram = load([filepath filename]);

            try
                hologram = hologram.Hol; %Interfere 1
            catch

                try
                    hologram = hologram.CGH.Hol; %Interfere 2 and 3
                catch

                    try
                        hologram = hologram.Hbin; %Interfere_bin
                        dataset = 'interfere_bin';
                    catch
                        error('nrsh:load_data', 'Error in nrsh: cannot load hologram')
                    end

                end

            end

        case 5 %Interfere 4
            dataset = 'interfere4';
            [filename, filepath] = uigetfile('*.mat', 'Search hologram to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            hologram = load([filepath filename]);

            try
                hologram = hologram.cghF; %CGH
            catch

                try
                    hologram = hologram.dh; %OPT
                catch

                    try
                        hologram = hologram.Hbin; %BIN
                        dataset = 'interfere4_bin';
                    catch
                        error('nrsh:load_data', 'Error in nrsh: cannot load hologram')
                    end

                end

            end

        case 6 % Emergimg
            dataset = 'emergimg';
            [filename, filepath] = uigetfile('*.mat', 'Search hologram to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            hologram = load([filepath filename]);

            try
                hologram = hologram.u1; %EmergImg
            catch

                try
                    hologram = hologram.Hbin; %EmergImg_bin
                    dataset = 'emergimg_bin';
                catch
                    error('nrsh:load_data', 'Error in nrsh: cannot load hologram')
                end

            end

        case 7 %WUT display (off-axis)
            dataset = 'wut_disp';
            [filename, filepath] = uigetfile('*.bmp', 'Search Red channel (or monochrome hologram) to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            else
                hologram(:, :, 1) = double(imread([filepath, filename]));

                gray_hol = questdlg('Is the hologram monochrome?', 'WUT Display', 'Yes', 'No', 'Yes');

                if strcmp('Yes', gray_hol)
                    return
                end

            end

            [filename, filepath] = uigetfile([filepath, '*.bmp'], 'Search Green channel to load');

            if filename == 0
                error(nrsh:load_data', 'Error in nrsh: no files selected')
            end

            hologram(:, :, 2) = double(imread([filepath, filename]));

            [filename, filepath] = uigetfile([filepath, '*.bmp'], 'Search Blue channel to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            hologram(:, :, 3) = double(imread([filepath, filename]));

        case 8 %WUT display (on-axis)
            dataset = 'wut_disp_on_axis';
            [filename, filepath] = uigetfile('*.mat', 'Search hologram to load');

            if filename == 0
                error('nrsh:load_data', 'Error in nrsh: no file selected');
            end

            hologram = load([filepath filename]);

            try
                hologram = hologram.dh;
            catch

                try
                    hologram = hologram.Hbin;
                    dataset = 'wut_disp_on_axis_bin';
                catch
                    error('nrsh:load_data', 'Error in nrsh: cannot load hologram')
                end

            end

        otherwise
            error('nrsh:load_data', 'Error in nrsh: unknown dataset type');
    end

    %msg_box=msgbox('Hologram Loaded','Info');

end
