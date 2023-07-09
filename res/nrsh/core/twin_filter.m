function [img_cut] = twin_filter(img, mode)
    %TWIN_FILTER filters the orthoscopic or pseudoscopic image from the input.
    %
    %   Inputs:
    %    img               - image with ortho/pseudo component
    %    mode              - filtering mode: R filters the right part, L the
    %                        left part
    %   Output:
    %    img_cut           - img filtered
    %


    img_cols = size(img, 2);

    if strcmpi(mode, 'r') %R filter
        img_cut = img(:, 1:(round(img_cols / 2)), :);

    elseif strcmpi(mode, 'l') %L filter
        img_cut = img(:, (round(img_cols / 2)) + 1:end, :);
    else
        img_cut = img;
        warning('nrsh:wut_filter', 'Warning in nrsh: unable to filter the input. The mode parameter should be set to ''R'' or ''L''.')
    end

end
