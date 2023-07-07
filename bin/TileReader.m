function holoslice = TileReader(H,holo,Y,X)
    %Created:Raees KM.
    %Retreives the Y:X slice of hologram in H stored as tiles
    %Tiles to be read
    Ydash = ceil(Y(1)/H.ytile):ceil(Y(end)/H.ytile);  
    Xdash = ceil(X(1)/H.xtile):ceil(X(end)/H.xtile);  
    %Data to be clipped away
    Yin1 = Y(1)-((Ydash(1)-1)*H.ytile);
    Xin1 = X(1)-((Xdash(1)-1)*H.xtile);
    Yin2 = (Ydash(end)*H.ytile)-Y(end);
    Xin2 = (Xdash(end)*H.xtile)-X(end);
    %Declare slice hologram
    holoslice = false((Ydash(end)-Ydash(1)+1)*H.ytile,(Xdash(end)-Xdash(1)+1)*H.xtile,H.colours);
    ycount = 0;
for ydash = Ydash
    xcount = 0;
    for xdash = Xdash
        holoslice(ycount*H.ytile+1:(ycount+1)*H.ytile,xcount*H.xtile+1:(xcount+1)*H.xtile,:)= tilereader(ydash,xdash);
        xcount = xcount+1;
    end
    ycount = ycount+1;
end
holoslice = holoslice(Yin1:end-Yin2,Xin1:end-Xin2,:);

function temp = tilereader(y,x)
    switch (holo.family)
        case 'ETRI'
            fname = ['P00_' num2str(y,'%02d') num2str(x,'%02d') '.tif'];
            temp = imread(fullfile(holo.location,fname));
        case 'BCOM'
            fname = ['dices200k_' num2str(y) '_' num2str(x) '.bmp'];
            temp = imread(fullfile(holo.location,fname));
            temp(temp==255)=1;
            temp=logical(temp);
    end
end
end
