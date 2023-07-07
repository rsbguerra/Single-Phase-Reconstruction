function Y = borderpad(X, S)
    % function Y = borderpad(X, S)
    %
    %   adds black borders to image X until such that it has dimensions S
    %
    %   v1.00
    %   16.01.2018, Tobias Birnbaum

    s = size(X);
    s(1:numel(S)) = S;

    Y = zeros(s);
    xs = floor((s(2) - size(X, 2)) / 2);

    if S(1) == 1
        ys = 0;
    else
        ys = floor((s(1) - size(X, 1)) / 2);
    end

    Y(ys + 1:ys + size(X, 1), xs + 1:xs + size(X, 2), :) = X;
end
