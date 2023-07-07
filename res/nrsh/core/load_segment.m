function segment = load_segment(hol, info, m, n)
    % Function Name: load_segment
    % This function loads a given hologram segment from its line and column indexes
    %
    % Inputs:
    %   hol  - folder path in which the hologram segments can be found
    %   info - structure with rendering parameters, read from
    %          configuration file
    %   m    - line index of the hologram segment (from top to bottom)
    %   n    - column index of the hologram segment (from left to right)
    %
    % Outputs:
    %   segment - complex modulation or bilevel phase hologram segment
    %
    % Authors:      Antonin GILLES, Patrick GIOIA
    %               Institute of Research & Technology b<>com
    % -------------------------------------------------------------------------

    switch lower(info.dataset)
        case 'bcom_print'

            if strcmpi(info.format, 'bilevel')
                filePath = [hol '\' info.hologramname '_' int2str(m - 1) '_' int2str(n - 1) '.bmp'];
                phase = pi * im2double(imread(filePath));
                segment = single(exp(1i * phase));
            else
                ampliPath = [hol '\' info.hologramname '_' int2str(m - 1) '_' int2str(n - 1) '_ampli.bmp'];
                phasePath = [hol '\' info.hologramname '_' int2str(m - 1) '_' int2str(n - 1) '_phase.bmp'];
                ampli = im2double(imread(ampliPath));
                phase = 2.0 * pi * im2double(imread(phasePath));
                segment = single(ampli .* exp(1i * phase));
            end

        case 'etri_print'
            filePath = [hol '\' info.hologramname '_' sprintf('%02d%02d', m, n) '.tif'];
            phase = pi * im2double(imread(filePath));
            segment = single(exp(1i * phase));

        otherwise
            error('nrsh_print:load_segment', 'Error in nrsh_print: expected input number 2, dataset, to be one of the following char. array: ''bcom_print'', ''etri_print''')

    end
