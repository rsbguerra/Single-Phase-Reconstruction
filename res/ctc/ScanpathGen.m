function [AperX, AperY, RecZ] = ScanpathGen(rec_dists, HolNam, testtype)
    % function [AperX,AperY,RecZ] = ScanpathGen(rec_dists,HolNam)
    %   Function which generates the scan paths for the movement of aperture and
    %   chosen reconstruction distances specifically defined for the JPEG PLENO
    %   subjecive experiments.
    %
    % INPUT:
    %   rec_dists@numeric(n,1)...    list of reconstruction distances to iterate over
    %   HolNam@char-array...         Hologram name for which to load the scan-paths
    %                                   Astronaut, Breakdancers8k4k, lowiczanka_doll, |DeepChess, Piano16K, Plane16K_Interfere, CornellBox3_16K, Dices_16K
    %   testtype@logical             is true if subjective test is in dynamic mode. It is false if it is a static subjective test.
    % Ayyoub Ahar
    % V 0.25, 10.11.2020

    switch HolNam

        case 'Astronaut'

            if testtype
                keys = [-160, -175, -160];
                stopfr = 1;
                trans = 49;

                frs = [];

                for ii = 1:numel(keys) - 1
                    curtrans = linspace(keys(ii), keys(ii + 1), trans + 2);
                    frs = [frs; repmat(keys(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frs = [frs; repmat(keys(end), stopfr, 1)];
                RecZ = frs / 1000; AperX = zeros(size(frs)); AperY = AperX;

                %         pnam = ['Spath_' HolNam '_13key1_12trans7'];
                % %         pnam = 'QoMEX_Astronaut';
                %         fig = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %          plot(1:numel(frs), frs(:),'-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %         ax = gca;
                %         ax.FontSize = 20;
                %         ax.TickLength = [0.02 0.02];
                %         ax.YLim = [min(keys) max(keys)];
                %         ax.XLim = [1 numel(frs)];
                %          xlabel('Frames','FontSize',20,'FontWeight','bold','Color','k')
                %         % ylabel('Horizontal position index of aperture','FontSize',16,'FontWeight','bold','Color','k')
                %          ylabel('Focal Distance (mm)','FontSize',20,'FontWeight','bold','Color','k')
                %           print(fig,pnam,'-dpng','-r100');close;
            else
                RecZ = rec_dists; AperX = zeros(size(RecZ)); AperY = AperX;
            end

        case 'Breakdancers8k4k'
            % keys = [4.18; 8.69; 20.60; 23.62; 25.51; 33.53];
            keys = [4.18; 33.53; 4.18];

            if testtype

                stopfr = 1;
                trans = 49;

                frs = [];

                for ii = 1:numel(keys) - 1
                    curtrans = linspace(keys(ii), keys(ii + 1), trans + 2);
                    frs = [frs; repmat(keys(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frs = [frs; repmat(keys(end), stopfr, 1)];
                RecZ = frs / 1000; AperX = zeros(size(frs)); AperY = AperX;
                %                 pnam = 'QoMEX_Breakdancers8k4k';
                %         fig = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %          plot(1:numel(frs), frs(:),'-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %         ax = gca;
                %         ax.FontSize = 20;
                %         ax.TickLength = [0.02 0.02];
                %         ax.YLim = [min(keys) max(keys)];
                %         ax.XLim = [1 numel(frs)];
                %          xlabel('Frames','FontSize',20,'FontWeight','bold','Color','k')
                %         % ylabel('Horizontal position index of aperture','FontSize',16,'FontWeight','bold','Color','k')
                %          ylabel('Focal Distance (mm)','FontSize',20,'FontWeight','bold','Color','k')
                %           print(fig,pnam,'-dpng','-r100');close;
            else
                keys = [4.18; 8.69; 20.60; 23.62; 25.51; 33.53];
                RecZ = [8.69 23.62 25.51] / 1000; AperX = zeros(size(RecZ)); AperY = AperX;
            end

        case 'lowiczanka_doll'

            if testtype
                keys = [1; 0; -1];
                stopfr = 1;
                trans = 49;

                frs = [];

                for ii = 1:numel(keys) - 1
                    curtrans = linspace(keys(ii), keys(ii + 1), trans + 2);
                    frs = [frs; repmat(keys(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frs = [frs; repmat(keys(end), stopfr, 1)];
                RecZ = rec_dists(2) * ones(size(frs)); AperX = frs; AperY = zeros(size(frs));
                %                 pnam = 'QoMEX_lowiczanka_doll';
                %         fig = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %          plot(1:numel(frs), frs(:),'-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %         ax = gca;
                %         ax.FontSize = 20;
                %         ax.TickLength = [0.02 0.02];
                %         ax.YLim = [min(keys) max(keys)];
                %         ax.XLim = [1 numel(frs)];
                %          xlabel('Frames','FontSize',20,'FontWeight','bold','Color','k')
                %          ylabel('Horizontal position index of aperture','FontSize',20,'FontWeight','bold','Color','k')
                % %          ylabel('Focal Distance (mm)','FontSize',20,'FontWeight','bold','Color','k')
                %           print(fig,pnam,'-dpng','-r100');close;
            else
                RecZ = rec_dists; AperX = [-1 0 1]; AperY = zeros(size(AperX));
            end

        case 'DeepChess'

            if testtype
                % keysx1 = [1; 0; 0; 1; 1; 0];
                keysx1 = [1; 0; 0; -1; -1; 0];
                %          keysx1 = [1; 0; -1];

                stopfr = 1;
                transx = 30;

                transx2 = 5;

                frs = [];

                for ii = 1:numel(keysx1) - 1

                    if mod(ii, 2) == 1
                        curtrans = linspace(keysx1(ii), keysx1(ii + 1), transx + 2);
                        frs = [frs; repmat(keysx1(ii), stopfr, 1); curtrans(2:end - 1)'];
                    else
                        curtrans = linspace(keysx1(ii), keysx1(ii + 1), transx2 + 2);
                        frs = [frs; repmat(keysx1(ii), stopfr, 1); curtrans(2:end - 1)'];
                    end

                end

                frsx = [frs; repmat(keysx1(end), stopfr, 1)];
                %         rec_dists = [0.3964 0.9986 1.6063]; %for debug and test only
                keysz = [rec_dists(3); rec_dists(3); rec_dists(2); rec_dists(2); rec_dists(1); rec_dists(1)];
                frs = [];
                stopfr = 1;
                transz = 30;
                transz2 = 5;

                for ii = 1:numel(keysz) - 1

                    if mod(ii, 2) == 1
                        curtrans = linspace(keysz(ii), keysz(ii + 1), transz + 2);
                        frs = [frs; repmat(keysz(ii), stopfr, 1); curtrans(2:end - 1)'];
                    else
                        curtrans = linspace(keysz(ii), keysz(ii + 1), transz2 + 2);
                        frs = [frs; repmat(keysz(ii), stopfr, 1); curtrans(2:end - 1)'];
                    end

                end

                frsz = [frs; repmat(keysz(end), stopfr, 1)];
                %  frsz = repmat(rec_dists(1),(numel(keysx1)*stopfr)+((numel(keysx1)-1)*trans),1);
                RecZ = frsz; AperX = frsx; AperY = zeros(size(frsx));

                % %         pnam = 'Spath2_Deepchess_6key1_5trans30x_5z';
                %             pnam = 'QoMEX_Deepchess';
                %         fig1 = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %          plot(frsx(:),frsz(:), '-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %         ax = gca; % current axes
                %         ax.FontSize = 20;
                %         ax.TickLength = [0.02 0.02];
                %         ax.YLim = [min(keysz) max(keysz)];
                %         ax.XLim = [-1 1];
                %         xlabel('Horizontal position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % x-axis label
                %         ylabel('Focal Distance (m)','FontSize',20,'FontWeight','bold','Color','k') % y-axis label
                %           print(fig1,pnam,'-dpng','-r100');close;
                %
            else
                RecZ = rec_dists; AperX = [-0.8 0 0.8]; AperY = zeros(size(AperX));

            end

        case 'Plane16K_Interfere'

            if testtype
                keysx1 = [-0.75; 0.75; 0.75; -0.75; -0.75; 0.75];
                stopfr = 1;
                %                 trans = 20; %subjective path
                trans = 1; %coarse objective path
                frs = [];

                for ii = 1:numel(keysx1) - 1
                    curtrans = linspace(keysx1(ii), keysx1(ii + 1), trans + 2);
                    frs = [frs; repmat(keysx1(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frsx = [frs; repmat(keysx1(end), stopfr, 1)];

                keysy = [0.75; 0.75; 0; 0; -0.75; -0.75];
                %                  stopfr = 6;%subjective path
                %                  trans = 14; %subjective path
                frs = [];

                for ii = 1:numel(keysy) - 1
                    curtrans = linspace(keysy(ii), keysy(ii + 1), trans + 2);
                    frs = [frs; repmat(keysy(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frsy = [frs; repmat(keysy(end), stopfr, 1)];

                RecZ = ones(size(frsx)) * 0.047; AperX = frsx; AperY = frsy;
                % %                        pnam = 'Spath_Plane16Ks_coarse path';
                %                      pnam = 'QoMEX_Plane16K_Interfere';
                %                 fig1 = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %                  plot(frsx(:),frsy(:), '-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %                 ax = gca; % current axes
                %                 ax.FontSize = 20;
                %                 ax.TickLength = [0.02 0.02];
                %                 ax.YLim = [-1 1];
                %                 ax.XLim = [-1 1];
                %                 xlabel('Horizontal position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % x-axis label
                %                 ylabel('Vertical position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % y-axis label
                %                 %   print(fig1,pnam,'-dpng','-r100');close;

            else
                RecZ = rec_dists; AperX = [0.75; 0; -0.75]; AperY = AperX;
            end

        case 'CornellBox3_16K'

            if testtype
                keysx1 = [-1; 1; -1; 1];
                stopfr = 1;
                trans = 33;
                frs = [];

                for ii = 1:numel(keysx1) - 1
                    curtrans = linspace(keysx1(ii), keysx1(ii + 1), trans + 2);
                    frs = [frs; repmat(keysx1(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frsx = [frs; repmat(keysx1(end), stopfr, 1)];

                keysy = [1; 0; 0; -1];
                frs = [];

                for ii = 1:numel(keysy) - 1
                    curtrans = linspace(keysy(ii), keysy(ii + 1), trans + 2);
                    frs = [frs; repmat(keysy(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frsy = [frs; repmat(keysy(end), stopfr, 1)];
                %                  pnam = 'QoMEX_CornellBox3_16K';
                %                 fig1 = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %                  plot(frsx(:),frsy(:), '-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %                 ax = gca; % current axes
                %                 ax.FontSize = 20;
                %                 ax.TickLength = [0.02 0.02];
                %                 ax.YLim = [-1 1];
                %                 ax.XLim = [-1 1];
                %                 xlabel('Horizontal position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % x-axis label
                %                 ylabel('Vertical position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % y-axis label
                %                 %   print(fig1,pnam,'-dpng','-r100');close;
                RecZ = ones(size(frsx)) * 0.27; AperX = frsx; AperY = frsy;
            else
                RecZ = [rec_dists(1) rec_dists(2) rec_dists(4)]; AperX = [1; 0; -1]; AperY = -AperX;
            end

        case 'Dices16K'

            if testtype
                keysx1 = [-1; 1; -1; 1];
                stopfr = 1;
                %                 trans = 33;  %subjective test
                trans = 3; % objective test
                frs = [];

                for ii = 1:numel(keysx1) - 1
                    curtrans = linspace(keysx1(ii), keysx1(ii + 1), trans + 2);
                    frs = [frs; repmat(keysx1(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frsx = [frs; repmat(keysx1(end), stopfr, 1)];

                keysy = [1; 0.5; -0.5; -1];
                frs = [];

                for ii = 1:numel(keysy) - 1
                    curtrans = linspace(keysy(ii), keysy(ii + 1), trans + 2);
                    frs = [frs; repmat(keysy(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frsy = [frs; repmat(keysy(end), stopfr, 1)];
                %                                  pnam = 'QoMEX_Dices16K';
                %                 fig1 = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %                  plot(frsx(:),frsy(:), '-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %                 ax = gca; % current axes
                %                 ax.FontSize = 20;
                %                 ax.TickLength = [0.02 0.02];
                %                 ax.YLim = [-1 1];
                %                 ax.XLim = [-1 1];
                %                 xlabel('Horizontal position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % x-axis label
                %                 ylabel('Vertical position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % y-axis label
                %                 %   print(fig1,pnam,'-dpng','-r100');close;
                RecZ = ones(size(frsx)) * 0.0079; AperX = frsx; AperY = frsy;
                %                 pnam = 'Spath_16Ks_3key1_2trans49';
                %                 fig1 = figure('MenuBar','none','ToolBar','auto','OuterPosition',[500 150 1000 1000]);
                %                  plot(frsx(:),frsy(:), '-o', 'Linewidth',2)
                %                 ax = gca; % current axes
                %                 ax.FontSize = 14;
                %                 ax.TickLength = [0.02 0.02];
                %                 ax.YLim = [-1 1];
                %                 ax.XLim = [-1 1];
                %                 xlabel('Horizontal position index of aperture','FontSize',16,'FontWeight','bold','Color','k') % x-axis label
                %                 ylabel('Vertical position index of aperture','FontSize',16,'FontWeight','bold','Color','k') % y-axis label
                %                 %   print(fig1,pnam,'-dpng','-r100');close;
            else
                RecZ = rec_dists; AperX = [1; 0; -1]; AperY = -AperX;
            end

        case 'Piano16K'

            if testtype
                keysx1 = [1; -1; 1; -1];
                stopfr = 1;
                trans = 33; %subjective test
                %                 trans = 3; % objective test
                frs = [];

                for ii = 1:numel(keysx1) - 1
                    curtrans = linspace(keysx1(ii), keysx1(ii + 1), trans + 2);
                    frs = [frs; repmat(keysx1(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frsx = [frs; repmat(keysx1(end), stopfr, 1)];

                keysy = [1; 0; 0; -1];
                frs = [];

                for ii = 1:numel(keysy) - 1
                    curtrans = linspace(keysy(ii), keysy(ii + 1), trans + 2);
                    frs = [frs; repmat(keysy(ii), stopfr, 1); curtrans(2:end - 1)'];
                end

                frsy = [frs; repmat(keysy(end), stopfr, 1)];
                %                   pnam = 'QoMEX_Piano16K';
                %                 fig1 = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %                  plot(frsx(:),frsy(:), '-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %                 ax = gca; % current axes
                %                 ax.FontSize = 20;
                %                 ax.TickLength = [0.02 0.02];
                %                 ax.YLim = [-1 1];
                %                 ax.XLim = [-1 1];
                %                 xlabel('Horizontal position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % x-axis label
                %                 ylabel('Vertical position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % y-axis label
                %                 %   print(fig1,pnam,'-dpng','-r100');close;

                RecZ = ones(size(frsx)) * 0.0085; AperX = frsx; AperY = frsy;
            else
                RecZ = rec_dists; AperX = [1; 0; -1]; AperY = AperX;
            end

        case 'DeepDices8K4K'

            if testtype

                RecZ = frsz; AperX = frsx; AperY = zeros(size(frsx));

                % %         pnam = 'Spath2_Deepchess_6key1_5trans30x_5z';
                %             pnam = 'QoMEX_Deepchess';
                %         fig1 = figure('MenuBar','none','ToolBar','auto','OuterPosition',[300 150 600 600]);
                %          plot(frsx(:),frsz(:), '-o', 'Linewidth',2,'MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor','b')
                %         ax = gca; % current axes
                %         ax.FontSize = 20;
                %         ax.TickLength = [0.02 0.02];
                %         ax.YLim = [min(keysz) max(keysz)];
                %         ax.XLim = [-1 1];
                %         xlabel('Horizontal position index of aperture','FontSize',20,'FontWeight','bold','Color','k') % x-axis label
                %         ylabel('Focal Distance (m)','FontSize',20,'FontWeight','bold','Color','k') % y-axis label
                %           print(fig1,pnam,'-dpng','-r100');close;
                %
            else
                RecZ = [rec_dists(3) rec_dists(4) rec_dists(6)]; AperX = [0; 0; 0]; AperY = [0; 0; 0]; %AperX = zeros(size(RecZ)); AperY = AperX; %AperX = [1;0; -1]; AperY = [-1;0.5; 1];

            end

        case 'DeepDices16K'

            if testtype
                RecZ = frsz; AperX = frsx; AperY = zeros(size(frsx));
            else
                RecZ = [rec_dists(3) rec_dists(4) rec_dists(6)]; AperX = [0; -0.5; 0]; AperY = [0.5; 0.5; 1]; %AperX = zeros(size(RecZ)); AperY = AperX; %AperX = [1;0; -1]; AperY = [-1;0.5; 1];
            end

        case 'DeepDices2K'

            if testtype
                RecZ = frsz; AperX = frsx; AperY = zeros(size(frsx));
            else
                RecZ = [rec_dists(3) rec_dists(4) rec_dists(6)]; AperX = [0; 0; 0]; AperY = [0; 0; 0]; %AperX = zeros(size(RecZ)); AperY = AperX; %AperX = [1;0; -1]; AperY = [-1;0.5; 1];
            end

        case 'DeepCornellBox_16K'

            if testtype
                %              RecZ = frsz; AperX = frsx; AperY =zeros(size(frsx));
            else
                RecZ = [rec_dists(2) rec_dists(5) rec_dists(12)]; AperX = [0.5; 0; 0]; AperY = [0; 0; 0.5]; %AperX = zeros(size(RecZ)); AperY = AperX; %AperX = [1;0; -1]; AperY = [-1;0.5; 1];
            end

        case 'BallColor'

            if testtype
                %              RecZ = frsz; AperX = frsx; AperY =zeros(size(frsx));
            else
                RecZ = rec_dists; AperX = [0; 0]; AperY = [0; 0]; %AperX = zeros(size(RecZ)); AperY = AperX; %AperX = [1;0; -1]; AperY = [-1;0.5; 1];
            end

        otherwise
            error('Hologram name is not valid. Please check the input for the ScanpathGen function');
    end

end
