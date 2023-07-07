function [rec_par_idx] = aperture_angle_checker(hol_rows, hol_cols, rec_par_idx, ...
        rec_dists, ap_sizes, h_pos, v_pos, pp, verbosity)
    %APERTURE_ANGLE_CHECKER checks for out-of-bound synthetic apertures (angle-based).
    %
    %   Inputs:
    %    hol_rows          - hologram rows
    %    hol_cols          - hologram columns
    %    rec_par_idx       - indexes to user input parameters, shaped with
    %                        combvec/combvec alternative
    %    rec_dists         - reconstruction distance(s) [m]
    %    ap_sizes          - synthetic aperture size(s) [deg]
    %    h_pos             - horizontal position(s) [deg] at which the synthetic
    %                        aperture will be placed
    %    v_pos             - vertical position(s) [deg] at which the synthetic
    %                        aperture will be placed
    %    pp                - pixel pitch [m]
    %    verbosity         - boolean
    %
    %   Output:
    %    rec_par_idx       - is equal to the input if no out-of-bound is
    %                        detected. If out-of-bound is detected and the user
    %                        wishes to continue, it does not contain the
    %                        out-of-bound combinations.
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

    if (verbosity)
        fprintf('\nSynthetic aperture out-of-bound check...')
    end

    bad_comb = [];

    for idx = 1:size(rec_par_idx, 2)

        rec_dist = rec_dists(rec_par_idx(1, idx));
        h_angle = h_pos(rec_par_idx(2, idx));
        v_angle = v_pos(rec_par_idx(3, idx));
        dof_angle = ap_sizes{rec_par_idx(4, idx)};

        if ~isequal(dof_angle, 0)

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

            %if the horizontal and vertical dimensions of the synth. aperture differ by
            %1 pixel, this differece is automatically fixed. Further analysis is
            %necessary otherwise.
            size_V = end_row - start_row + 1;
            size_H = end_col - start_col + 1;

            if ((size_V - size_H) == 1)
                end_col = end_col - 1;
                disp('Square fix!')
            elseif ((size_H - size_V) == 1)
                disp('Square fix!')
                end_row = end_row - 1;
            elseif (((size_V - size_H) > 1) || ((size_H - size_V) > 1))
                warning('nrsh:aperture', ['Warning in nrsh: the synthetic aperture is not squared!\n', ...
                                'Please keep track of the following parameters that generate ', ...
                                'this condition:\n', ...
                                'Hologram rows: %d cols: %d, rec_dist: %d pitch: %d ', ...
                            'theta: %d [deg] phi: %d [deg] psi: %d [deg]'], hol_rows, hol_cols, rec_dist, pp, ...
                    rad2deg(h_angle), rad2deg(v_angle), rad2deg(dof_angle))

            end

            if start_row > hol_rows || end_row > hol_rows || start_col > hol_cols || ...
                    end_col > hol_cols || start_row < 1 || end_row < 1 || start_col < 1 || ...
                    end_col < 1
                bad_comb = [bad_comb, idx];
            end

        end

    end

    if ~isempty(bad_comb)
        fprintf('\n')
        warning('nrsh:aperture', 'Warning in nrsh: the following combination(s) of h_angle/v_angle/dof_angle/rec_dist generate(s) an out-of-bound synthetic aperture:')

        for idx = 1:size(bad_comb, 2)
            fprintf('h_angle=%g, v_angle=%g, dof_angle=%g, rec_dist=%g\n', ...
                h_pos(rec_par_idx(2, bad_comb(idx))), ...
                v_pos(rec_par_idx(3, bad_comb(idx))), ...
                ap_sizes{rec_par_idx(4, bad_comb(idx))}, ...
                rec_dists(rec_par_idx(1, bad_comb(idx))));
        end

        if isequal(size(bad_comb, 2), size(rec_par_idx, 2))
            error('nrsh:aperture', 'Error in nrsh: there are no other valid combinations! Execution aborted.')
        else
            rec_par_idx(:, bad_comb) = [];
            disp('The execution will continue without the uncorrect apertures.')
        end

    end

    if (verbosity)
        disp('passed!')
    end

end
