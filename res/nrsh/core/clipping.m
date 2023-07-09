function [hol_rendered, clip_out_min, clip_out_max] = clipping(hologram, perc_clip, perc_value, hist_stretch, clip_min, clip_max)
    %CLIPPING performs clipping and histogram stretching operations
    %
    %   Inputs:
    %    hologram          - hologram reconstruction
    %    clip_min          - minimal intensity value for clipping. It must be a
    %                        single value
    %    clip_max          - maximal intensity value for clipping. It must be a
    %                        single value
    %
    %   Output:
    %    hol_rendered      - clipped hologram reconstruction
    %    clip_min_out      - minimal intensity of the numerical reconstruction
    %    clip_max_out      - maximal intensity of the numerical reconstruction
    %


    %% ENHANCEMENT
    hol_rendered = hologram;
    %absolute value clipping
    if clip_min > -1 && clip_max > -1
        hol_rendered(hol_rendered > clip_max) = clip_max;
        hol_rendered(hol_rendered < clip_min) = clip_min;

        clip_out_min = clip_min;
        clip_out_max = clip_max;
    else
        %percentile clipping
        if perc_clip == 1
            clip_value = prctile(hol_rendered(:), perc_value);
            hol_rendered(hol_rendered > clip_value) = clip_value;
        end

        clip_out_min = min(hol_rendered(:));
        clip_out_max = max(hol_rendered(:));
    end

    %histogram stretching
    if hist_stretch == 1
        hol_rendered = (hol_rendered - clip_out_min) ./ (clip_out_max - clip_out_min);
    end

end
