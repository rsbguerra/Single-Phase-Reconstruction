
function generate_inputs(holo_config, enc_config)

    paths.out = ['../res/interfere_output/' holo_config.name];
    paths.holo_cfg = fullfile(paths.out, [holo_config.name '_holo_001.txt']);
    paths.enc_cfg  = fullfile(paths.out, [holo_config.name '_enc_001.txt']);
    paths.infile   = fullfile(paths.out, [holo_config.name '.bin']);

    if ~exist(paths.out, 'dir')
        mkdir(paths.out)
    end

    interfere_write_holocfg(paths.holo_cfg, holo_config);
    interfere_write_enccfg(paths.enc_cfg, enc_config);

    %% Write input file
    disp(['Writing input file: ' paths.infile])

    %% Write data
    write_matrices(holo_config.name, paths.infile, iscomplex(holo_config.data))
end
