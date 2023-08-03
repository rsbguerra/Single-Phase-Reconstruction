function [rec_par_idx] = aperture_pixel_checker(hol_rows, hol_cols, ...
        rec_par_idx, ap_sizes)
    %APERTURE_PIXEL_CHECKER checks for out-of-bound synthetic apertures (pixel-based).
    %
    %   Inputs:
    %    hol_rows          - hologram rows
    %    hol_cols          - hologram columns
    %    rec_par_idx       - indexes to user input parameters, shaped with
    %                        combvec/combvec alternative
    %    ap_sizes          - synthetic aperture size(s) [deg]
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

    fprintf('\nSynthetic aperture out-of-bound check...')

    bad_comb = [];

    for idx = 1:size(rec_par_idx, 2)
        current_size = ap_sizes{rec_par_idx(4, idx)};

        %first check if the size is a 2 elements row vector
        if ~isequal(size(current_size), [1, 2])
            bad_comb = [bad_comb, idx];
        else
            %then do the other checks
            if ((current_size(1) > hol_rows) || (current_size(2) > hol_cols) ...
                    || (current_size(1) < 0) || (current_size(2) < 0))

                bad_comb = [bad_comb, idx];
            end

        end

    end

    if ~isempty(bad_comb)
        fprintf('\n')
        warning('The following synthetic apertures are not consistent with hologram dimensions [%dx%d]:', hol_rows, hol_cols)

        for idx = 1:size(bad_comb, 2)
            wrong_size = strrep(mat2str(ap_sizes{rec_par_idx(4, bad_comb(idx))}), ' ', 'x');
            fprintf('%s\n', wrong_size);
        end

        if isequal(size(bad_comb, 2), size(rec_par_idx, 2))
            error('There are no other valid synthetic apertures! Execution aborted.')
        else
            user_rep = input('Do you wish to delete these apertures and continue with the others? Otherwise the current execution will be aborted. (y/n) [n]: ', 's');

            if strcmpi(user_rep, 'y')
                rec_par_idx(:, bad_comb) = [];
                disp('The execution will continue without the uncorrect apertures.')
                return
            elseif strcmpi(user_rep, 'n')
                error('Exectution aborted by the user.')
            else
                error('Exectution aborted.')
            end

        end

    end

    disp('passed!')

end
