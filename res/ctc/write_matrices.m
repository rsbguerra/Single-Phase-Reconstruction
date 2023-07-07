function write_matrices(M, fname, forcecomplex)
    % Write one or more float matrices M to file (path) 'fname'
    % Multiple matrices should be put in a cell matrix
    % optional parameter 'forcecomplex' forces complex input
    if nargin < 3; forcecomplex = 0; end

    if ischar(fname) || isstring(fname)
        fid = fopen(fname, 'w');
        closeme = 1;
    else
        fid = fname;
        closeme = 0;
    end

    if iscell(M)

        for i = 1:length(M)
            writemat(M{i});
        end

    else
        writemat(M);
    end

    if closeme; fclose(fid); end

    function writemat(X)
        fwrite(fid, unrollmat(X), 'single');
    end

    function Y = unrollmat(X)

        if ~isreal(X) || forcecomplex
            Y = zeros(2 * numel(X), 1, 'single');
            Y(1:2:end) = single(real(X(:)));
            Y(2:2:end) = single(imag(X(:)));
        else
            Y = single(X);
        end

    end

end
