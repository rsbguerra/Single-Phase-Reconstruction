function [hol_view] = aperture_gen_pixel(Hol, isFourierDH, ...
        h_pos, v_pos, ap_size, apod)
    %APERTURE_GEN_PIXEL sets a pixel-based synthetic aperture.
    %
    %   Inputs:
    %    Hol               - hologram
    %    isFourierDH       - isFourierDH boolean
    %    h_pos             - horizontal position expressed in the [-1, 1] range
    %    v_pos             - vertical position expressed in the [-1, 1] range
    %    ap_size           - it must be a row vector. The first elementent is
    %                        the vertical dimension while the second element is
    %                        the horizontal dimension of the synth. aperture.
    %                        Both are expressed in pixel
    %    apod              - "1" to apodize the aperture with 2D Hanning window
    %
    %   Output:
    %    hol_view          -windowed hologram
    %
    % NOTE: positive h_pos: right; positive v_pos: up
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

    [hol_rows, hol_cols, ~] = size(Hol);

    v_pos = -v_pos;

    %positions in pixel
    start_row = max(1, round(hol_rows / 2 + (hol_rows / 2 - ap_size(1) / 2) * v_pos - ap_size(1) / 2) + 1);
    end_row = min(hol_rows, round(hol_rows / 2 + (hol_rows / 2 - ap_size(1) / 2) * v_pos + ap_size(1) / 2));
    start_col = max(1, round(hol_cols / 2 + (hol_cols / 2 - ap_size(2) / 2) * h_pos - ap_size(2) / 2) + 1);
    end_col = min(hol_cols, round(hol_cols / 2 + (hol_cols / 2 - ap_size(2) / 2) * h_pos + ap_size(2) / 2));

    %set the aperture
    if (isFourierDH)
        hol_view = Hol(start_row:end_row, start_col:end_col, :);

        if apod == 1
            apod_wind = window2((end_row - start_row + 1), (end_col - start_col + 1), @hann);
            hol_view = hol_view .* apod_wind;
        end

    else
        hol_view = zeros(size(Hol));

        if apod == 1
            apod_wind = window2((end_row - start_row + 1), (end_col - start_col + 1), @hann);
            hol_view(start_row:end_row, start_col:end_col, :) = ...
                Hol(start_row:end_row, start_col:end_col, :) .* apod_wind;
        else
            hol_view(start_row:end_row, start_col:end_col, :) = ...
                Hol(start_row:end_row, start_col:end_col, :);
        end

    end

end
