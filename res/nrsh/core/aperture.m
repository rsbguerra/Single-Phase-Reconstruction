function [hol_rendered] = aperture(hologram, isFourierDH, pixel_pitch, rec_dist, h_pos, v_pos, ap_size, apod)
    %APERTURE creates a synthetic aperture in the hologram.
    %
    %   Inputs:
    %    hologram          - hologram to reconstruct
    %    isFourierDH       - isFourierDH boolean
    %    pixel_pitch       - pixel pitch, in meters
    %    rec_dist          - reconstruction distance, in meters
    %    h_pos             - horizontal position at which the synthetic
    %                        aperture will be placed
    %    v_pos             - vertical position at which the synthetic
    %                        aperture will be placed
    %    ap_size           - synthetic aperture size
    %    apod              - apodization window
    %
    %   Output:
    %    hol_rendered      - hologram with synthetic aperture
    %


    %% SYNTHETIC APERTURE GENERATION
    if size(ap_size, 2) == 2 %PIXEL MODE

        if nnz(ap_size) < 2 %if one of the two dims. of the aperture is zero, the full hologram will be reconstructed
            hol_rendered = hologram;
        else
            hol_rendered = aperture_gen_pixel(hologram, isFourierDH, h_pos, v_pos, ap_size, apod);
        end

    elseif (size(ap_size, 2) == 1) %ANGLE MODE

        if (ap_size > 0)
            hol_rendered = aperture_gen_angle(hologram, isFourierDH, pixel_pitch, rec_dist, h_pos, v_pos, ap_size, apod);
        else %if the DOF angle is 0 the full hologram will be reconstructed (cannot be negative here, due to the input check)
            hol_rendered = hologram;
        end

    else
        error('nrsh:invalid_input', 'Error in nrsh: The shape of ap_size is not 1x1 or 1x2 as expected.')
    end
