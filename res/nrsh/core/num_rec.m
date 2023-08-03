function [hol_rendered] = num_rec(hologram, rec_par_cfg, rec_dist, direction)
    %NUM_REC reconstructs a hologram belonging to Pleno DB.
    %
    %   Inputs:
    %    hologram          - hologram to reconstruct
    %    dataset           - dataset info. Same as load_data.
    %    rec_par_cfg       - structure with rendering parameters, read from
    %                        configuration file
    %    rec_dist          - reconstruction distance [m]
    %    direction         - reconstruction direction. It should be one of
    %                        the following char. arrays: forward (propagation
    %                        towards the object plane) or inverse (propagation
    %                        towards the hologram plane)
    %
    %   Output:
    %    hol_rendered      - hologram reconstruction.
    %

    %% RECONSTRUCTION
    colors = size(hologram, 3);
    hol_rendered = hologram;

    switch lower(rec_par_cfg.method)

        case 'asm'

            for idx = 1:colors
                hol_rendered(:, :, idx) = rec_asm(hol_rendered(:, :, idx), ...
                    rec_par_cfg.pixel_pitch, ...
                    rec_par_cfg.wlen(idx), rec_dist, ...
                    rec_par_cfg.zero_pad, direction);
            end

        case 'fresnel'

            for idx = 1:colors
                hol_rendered(:, :, idx) = rec_fresnel(hol_rendered(:, :, idx), ...
                    rec_par_cfg.pixel_pitch, ...
                    rec_par_cfg.wlen(idx), rec_dist, ...
                    direction);
            end

        case 'fourier-fresnel'
            [rows_ev, cols_ev, ~] = size(hol_rendered);

            %hologram dimensions forced to be even
            if (mod(rows_ev, 2) ~= 0)
                rows_ev = rows_ev - 1;
                hol_rendered = hol_rendered(1:rows_ev, :, :);
            end

            if (mod(cols_ev, 2) ~= 0)
                cols_ev = cols_ev - 1;
                hol_rendered = hol_rendered(:, 1:cols_ev, :);
            end

            %         %this if needs to be verified
            %         if strcmpi(dataset, 'interfere4')
            %             rec_dist=-rec_dist;
            %             rec_par_cfg.ref_wave_rad=-rec_par_cfg.ref_wave_rad;
            %         end

            for idx = 1:colors
                hol_rendered(:, :, idx) = rec_fourier_fresnel(hol_rendered(:, :, idx), ...
                    rec_par_cfg.pixel_pitch, ...
                    rec_par_cfg.wlen(idx), rec_dist, ...
                    rec_par_cfg.ref_wave_rad, direction);
            end

        otherwise
            error('%s: unknown reconstruction method.', rec_par_cfg.method)
    end

end
