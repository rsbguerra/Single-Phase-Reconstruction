function [hol_view] = aperture_gen_angle(Hol, isFourierDH, pp, rec_dist, ...
        h_angle, v_angle, dof_angle, apod)
    %APERTURE_GEN_ANGLE sets an automatic (position and dimension)
    % synthetic aperture from h_angle,v_angle,dof_angle.
    % Based on ISO/IEC JTC 1/SC 29/WG1 M82039.
    %
    %   Inputs:
    %    Hol               - hologram
    %    isFourierDH       - isFourierDH boolean
    %    pp                - pixel pitch [m]
    %    rec_dist          - reconstruction distance [m]
    %    h_angle           - horizontal angle (theta) [deg]
    %    v_angle           - vertical angle (phi) [deg]
    %    dof_angle         - depth of field angle (psi) [deg]
    %    apod              - "1" to apodize the aperture with 2D Hanning window
    %
    %   Output:
    %    hol_view          - windowed hologram
    %
    % Positive h_angle: right
    % Positive v_angle: up
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

    h_angle = deg2rad(h_angle);
    v_angle = deg2rad(v_angle);
    dof_angle = deg2rad(dof_angle);

    %positions
    x_a = abs(rec_dist) * (tan(h_angle) - tan(dof_angle));
    x_b = abs(rec_dist) * (tan(h_angle) + tan(dof_angle));
    y_a = abs(rec_dist) * (tan(v_angle) - tan(dof_angle));
    y_b = abs(rec_dist) * (tan(v_angle) + tan(dof_angle));

    %positions in pixel
    start_row = (hol_rows / 2) - ceil(y_b / pp);
    start_row = fix(start_row); %useful if hol dim. is odd

    if start_row == 0 %shadow approx
        start_row = 1;
    end

    end_row = (hol_rows / 2) - floor(y_a / pp);
    end_row = fix(end_row);

    if end_row == hol_rows + 1 %shadow approx
        end_row = end_row - 1;
    end

    start_col = floor(x_a / pp) + (hol_cols / 2);
    start_col = fix(start_col);

    if start_col == 0 %shadow approx
        start_col = start_col + 1;
    end

    end_col = ceil(x_b / pp) + (hol_cols / 2);
    end_col = fix(end_col);

    if end_col == hol_cols + 1 %shadow approx
        end_col = end_col - 1;
    end

    size_V = end_row - start_row + 1;
    size_H = end_col - start_col + 1;

    if ((size_V - size_H) == 1)
        end_col = end_col - 1;
    elseif ((size_H - size_V) == 1)
        end_row = end_row - 1;
    end

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
