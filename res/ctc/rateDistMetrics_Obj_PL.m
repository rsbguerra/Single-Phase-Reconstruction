function RD = rateDistMetrics_Obj_PL(Rec, Ref, doCoreVerification)
    % RateDistMetrics_PL computes the rate-distortion metrics in the reconstructions.
    %
    % Created by K.M. Raees, 21.04.2020
    % Modified: T. Birnbaum, 04.07.2020
    % Modified: T. Birnbaum, 30.09.2020
    % Modified: T. Birnbaum, 17.02.2022
    %
    % Inputs:
    %   Rec        - Compressed reconstruction
    %   Rec        - Reference reconstruction
    %   doCoreVerification@bool(1)... flag for signaling core-experiment mode (no removal of interim bitstreams)
    %
    %   Output:
    %    RD.psnr_obj - PSNR of intensity at object planes
    %    RD.vifp_obj - VIFq of intensity at object planes
    %   If ~doCoreVerification:
    %    RD.ssim_obj - SSIM of intensity at object planes

    % Layman's check for octave compatible mode
    isOctave = false;

    try
        a = datetime; clear a;
        contains('abc', 'a');
        isOctave = false;
    catch me
        isOctave = true;
    end

    if (nargin < 3), doCoreVerification = false; error('DEBUG'); end

    if (~doCoreVerification)
        if (isOctave), ssimFun = @(x, y) ssim_index_wrapper(x, y); warning('CTC:ssim_octave', 'The original ssim implementation is not comparable with the proprietary Matlab implementation.'), else, ssimFun = @(x, y) ssim(x, y); end
    end

    for c = size(Rec, 3):-1:1
        psnr_obj(c) = psnr(Rec(:, :, c), Ref(:, :, c));
        vifp_obj(c) = vifp_mscale(double(Ref(:, :, c)), double(Rec(:, :, c)));

        if (~doCoreVerification)
            ssim_obj(c) = ssimFun(Rec(:, :, c), Ref(:, :, c));
        end

    end

    RD.psnr_obj = psnr_obj;
    RD.vifp_obj = vifp_obj;

    if (~doCoreVerification)
        RD.ssim_obj = ssim_obj;
    end

end
