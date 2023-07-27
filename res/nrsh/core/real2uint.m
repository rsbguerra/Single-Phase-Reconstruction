function [image, minim, max_scaled] = real2uint(image, qbit)
    %REAL2UINT Convert double image to uint image.
    %
    %   Inputs:
    %    image             - real image
    %    qbit              - quantization bit for output image
    %
    %   Output:
    %    image            - input image quantized at qbit
    %    minim            - original minimum in real image
    %    max_scaled       - maximum value in image after minimum subtraction
    %
    %If the input is already uint8 or uint16, it will be returned with no
    %modifications, minim and max_scaled will be empty.
    %

    if isa(image, 'uint8') || isa (image, 'uint16')
        minim = [];
        max_scaled = [];
        return
    end

    minim = min(image(:));
    image = (image - minim);

    max_scaled = max(image(:));
    image = (image / max_scaled);

    image = image * ((2 ^ (qbit)) - 1);

    if qbit <= 8
        image = uint8(round(image));
    else
        image = uint16(round(image));
    end

end
