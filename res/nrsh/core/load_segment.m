function segment = load_segment(folder_path, dataset, rec_par_cfg, m, n)
    % Function Name: load_segment
    % This function loads a given hologram segment from its line and column indexes
    %
    % Inputs:
    %   folder_path		- folder path in which the hologram segments can be found
    %   dataset         - dataset to which the hologram belongs. It should be one
    %                     of the following char. arrays: bcom_print, etri_print
    %    rec_par_cfg    - structure with rendering parameters, read from
    %                     configuration file
    %   m				- line index of the hologram segment (from top to bottom)
    %   n				- column index of the hologram segment (from left to right)
    %
    % Outputs:
    %   segment		    - complex modulation or bilevel phase hologram segment
    %
    % Authors:      Antonin GILLES, Patrick GIOIA
    %               Institute of Research & Technology b<>com
    % -------------------------------------------------------------------------

    switch lower(dataset)
        case 'bcom_print'

            if strcmp(rec_par_cfg.format, 'bilevel')
                filePath = [folder_path '\' rec_par_cfg.hologramName '_' int2str(m - 1) '_' int2str(n - 1) '.bmp'];
                phase = pi * im2double(imread(filePath));
                segment = single(exp(1i * phase));
            else
                ampliPath = [folder_path '\' rec_par_cfg.hologramName '_' int2str(m - 1) '_' int2str(n - 1) '_ampli.bmp'];
                phasePath = [folder_path '\' rec_par_cfg.hologramName '_' int2str(m - 1) '_' int2str(n - 1) '_phase.bmp'];
                ampli = im2double(imread(ampliPath));
                phase = 2.0 * pi * im2double(imread(phasePath));
                segment = single(ampli .* exp(1i * phase));
            end

        case 'etri_print'
            filePath = [folder_path '\' rec_par_cfg.hologramName '_' sprintf('%02d%02d', m, n) '.tif'];
            phase = pi * im2double(imread(filePath));
            segment = single(exp(1i * phase));

        otherwise
            error("Expected input number 2, dataset, to be one of the following char. array: 'bcom_print', 'etri_print'")

    end
