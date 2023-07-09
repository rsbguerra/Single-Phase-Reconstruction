function [comb] = combvec_alternative(rec_dists, h_pos, v_pos, ap_sizes)
    %COMBVEC_ALTERNATIVE alternative to combvec function (NeuralNet Toolbox)
    %
    %This function creates the INDEXES for the user inputs (h_pos, v_pos,
    %ap_sizes) in order to get all the possible combinations. The output is not
    %the inputs combined, as in previous verisions of NRSH (1.1.1 or below).
    %

    comb = {1:size(rec_dists, 2), 1:size(h_pos, 2), 1:size(v_pos, 2), 1:size(ap_sizes, 2)};
    [comb{:}] = ndgrid(comb{:});
    n = length(comb);

    comb = reshape(cat(n + 1, comb{:}), [], n);
    comb = comb';

end
