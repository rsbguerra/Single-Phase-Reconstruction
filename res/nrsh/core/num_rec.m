function [hol_rendered] = num_rec(hologram, info, rec_dist)
    %NUM_REC reconstructs a hologram belonging to Pleno DB.
    %
    %   Inputs:
    %    hologram - hologram to reconstruct
    %    info     - reconstruction parameters
    %    rec_dist - reconstruction distance [m]
    %
    %   Output:
    %    hol_rendered - hologram reconstruction.
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

    %% RECONSTRUCTION
    colors = size(hologram, 3);
    hol_rendered = hologram;
    if (rec_dist == 0), return, end % Early exit

    switch lower(info.method)

        case 'asm'

            for idx = 1:colors
                hol_rendered(:, :, idx) = rec_asm(hol_rendered(:, :, idx), ...
                    info.pixel_pitch, ...
                    info.wlen(idx), rec_dist, ...
                    info.zero_pad, info.direction);
            end

        case 'fresnel'

            if (contains(info.dataset, 'emergimg'))
                fun = @(dh, p, wlen, z, pad, dir) rec_fresnel_deprecated(dh, p, wlen, z, pad, dir);
            else
                fun = @(dh, p, wlen, z, pad, dir) rec_fresnel(dh, p, wlen, z, pad, dir);
            end

            for idx = 1:colors
                hol_rendered(:, :, idx) = fun(hol_rendered(:, :, idx), ...
                    info.pixel_pitch, ...
                    info.wlen(idx), rec_dist, ...
                    info.zero_pad, info.direction);
            end

        case 'fourier-fresnel'
            [rows_ev, cols_ev, ~] = size(hol_rendered);

            %hologram dimensions forced to be even
            if (mod(rows_ev, 2) ~= 0)
                rows_ev = rows_ev - 1;
                hol_rendered = hol_rendered(1:rows_ev, :, :);
            end

            if (mod(cols_ev, 2) ~= 0)
                cols_ev = cols_ev - 1;
                hol_rendered = hol_rendered(:, 1:cols_ev, :);
            end

            for idx = 1:colors
                hol_rendered(:, :, idx) = rec_fresnel(hol_rendered(:, :, idx), ...
                    info.pixel_pitch, ...
                    info.wlen(idx), rec_dist, ...
                    info.zero_pad, info.direction, info.ref_wave_rad);
            end

        otherwise
            error('nrsh:num_rec:method', 'Error in nrsh: %s: unknown reconstruction method.', info.method)
    end

end
