function [mssim, ssim_map] = ssim_index_wrapper(img1, img2, varargin)
    % Wrapper for proper dynamic range for ssim_index given arb. input dyn. range

    mi = min([real(img1(:)); real(img2(:))]);
    ma = max([real(img1(:)); real(img2(:))]);

    if (~isreal(img1) || ~isreal(img2))
        mi = min([mi; imag(img1(:)); imag(img2(:))]);
        ma = max([ma; imag(img1(:)); imag(img2(:))]);
    end

    img1 = 255 * (img1 - mi) / (ma - mi);
    img2 = 255 * (img2 - mi) / (ma - mi);

    if (nargout > 1)
        mssim = ssim_index(img1, img2, varargin{:});
    else
        [mssim, ssim_map] = ssim_index(img1, img2, varargin{:});
    end

end
