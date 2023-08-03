function [hol_rendered] = wut_filter(hologram, rec_par_cfg)
    %WUT_FILTER filters the reconstruction for WUT holograms
    %
    %   Inputs:
    %    hologram          - hologram reconstruction
    %    rec_par_cfg       - structure with rendering parameters, read from
    %                        configuration file
    %
    %   Output:
    %    hol_rendered      - filtered reconstruction.
    %

    %% WUT_DISPLAY ONLY OPERATIONS
    depth = size(hologram, 3);

    if depth == 3
        hol_rendered = rgb_align(hologram, rec_par_cfg); %includes saturate_gray
    else
        hol_rendered = saturate_gray(hologram, [], 1, rec_par_cfg.bit_depth);
    end

    if ~isempty(rec_par_cfg.img_flt)
        hol_rendered = twin_filter(hol_rendered, rec_par_cfg.img_flt);
    end

end
