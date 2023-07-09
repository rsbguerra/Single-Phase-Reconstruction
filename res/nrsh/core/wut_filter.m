function [hol_rendered] = wut_filter(hologram, info)
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
        hol_rendered = rgb_align(hologram, info);
    else
        %hol_rendered=saturate_gray(hologram,[],1,info.bit_depth);
        hol_rendered = hologram;
    end

    if ~isempty(info.img_flt)
        hol_rendered = twin_filter(hol_rendered, info.img_flt);
    end

end
