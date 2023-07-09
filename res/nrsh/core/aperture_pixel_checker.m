function [rec_par_idx] = aperture_pixel_checker(hol_rows, hol_cols, ...
        rec_par_idx, ap_sizes, verbosity)
    %APERTURE_PIXEL_CHECKER checks for out-of-bound synthetic apertures (pixel-based).
    %
    %   Inputs:
    %    hol_rows          - hologram rows
    %    hol_cols          - hologram columns
    %    rec_par_idx       - indexes to user input parameters, shaped with
    %                        combvec/combvec alternative
    %    ap_sizes          - synthetic aperture size(s) [deg]
    %    verbosity         - boolean
    %
    %   Output:
    %    rec_par_idx       - is equal to the input if no out-of-bound is
    %                        detected. If out-of-bound is detected and the user
    %                        wishes to continue, it does not contain the
    %                        out-of-bound combinations.
    %


    if (verbosity)
        fprintf('\nSynthetic aperture out-of-bound check...')
    end

    bad_comb = [];

    for idx = 1:size(rec_par_idx, 2)
        current_size = ap_sizes{rec_par_idx(4, idx)};

        %first check if the size is a 2 elements row vector
        if ~isequal(size(current_size), [1, 2])
            bad_comb = [bad_comb, idx];
        else
            %then do the other checks
            if ((current_size(1) > hol_rows) || (current_size(2) > hol_cols) ...
                    || (current_size(1) < 0) || (current_size(2) < 0))

                bad_comb = [bad_comb, idx];
            end

        end

    end

    if ~isempty(bad_comb)

        if (verbosity)
            fprintf('\n')
        end

        warning('nrsh:aperture', 'Warning in nrsh: the following synthetic apertures are not consistent with hologram dimensions [%dx%d]:', hol_rows, hol_cols)

        for idx = 1:size(bad_comb, 2)
            wrong_size = strrep(mat2str(ap_sizes{rec_par_idx(4, bad_comb(idx))}), ' ', 'x');
            fprintf('%s\n', wrong_size);
        end

        if isequal(size(bad_comb, 2), size(rec_par_idx, 2))
            error('nrsh:aperture', 'Error in nrsh: there are no other valid synthetic apertures! Execution aborted.')
        else
            rec_par_idx(:, bad_comb) = [];
            disp('The execution will continue without the uncorrect apertures.')
        end

    end

    if (verbosity)
        disp('passed!')
    end

end
