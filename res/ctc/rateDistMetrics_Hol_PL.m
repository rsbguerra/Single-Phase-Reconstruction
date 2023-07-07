function RD = rateDistMetrics_Hol_PL(Xhat_all, X_all, doCoreVerification)
    % RateDistMetrics_PL computes the  rate-distortion metrics
    %
    % Created by K.M. Raees, 21.04.2020
    % Modified: T. Birnbaum, 04.07.2020
    % Modified: T. Birnbaum, 12.01.2021
    % Modified: T. Birnbaum, 17.02.2022
    %
    % Inputs:
    %   Xhat_all     - Hologram in hologram pnae
    %   X_all        - Reference hologram in hologram pnae
    %   doCoreVerification@bool(1)... flag for signaling core-experiment mode (no removal of interim bitstreams)
    %
    %   Output:
    %   Always:
    %    RD.snr_hol               - SNR of wavefield (Complex float) at hologram
    %                               plane
    %   Binary:
    %    RD.hamming_hol           - Hamming distance for binary holograms at hologram plane
    %
    %   Non-binary:
    %    RD.ssim                  - ssim(Real) + ssim(Imag) at hologram plane
    % If ~doCoreVerification:
    %    RD.ussim                 - ussim(Real) + ussim(Imag) at hologram plane
    %                               ussim does renormalize + dc shift the GT
    %                                   the deg. data is processed the same way
    %                                   and clipped eventually

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

    X_all = cast(X_all, 'like', Xhat_all);

    if (isOctave), ssimFun = @(x, y) ssim_index_wrapper(x, y); warning('CTC:ssim_octave', 'The original ssim implementation is not comparable with the proprietary Matlab implementation.'), else, ssimFun = @(x, y) ssim(x, y); end

    isbinary = isa(X_all, 'logical') || (numel(unique(X_all(:))) < 3);

    for c = size(X_all, 3):-1:1
        Sig = norm(X_all(:, :, c), 'fro') .^ 2; %sum(sum(X_all(:,:,c).*conj(X_all(:,:,c))));
        Noi = norm(X_all(:, :, c) - Xhat_all(:, :, c), 'fro') .^ 2; %sum(sum((X_all(:,:,c)-Xhat_all(:,:,c)).*conj(X_all(:,:,c)-Xhat_all(:,:,c))));
        snr_hol(c) = 10 * log10(Sig / Noi);

        if (isbinary)
            hamming_hol(c) = nnz(bitxor(Xhat_all(:, :, c), X_all(:, :, c)));
        else
            ssim_hol(c) = (ssimFun(real(Xhat_all(:, :, c)), real(X_all(:, :, c))) + ssimFun(imag(Xhat_all(:, :, c)), imag(X_all(:, :, c)))) / 2;

            if (~doCoreVerification)
                ussim_hol(c) = (ussimFun(real(Xhat_all(:, :, c)), real(X_all(:, :, c))) + ussimFun(imag(Xhat_all(:, :, c)), imag(X_all(:, :, c)))) / 2;
            end

        end

    end

    RD.snr_hol = snr_hol;

    if (isbinary)
        RD.hamming_hol = hamming_hol;
    else
        RD.ssim_hol = ssim_hol;

        if (~doCoreVerification)
            RD.ussim_hol = ussim_hol;
        end

    end

    function res = ussimFun(a, ref)
        m = max(abs(ref(:)));
        a = min(max(a ./ m, -1), 1) / 2 + 0.5;
        ref = ref ./ m / 2 + 0.5;

        if (isOctave)
            a = a * 255;
            ref = ref * 255;
        end

        res = ssimFun(a, ref);
    end

end
