function Quarefwrite_PL(Qcodec, Xqref, Xpoi, L, quantmethod, Folders)
    % quarefwrite_PL writes the quantized reference in hologram plane and
    % its reconstructions
    % Created by K.M. Raees, 21.04.2020
    % Modified: T. Birnbaum, 04.07.2020
    %
    %   Inputs:
    %    Xqref   - Floating point quantized reference in hologram plane
    %    H       - Hologram information loaded from Pleno DB
    %    Folders - Folders structure

    % Layman's check for octave compatible mode
    isOctave = false;

    try
        a = datetime; clear a;
        contains('abc', 'a');
        isOctave = false;
    catch me
        isOctave = true;
    end

    if (isOctave)
        save73 = {'-hdf5'};
    else
        save73 = {'-v7.3', '-nocompression'};
    end

    makefolder(Folders.forkfolder);
    save(fullfile(Folders.forkfolder, 'quantref.mat'), save73{:}, 'Qcodec', 'Xqref', 'Xpoi', 'L', 'quantmethod');
end
