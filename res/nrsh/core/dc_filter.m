function [img_filtered] = dc_filter(img, dc_size, dc_type)
    %DC_FILTER filters the DC component of the reconstructed image
    %
    %   Inputs:
    %    img               - reconstructed image to be filtered
    %    dc_size           - DC filter size with respect to img dimensions
    %                        (in percentage: 1=100%, 0.5=50%...). If set to []
    %                        the default value of 0.5 is used.
    %    dc_type*          - type of filter used for DC filtering. See
    %                        window2.m for supported filters.
    %
    %(*)optional. If not provided, the original W.U.T. DC filter is used.
    %
    %   Output:
    %    img_filtered     - image with the DC filtered
    %
    % alternative filters can be declared as char. vectors, without @. i.e.
    % @bartlett can be also declared as 'bartlett'.
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
    if nargin < 3
        dc_type = 'wut';
    end

    if (dc_size > 1) || (dc_size < 0)
        dc_size = 0.5;
        warning('nrsh:dc_filter', 'Warning in nrsh: the DC filter size is out of the allowed range [0, 1]. The default value of %.2f is used.', dc_size)
    end

    if isempty(dc_size)
        dc_size = 0.5;
    end

    [img_rows, img_cols, ~] = size(img);

    if strcmpi(dc_type, 'wut')
        img_filtered = img .* DCfilter(img_cols, img_rows, dc_size);
    else
        filt_rows = round(img_rows * dc_size);
        filt_cols = round(img_cols * dc_size);

        %filter dimensions are forced to be even
        if (mod(filt_rows, 2) ~= 0)
            filt_rows = filt_rows - 1;
        end

        if (mod(filt_cols, 2) ~= 0)
            filt_cols = filt_cols - 1;
        end

        %DC Filter
        kernel = imcomplement(window2(filt_rows, filt_cols, dc_type));

        row_pad = round((img_rows - filt_rows) / 2);
        col_pad = round((img_cols - filt_cols) / 2);

        img_filtered = img .* padarray(kernel, [row_pad, col_pad], 1, 'both');

    end

end
