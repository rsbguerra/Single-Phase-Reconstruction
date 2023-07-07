function [q, xq] = quantize_helper(x, xpoi, L, quantmethod)
    % Quantizer (Mid-rise/Mid-tread)
    switch quantmethod
        case 'MRQ'
            stepsize = 2 * xpoi / L;
            %Quantize to levels
            q = floor(x / stepsize);
            %Clip to maximum and minimum output values
            q(q > L / 2 - 1) = L / 2 - 1;
            q(q <- L / 2) = -L / 2;
            %Quantized values
            xq = (q + 0.5) * stepsize;
            q = q + L / 2;
    end

end
