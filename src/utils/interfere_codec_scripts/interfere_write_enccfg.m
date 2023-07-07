function interfere_write_enccfg(enc_config_file, enc_config)
    fid = fopen(enc_config_file, 'w');

    fprintf(fid, '#Optimization aux. parameters \n');
    fprintf(fid, 'out_bitdepth_max : %d\n', enc_config.maxCoeffBitDepth);
    fprintf(fid, 'bs_max_iter : %d\n', enc_config.bs_max_iter);
    fprintf(fid, 'gs_max_iter : %d\n', enc_config.gs_max_iter);
    fprintf(fid, 'opt_target_tolerance : 0.1\n'); %TODO: Enable passing and writing here

    % The parameters below are not in use for this pipeline, for now %TODO: fixme
    fprintf(fid, '#PROGRAMFLOW PARAMETERS\n');
    fprintf(fid, 'doLossless : false\n');
    fprintf(fid, 'doObjectPlaneCompression : false\n');
    fprintf(fid, 'doTransform : true\n');
    fprintf(fid, 'doAdaptiveQuantization : false\n');

    fprintf(fid, '#Optimization control parameters\n');
    fprintf(fid, 'mode : "SNR"\n');
    fprintf(fid, 'opt_target : 0\n');
    fclose(fid);
end
