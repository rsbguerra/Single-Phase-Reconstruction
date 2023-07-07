function [hol_rendered, clip_out_min, clip_out_max] = clipping(hologram, perc_clip, perc_value, hist_stretch, clip_min, clip_max)
    %CLIPPING performs clipping and histogram stretching operations
    %
    %   Inputs:
    %    hologram          - hologram reconstruction
    %    clip_min          - minimal intensity value for clipping. It must be a
    %                        single value
    %    clip_max          - maximal intensity value for clipping. It must be a
    %                        single value
    %
    %   Output:
    %    hol_rendered      - clipped hologram reconstruction
    %    clip_min_out      - minimal intensity of the numerical reconstruction
    %    clip_max_out      - maximal intensity of the numerical reconstruction
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

    %% ENHANCEMENT
    hol_rendered = hologram;
    %absolute value clipping
    if clip_min > -1 && clip_max > -1
        hol_rendered(hol_rendered > clip_max) = clip_max;
        hol_rendered(hol_rendered < clip_min) = clip_min;

        clip_out_min = clip_min;
        clip_out_max = clip_max;
    else
        %percentile clipping
        if perc_clip == 1
            clip_value = prctile(hol_rendered(:), perc_value);
            hol_rendered(hol_rendered > clip_value) = clip_value;
        end

        clip_out_min = min(hol_rendered(:));
        clip_out_max = max(hol_rendered(:));
    end

    %histogram stretching
    if hist_stretch == 1
        hol_rendered = (hol_rendered - clip_out_min) ./ (clip_out_max - clip_out_min);
    end

end
