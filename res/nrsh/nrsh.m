function [hol_rendered, clip_min, clip_max] = nrsh(hol, dataset, cfg_file, rec_dists, ap_sizes, h_pos, v_pos, clip_min, clip_max, name_prefix, doDynamic, outFolderPath, refFroNorm)
    %% NRSH reconstructs a hologram from Pleno DB. The hologram should be provided as input to the function.
    %
    %   Inputs:
    %    hol               - hologram to reconstruct. It can be a matrix that
    %                        has been previously loaded in the workspace or a
    %                        path to a folder where the hologram is stored.
    %    dataset           - dataset to which hol belongs. It should be one of
    %                        the following char. arrays: bcom8, bcom32, interfere4
    %                        interfere, emergimg, wut_disp, wut_disp_on_axis,
    %                        bcom32_bin, interfere4_bin, interfere_bin, emergimg_bin,
    %                        wut_disp_on_axis_bin.
    %                        If hol is a path to a folder, it can be left empty with: ''
    %    cfg_file          - path to configuration file
    %    rec_dists         - reconstruction distance(s) [m]. It can be a single
    %                        value or a row or column vector of values
    %    ap_sizes(*)       - synthetic aperture size. It can be a single value,
    %                        a row or column vector of values (angle-based aperture) or
    %                        it can be a 1xN cell array (pixel-based aperture)
    %                        in which every element is a 1x2 array representing
    %                        the aperture size in pixel (HxW).
    %    h_pos             - horizontal position(s) [deg] at which the synthetic
    %                        aperture will be placed. It can be a single value
    %                        or a row or column vector of values
    %    v_pos(**)         - vertical position(s) at which the synthetic
    %                        aperture will be placed. It can be a single value
    %                        or a row or column vector of values
    %    clip_min(***)     - minimal intensity value for clipping. It can be a
    %                        single value or a row or column vector of values
    %    clip_max(***)     - maximal intensity value for clipping. It can be a
    %                        single value or a row or column vector of values
    %    name_prefix       - name prefix, optional.
    %    doDynamic         - true: use individual viewpoints as listed
    %                        false - default: use combination of all possible viewpoints
    %    outFolderPath     - path for base folder for figure output; default: './figures'
    %    refFroNorm        - Frobenius norm per color channel of complex valued ground truth;
    %                        only required for binary DHs, can be arbitrary (!=0) for binary
    %                        DHs not obtained from complex-valued pendants
    %
    %   Output:
    %    hol_rendered      - reconstruction of the input hologram, returned as
    %                        standard unsigned integer image (8 or 16 bpp). In
    %                        case of multiple reconstructions, only the last is
    %                        returned.
    %    clip_min          - minimal intensity of the numerical reconstructions.
    %                        In case of multiple reconstructions, one value per
    %                        reconstruction is returned
    %    clip_max          - maximal intensity of the numerical reconstructions.
    %                        In case of multiple reconstructions, one value per
    %                        reconstruction is returned
    %
    % (*)optional. If not provided, no synthetic aperture will be used
    %              (dof_angles=0).
    % (**)optional. If not provided, is equal to h_angles.
    % (***)optional. If not provided, are computed and returned as the minimal
    %               and maximal numerical reconstruction intensity values after
    %               the optional percentile clipping and histogram stretching
    %               operations
    %
    %   Examples:
    %   [hol_rendered, clip_min, clip_max]=nrsh('./folder', '', ...
    %               './config_files/bcom/dices8k_000.txt', 0.00329, 5, 0, 0, 0, 1, 'GT_')
    %
    %   [hol_rendered, clip_min, clip_max]=nrsh(u1, 'interfere/emergimg',...
    %              './config_files/emergimg/astronaut_000.txt', -0.1721)

    %INIZIALIZATION
    addpath(genpath('./core'));

    avg_rec_time = 0; %average reconstruction time (all reconstructions)

    %USER INPUT CHECK
    %create reconstructions savepath
    [~, cfg_name] = fileparts(cfg_file);

    if (nargin < 12)
        figures_path = fullfile('./figures', cfg_name); %path where figures will be saved
    else
        figures_path = fullfile(outFolderPath, cfg_name); %path where figures will be saved
    end

    if (~exist(figures_path, 'dir')), mkdir(figures_path); end
    if (nargin < 11), doDynamic = false; end

    switch nargin
        case {10, 11, 12, 13}
            if (doDynamic)
                nbRecons = max([numel(rec_dists); numel(ap_sizes); numel(h_pos); numel(v_pos)]);
            else
                nbRecons = numel(rec_dists) * numel(ap_sizes) * numel(h_pos) * numel(v_pos);
            end

            clip_max = clip_max(:).';
            clip_min = clip_min(:).';
            v_pos = v_pos(:).';
            h_pos = h_pos(:).';
            ap_sizes = ap_sizes(:).';
            rec_dists = rec_dists(:).';

        case 9
            if (doDynamic)
                nbRecons = max([numel(rec_dists); numel(ap_sizes); numel(h_pos); numel(v_pos)]);
            else
                nbRecons = numel(rec_dists) * numel(ap_sizes) * numel(h_pos) * numel(v_pos);
            end

            name_prefix = '';
            clip_max = clip_max(:).';
            clip_min = clip_min(:).';
            v_pos = v_pos(:).';
            h_pos = h_pos(:).';
            ap_sizes = ap_sizes(:).';
            rec_dists = rec_dists(:).';

        case {7, 8}
            if (doDynamic)
                nbRecons = max([numel(rec_dists); numel(ap_sizes); numel(h_pos); numel(v_pos)]);
            else
                nbRecons = numel(rec_dists) * numel(ap_sizes) * numel(h_pos) * numel(v_pos);
            end

            name_prefix = '';
            clip_min = -ones(1, nbRecons);
            clip_max = -ones(1, nbRecons);
            v_pos = v_pos(:).';
            h_pos = h_pos(:).';
            ap_sizes = ap_sizes(:).';
            rec_dists = rec_dists(:).';

        case 6
            name_prefix = '';
            h_pos = h_pos(:).';
            v_pos = h_pos;

            if (doDynamic)
                nbRecons = max([numel(rec_dists); numel(ap_sizes); numel(h_pos); numel(v_pos)]);
            else
                nbRecons = numel(rec_dists) * numel(ap_sizes) * numel(h_pos) * numel(v_pos);
            end

            clip_min = -ones(1, nbRecons);
            clip_max = -ones(1, nbRecons);
            ap_sizes = ap_sizes(:).';
            rec_dists = rec_dists(:).';

        case 5
            error('NRSH:input_arguments', 'The synthetic aperture size has been specified without providing its position.\nPlease restart NRSH providing also h_pos and v_pos parameters.');

        case 4
            name_prefix = '';
            nbRecons = numel(rec_dists);
            clip_min = -ones(1, nbRecons);
            clip_max = -ones(1, nbRecons);
            ap_sizes = 0; h_pos = 0; v_pos = 0;
            rec_dists = rec_dists(:).';

        case {1, 2, 3}
            error('NRSH:input_arguments', 'Not enough input arguments.')
    end

    if (isempty(clip_min)), clip_min = -ones(1, nbRecons); end
    if (isempty(clip_max)), clip_max = -ones(1, nbRecons); end

    if iscell(ap_sizes)
        pix_mode = 1;
        disp('NRSH IS WORKING IN PIXEL-BASED MODE.')
    else
        pix_mode = 0;
        disp('NRSH IS WORKING IN ANGLE-BASED MODE.')
    end

    check_user_input

    %LOAD HOLOGRAM FROM FOLDER IF hol IS A PATH
    if ischar(hol)
        [hol, dataset] = load_data_auto(hol); %load hologram from folder
    end

    isBinary = contains(dataset, 'bin');

    if isBinary
        dataset = dataset(1:end - 4);
        if (nargin < 13), refFroNorm = ones(size(hol, 3), 1); end
    end

    %MERGE AND ORGANIZATION OF CFG_FILE/USER INPUT
    rec_par_cfg = read_render_cfg(cfg_file, dataset); %read configuration file

    %combvec requires NeuralNet toolbox
    %rec_par_input=combvec(rec_dists,h_angles,v_angles,dof_angles);
    if (doDynamic)
        rec_par_idx = ones(4, nbRecons) * spdiags([1:nbRecons].', 0, nbRecons, nbRecons);

        if (pix_mode == 1 && max(rec_par_idx(4, :)) > numel(ap_sizes))
            rec_par_idx(4, :) = numel(ap_sizes);
        end

    else
        rec_par_idx = combvec_alternative(rec_dists, h_pos, v_pos, ap_sizes);
    end

    print_setup(cfg_file, rec_par_cfg, rec_dists, h_pos, v_pos, ap_sizes);

    %check out-of-bound apertures before start
    if pix_mode == 0
        % TODO: Add equivalent check to: if(isBinary && any(cellfun(@(x)any(x>size(hol(:,:,1))),  repmat(ap_sizes, [2,1]))))
        rec_par_idx = aperture_angle_checker(size(hol, 1), size(hol, 2), rec_par_idx, ...
            rec_dists, ap_sizes, h_pos, v_pos, ...
            rec_par_cfg.pixel_pitch);
    else

        if (isBinary && any(cellfun(@(x)any(x > size(hol(:, :, 1))), repmat(ap_sizes, [2, 1]))))

            if (strcmpi(dataset, 'wut_disp_on_axis') || strcmpi(dataset, 'interfere4'))
                warning('nrsh:binary_aperture', 'The aperture may only be half the horizontal size of the binary hologram, due to its generation.')
            else
                warning('nrsh:binary_aperture', 'The aperture may only be half the vertical size of the binary hologram, due to its generation.')
            end

        end

        rec_par_idx = aperture_pixel_checker(size(hol, 1), size(hol, 2), ...
            rec_par_idx, ap_sizes);
    end

    total_recons_number = size(rec_par_idx, 2); %total number of reconstructions to be done

    %ap_sizes is forced to be a cell also in angle-based mode, because of
    %the indexing in the subsequent for loop. this will be changed in next
    %releases.
    if ~iscell(ap_sizes)
        ap_sizes = num2cell(ap_sizes);
    end

    %RECONSTRUCTION
    try
        if isBinary
            si = size(hol);
            hol = single(hol);

            if (strcmpi(dataset, 'wut_disp_on_axis') || strcmpi(dataset, 'interfere4'))
                [X, ~] = meshgrid(((-si(2) / 2:si(2) / 2 - 1) + 0.5) / si(2), ((-si(1) / 2:si(1) / 2 - 1) + 0.5) / si(1));
                % bandlimit horizontally the hologram (because we will illuminate it later with off-axis vertical fringes)
                % simulate an incident off-axis planar illumination above the hologram (create vertical fringes)
                R = exp(2i * pi * X * si(2) / 4); % off-axis phase modulation
                clear X;
                % filter conjugated orders + DC
                hol = ifftshift(fft2(fftshift(hol .* R)));
                hol(:, [1:si(2) / 4, si(2) * 3/4 + 1:end], :) = [];
                hol = ifftshift(ifft2(fftshift(hol)));
            else
                [~, Y] = meshgrid(((-si(2) / 2:si(2) / 2 - 1) + 0.5) / si(2), ((-si(1) / 2:si(1) / 2 - 1) + 0.5) / si(1));
                % bandlimit vertically the hologram (because we will illuminate it later with off-axis horizontal fringes)
                % simulate an incident off-axis planar illumination above the hologram (create horizontal fringes)
                R = exp(2i * pi * Y * si(1) / 4); % off-axis phase modulation
                clear Y;
                % filter conjugated orders + DC
                hol = ifftshift(fft2(fftshift(hol .* R)));
                hol([1:si(1) / 4, si(1) * 3/4 + 1:end], :, :) = [];
                hol = ifftshift(ifft2(fftshift(hol)));
            end

            % re-normalize DH to ensure dynamic range comparable with complex-valued pendants
            for color = size(hol, 3):-1:1
                hol(:, :, color) = hol(:, :, color) / norm(hol(:, :, color), 'fro') * refFroNorm(color);
            end

        end

        if (strcmpi(dataset, 'wut_disp_on_axis'))
            si = size(hol);
            hol = fftshift(fft2(hol));
            hol = circshift(hol, [0, round(si(2) / 4), 0]);
            hol = ifft2(ifftshift(hol));
            dataset = 'wut_disp'; % From hereon reconstruct like off_axis: wut_disp
        end

        for idx = 1:total_recons_number

            fprintf('\nCalculating h_pos=%g v_pos=%g apert_size=%s rec_dist=%g ... ', ...
                h_pos(rec_par_idx(2, idx)), v_pos(rec_par_idx(3, idx)), ...
                strrep(mat2str(ap_sizes{rec_par_idx(4, idx)}), ' ', 'x'), ...
                rec_dists(rec_par_idx(1, idx)));

            tic

            [hol_rendered] = aperture(hol, dataset, rec_par_cfg, ...
                rec_dists(rec_par_idx(1, idx)), ...
                h_pos(rec_par_idx(2, idx)), ...
                v_pos(rec_par_idx(3, idx)), ...
                ap_sizes{rec_par_idx(4, idx)});
            [hol_rendered] = num_rec(hol_rendered, ...
                dataset, rec_par_cfg, ...
                rec_dists(rec_par_idx(1, idx)), 'forward');

            if strcmpi(dataset, 'wut_disp')
                hol_rendered = dc_filter(hol_rendered, rec_par_cfg.DC_filter_size, ...
                    rec_par_cfg.DC_filter_type);
                hol_rendered = abs(hol_rendered);
                hol_rendered = imresize(hol_rendered, rec_par_cfg.recons_img_size, 'bilinear');
            else
                hol_rendered = abs(hol_rendered);
            end

            if rec_par_cfg.save_intensity == 1
                hol_rendered = hol_rendered .^ 2;
            end

            if (strcmpi(dataset, 'wut_disp'))
                hol_rendered = wut_filter(hol_rendered, rec_par_cfg);
            end

            [hol_rendered, clip_min(idx), clip_max(idx)] = clipping(hol_rendered, ...
                rec_par_cfg, clip_min(idx), clip_max(idx));

            actual_rec_time = toc; %reconstruction time (this reconstruction)
            avg_rec_time = avg_rec_time + actual_rec_time;
            fprintf('done in %.2f seconds.\n', actual_rec_time);

            savename = sprintf('%s%s_%g_%g_%s_%g', name_prefix, cfg_name, ...
                h_pos(rec_par_idx(2, idx)), ...
                v_pos(rec_par_idx(3, idx)), ...
                strrep(mat2str(ap_sizes{rec_par_idx(4, idx)}), ' ', 'x'), ...
                rec_dists(rec_par_idx(1, idx)));

            %save abs as .mat file
            if rec_par_cfg.save_as_mat == 1
                save(fullfile(figures_path, [savename, '.mat']), ...
                    'hol_rendered', '-v7.3');
            end

            hol_rendered = real2uint(hol_rendered, rec_par_cfg.bit_depth); %also if png will not be saved: safer imshow behaviour

            %show abs
            if rec_par_cfg.show == 1
                figure()
                imshow(hol_rendered)
                title(sprintf('%s h_pos=%g v_pos=%g apert_size=%s rec_dist.=%g', cfg_name, ...
                    h_pos(rec_par_idx(2, idx)), ...
                    v_pos(rec_par_idx(3, idx)), ...
                    strrep(mat2str(ap_sizes{rec_par_idx(4, idx)}), ' ', 'x'), ...
                    rec_dists(rec_par_idx(1, idx))), 'Interpreter', 'none');
            end

            %save abs as png image
            if rec_par_cfg.save_as_image == 1
                imwrite(hol_rendered, fullfile(figures_path, [savename, '.png']), ...
                    'BitDepth', rec_par_cfg.bit_depth);
            end

        end

    catch msg_err
        persistent_sweeper(rec_par_cfg.method);
        rethrow(msg_err)
    end

    avg_rec_time = avg_rec_time / total_recons_number;

    fprintf('\nAverage reconstruction time (%d reconstruction(s)): %.2f seconds.\n', ...
        total_recons_number, avg_rec_time);

    persistent_sweeper(rec_par_cfg.method);
    %END RECONSTRUCTIONS

    % AUX. FUNCTIONS
    function check_user_input
        %check if types are ok
        try
            validateattributes(hol, {'char'}, {'nonempty'}, 'nrsh', 'hol', 1);
        catch

            try
                validateattributes(hol, {'numeric', 'logical'}, {'3d', 'nonempty'}, 'nrsh', 'hol', 1);
            catch
                error('NRSH:input_hol', 'Error using NRSH: Expected input number 1, hol, to be a numeric matrix or a path to a folder.')
            end

        end

        validateattributes(dataset, {'char'}, {'scalartext'}, 'nrsh', 'dataset', 2);

        if ~ischar(hol) %if hol is a varible, the dataset must be exactly specified

            if ~strcmpi(dataset, {'bcom8', 'bcom32', 'interfere', 'interfere4', 'emergimg', 'wut_disp', 'wut_disp_on_axis', 'bcom32_bin', 'interfere_bin', 'interfere4_bin', 'emergimg_bin', 'wut_disp_on_axis_bin'})
                error('NRSH:input_dataset', 'Error using NRSH: Expected input number 2, dataset, to be one of the following char. array: ''bcom8'', ''bcom32'', ''interfere'', ''interfere4'', ''emergimg'', ''wut_disp'', ''wut_disp_on_axis'', ''bcom32_bin'', ''interfere_bin'', ''interfere4_bin'', ''emergimg_bin'', ''wut_disp_on_axis_bin''.')
            end

        end

        validateattributes(cfg_file, {'char'}, {'nonempty'}, 'nrsh', 'cfg_file', 3);
        validateattributes(rec_dists, {'numeric'}, {'nonempty'}, 'nrsh', 'rec_dists', 4);

        if pix_mode == 0
            validateattributes(ap_sizes, {'numeric'}, {'row', 'nonnegative'}, 'nrsh', 'ap_sizes', 5);
            validateattributes(h_pos, {'numeric'}, {'row'}, 'nrsh', 'h_pos', 6);
            validateattributes(v_pos, {'numeric'}, {'row'}, 'nrsh', 'v_pos', 7);
        else
            %no validation for sizes!
            validateattributes(h_pos, {'numeric'}, {'>=', -1, '<=', 1, 'row'}, 'nrsh', 'h_pos', 6);
            validateattributes(v_pos, {'numeric'}, {'>=', -1, '<=', 1, 'row'}, 'nrsh', 'v_pos', 7);
        end

        %check if synth. aperture position has been declared, but without
        %declaring the synthetic aperture.
        if pix_mode == 0

            if (~all(ap_sizes) && (any(h_pos) || any(v_pos)))
                warning('When synthetic aperture is not set (ap_sizes=0) : h_pos and/or v_pos value(s) will be ignored.')
            end

            %a similar check is not performed in pixel mode
        end

        try
            validateattributes(clip_min, {'numeric'}, {'size', [1 nbRecons]}, 'nrsh', 'clip_min', 8);
        catch
            error('NRSH:input_arguments', 'Error using NRSH: Expected input number 8, clip_min, to be a numerical row vector with one value per reconstruction')
        end

        try
            validateattributes(clip_max, {'numeric'}, {'size', [1 nbRecons]}, 'nrsh', 'clip_max', 9);
        catch
            error('NRSH:input_arguments', 'Error using NRSH: Expected input number 9, clip_max, to be a numerical row vector with one value per reconstruction')
        end

    end

end
