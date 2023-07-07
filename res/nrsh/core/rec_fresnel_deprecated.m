function [recons] = rec_fresnel_deprecated(hol, pitch, wlen, rec_dist, zero_pad, direction)
    %REC_FRESNEL Frensnel Method implementation.
    %
    %   Inputs:
    %    hol               - input hologram to reconstruct
    %    pitch             - pixel pitch in meters
    %    wlen              - wavelength in meters.
    %    rec_dist          - reconstruction distance in meters
    %    zero_pad          - Enables interim zero_padding and kernel
    %                        band-wdith limitation, for more details on the latter
    %                        see [1]
    %    direction         - reconstruction direction. It should be one of
    %                        the following char. arrays: forward (propagation
    %                        towards the object plane) or inverse (propagation
    %                        towards the hologram plane)
    %
    %   Output:
    %    recons            - reconstructed field (complex magnitude)
    %
    %   [1] Blinder, David, Tobias Birnbaum, and Peter Schelkens.
    %       "Pincushion point-spread function for computer-generated holography."
    %       Optics Letters 47.8 (2022): 2077-2080.
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

    %% 0) Initialization
    % Initialize missing arguments
    if nargin < 6
        direction = 'forward';

        if nargin < 5
            zero_pad = false;

            if nargin < 4
                error('nrsh:rec_fresnel:input_args', 'Error in rec_fresnel: not enough input arguments.')
            end

        end

    end

    % Check if propagation has to happen
    doPropag = (abs(rec_dist) > eps('single'));

    % Zero-pad only if propagation is happening
    zero_pad = zero_pad && doPropag;

    % Initialize other parameters
    super_res_fac = 2;
    k = 2 * pi / wlen;

    % Keep pixel pitch in memory
    persistent pitch_pers;

    if isempty(pitch_pers)
        pitch_pers = pitch;
    end

    %% 1) Zero-padding
    if (zero_pad == true)
        pitch = pitch / super_res_fac;
        hol = fourierpadcrop(hol, super_res_fac);
    end

    %% 2) Initialize frequency grid and mask
    [rows, cols] = size(hol);
    persistent F
    recons = hol;

    Lx = cols * pitch(1);
    Ly = rows * pitch(end);

    doUpdateF = doPropag && (isempty(F) || cols ~= size(F, 1) || rows ~= size(F, 2) || abs(pitch(1) - pitch_pers(1)) > eps('single') || abs(pitch(end) - pitch_pers(end)) > eps('single'));
    isSameDim = isequal(cols, rows) && (abs(pitch(1) - pitch(end)) < eps('single'));
    pitch_pers = pitch;

    if (doUpdateF || zero_pad) % Need to compute mask or F

        if (isSameDim)
            X = -Lx / 2:pitch_pers:Lx / 2 - pitch_pers;
            [X, ~] = meshgrid(X);
        else
            X = -Lx / 2:pitch_pers:Lx / 2 - pitch_pers;
            Y = -Ly / 2:pitch_pers:Ly / 2 - pitch_pers;
            [X, Y] = meshgrid(X, Y);
        end

    end

    if (doUpdateF) % Recompute F, only if needed

        if (isSameDim)
            F = X .^ 2 + X' .^ 2;
        else
            F = X .^ 2 + Y .^ 2;
        end

    end

    if (zero_pad) % Need to always compute mask, if zero_pad == true

        if (isSameDim)
            mask = abs(X) ./ sqrt(X .^ 2 + X.' .^ 2 + rec_dist ^ 2) < wlen / (2 * pitch_pers);
            %      & abs(X.')./sqrt(X.^2 + X.'.^2 + rec_dist^2) < wlen/(2*pitch_pers);
            mask = mask & mask.';
            mask = fftshift(mask);
        else
            mask = abs(X) ./ sqrt(X .^ 2 + Y .^ 2 + rec_dist ^ 2) < wlen / (2 * pitch_pers) & ...
                abs(Y) ./ sqrt(X .^ 2 + Y .^ 2 + rec_dist ^ 2) < wlen / (2 * pitch_pers);
            mask = fftshift(mask);
        end

    end

    clear Y X Y pitch; % Use pitch_pers instead of pitch

    %% 3) Propagate
    if strcmpi(direction, 'forward')
        %% 4.a1) Apply Kernel
        if (doPropag)
            recons = ((-1i / (wlen * rec_dist)) * exp((1i * k / (2 * rec_dist)) * F)) .* recons;
        end

        %% 4.a2) BW limit, if required
        if (zero_pad == true)
            recons = recons .* mask;
        end

        %% 4.a3) Inverse Fourier transform
        recons = ifftshift(ifft2(recons));
    else
        %% 4.b1) Inverse Fourier transform
        recons = fft2(fftshift(recons));

        %% 4.b2) Apply kernel
        if (doPropag)
            recons = ((- (wlen * rec_dist) / 1i) * exp(- (1i * k / (2 * rec_dist)) * F)) .* recons;
        end

        %% 4.b3) BW limit, if required
        if (zero_pad == true)
            recons = recons .* mask;
        end

    end

    %% 5) Undo interim zero padding
    if (zero_pad == true)
        recons = fourierpadcrop(recons, 1 / super_res_fac);
    end
