function Codecs = EncodeDecode(data,y,x,Codecs,codecflag,folder)
    %Created:Tobias B., Raees KM.
    %Main compression loop
    delete(fullfile(folder.temp,'*'));

    %% Map codecflag to distL
    distLL = {'png', 'jbig1', 'jbig2', 'jpegxl', 'proponentTemplate'}; % This list is context sensitive!
    distL = {}; % List of codecs to actually test in this run
    for distC = distLL
        dist = distC{1};
        if(isfield(codecflag, dist) && codecflag.(dist) == true)
            distL = [distL, distC];
        end
    end
    
    
    %% Perform compressions
    for c = 1:size(data,3)
        count = 1;  
        fprintf(['Compressing color ' num2str(c) '...']);
        
        for distC = distL
            dist = distC{1};
            switch(dist) % this match is context sensitive!
                case 'png'
                    Codecs(count).name= 'PNG';
                    outf = fullfile(folder.temp, ['f_enc' num2str(c) '.png']);
                    tic;
                    imwrite(data(:,:,c),outf);
                    Codecs(count).Block(y,x).CPUsec(c) = toc;
                    fil = dir(outf);
                    Codecs(count).Block(y,x).Rate(c) = fil.bytes*8/(size(data,1)*size(data,2));                    
                    Codecs(count).Block(y,x).Dim = [size(data,1) size(data,2)];
                    if (codecflag.pngdecodecheck)
                        temp = imread(outf);
                        if (nnz(temp-data(:,:,c))==0)
                           Codecs(count).Block(y,x).Decodepassed(c) = true;
                        else
                           Codecs(count).Block(y,x).Decodepassed(c) = false;
                        end
                    end
                    count= count+1;
                    fprintf([Codecs(count-1).name '  '])
                case 'jbig1'
                    Codecs(count).name= 'JBIG1';
                    inpf = fullfile(folder.temp, ['f_enc' num2str(c) '.pbm']);
                    outf = fullfile(folder.temp, ['f_enc' num2str(c) '.jbg']);
                    decf = fullfile(folder.temp, ['f_decjbig1' num2str(c) '.pbm']);
                    encodecmd  = [fullfile(folder.codec,'pbmtojbg.exe') ' ' inpf ' ' outf];
                    decodecmd  = [fullfile(folder.codec,'jbgtopbm.exe') ' ' outf ' ' decf];
                    decodeflag = codecflag.jbig1decodecheck;
                    cmdlinecaller;
                    fprintf([Codecs(count-1).name '  '])
                case 'jbig2'
                    Codecs(count).name= 'JBIG2';
                    inpf = fullfile(folder.temp, ['f_enc' num2str(c) '.png']);
                    outf = fullfile(folder.temp, ['f_enc' num2str(c) '.jbig2']);
                    decf = fullfile(folder.temp, ['f_decjbig2' num2str(c) '.png']);
                    encodecmd  = [fullfile(folder.codec,'jbig2.exe') ' -v -a ' inpf ' > ' outf];
                    decodecmd = [fullfile(folder.codec,'jbig2dec.exe') ' -o ' decf ' ' outf];
                    decodeflag = codecflag.jbig2decodecheck;     
                    cmdlinecaller;
                    fprintf([Codecs(count-1).name '  '])
                case 'jpegxl'
                    Codecs(count).name= 'JPEGXL';
                    inpf = fullfile(folder.temp, ['f_enc' num2str(c) '.png']);
                    outf = fullfile(folder.temp, ['f_enc' num2str(c) '.jxl']);
                    decf = fullfile(folder.temp, ['f_decjxl' num2str(c) '.png']);
                    encodecmd  = [fullfile(folder.codec,'cjxl.exe') ' -v -s 9 --num_threads=4 -d 0.0 ' inpf ' ' outf];
                    decodecmd  = [fullfile(folder.codec,'djxl.exe') ' --noise=0 ' outf ' ' decf];
                    decodeflag = codecflag.jpegxldecodecheck;
                    cmdlinecaller;      
                    fprintf([Codecs(count-1).name '  '])
                case 'proponentTemplate'
                    Codecs(count).name= upper('proponentTemplate'); % don't use spaces in the name
                    % Assumes that proponent compresses color channels individually.
                    inpf = fullfile(folder.temp, ['f_enc' num2str(c) '.png']);                                          % TODO: Adjust filename
                    outf = fullfile(folder.temp, ['f_enc' num2str(c) '.jpl']);                                          % TODO: Adjust filename
                    decf = fullfile(folder.temp, ['f_decXXX' num2str(c) '.png']);                                       % TODO: Adjust filename
                    encodecmd  = [fullfile(folder.codec,'EncodeBinary.exe') ' --encoderParameters ' inpf ' ' outf];     % TODO: Adjust command line
                    decodecmd  = [fullfile(folder.codec,'DecoderBinary.exe') ' --decoderParameters ' outf ' ' decf];    % TODO: Adjust command line
                    decodeflag = codecflag.proponentTemplatedecodecheck;
                    cmdlinecaller2;                                                                                     % TODO: Adjust cmdlinecaller2 function in case different in-/output formats are needed etc.
                    fprintf([Codecs(count-1).name '  '])
                otherwise
                    disp(['Codec ' dist ' not implemented.'])
            end
        end
        fprintf('\n');
    end

    colorRatio = @(block) arrayfun(@(x) sum(x.Rate)/numel(x.Rate), block); % CompressionRatio for all colors combined
    totRatio = 0;
    for ii = 1:size(Codecs(count).Block, 1)
        for jj = 1:size(Codecs(count).Block, 2)
            totRatio = totRatio + colorRatio(Codecs(1).Block(ii, jj));
        end
    end
    totRatio = totRatio/numel(Codecs(count).Block);
    Codecs(count).totRatio = totRatio;

function cmdlinecaller
    if ~isfile(inpf)
        imwrite(data(:,:,c),inpf);      % Writes image
    end
    tic
    [status, out] = system(encodecmd);
    if(status)
        disp(out)
        error(['Encoding with the following cmd-line failed: ' encodecmd])
    end
    Codecs(count).Block(y,x).CPUsec(c) = toc;
    fil = dir(outf);
    Codecs(count).Block(y,x).Rate(c) = fil.bytes*8/(size(data,1)*size(data,2));                    
    Codecs(count).Block(y,x).Dim = [size(data,1) size(data,2)];
    if (decodeflag)
        [status, out] = system(decodecmd);
        if(status)
            disp(out)
            error(['Decoding with the following cmd-line failed: ' decodecmd])
        end
        temp = imread(decf);            % Reads image
        temp =logical(temp);
        if (nnz(temp-data(:,:,c))==0)
            Codecs(count).Block(y,x).Decodepassed(c) = true;
        else
            Codecs(count).Block(y,x).Decodepassed(c) = false;
        end
    end
    count= count+1;
end

    function cmdlinecaller2
        cmdlinecaller
    end

end
