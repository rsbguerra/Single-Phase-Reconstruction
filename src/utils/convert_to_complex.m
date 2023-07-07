function [x] = convert_to_complex(am, ph)
    x = complex(zeros(size(am), 'single'), 0);
    for i = 1:3
        x(:, :, i) = am(:, :, i) .* exp(1j .* ph);
    end
end
