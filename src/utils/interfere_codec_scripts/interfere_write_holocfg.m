function interfere_write_holocfg(holo_config_path, holo_config)
    fid = fopen(holo_config_path, 'w');
    strCpx = {'real', 'complex'};
    strCpx = strCpx{1 + iscomplex(holo_config.mat.var)};

    dim = size(holo_config.data);

    fprintf(fid, '#Format specifics\n');
    fprintf(fid, 'representation : "%s"\n', strCpx);
    fprintf(fid, 'datatype : "float"\n');
    fprintf(fid, 'dimension : [%d,%d]\n', dim(1), dim(2));

    fprintf(fid, '#HOLOGRAM SPLITTING\n');
    fprintf(fid, 'tile_size : [%d,%d]\n', holo_config.tile_size(1), holo_config.tile_size(2));
    fprintf(fid, 'transform_block_size : [%d,%d]\n', holo_config.transform_size(1), holo_config.transform_size(2));
    fprintf(fid, '# Format 4D: fx, fy, x, y\n');
    fprintf(fid, 'code_block_size: [%d,%d,%d,%d]\n', holo_config.cb_size(1), holo_config.cb_size(2), holo_config.cb_size(3), holo_config.cb_size(4));
    fprintf(fid, 'quantization_block_size: [%d,%d,%d,%d]\n', holo_config.qb_size(1), holo_config.qb_size(2), holo_config.qb_size(3), holo_config.qb_size(4));

    % These parameters are not in use for now %TODO: Fixme later
    fprintf(fid, '#RECONSTRUCTION PARAMETERS\n');
    fprintf(fid, 'wlen : [%f]\n', 1e-2);
    fprintf(fid, 'pixel_pitch : ([%f])\n', 1e-1);
    fclose(fid);
end
