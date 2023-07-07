function [hol_rendered] = aperture(hologram, isFourierDH, pixel_pitch, rec_dist, h_pos, v_pos, ap_size, apod)
    %APERTURE creates a synthetic aperture in the hologram.
    %
    %   Inputs:
    %    hologram          - hologram to reconstruct
    %    isFourierDH       - isFourierDH boolean
    %    pixel_pitch       - pixel pitch, in meters
    %    rec_dist          - reconstruction distance, in meters
    %    h_pos             - horizontal position at which the synthetic
    %                        aperture will be placed
    %    v_pos             - vertical position at which the synthetic
    %                        aperture will be placed
    %    ap_size           - synthetic aperture size
    %    apod              - apodization window
    %
    %   Output:
    %    hol_rendered      - hologram with synthetic aperture
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

    %% SYNTHETIC APERTURE GENERATION
    if size(ap_size, 2) == 2 %PIXEL MODE

        if nnz(ap_size) < 2 %if one of the two dims. of the aperture is zero, the full hologram will be reconstructed
            hol_rendered = hologram;
        else
            hol_rendered = aperture_gen_pixel(hologram, isFourierDH, h_pos, v_pos, ap_size, apod);
        end

    elseif (size(ap_size, 2) == 1) %ANGLE MODE

        if (ap_size > 0)
            hol_rendered = aperture_gen_angle(hologram, isFourierDH, pixel_pitch, rec_dist, h_pos, v_pos, ap_size, apod);
        else %if the DOF angle is 0 the full hologram will be reconstructed (cannot be negative here, due to the input check)
            hol_rendered = hologram;
        end

    else
        error('nrsh:invalid_input', 'Error in nrsh: The shape of ap_size is not 1x1 or 1x2 as expected.')
    end
