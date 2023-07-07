function Xq = Dequantize_PL(Q_all, Xpoi_all, L, quantmethod)
    %Dequantize_PL converts unsigned integer values to floating point
    %values
    %
    %
    % Created by K.M. Raees, 21.04.2020
    %   Dequantizes the hologram  with unsigned integer representation
    %  Q having bitdepth L. Quantization method(Mid-rise/Mid-tread) used is
    %  specified in quantmethod.
    %
    %   Inputs:
    %    Q_all             - Complex valued unsigned integer hologram
    %    Xpoi_all          - Clipping points
    %    L                 - Bit-depth of unsigned integer representation
    %    quantmethod       - Quantization method
    %
    %   Output:
    %    Xq                - Dequantized Q
    for i = 1:size(Q_all, 3)
        Q = squeeze(Q_all(:, :, i));
        Xpoi = Xpoi_all(i);
        qreal = double(real(Q(:))); xpoireal = real(Xpoi);
        qimag = double(imag(Q(:))); xpoiimag = imag(Xpoi);
        xqreal = dequantize_PL(qreal, xpoireal, L, quantmethod);
        xqimag = dequantize_PL(qimag, xpoiimag, L, quantmethod);
        Xq(:, :, i) = reshape(xqreal, size(Q, 1), size(Q, 2)) + 1j * reshape(xqimag, size(Q, 1), size(Q, 2));
    end

end

function [xq] = dequantize_PL(q, xpoi, L, quantmethod)
    % Quantizer (Mid-rise/Mid-tread)
    switch quantmethod
        case 'MRQ'
            q = q - L / 2;
            stepsize = 2 * xpoi / L;
            xq = (q + 0.5) * stepsize;
    end

end
