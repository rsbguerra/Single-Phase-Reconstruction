function [hologram, dataset] = load_data_auto(path)
    %========================================================================
    %LOAD_DATA_AUTO load hologram automatically, from a folder. Supported
    % datasets: Interfere I,II,III,IV, EmergImg Holograil, B-com 8 bit (Am-Ph),
    % B-com 32 bit (Re-Im), WUT Display.
    %   Inputs:
    %    path              -path to folder where the hologram's files are. In
    %                       this folder, there should not be any other file.
    %
    %   Output:
    %    hologram          - hologram data. It is always a matrix
    %                        (hologram's metadata discarded)
    %    dataset           - dataset info. Same as load_data
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

    fprintf('Automatic hologram loading from %s ...\n', path);

    %load hologram filename(s)
    dir_content = dir(fullfile(path, '*'));
    names_list = {dir_content.name};
    filter = ~[dir_content.isdir] & (~startsWith({dir_content.name}, '.'));
    names_list = names_list(filter);

    if size(names_list, 2) > 3
        error('nrsh:load_data_auto', 'Error in nrsh: too many files in %s.', path)
    elseif isempty(names_list)
        error('nrsh:load_data_auto', 'Error in nrsh: no valid file found in %s.', path)
    end

    load('plenodb.mat', 'plenodb')

    [~, hol_name1, hol_ext1] = fileparts(names_list{1});

    total_match = zeros(1, size(plenodb, 2));

    for idx = 1:size(plenodb, 2)
        current_match = regexpi(hol_name1, plenodb{1, idx});
        current_match = cell2mat(current_match);

        if length(current_match) > 1
            error('nrsh:load_data_auto', 'Error in nrsh: unable to find a match!') %multiple matches not allowed, for now.
        elseif isempty(current_match)
            current_match = 0;
        end

        total_match(1, idx) = current_match;
    end

    dataset = find(total_match);

    if dataset == 1 %BCOM. It can be Am-Ph or Re-Im
        [hol_ord_names, bcom_type_flag] = bcom_check(names_list, hol_name1, hol_ext1);
        %hol_ord_names are the components' names in
        %loading order: first Am or Re, second Ph or Im.
    end

    if dataset == 7 %WUT DISP. It can be monochr. or rgb
        [hol_ord_names, rgb_flag, on_axis] = wut_disp_check(names_list, hol_name1, hol_ext1);
    end

    if isempty(dataset)
        error('nrsh:load_data_auto', 'Error in nrsh: automatic loading failed. Note that:\n1. It is strongly recommended to use the original filenames;\n2. %s should not contain any other file other than those that constitute the hologram to load.', path)
    end

    switch dataset
        case 1 %bcom dataset

            if bcom_type_flag == 1
                dataset = 'bcom8';
                am = im2double(imread(fullfile(path, hol_ord_names{1})));
                ph = 2.0 * pi * im2double(imread(fullfile(path, hol_ord_names{2})));
                hologram = am .* exp(1i * ph);
            elseif bcom_type_flag == 0
                dataset = 'bcom32';
                real_part_path = fullfile(path, hol_ord_names{1});
                info = exrinfo(real_part_path);
                hol_real = zeros(info.size(1), info.size(2), 3, 'single');
                hol_real(:, :, 1) = exrreadchannels(real_part_path, 'R');
                hol_real(:, :, 2) = exrreadchannels(real_part_path, 'G');
                hol_real(:, :, 3) = exrreadchannels(real_part_path, 'B');

                imag_part_path = fullfile(path, hol_ord_names{2});
                hol_imag = zeros(size(hol_real), 'single');
                hol_imag(:, :, 1) = exrreadchannels(imag_part_path, 'R');
                hol_imag(:, :, 2) = exrreadchannels(imag_part_path, 'G');
                hol_imag(:, :, 3) = exrreadchannels(imag_part_path, 'B');

                hologram = complex(hol_real, hol_imag);
            else
                dataset = 'bcom32_bin';
                hologram = load(fullfile(path, hol_ord_names{1}));

                try
                    hologram = hologram.Hbin; %bcom32_bin
                catch
                    error('nrsh:load_data_auto', 'Error in nrsh: cannot load hologram')
                end

            end

        case {2, 3, 4} %interfere1,2,3
            dataset = 'interfere';

            if ~(strcmpi(hol_ext1, '.mat') && size(names_list, 2) == 1)
                error('nrsh:load_data_auto', 'Error in nrsh: unable to load the hologram from %s. In order to load an Interfere hologram, only one mat file should be in the folder.', path)
            end

            hologram = load(fullfile(path, names_list{1}));

            try
                hologram = hologram.Hol; %Interfere 1
            catch

                try
                    hologram = hologram.CGH.Hol; %Interfere 2 and 3
                catch

                    try
                        hologram = hologram.H; %Interfere 5
                    catch

                        try
                            hologram = hologram.Hbin; %Interfere_bin
                            dataset = 'interfere_bin';
                        catch
                            error('nrsh:load_data_auto', 'Error in nrsh: cannot load hologram')
                        end

                    end

                end

            end

        case 5 %interfere4
            dataset = 'interfere4';

            if ~(strcmpi(hol_ext1, '.mat') && size(names_list, 2) == 1)
                error('nrsh:load_data_auto', 'Error in nrsh: unable to load the hologram from %s. In order to load an Interfere IV hologram, only one mat file should be in the folder.', path)
            end

            hologram = load(fullfile(path, names_list{1}));

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
                        error('nrsh:load_data_auto', 'Error in nrsh: cannot load hologram')
                    end

                end

            end

        case 6 %Emergimg
            dataset = 'emergimg';

            if ~(strcmpi(hol_ext1, '.mat') && size(names_list, 2) == 1)
                error('nrsh:load_data_auto', 'Error in nrsh: unable to load the hologram from %s. In order to load an EmergImg-Holograil hologram, only one mat file should be in the folder.', path)
            end

            hologram = load(fullfile(path, names_list{1}));

            try
                hologram = hologram.u1; %EmergImg
            catch

                try
                    hologram = hologram.Hbin; %EmergImg_bin
                    dataset = 'emergimg_bin';
                catch
                    error('nrsh:load_data_auto', 'Error in nrsh: cannot load hologram')
                end

            end

        case 7 %WUT display

            if on_axis == 0
                dataset = 'wut_disp';

                if rgb_flag == 0
                    hologram = double(imread(fullfile(path, hol_ord_names)));
                else
                    hologram(:, :, 1) = double(imread(fullfile(path, hol_ord_names{1})));
                    hologram(:, :, 2) = double(imread(fullfile(path, hol_ord_names{2})));
                    hologram(:, :, 3) = double(imread(fullfile(path, hol_ord_names{3})));
                end

            else
                hologram = load(fullfile(path, hol_ord_names));

                try
                    hologram = hologram.dh;
                    dataset = 'wut_disp_on_axis';
                catch

                    try
                        hologram = hologram.Hbin;
                        dataset = 'wut_disp_on_axis_bin';
                    catch
                        error('nrsh:load_data_auto', 'Error in nrsh: cannot load hologram')
                    end

                end

            end

        otherwise
            error('nrsh:load_data_auto', 'Error in nrsh: unknown dataset type');
    end

    disp('...loading completed.');

end

%% AUX. FUNCTIONS

function [hol_ord_names, bcom_type_flag] = bcom_check(names_list, hol_name1, hol_ext1)

    if size(names_list, 2) == 2
        [~, hol_name2, hol_ext2] = fileparts(names_list{2});

        if strcmpi(hol_ext1, '.bmp') && strcmpi(hol_ext2, '.bmp')
            bcom_type_flag = 1;
        elseif strcmpi(hol_ext1, '.exr') && strcmpi(hol_ext2, '.exr')
            bcom_type_flag = 0;
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a B-Com hologram, but file extensions are not bmp or exr.', path)
        end

    elseif size(names_list, 2) == 1 && strcmpi(hol_ext1, '.mat')
        bcom_type_flag = 2;
    else
        error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a B-Com hologram, but one of the two files is missing.', path)
    end

    if bcom_type_flag == 1

        if regexpi(hol_name1, '.*ampli.*')
            hol_ord_names{1} = names_list{1};
        elseif regexpi(hol_name2, '.*ampli.*')
            hol_ord_names{1} = names_list{2};
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a B-Com 8 bit hologram, the amplitude file cannot be found.', path)
        end

        if regexpi(hol_name1, '.*phase.*')
            hol_ord_names{2} = names_list{1};
        elseif regexpi(hol_name2, '.*phase.*')
            hol_ord_names{2} = names_list{2};
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a B-Com 8 bit hologram, the phase file cannot be found.', path)
        end

    elseif bcom_type_flag == 0

        if regexpi(hol_name1, '.*real.*')
            hol_ord_names{1} = names_list{1};
        elseif regexpi(hol_name2, '.*real.*')
            hol_ord_names{1} = names_list{2};
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a B-Com 32 bit hologram, the real part file cannot be found.', path)
        end

        if regexpi(hol_name1, '.*imag.*')
            hol_ord_names{2} = names_list{1};
        elseif regexpi(hol_name2, '.*imag.*')
            hol_ord_names{2} = names_list{2};
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a B-Com 32 bit hologram, the imag part file cannot be found.', path)
        end

    else
        hol_ord_names{1} = names_list{1};
    end

end

function [hol_ord_names, rgb_flag, on_axis] = wut_disp_check(names_list, hol_name1, hol_ext1)

    if length(names_list) == 1 %assumed monochrome hologram. Not strong, though.
        rgb_flag = 0;

        if strcmpi(hol_ext1, '.bmp')
            hol_ord_names = names_list{1};
            on_axis = 0;
        elseif strcmpi(hol_ext1, '.mat')
            hol_ord_names = names_list{1};
            on_axis = 1;
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a WUT Display hologram, but file extensions are not bmp or mat.', path)
        end

    elseif length(names_list) == 3
        rgb_flag = 1;
        [~, hol_name2, hol_ext2] = fileparts(names_list{2});
        [~, hol_name3, hol_ext3] = fileparts(names_list{3});

        if strcmpi(hol_ext1, '.bmp') && strcmpi(hol_ext2, '.bmp') && strcmpi(hol_ext3, '.bmp')
            on_axis = 0;
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a WUT Display color hologram, but file extensions are not bmp.', path)
        end

        %search the R component. The name must contain _R/G/B. Not strong.
        if regexp(hol_name1, '.*_R.*')
            hol_ord_names{1} = names_list{1};
        elseif regexpi(hol_name2, '.*_R.*')
            hol_ord_names{1} = names_list{2};
        elseif regexpi(hol_name3, '.*_R.*')
            hol_ord_names{1} = names_list{3};
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a WUT Display color hologram, but the RED component cannot be found.', path)
        end

        %search the G component.
        if regexp(hol_name1, '.*_G.*')
            hol_ord_names{2} = names_list{1};
        elseif regexpi(hol_name2, '.*_G.*')
            hol_ord_names{2} = names_list{2};
        elseif regexpi(hol_name3, '.*_G.*')
            hol_ord_names{2} = names_list{3};
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a WUT Display color hologram, but the GREEN component cannot be found.', path)
        end

        %search the B component.
        if regexp(hol_name1, '.*_B.*')
            hol_ord_names{3} = names_list{1};
        elseif regexpi(hol_name2, '.*_B.*')
            hol_ord_names{3} = names_list{2};
        elseif regexpi(hol_name3, '.*_B.*')
            hol_ord_names{3} = names_list{3};
        else
            error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a WUT Display color hologram, but the BLUE component cannot be found.', path)
        end

    else
        error('nrsh:load_data_auto', 'Error in nrsh: it appears that %s contains a WUT Display color hologram, but some files are missing.', path)
    end

end
