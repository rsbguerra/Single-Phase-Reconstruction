function [recons_ali] = rgb_align(recons, info)
    %RGB_ALIGN aligns the three color channels, necessary for WUT display RGB
    % holograms after the reconstruction process.
    %
    %
    %   Inputs:
    %    recons            - reconstructed RGB hologram
    %    rec_par_cfg       - structure with rendering parameters, read from
    %                        configuration file
    %   Output:
    %    recons_ali        - reconstructed RGB hologram with the three color
    %                        channels aligned. The dimension is equal to that
    %                        specified in the configuration file.
    %
    %-------------------------------------------------------------------------
    % Copyright(c) 2019
    % University of Cagliari
    % Department of Electrical and Electronic Engineering
    % Italy
    % All Rights Reserved.
    %-------------------------------------------------------------------------
    %
    % The University of Cagliari - Department of Electrical and Electronic
    % Engineering hereby grants to ISO/IEC JTC1 SC29 WG1
    % (JPEG Committee) and each Member of ISO/IEC JTC1 SC29 WG1 (JPEG
    % Committee) who participate in the Working Group dedicated to the
    % standardization of JPEG Pleno, a non-exclusive, nontransferable,
    % worldwide, license under "University of Cagliari - Department of
    % Electrical and Electronic Engineering" copyrights
    % in this software to reproduce, distribute, display, perform and
    % create derivative works for the sole and exclusive purposes of
    % creating a hologram reconstruction software in the frame of
    % the JPEG Pleno standard.
    %
    % Modifications to this code shall be clearly indicated and
    % identified by the relevant copyright notice(s) of the party
    % generating these changes and/or derivative works.
    %
    % Nothing contained in this software shall, except as herein
    % expressly provided, be construed as conferring by implication,
    % estoppel or otherwise, any license or right under (i) any existing
    % or later issuing patent, whether or not the use of information in
    % this software necessarily employs an invention of any existing or
    % later issued patent, (ii) any copyright, (iii) any trademark, or
    % (iv) any other intellectual property right.
    %
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS "AS IS" AND
    % ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
    % TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
    % PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    % COPYRIGHT OWNER BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    % SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    % LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
    % USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
    % AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    % LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
    % IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
    % THE POSSIBILITY OF SUCH DAMAGE.
    %
    %-------------------------------------------------------------------------

    %recons=uint8(recons.*255);%recons should be the out. of the stretch.

    %channel shifts: m to pixel conversion
    recons_img_size = size(recons(:, :, 1));

    shift_yx_R = (info.shift_yx_r) .* (recons_img_size) ./ ...
        (info.wlen(1)) / (info.ref_wave_rad) * ...
        (info.pixel_pitch);
    
    shift_yx_G = (info.shift_yx_g) .* (recons_img_size) ./ ...
        (info.wlen(2)) / (info.ref_wave_rad) * ...
        (info.pixel_pitch);
    
    %NOT USED, for now:
    %shift_yx_B=(rec_par_cfg.shift_yx_b) .* (rec_par_cfg.out_size) ./...
    %            (rec_par_cfg.wlen(3)) / (rec_par_cfg.ref_wave_rad) *...
    %            (rec_par_cfg.pixel_pitch);

    Nyx_R = ceil(info.wlen(1) / info.wlen(3) * recons_img_size(1));
    Nyx_G = ceil(info.wlen(2) / info.wlen(3) * recons_img_size(1));

    %force even dimensions
    if mod(Nyx_R, 2) ~= 0
        Nyx_R = Nyx_R + 1;
    end

    if mod(Nyx_G, 2) ~= 0
        Nyx_G = Nyx_G + 1;
    end

    %RGB channels scale and padding to equal size
    rows_ali = (recons_img_size(1) + (Nyx_R - recons_img_size(1)));
    cols_ali = (recons_img_size(2) + (Nyx_R - recons_img_size(1)));
    recons_ali = zeros(rows_ali, cols_ali, 3);

    %R channel
    ch_temp = fftshift(fft2(recons(:, :, 1)));
    ch_temp_pad = padarray(ch_temp, [(Nyx_R - recons_img_size(1)) / 2, (Nyx_R - recons_img_size(1)) / 2]);
    ch_temp_pad = ifft2(ifftshift(ch_temp_pad));
    recons_ali(:, :, 1) = abs(real(ch_temp_pad));
    recons_ali(:, :, 1) = subarray_yx(recons_ali(:, :, 1), [], -shift_yx_R ./ size(ch_temp_pad));

    %G channel
    ch_temp = fftshift(fft2(recons(:, :, 2)));
    ch_temp_pad = padarray(ch_temp, [(Nyx_G - recons_img_size(1)) / 2, (Nyx_G - recons_img_size(1)) / 2]);
    ch_temp_pad = ifft2(ifftshift(ch_temp_pad));
    ch_temp_pad = padarray(ch_temp_pad, [(Nyx_R - Nyx_G) / 2, (Nyx_R - Nyx_G) / 2]);
    recons_ali(:, :, 2) = abs(real(ch_temp_pad));
    recons_ali(:, :, 2) = subarray_yx(recons_ali(:, :, 2), [], -shift_yx_G ./ size(ch_temp_pad));

    %B channel
    recons_ali(:, :, 3) = padarray(recons(:, :, 3), [(Nyx_R - recons_img_size(1)) / 2, ...
                                              (Nyx_R - recons_img_size(1)) / 2]);

    %%saturate
    %for ch=1:3
    %    recons_ali(:,:,ch)=saturate_gray(recons_ali(:,:,ch),[],1,info.bit_depth);
    %end

    %restore user-defined output size
    recons_ali = recons_ali((rows_ali / 2 - recons_img_size(1) / 2) + 1: ...
    (rows_ali / 2 + recons_img_size(1) / 2), ...
        (cols_ali / 2 - recons_img_size(2) / 2) + 1: ...
        (cols_ali / 2 + recons_img_size(2) / 2), :);

end
