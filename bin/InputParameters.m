function H = InputParameters(holo)
    %Created:Raees KM.
    %Assigns hologram and codec parameters f Pleno database
    %For tiled input tile parameters and hologram dimensions is specified
    %here while for non-tiled input hologram is read
    if (holo.tiledinput)
        Readbin_tiled;
    else
        Readbin_nontiled;        
    end
        
    function Readbin_tiled
        switch holo.family
            case 'ETRI'
                 H.ytile = 10000;
                 H.xtile = 10000;
                 H.ylen = 100000;
                 H.xlen = 100000;
                 H.colours = 1;
            case 'BCOM'
                 H.ytile = 2160;
                 H.xtile = 4096;
                 H.ylen = 108000;
                 H.xlen = 204800;
                 H.colours = 3;
        end
    end
    function Readbin_nontiled
        switch holo.family
            case 'ETRO'
                 H.Hbin = load(holo.location);
                 H.Hbin = H.Hbin.Hbin;
                 H.ylen = size(H.Hbin,1);
                 H.xlen = size(H.Hbin,2);
                 H.colours = size(H.Hbin,3);
        end
    end
end