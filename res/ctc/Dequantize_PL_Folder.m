function Dequantize_PL_Folder(Folders)
    % Dequantize_PL_Folder is the folder wrapper that dequantizes decoded
    % unsigned integer values of the different codecs into the original
    % floating point representation
    %
    %
    % Created by K.M. Raees, 21.04.2020
    %
    %   Inputs:
    %   Folders           - Working folder
    Xpoi = []; L = []; quantmethod = [];
    load(fullfile(Folders.forkfolder, 'quantref.mat'), 'Xpoi', 'L', 'quantmethod');
    f_hm = fullfile(Folders.forkfolder, 'hm');
    f_j2k = fullfile(Folders.forkfolder, 'j2k');

    dequantize_PL_Folder(f_hm);
    dequantize_PL_Folder(f_j2k);

    function dequantize_PL_Folder(curfolder)
        flag = 1;
        count = 1;
        dircodec = dir(curfolder);

        while (flag == 1)
            fname = ['rate' num2str(count, '%03d') '.mat'];

            if any(strcmp({dircodec.name}, fname))
                Qcodechat = [];
                load(fullfile(curfolder, fname), 'Qcodechat');
                Xcodechat = Dequantize_PL(Qcodechat, Xpoi, L, quantmethod);
                save(fullfile(curfolder, fname), 'Xcodechat', '-append');
                count = count + 1;
            else
                flag = 0;
            end

        end

    end

end
