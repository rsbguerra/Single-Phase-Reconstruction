function [Q, Xq, Xpoi] = Quantize_PL(X_all, L, quantmethod, varg)
    %quantize_helper converts floating point values to unsigned integer values.
    %
    %
    % Created by K.M. Raees, 21.04.2020
    % Modified: T. Birnbaum, 12.11.2020
    %   Convert the floating point hologram X into its quantized version Xq
    % with unsigned integer representation Q having bitdepth L. Quantization
    % method(Mid-rise/Mid-tread) to be used is specified in quantmethod.
    % optmethod refers refers to the method to be used for finding the
    % clipping point Xpoi for the quantizer.
    %
    %   Inputs:
    %    X_all             - Complex valued floating point color hologram
    %    L                 - Bit-depth of unsigned integer representation
    %    quantmethod       - Quantization method
    %    varg:
    %       varg@char-array   - Optimization method for finding clipping
    %        == optmethod                       point
    %       varg@complex(1)   - Clipping point, if clipping point should be reused
    %        == Xpoi
    %   Output:
    %    Q                 - Unsigned integer representation
    %    Xq                - Dequantized Q
    %    Xpoi              - Clipping point

    si = size(X_all);
    si(3) = size(X_all, 3);

    Xq = zeros(si, class(X_all));

    for c = si(3):-1:1

        if (ischar(varg))

            switch varg
                case 'Noclip'
                    xpoireal = max(abs(real(reshape(X_all(:, :, c), [], 1))));
                    [qtmp, xqtmp] = quantize_helper(real(reshape(X_all(:, :, c), [], 1)), xpoireal, L, quantmethod);
                    Xq(:, :, c) = reshape(xqtmp, si(1), si(2));
                    Q(:, :, c) = uint16(reshape(qtmp, si(1), si(2)));

                    xpoiimag = max(abs(imag(reshape(X_all(:, :, c), [], 1))));
                    [qtmp, xqtmp] = quantize_helper(imag(reshape(X_all(:, :, c), [], 1)), xpoiimag, L, quantmethod);
                    Xq(:, :, c) = Xq(:, :, c) + 1i * reshape(xqtmp, si(1), si(2));
                    Q(:, :, c) = complex(Q(:, :, c), uint16(reshape(qtmp, si(1), si(2))));
                case 'SD'
                    xpoireal = std(real(reshape(X_all(:, :, c), [], 1))) * 3.35268;
                    [qtmp, xqtmp] = quantize_helper(real(reshape(X_all(:, :, c), [], 1)), xpoireal, L, quantmethod);
                    Xq(:, :, c) = reshape(xqtmp, si(1), si(2));
                    Q(:, :, c) = uint16(reshape(qtmp, si(1), si(2)));

                    xpoiimag = std(imag(reshape(X_all(:, :, c), [], 1))) * 3.35268;
                    [qtmp, xqtmp] = quantize_helper(imag(reshape(X_all(:, :, c), [], 1)), xpoiimag, L, quantmethod);
                    Xq(:, :, c) = Xq(:, :, c) + 1i * reshape(xqtmp, si(1), si(2));
                    Q(:, :, c) = complex(Q(:, :, c), uint16(reshape(qtmp, si(1), si(2))));
                case 'GSS'
                    [qtmp, xqtmp, xpoireal] = gss(real(reshape(X_all(:, :, c), [], 1)), L, quantmethod);
                    Xq(:, :, c) = reshape(xqtmp, si(1), si(2));
                    Q(:, :, c) = uint16(reshape(qtmp, si(1), si(2)));

                    [qtmp, xqtmp, xpoiimag] = gss(imag(reshape(X_all(:, :, c), [], 1)), L, quantmethod);
                    Xq(:, :, c) = Xq(:, :, c) + 1i * reshape(xqtmp, si(1), si(2));
                    Q(:, :, c) = complex(Q(:, :, c), uint16(reshape(qtmp, si(1), si(2))));
                case 'Hybrid'
                    % Part 1
                    [qtmp, xqtmp, xpoireal] = gss(real(reshape(X_all(:, :, c), [], 1)), L, quantmethod);
                    Xq(:, :, c) = reshape(xqtmp, si(1), si(2));
                    Q(:, :, c) = uint16(reshape(qtmp, si(1), si(2)));

                    [qtmp, xqtmp, xpoiimag] = gss(imag(reshape(X_all(:, :, c), [], 1)), L, quantmethod);
                    Xq(:, :, c) = Xq(:, :, c) + 1i * reshape(xqtmp, si(1), si(2));
                    Q(:, :, c) = complex(Q(:, :, c), uint16(reshape(qtmp, si(1), si(2))));
                    D1 = norm(X_all(:, :, c) - Xq(:, :, c), 'fro');

                    % Part 2
                    xpoireal2 = max(abs(real(reshape(X_all(:, :, c), [], 1))));
                    [qtmp, xqtmp] = quantize_helper(real(reshape(X_all(:, :, c), [], 1)), xpoireal2, L, quantmethod);
                    Xq2 = reshape(xqtmp, si(1:2));
                    Q2 = reshape(uint16(qtmp), si(1:2));

                    xpoiimag2 = max(abs(imag(reshape(X_all(:, :, c), [], 1))));
                    [qtmp, xqtmp] = quantize_helper(imag(reshape(X_all(:, :, c), [], 1)), xpoiimag2, L, quantmethod);
                    Xq2 = complex(Xq2, reshape(xqtmp, si(1:2)));
                    Q2 = complex(Q2, reshape(uint16(qtmp), si(1:2)));
                    D2 = norm(X_all(:, :, c) - Xq2, 'fro');

                    % Decide
                    if D1 > D2 % Keep 2
                        Q(:, :, c) = Q2;
                        Xq(:, :, c) = Xq2;
                        xpoireal = xpoireal2;
                        xpoiimag = xpoiimag2;
                    end

            end

            Xpoi(c) = xpoireal + 1i * xpoiimag;
        else
            [Q(:, :, c), Xq(:, :, c)] = quantize_helper(X_all(:, :, c), varg(c), L, quantmethod);
        end

    end

end

function [q, xq, xpoi] = gss(x, L, quantmethod)
    % Golden section search with fixed iterations
    phi = (1 + sqrt(5)) / 2;
    b = max(abs(x));
    a = 0;
    c = b - ((b - a) / phi);
    d = a + ((b - a) / phi);
    ITERATIONS = 50;

    for it = 1:ITERATIONS
        [~, xq] = quantize_helper(x, c, L, quantmethod);
        D_c = sum((x - xq) .* (x - xq));
        [~, xq] = quantize_helper(x, d, L, quantmethod);
        D_d = sum((x - xq) .* (x - xq));

        if (D_c < D_d)
            b = d;
        else
            a = c;
        end

        c = b - ((b - a) / phi);
        d = a + ((b - a) / phi);
    end

    xpoi = (b + a) / 2;
    [q, xq] = quantize_helper(x, xpoi, L, quantmethod);
end
