function metricsCombine(file1, file2, fileOut)
    % function metricsCombine(file1, file2, fileOut)
    %
    % 	Combines Metrics.mat of proponents and anchors for common processing.
    % 	Use e.g. as:
    % 	for str2C = {'DeepChess', 'DeepCornellBox_16k', 'DeepDices2k', 'Lowinczanka_doll'}; str2 = str2C{1}; metricsCombine(['H:\Rating_OutData\JPEG_Pleno_subj\proposal\' str2 '\'], ['H:\Rating_OutData\JPEG_Pleno_subj\' str2 '\'], ['H:\Rating_OutData\JPEG_Pleno_subj\' str2 '\']), end
    %
    % INPUT: paths to Metrics.mat files of proponent and anchors
    % OUTPUT: path to Metrics.mat file of combined struct (input for subjective test)
    %
    % File paths or folders containing the "Metrics.mat" can be specified.
    %
    % Version 1.00
    % 01.10.2021, Tobias Birnbaum

    if (~contains(file1, 'Metrics.mat')), file1 = fullfile(file1, 'Metrics.mat'); end
    if (~contains(file2, 'Metrics.mat')), file2 = fullfile(file2, 'Metrics.mat'); end
    if (~contains(fileOut, '.mat')), fileOut = fullfile(fileOut, 'Metrics.mat'); end

    disp(['Reading ' file1])
    a = load(file1);
    disp(['Reading ' file2])
    b = load(file2);

    a.distL = [a.distL, b.distL];

    for f = {'obj', 'holo'}

        try
            f2L = fieldnames(b.M.(f{1}));

            for f2 = f2L(:).'
                a.M.(f{1}).(f2{1}) = b.M.(f{1}).(f2{1});
            end

        catch me
        end

    end

    disp(['Writing ' fileOut])
    save(fileOut, '-struct', 'a');
end
