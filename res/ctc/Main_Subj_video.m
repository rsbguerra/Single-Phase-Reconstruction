clear all;clc;

% Layman's check for octave compatible mode
isOctave = false;

try
    datetime
    contains('abc', 'a')
    isOctave = false;
catch me
    isOctave = true;
end

targetRes = [2160 4096];
mainVidpath = 'B:\Temp\jpeg-pleno-holo-ctc\Version20\figures';

mainOutpath = mainVidpath;
% mkdir(mainOutpath);
ofold = pwd();

[vidfolds] = GetSubDirsFirstLevelOnly(mainVidpath);

for ii = 5:numel(vidfolds)
    curDir = dir(fullfile(mainVidpath, cell2mat(vidfolds(ii)), '\*.png'));
    curvids = string({curDir.name}');

    if (isOctave)
        GTvid = char(curvids(cellfun('isempty', strfind(lower(curvids), lower('GT')))));
    else
        GTvid = char(curvids(contains(curvids, 'GT', 'IgnoreCase', true)));
    end

    splts = strsplit(GTvid(1, :), '_');
    splt1 = strsplit(char(splts(2)), '_'); sp1 = char(splt1(1));
    outfiledir = fullfile (mainOutpath, sp1);
    mkdir(outfiledir);
    cd(fullfile(mainVidpath, char(vidfolds(ii))))

    for jj = 1:numel(curvids)
        curDistVid = char(curvids(jj));
        splts = strsplit(curDistVid, '__');
        splt2 = strsplit(char(splts(1)), '_'); sp2 = strrep(char(splts(1)), [char(splt2(1)) '_'], '');
        outfilename = [outfiledir '\' sp1 '_' sp2 '.png'];

        if strcmp(char(vidfolds(ii)), 'breakdancers8k4k_000')
            crptopleftpos = [4300 800];
            crop_video(outfilename, GTvid(1, :), curDistVid, targetRes, padCenter, crptopleftpos)
        elseif strcmp(char(vidfolds(ii)), 'astronaut_000')
            crptopleftpos = [330 280];
            crop_video(outfilename, GTvid, curDistVid, targetRes, padCenter, crptopleftpos)
        else
            join_video(outfilename, GTvid, curDistVid, targetRes, padCenter)
        end

        disp([GTvid '   and   ' curDistVid '   are joined and saved as:  ' sp1 '_' sp2 '.mp4'])
    end

end

cd(ofold);

%% functions
function [subDirsNames] = GetSubDirsFirstLevelOnly(parentDir)
    %gets the folder names inside the parent directory
    files = dir(parentDir);
    names = {files.name};
    dirFlags = [files.isdir] & ~strcmp(names, '.') & ~strcmp(names, '..');
    subDirsNames = names(dirFlags)';
end

%% Test run for nrshvideo =>>> makes a signle video of GT
% addpath(genpath('B:\Temp\jpeg-pleno-holo-ctc\nrsh'));
% addpath('B:\Temp\jpeg-pleno-holo-ctc\Original')
% dataset = {'bcom8', 'bcom32','interfere', 'interfere4', 'emergimg', 'wut_disp'};
% holnams = {'CornellBox3_16K', 'Biplane','DeepChess', 'Dices_16K', 'Piano_16K', 'Breakdancers8k4k', 'Astronaut', 'Lowiczanka_Doll'};
% frnums = 120;
%
%
% holnam = holnams{3};
% %% Loading the hologram
% switch holnam
%     case 'CornellBox3_16K'
%         data = load('CornellBox3_16K.mat');
%         H = double(data.H);
%         H.cfg_file = fullfile('interfereV','CornellBox3_16K_000.txt');
%         H.rec_dists = [0.25 0.22 0.28615];
%         H.zobjs = [0.22 0.228 0.25 0.28615];
%         H.ap_sizes = {[4096 4096]};
%         dataset_id = 3;
%         H.h_pos = [];
%         H.v_pos = [];
%         H.z_pos = [];
%     case 'Biplane'
%         data = load('CGH_Biplane16k_rgb.mat');
%         X = double(data.CGH.Hol);
%         H.pp = data.CGH.setup.pp(1);
%         H.lambda = data.CGH.setup.wlen;
%         H.cfg_file = fullfile('interfereIII','biplane16k_000.txt');
%         H.ap_sizes = {[2048 2048]};
%         H.rec_dists = [0.0455 0.0374 0.0497];
%         H.obj_dist = 0.0455;
%         H.h_pos = [];
%         H.v_pos = [];
%         H.z_pos = [];
%     case 'DeepChess'
%         data = load('DeepChess.mat');
%         X = double(data.dh);
%         H.cfg_file = fullfile('interfereIV','deepchess2_000.txt');
%         H.rec_dists = [0.3964 0.9986 1.6063];
%         H.zobjs = [];
%         H.ap_sizes = {[2048 2048]};
%         dataset_id = 4;
%         H.h_pos = [];
%         H.v_pos = [];
%         H.z_pos = [];
%         H.obj_dist = 0.9986;
%     case 'Dices_16K'
%         data = load('Dices16K.mat');
%         X = double(data.data);
%         cfg_file = fullfile('bcom','dices16k_000.txt');
%         rec_dists = [0.01 0.00656 0.0131];
%         dataset_id = 2;
%         H.ap_sizes = {[2048 2048]};
%         zrec = [0.00656 0.0131];
%         H.h_pos = [];
%         H.v_pos = [];
%         H.z_pos = [];
%     case 'Piano_16K'
%         data = load('Piano16K.mat');
%         X = double(data.data);
%         dataset_id = 2;
%         cfg_file = fullfile('bcom','piano16k_000.txt');
%         H.ap_sizes = {[2048 2048]};
%         rec_dists = [0.01 0.0068 0.0125];
%         zrec = [0.0068 0.0125];
%         H.h_pos = [];
%         H.v_pos = [];
%         H.z_pos = [];
%     case 'Breakdancers8k4k'
%         data = load('breakdancers8k4k_022.mat');
%         X =  double(data.data);
%         H.cfg_file = fullfile('bcom','breakdancers8k4k_000.txt');
%         H.rec_dists = [0.025 0 0.081];
%         H.zobjs = [0 0.025 0.05 0.081];
%         H.ap_sizes = {[size(X,1) size(X,2)]};
%         dataset_id =1;
%         H.h_pos = [];
%         H.v_pos = [];
%         H.z_pos = [];
%     case 'Astronaut'
%         data = load('Astronaut_Hol_v2.mat');
%         X = double(data.u1);
%         H.rec_dists = [-0.172 -0.16 -0.175];
%         H.zobjs = [-0.16 -0.165 -0.17 -0.175];
%         H.pp = data.pitch;
%         H.lambda = data.lambda;
%         H.cfg_file = fullfile('emergimg','astronaut_000.txt');
%         H.ap_sizes = {[size(X,1) size(X,2)]};
%         dataset_id = 5;
%         H.h_pos = [];
%         H.v_pos = [];
%         H.z_pos = [];
%     case 'Lowiczanka_Doll'
%         data = load('SourceHols\XXXXXXXXXXXXXXXXXXXXXXX.mat');
%         X = double(data);
%         H.pp = 3.45e-6;
%         H.lambda = [6.37e-7 5.32e-7 4.57e-7];
%         H.cfg_file = fullfile('wut','lowiczanka_doll_000.txt');
%         H.ap_sizes = {[2016 2016]};
%         H.rec_dists = [1.030 1.060 1.075];
%         H.obj_dist = 1.060;
%         dataset_id = 6;
%         H.h_pos = [];
%         H.v_pos = [];
%         H.z_pos = [];
%     otherwise
%
% end
%
% % % % %breakdances
% % % keys = [4.18; 8.69; 20.60; 23.62; 25.51; 33.53];
% % % keys = [4.18; 20.60; 25.51; 33.53;  23.62; 8.69];
% % keys = [4.18; 33.53;4.18];
% % stopfr = 1;
% % trans = 49;
%
% % %Astronaut
% % keys = [-150, -155, -160, -165, -170, -175, -180, -175, -170, -165, -160, -155, -150];
% % %  keys = [-165,-175, -170,-160];
% % stopfr = 1;
% % trans = 7;
%
% % %doll
% % % keys = linspace(-1,1,5);
% % keys = [1; 0; -1];
% %
% % stopfr = 1;
% % trans = 49;
%
% % pnam = 'Spath1_Doll_3key1_2trans49';
% %
% % frs = [];
% % for ii = 1:numel(keys)-1
% %    curtrans = linspace(keys(ii), keys(ii+1),trans+2);
% %    frs = [frs; repmat(keys(ii),stopfr,1); curtrans(2:end-1)'];
% % end
% % frs = [frs; repmat(keys(end),stopfr,1)];
% %
% % fig = figure('MenuBar','none','ToolBar','auto','OuterPosition',[500 150 1000 1000]);
% %  plot(1:numel(frs), frs(:),'-o', 'Linewidth',2)
% % ax = gca; % current axes
% % ax.FontSize = 12;
% % ax.TickLength = [0.02 0.02];
% % ax.YLim = [min(keys) max(keys)];
% % ax.XLim = [1 numel(frs)];
% %  xlabel('Frames','FontSize',16,'FontWeight','bold','Color','k') % x-axis label
% % ylabel('Horizontal position index of aperture','FontSize',16,'FontWeight','bold','Color','k') % y-axis label
% % %  ylabel('Focal Distance (mm)','FontSize',16,'FontWeight','bold','Color','k')
% %  print(fig,pnam,'-dpng','-r100');close;
% %
% % % foldnam = 'scanpathtest';
% % H.z_pos = frs/1000; H.h_pos = zeros(size(frs));H.v_pos = H.h_pos;
%
%
% %Deepchess
% % keysx1 = [1; 0; 0; 1; 1; 0];
%   keysx1 = [1; 0; 0; -1; -1; 0];
% %  keysx1 = [1; 0; -1];
% %  pnam = 'Spath5_Deepchess_3key1_2trans49';
% stopfr = 1;
% trans = 49;
% frs = [];
% for ii = 1:numel(keysx1)-1
%    curtrans = linspace(keysx1(ii), keysx1(ii+1),trans+2);
%    frs = [frs; repmat(keysx1(ii),stopfr,1); curtrans(2:end-1)'];
% end
% frsx = [frs; repmat(keysx1(end),stopfr,1)];
% % fig = figure('MenuBar','none','ToolBar','auto','OuterPosition',[500 150 1000 1000]);
% %  plot(1:numel(frsx), frsx(:),'-o', 'Linewidth',2)
% % ax = gca; % current axes
% % ax.FontSize = 12;
% % ax.TickLength = [0.02 0.02];
% % ax.YLim = [min(keysx1) max(keysx1)];
% % ax.XLim = [1 numel(frsx)];
% % xlabel('Frames','FontSize',16,'FontWeight','bold','Color','k') % x-axis label
% % ylabel('Horizontal position index of aperture','FontSize',16,'FontWeight','bold','Color','k') % y-axis label
%
%
%  keysz = [H.rec_dists(3); H.rec_dists(3); H.rec_dists(2); H.rec_dists(2); H.rec_dists(1); H.rec_dists(1)];
% % frs = [];
% % for ii = 1:numel(keysz)-1
% %    curtrans = linspace(keysz(ii), keysz(ii+1),trans+2);
% %    frs = [frs; repmat(keysz(ii),stopfr,1); curtrans(2:end-1)'];
% % end
% % frsz = [frs; repmat(keysz(end),stopfr,1)];
%  frsz = repmat(H.rec_dists(1),(numel(keysx1)*stopfr)+((numel(keysx1)-1)*trans),1);
% % fig = figure('MenuBar','none','ToolBar','auto','OuterPosition',[500 150 1000 1000]);
% %  plot(1:numel(frsz), frsz(:),'-o', 'Linewidth',2)
% % ax = gca; % current axes
% % ax.FontSize = 12;
% % ax.TickLength = [0.02 0.02];
% % ax.YLim = [min(keysz) max(keysz)];
% % ax.XLim = [1 numel(frsz)];
% % xlabel('Frames','FontSize',16,'FontWeight','bold','Color','k') % x-axis label
% % ylabel('Focal Distance (mm)','FontSize',16,'FontWeight','bold','Color','k') % y-axis label
%
% fig1 = figure('MenuBar','none','ToolBar','auto','OuterPosition',[500 150 1000 1000]);
%  plot(frsx(:),frsz(:), '-o', 'Linewidth',2)
% ax = gca; % current axes
% ax.FontSize = 12;
% ax.TickLength = [0.02 0.02];
% ax.YLim = [min(keysz) max(keysz)];
% ax.XLim = [-1 1];
% xlabel('Horizontal position index of aperture','FontSize',16,'FontWeight','bold','Color','k') % x-axis label
% ylabel('Focal Distance (m)','FontSize',16,'FontWeight','bold','Color','k') % y-axis label
%   print(fig1,pnam,'-dpng','-r100');close;
%  H.z_pos = frsz; H.h_pos = frsx;H.v_pos = [0];
%
% [clip_min, clip_max] = nrsh_video(X, cell2mat(dataset( dataset_id)), ...
%     H.cfg_file, H.z_pos,  H.ap_sizes , H.h_pos, H.v_pos, [], [], pnam,  @(x) imresize(x, 1024*[1,1], 'bilinear'),10);
%

%% dump

% % H = load('SourceHols\Dices16K.mat');
% % H = H.data;
% % cfg_file = fullfile('bcom','dices16k_000.txt');
% % rec_dists = [0.01 0.00656 0.0131];
% % dataset_id = 2;
%
% %% Make the render path,  Reconstruction and Generating Frames
%  [X,Y,Z] = CampathGen(hsize,aprs,zrec,zoi,pathnam);
% % % % List of horizontal viewpoints
% % % x = linspace(-1, 1, 10);
% % %
% % % % % List of vertical viewpoints
% % % y = sin(linspace(-pi/2,-pi, 4));
% % % % y = 0;
% % %
% % %
% % % % List of distances per viewpoint
% % %  zL = linspace(rec_dists(2), rec_dists(3),3);
% % %
% % %
% % % frnums = numel(x)*numel(y)*numel(zL);
% % %
% % % % List of apertures per viewpoint
% % % % aprs = {[4096 4096]};
% % % % apL = repmat(aprs, frnums/numel(aprs),1); apL = apL(:);
% % % aprs = {4096*[1, 1], 2048*[1, 1], 1024*[1, 1], 512*[1, 1]};
% % % apL = repmat(aprs, frnums/numel(aprs),1); apL = apL(:);
% % %
% % % coord = zeros(frnums,3);
% % % ind = 1;
% % %     for ii = 1:numel(zL)
% % %
% % %         for jj=1:numel(y)
% % %
% % %             for kk=1:numel(x)
% % %                  coord(ind,:,:) = [zL(ii) y(jj) x(kk)];
% % %                   ind = ind+1;
% % %             end
% % %     %       if rem(ii, 2) == 0
% % %             x = flip(x);
% % %     %       end
% % %         end
% % %         y=flip(y);
% % %     end
% % % figure;plot3(coord(:,3),coord(:,2) ,coord(:,1),'o-','LineWidth',5);xlabel('X');ylabel('Y');zlabel('Z');title('Aperture Path');set(gca,'Fontsize',15);
% %
% % % % delete(gcp('nocreate'))
% % % numworkers = 2;
% % % g = gcp('nocreate');
% % % parpool(numworkers)
% % % for idx = 1:frnums
% % %    currcoord = coord(idx,:,:);
% % %    nrsh_modifiedV(H, cell2mat(dataset( dataset_id)), cfg_file, currcoord(1), apL(idx),  currcoord(3),  currcoord(2),idx);
% % %
% % % end
% %
% % zL = linspace(rec_dists(2), rec_dists(3),50)';zL = [zL; zL(end)*ones(19,1) ;flip(zL)];
% % frnums =120;
% %
% % x = zeros(size(zL)); x(frnums/2+1:end) = -1; x(51:69)= linspace(0, -1, 19);
% % y = x;
% % for idx = 1:frnums
% %    nrsh_modifiedV(H, cell2mat(dataset( dataset_id)), cfg_file, xL(idx), {[4096 4096]},  x(idx),  y(idx),idx);
% % end
%
% %% Renaming the frames and producing the video clips
%
% % tmp2 = strsplit(cfg_file, '\'); tmp2 = strrep(tmp2{2}, '.txt', '');
% % pa = fullfile(pwd(), 'figures', tmp2);
%
% pa =  fullfile(pwd(), 'figures', 'Dices16K_Ref_IndependentClipPerFR');
% fpss = 10;
% framst = dir(fullfile(pa, '*.png')); frams = {framst.name};
%
% pa2 =  fullfile(pwd(), 'figures', 'Dices16K_JP2Kex_RefClipperFR');
% framst2 = dir(fullfile(pa2, '*.png')); frams2 = {framst2.name};
% % Use simpler filenames resize / crop
% % s = size(H);
% % windo =  2048*[1,1];
% % crpcnt = [s(1)/2 s(1)/2]; %center crop
% % crpcnt = [6700 11300];
% for ii=1:frnums
% %     copyfile(fullfile(framst(1).folder, frams{ii}),fullfile(framst(1).folder, ['frame_' num2str(ii, '%03.0f') '.png']))
% curfr = imread(fullfile(framst(1).folder, frams{ii}));
% curfrjp2 = imread(fullfile(framst2(1).folder, frams2{ii}));
%  imwrite(cat(2,curfr,ones(2048,20,3)*(2^16/2),curfrjp2),  fullfile(framst(1).folder, ['both_frame_' num2str(ii, '%03.0f') '.png'])) ;
% %        imwrite(uint8(255*mat2gray(imresize(curfr, windo))),  fullfile(framst(1).folder, ['frame_' num2str(ii, '%03.0f') '.png']))
% %         imwrite(uint8(255*mat2gray(curfr(crpcnt(2) - windo(1)/2:crpcnt(2) + windo(1)/2-1 , crpcnt(1) - windo(2)/2:crpcnt(1) + windo(2)/2-1,:)))...
% %             ,  fullfile(framst(1).folder, ['frameCrop_' num2str(ii, '%03.0f') '.png']))
% end
%
% ofold = pwd();
% for ff = 1:numel(fpss)
%     fps = fpss(ff);
%     videonam = ['Dices16K_JP2Kex_RefClipperFR' '_Nframe' num2str(frnums), '_fps' num2str(fps) '.mp4'];
%
%     cd(framst(1).folder)
%     tic, [status, out] = system(['B:/Ayyoub/PlenoSubjective/ffmpeg/bin/ffmpeg.exe -y -r ' num2str(fps) ' -i both_frame_%03d.png -c:v libx264 -qp 0 -f mp4 ' videonam]); toc % -pix_fmt rgb24
%
% %     if(~status), error(out), end
%      movefile(videonam, fullfile(ofold, videonam));
% end
% cd(ofold);
%
% % ofold = pwd();
% % for ff = 1:numel(fpss)
% %     fps = fpss(ff);
% %     videonam = [tmp2 'Crop_Nframe' num2str(frnums), '_fps' num2str(fps) '.mp4'];
% %
% %     cd(framst(1).folder)
% %     tic, [status, out] = system(['B:/Ayyoub/PlenoSubjective/ffmpeg/bin/ffmpeg.exe -y -r ' num2str(fps) ' -i frameCrop_%03d.png -c:v libx264 -qp 0 -f mp4 ' videonam]); toc % -pix_fmt rgb24
% %
% % %     if(~status), error(out), end
% %      movefile(videonam, fullfile(ofold, videonam));
% % end
% % cd(ofold);
