function [X, H] = holoread_PL(Folders)
    %holoread_PL reads a hologram belonging to Pleno DB.
    %
    % Created by K.M. Raees, 21.04.2020
    %   From the file in Pleno DB Reads complex valued hologram into X,
    %pixel pitch into pp, wavelength into lambda and category idenifier into
    %holofamily. Overloads X and H.lambda by an extra dimension for colour
    %holograms. Writes reference reconstruction for X
    %
    %   Inputs:
    %    Folders             - Folders structure
    %
    %   Output:
    %    X                   - Complex valued hologram
    %    H.pp                - Pixel pitch
    %    H.lambda            - Wavelength
    %    H.dataset           - Hologram family idenitfier.
    %    H.cfg_file          - Configfile for NRSH.
    %    H.ap_sizes          - Depth parameters from Pleno DB for NRSH.
    %    H.rec_dists         - Reconstruction distances from Pleno DB for NRSH.
    %    H.h_pos             - Synthetic horizontal aperture position(pixel)
    %                          from PlenoDB for NRSH.
    %    H.v_pos             - Synthetic horizontal aperture position(pixel)
    %                          from PlenoDB for NRSH.
    %    H.obj_dist          - Object depth from Pleno DB for compression.
    %    H.Hsubj             - by default Hsubj == H, but specification of Hsubj per dataset is possible
    %
    % Please don't touch. This document sets the objective test reconstruction parameters and loads the data.
    %
    % Reconstruction parameters, except for objective plane distance + perspective view points are listed here:
    %   https://docs.google.com/spreadsheets/d/17YW4iS6HQEK7-fUA91i0IiwhleaqMjAI7HWX3NwkZyE/edit#gid=0
    %
    % If you encounter problems loading your data, please confer to this file and main_degrade.m to derive the correct filename and structure of the input data.

    % The organization in groups here is solely for better legibility
    interfere = {'CGH_Biplane16k_rgb.mat', 'HolD8K_earth32.mat', 'BallColor.mat'};
    interfere4 = {'DeepChess.mat', 'cgh_ball_slit_AS_ccd_plane.mat', 'opt_Sphere.mat', 'cgh_chess2_slit_AS_ccd_plane.mat', 'opt_Squirrel.mat'};
    interfereV = {'CornellBox2_10K.mat', 'CornellBox3_16K.mat', 'CornellBox4_16K.mat', 'DeepCornellBox_16K.mat'};
    bcom32 = {'SpecularCar16K.mat', 'DeepDices16K.mat', 'DeepDices2K.mat', 'DeepDices8K4K.mat', 'Dice8K4K.mat', 'Piano8K4K.mat', 'Piano16K.mat', 'Piano16KR.mat', ...
                  'Dices4K.mat', 'Dices8K.mat', 'Dices16K.mat', 'Ring16K.mat', 'biplane16k.mat', 'breakdancers8k4k_022.mat', 'ballet8k4k_022.mat'};
    wut_disp_on_axis = {'opt_Warsaw_Lowiczanka_Doll.mat', 'opt_Warsaw_Mermaid.mat'};
    emergimg = {'Astronaut_Hol_v2.mat', 'horse_Hol_v1.mat'};

    %if (~exist(Folders.holofile, 'file') && contains(Folders.holofile, 'Piano16KR.mat'))
    % Load Piano16KR from Piano16K.mat, if necessary
    %    data = load(fullfile(Folders.holofolder, strrep(Folders.holofile, '16KR', '16K')));
    %else
    data = load(fullfile(Folders.holofolder, Folders.holofile));
    %end

    % Layman's check for octave compatible mode
    isOctave = false;

    if (isOctave)
        save73 = {'-hdf5'};
    else
        save73 = {'-v7.3', '-nocompression'};
    end

    objZfun = @(x) mean([max(x(:)), min(x(:))]);

    if (any(strcmp(interfere, Folders.holofile)))
        H.dataset = 'interfere';

        switch Folders.holofile
            case 'CGH_Biplane16k_rgb.mat'
                X = double(data.CGH.Hol);
                H.pp = data.CGH.setup.pp(1);
                H.lambda = data.CGH.setup.wlen;
                H.cfg_file = fullfile('interfereIII', 'biplane16kETRO_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.0455 0.0374 0.0497];
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.04355;
                H.Hsubj = H;

                %% Subjective test specification 27.09.2021
                H.Hsubj.rec_dists = [0.0374, 0.0455];
                H.Hsubj.h_pos = [0 1];
                H.Hsubj.v_pos = [0 1];
            case 'HolD8K_earth32.mat'
                X = double(data.HH.Hol);
                H.pp = data.pp(1);
                H.lambda = 633e-9;
                H.cfg_file = fullfile('interfereII', 'earth8kD_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = 0.0120;
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.012;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'BallColor.mat'
                X = double(data.CGH.Hol);
                H.pp = data.CGH.setup.pp(1);
                H.lambda = data.CGH.setup.wlen;
                H.cfg_file = fullfile('interfereIII', 'sphere3_000.txt');
                H.ap_sizes = {[1536 1536]};
                H.rec_dists = [0.2952 0.3050];
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.295;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
        end

    elseif (any(strcmp(interfere4, Folders.holofile)))
        H.dataset = 'interfere4';

        switch Folders.holofile
            case 'cgh_ball_slit_AS_ccd_plane.mat'
                X = double(data.dh);
                H.pp = data.pp(1);
                H.lambda = data.wlen;
                H.cfg_file = fullfile('interfereIV', 'ball_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.701 0.751];
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.701;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'cgh_chess2_slit_AS_ccd_plane.mat'
                X = double(data.dh);
                H.pp = data.pp(1);
                H.lambda = data.wlen;
                H.cfg_file = fullfile('interfereIV', 'chess2_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.4964 0.6486 0.8063];
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.4964;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'DeepChess.mat'
                X = double(data.dh);
                H.pp = data.pp(1);
                H.lambda = data.wlen;
                H.cfg_file = fullfile('interfereIV', 'deepchess2_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.3964 0.9986 1.6063];
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.9986;
                H.Hsubj = H;

                %% Subjective test specification 27.09.2021
                H.Hsubj.rec_dists = [0.3964 * ones(1, 2) 0.9986 * ones(1, 2) 1.6063 * ones(1, 2)];
                H.Hsubj.h_pos = repmat([0 1], [1, 3]);
                H.Hsubj.v_pos = repmat([0 0], [1, 3]);
            case 'opt_Sphere.mat'
                X = double(data.dh);
                H.pp = data.pp(1);
                H.lambda = data.wlen;
                H.cfg_file = fullfile('interfereIV', 'sphere_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = 0.960;
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.960;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'opt_Squirrel.mat'
                X = double(data.dh);
                H.pp = data.pp(1);
                H.lambda = data.wlen;
                H.cfg_file = fullfile('interfereIV', 'squirrel_000.txt');
                H.ap_sizes = {[1792 3488]};
                H.rec_dists = [0.465 0.5 0.535];
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.5;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
        end

    elseif any(strcmp(interfereV, Folders.holofile))
        H.dataset = 'interfere';

        switch Folders.holofile
            case 'CornellBox2_10K.mat'
                X = double(data.H);
                H.pp = data.pp(1);
                H.lambda = data.wlen;
                H.cfg_file = fullfile('interfereV', 'CornellBox2_10K_000.txt');
                H.ap_sizes = {[4096 4096]};
                H.rec_dists = [0.214 0.222 0.225 0.2345];
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.214;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case {'CornellBox3_16K.mat', 'CornellBox4_16K.mat'}
                X = double(data.H);
                H.pp = data.pp(1);
                H.lambda = data.wlen;
                H.cfg_file = fullfile('interfereV', 'CornellBox3_16K_000.txt');
                H.ap_sizes = {[4096 4096]};
                H.rec_dists = [0.220 0.228 0.25 0.269, 0.28615];
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.25307;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'DeepCornellBox_16K.mat'
                X = double(data.H);
                H.pp = data.pp(1);
                H.lambda = data.wlen;
                H.cfg_file = fullfile('interfereV', 'DeepCornellBox_16K_000.txt');
                H.ap_sizes = {[4096 4096]};
                H.rec_dists = [0.2090 0.2122 0.2270 0.2500 0.2525 0.2550 0.3013 ...
                                   0.3425 0.3639 0.4051 0.4080 0.4183 0.4446 0.4891 0.5304 0.5320]; %Don't touch!!!
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.25;
                H.rec_dists = [0.2090 0.2500 0.3425 0.4183];
                H.Hsubj = H;

                %% Subjective test specification 27.09.2021
                H.Hsubj.rec_dists = [0.2500 0.4183 0.2090 0.2500 0.4183];
                H.Hsubj.h_pos = [0 0 ones(1, 3)];
                H.Hsubj.v_pos = [0 0 ones(1, 3)];
        end

    elseif any(strcmp(bcom32, Folders.holofile))
        H.dataset = 'bcom32';

        switch Folders.holofile
            case 'breakdancers8k4k_022.mat'
                X = double(data.data);
                H.ap_sizes = {[size(X, 1) size(X, 2)]};
                H.pp = 4.8e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'breakdancers8k4k_000.txt');
                H.rec_dists = [0.025 0 0.081];
                %H.rec_dists = [0.00418 0.00869, 0.018855, 0.02060, 0.02362, 0.0025, 0.002551, 0.003353];
                H.h_pos = [0];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.018855;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'ballet8k4k_022.mat'
                X = double(data.data);
                H.ap_sizes = {[size(X, 1) size(X, 2)]};
                H.pp = 4.8e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'ballet8k4k_000.txt');
                H.rec_dists = [0.00584 0.01894 0.02145 0.025, 0.02621, 0.05187];
                H.h_pos = [0];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.025;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'Dice8K4K.mat'
                X = double(data);
                H.pp = 4.8e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'dice8k4k_000.txt');
                H.ap_sizes = {[0 0]};
                H.rec_dists = [0 0.01 0.0197];
                H.h_pos = [0];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.010;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'DeepDices8K4K.mat'
                X = double(data.data);
                %                   X = borderpad(X, [length(X),length(X),3]);
                H.pp = 4.8e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'DeepDices8k4k_000.txt');
                H.ap_sizes = {[size(X, 1) size(X, 2)]};
                H.rec_dists = [0.0101 0.0148 0.173 0.331 0.492];
                H.h_pos = [0];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.0148;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'DeepDices16K.mat'
                X = double(data.data);
                H.pp = 0.4e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'DeepDices16k_000.txt');
                H.ap_sizes = {[size(X, 1) size(X, 2)]}; %{[8192 8192]};
                H.rec_dists = [0.00338 0.00494 0.0185 0.0318 0.0459];
                H.h_pos = [0];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.0185;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'DeepDices2K.mat'
                X = double(data.data);
                H.pp = 4.8e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'DeepDices2k_000.txt');
                H.ap_sizes = {[size(X, 1) size(X, 2)]};
                H.rec_dists = [0.00507 0.00741 0.0867 0.166 0.246];
                H.h_pos = [0];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.0867;
                H.Hsubj = H;

                %% Subjective test specification 27.09.2021
                H.Hsubj.rec_dists = repmat([0.00741 0.0867 0.166], [1, 2]);
                H.Hsubj.h_pos = zeros(1, 6);
                H.Hsubj.v_pos = zeros(1, 6);
            case 'Piano8K4K.mat'
                X = double(data);
                H.pp = 4.8e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'piano8k4k_000.txt');
                H.ap_sizes = {[0 0]};
                H.rec_dists = [0 0.01 0.018];
                H.h_pos = [0];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.010;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'Dices4K.mat'
                X = double(data.data);
                H.pp = 0.4e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'dices4k_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.01 0.00656 0.0131] / 4;
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.00983/4;

                H.Hsubj = H; % To be used mainly for doCoreVerification
                H.Hsubj.rec_dists = [0.00656 0.01 0.0131] / 4;
                H.Hsubj.h_pos = ones(1, 3);
                H.Hsubj.v_pos = ones(1, 3);
            case 'Dices8K.mat'
                X = double(data.data);
                H.pp = 0.4e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'dices8k_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.01 0.00656 0.0131] / 2;
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.00983/2;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'Dices16K.mat'
                X = double(data.data);
                H.pp = 0.4e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'dices16k_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.01 0.00656 0.0131];
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.00983;
                H.Hsubj = H;

                %% Subjective test specification 27.09.2021
                H.Hsubj.rec_dists = [0.00656 0.01 0.0131];
                H.Hsubj.h_pos = ones(1, 3);
                H.Hsubj.v_pos = ones(1, 3);
            case 'SpecularCar16K.mat'
                X = double(data.data);
                H.pp = 0.4e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'specular_car16k_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.0044 0.005 0.01];
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.005;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case 'Ring16K.mat'
                X = double(data.data);
                H.pp = 0.4e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'ring16k_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.01 0.006 0.008];
                %H.rec_dists = [0.01 0.006 0.0146];
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.008;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
            case {'Piano16K.mat', 'Piano16KR.mat'}
                X = double(data.data);
                H.pp = 0.4e-6;
                H.lambda = [6.4e-7 5.32e-7 4.73e-7];
                H.cfg_file = fullfile('bcom', 'piano16k_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.01 0.0068 0.0125];
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.00965;

                % Restrict to R only, if necessary
                if (strcmp(Folders.holofile, 'Piano16KR.mat'))
                    X = X(:, :, 1);
                    H.lambda = H.lambda(1);
                    H.cfg_file = fullfile('bcom', 'piano16kr_000.txt');
                end

                H.Hsubj = H;

                %% Subjective test specification 27.09.2021
                H.Hsubj.rec_dists = [0.01 0.0068];
                H.Hsubj.h_pos = zeros(1, 2);
                H.Hsubj.v_pos = ones(1, 2);
            case 'biplane16k.mat'
                X = double(data.data);
                H.pp = 1e-6;
                H.lambda = [640e-9 532e-9 473e-9];
                H.cfg_file = fullfile('bcom', 'biplane16kBCOM_000.txt');
                H.ap_sizes = {[2048 2048]};
                H.rec_dists = [0.0455 0.0374 0.0497];
                H.h_pos = [0 1];
                H.v_pos = [0 1];
                H.obj_dist = objZfun(H.rec_dists); %0.04355;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
        end

    elseif any(strcmp(wut_disp_on_axis, Folders.holofile))
        H.dataset = 'wut_disp_on_axis';

        switch Folders.holofile
            case 'opt_Warsaw_Lowiczanka_Doll.mat'

                try
                    X = double(data.dh);
                catch me
                    X = double(data.data);
                end

                H.pp = 3.45e-6;
                H.lambda = [6.37e-7 5.32e-7 4.57e-7];
                H.cfg_file = fullfile('wut', 'lowiczanka_doll_000.txt');
                H.ap_sizes = {[2016 2016]};
                H.rec_dists = [1.030 1.060 1.075];
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %1052.5;
                H.Hsubj = H;

                %% Subjective test specification 27.09.2021
                H.Hsubj.rec_dists = 1.075;
                H.Hsubj.h_pos = [1];
                H.Hsubj.v_pos = [0];
            case 'opt_Warsaw_Mermaid.mat'
                X = double(data.dh);
                H.pp = 3.45e-6;
                H.lambda = 6.328e-7;
                H.cfg_file = fullfile('wut', 'warsaw_mermaid_000.txt');
                H.ap_sizes = {[2010 2010]};
                H.rec_dists = [340 350 355] * 1e-3;
                H.h_pos = [0 1];
                H.v_pos = [0];
                H.obj_dist = objZfun(H.rec_dists); %0.35;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
        end

    elseif (any(strcmp(emergimg, Folders.holofile)))
        H.dataset = 'emergimg';

        switch Folders.holofile
            case 'Astronaut_Hol_v2.mat'
                X = double(data.u1);
                H.pp = data.pitch;
                H.lambda = data.lambda;
                H.cfg_file = fullfile('emergimg', 'astronaut_000.txt');
                H.ap_sizes = {[1940 size(X, 2)]};
                H.rec_dists = [-0.172 -0.16 -0.175];
                H.h_pos = 0;
                H.v_pos = 0;
                H.obj_dist = objZfun(H.rec_dists); %-0.1675;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...

                %% Subjective test specification 27.09.2021
                H.Hsubj.rec_dists = [-0.16, -0.172];
                H.Hsubj.h_pos = [0 0];
                H.Hsubj.v_pos = [0 0];
            case 'horse_Hol_v1.mat'
                X = double(data.u1);
                H.pp = data.pitch;
                H.lambda = data.lambda;
                H.cfg_file = fullfile('emergimg', 'horse_000.txt');
                H.ap_sizes = {[size(X, 1) size(X, 2)]};
                H.rec_dists = [0.140 0.135 0.145 0.150];
                H.h_pos = 0;
                H.v_pos = 0;
                H.obj_dist = objZfun(H.rec_dists); %0.140;
                H.Hsubj = H; % TODO: Implement specfic subjective Test viewpoints below here as e.g. H.Hsubj.h_pos = ...
        end

    end

    if (~exist(fullfile(Folders.plenofolder, 'input.mat'), 'file'))
        warning('off', 'MATLAB:MKDIR:DirectoryExists');
        try , mkdir(fullfile(Folders.plenofolder)), catch me, end
        warning('on', 'MATLAB:MKDIR:DirectoryExists');
        save(fullfile(Folders.plenofolder, 'input.mat'), save73{:}, 'X', 'H');
    end

end
