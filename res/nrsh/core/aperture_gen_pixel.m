function [hol_view] = aperture_gen_pixel(Hol, isFourierDH, ...
        h_pos, v_pos, ap_size, apod)
    %APERTURE_GEN_PIXEL sets a pixel-based synthetic aperture.
    %
    %   Inputs:
    %    Hol               - hologram
    %    isFourierDH       - isFourierDH boolean
    %    h_pos             - horizontal position expressed in the [-1, 1] range
    %    v_pos             - vertical position expressed in the [-1, 1] range
    %    ap_size           - it must be a row vector. The first elementent is
    %                        the vertical dimension while the second element is
    %                        the horizontal dimension of the synth. aperture.
    %                        Both are expressed in pixel
    %    apod              - "1" to apodize the aperture with 2D Hanning window
    %
    %   Output:
    %    hol_view          -windowed hologram
    %
    % NOTE: positive h_pos: right; positive v_pos: up
    %


    [hol_rows, hol_cols, ~] = size(Hol);

    v_pos = -v_pos;

    %positions in pixel
    start_row = max(1, round(hol_rows / 2 + (hol_rows / 2 - ap_size(1) / 2) * v_pos - ap_size(1) / 2) + 1);
    end_row = min(hol_rows, round(hol_rows / 2 + (hol_rows / 2 - ap_size(1) / 2) * v_pos + ap_size(1) / 2));
    start_col = max(1, round(hol_cols / 2 + (hol_cols / 2 - ap_size(2) / 2) * h_pos - ap_size(2) / 2) + 1);
    end_col = min(hol_cols, round(hol_cols / 2 + (hol_cols / 2 - ap_size(2) / 2) * h_pos + ap_size(2) / 2));

    %set the aperture
    if (isFourierDH)
        hol_view = Hol(start_row:end_row, start_col:end_col, :);

        if apod == 1
            apod_wind = window2((end_row - start_row + 1), (end_col - start_col + 1), @hann);
            hol_view = hol_view .* apod_wind;
        end

    else
        hol_view = zeros(size(Hol));

        if apod == 1
            apod_wind = window2((end_row - start_row + 1), (end_col - start_col + 1), @hann);
            hol_view(start_row:end_row, start_col:end_col, :) = ...
                Hol(start_row:end_row, start_col:end_col, :) .* apod_wind;
        else
            hol_view(start_row:end_row, start_col:end_col, :) = ...
                Hol(start_row:end_row, start_col:end_col, :);
        end

    end

end
