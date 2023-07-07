function [s] = channel2string(x)

    switch x
        case 1
            s = 'r';
        case 2
            s = 'g';
        case 3
            s = 'b';
    end

end
