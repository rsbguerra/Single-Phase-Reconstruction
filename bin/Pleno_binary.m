%% Pipeline for binary lossless compression
% Raees KM., Tobias B.
% Version 1.00
% 22.04.2021

%% 1) Initialization
%Maximum output tile size % Don't touch
ytile = 8192;
xtile = 8192;

%Location of binaries, working folder and results folder
folder.codec = 'codecs';
%Caution:temp folder is cleared
folder.temp = 'B:\temp\JPEGPlenoBinary' ;
folder.result = 'D:\Tobias\HotBackup\757_BinaryForJPEGPleno\01_Compression\result';

mkdir(folder.temp);
mkdir(folder.result);

%Codecs to activate
codecflag.jbig2 = true;                 % Anchor
codecflag.jbig2decodecheck = true;
% codecflag.png = false;
% codecflag.pngdecodecheck = false;
% codecflag.jbig1 = false;
% codecflag.jbig1decodecheck = false;
%codecflag.jpegxl = false;
%codecflag.jpegxldecodecheck = false;

codecflag.proponentTemplate = true;
codecflag.proponentTemplatedecodecheck = true;
 
%% 2) Specify input folder/original test data
iFold = fullfile('E:\Tobias\757_BinaryForJPEGPleno\binaryNoDitherX2');
fl = dir(fullfile(iFold, '*.mat')); fl = {fl.name};

i=1;
Holo = repmat(struct(), [numel(fl), 1]);
for ii = 1:numel(fl)
    % Specify file for non tiled input
    Holo(i).location = fullfile(iFold, fl{ii});
    Holo(i).family = 'ETRO';
    Holo(i).tiledinput = false;
    i=i+1;
end

% % Specify folder for tiled input
% Holo(i).location = 'G:\Pleno\Originals\Binary\dices200k-bilevel\data';
% Holo(i).family = 'BCOM';
% Holo(i).tiledinput = true;
% i=i+1;
% 
% Holo(i).location = 'G:\Pleno\Originals\Binary\bridge';
% Holo(i).family = 'ETRI';
% Holo(i).tiledinput = true;
% i=i+1;


%% 3) Compression loop over datasets
holoOut = cell(length(Holo), 1);
codecsOut = cell(length(Holo), 1);
nameOut = repmat("", [length(Holo), 1]);

for h = 1:length(Holo)
    holo = Holo(h);
    name = strsplit(holo.location, filesep); name = strrep(name{end}, '.mat', '');
    nameOut(h) = string(name);
    disp(['Compressing ' name])
    %Reads hologram in Pleno database
    H = InputParameters(holo);
    Codecs = [];
    %Determine number of output tiles
    YTIL = ceil(H.ylen/ytile); 
    XTIL = ceil(H.xlen/xtile);
    for y = 1:YTIL
        for x = 1:XTIL
            disp(['Tile X:' num2str(x) '/' num2str(XTIL) ' Y:' num2str(y) '/' num2str(YTIL)])
            %Determine location of current output tile
            if (y<YTIL)
                Y = (y-1)*ytile+1:(y)*ytile;
            else
                Y = (y-1)*ytile+1:H.ylen;
            end
            if (x<XTIL)
                X = (x-1)*xtile+1:(x)*xtile;
            else
                X = (x-1)*xtile+1:H.xlen;
            end

            %Load output tile to be encoded
            if (holo.tiledinput)
                data = TileReader(H,holo,Y,X);            
            else 
                data = H.Hbin(Y,X,:);            
            end

            %Compression and metrics
            Codecs = EncodeDecode(data,y,x,Codecs,codecflag,folder);   
        end
    end
    codecsOut(h) = {Codecs};
    holoOut(h) = {holo};
end

for h = 1:length(Holo)
    Codecs = codecsOut{h};
    holo = holoOut{h};
    save(fullfile(folder.result,['res_' char(nameOut(h)) '.mat']),'Codecs','holo');
end


%% Post-processing
cstr = [];
for ii = 1:numel(codecsOut{1})
    cstr = [cstr, 'ratios(:, ' num2str(ii) '), ' ];
end
eval(['resTab = table(nameOut, ' cstr 'codecsOut)'])

cstr = [];
Codec = struct(codecsOut{1});
for ii = 1:numel(Codec)
    cstr = [cstr, '''' Codec(ii).name ''', '];
end
eval(['resTab.Properties.VariableNames = {''Name'', ' cstr ' ''CodecsData''}'])
writetable(resTab, fullfile(folder.result, 'summary.xls'))
