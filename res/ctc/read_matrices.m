function R = read_matrices(fname, dims, cmplx)
    % read (complex) float matrix from file (path) 'fname'
    % give dimensions 'dims' and whether matrix is complex ('cmplx')
    if nargin < 3
        cmplx = 0;
    end

    if numel(dims) == 1
        dims = dims * [1 1];
    end

    fid = fopen(fname, 'r');

    if cmplx
        R = single(fread(fid, 2 * prod(dims), 'single'));
        R = reshape(R(1:2:end) + 1i * R(2:2:end), dims);
    else
        R = single(fread(fid, dims, 'single'));
    end

    fclose(fid);

end
