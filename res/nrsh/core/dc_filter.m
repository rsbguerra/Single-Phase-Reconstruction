function [img_filtered] = dc_filter(img, dc_size, dc_type)
    %DC_FILTER filters the DC component of the reconstructed image
    %
    %   Inputs:
    %    img               - reconstructed image to be filtered
    %    dc_size           - DC filter size with respect to img dimensions
    %                        (in percentage: 1=100%, 0.5=50%...). If set to []
    %                        the default value of 0.5 is used.
    %    dc_type*          - type of filter used for DC filtering. See
    %                        window2.m for supported filters.
    %
    %(*)optional. If not provided, the original W.U.T. DC filter is used.
    %
    %   Output:
    %    img_filtered     - image with the DC filtered
    %
    % alternative filters can be declared as char. vectors, without @. i.e.
    % @bartlett can be also declared as 'bartlett'.
    %

    if nargin < 3
        dc_type = 'wut';
    end

    if (dc_size > 1) || (dc_size < 0)
        dc_size = 0.5;
        warning('The DC filter size is out of the allowed range [0, 1]. The default value of %.2f is used.', dc_size)
    end

    if isempty(dc_size)
        dc_size = 0.5;
    end

    [img_rows, img_cols, ~] = size(img);

    if strcmpi(dc_type, 'wut')
        img_filtered = img .* DCfilter(img_cols, img_rows, dc_size);
    else
        filt_rows = round(img_rows * dc_size);
        filt_cols = round(img_cols * dc_size);

        %filter dimensions are forced to be even
        if (mod(filt_rows, 2) ~= 0)
            filt_rows = filt_rows - 1;
        end

        if (mod(filt_cols, 2) ~= 0)
            filt_cols = filt_cols - 1;
        end

        %DC Filter
        kernel = imcomplement(window2(filt_rows, filt_cols, dc_type));

        row_pad = round((img_rows - filt_rows) / 2);
        col_pad = round((img_cols - filt_cols) / 2);

        img_filtered = img .* padarray(kernel, [row_pad, col_pad], 1, 'both');

    end

end
