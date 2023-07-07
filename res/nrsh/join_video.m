function join_video(outfilename, infile_gt, infile_dist, targetRes, padCenter)
    % function join_video(outfilename, infile_gt, infile_distorted, targetRes, padCenter)
    %
    %   Joins two videos horizontally. Each video will be padded to [targetRes(1), targetRes(2)/2]. 
    %   The padding in between videos is padCenter pixels. The compression will be lossless.
    %
    %   May be used to join ground truth and distorted videos for subjective test.
    %
    % INPUT:
    %   outfilename@char-array...   outfilename
    %   infile_gt@char-array...     ground truth video file
    %   infile_dist@char-array...   distorted video file
    %   targetRes@numeric(1,2)...   resolution of the concatenated video
    %   padCenter@numeric(1)...     horz. padding in px between the two videos
    %
    % Run for example:
    %   join_video('concatenated.mp4', 'gt.mp4', 'dist.mp4', [2160 3840], 40)
    %
    % Version 1.00
    % 19.11.2020, Tobias Birnbaum
    
    
    % Check FFMPEG install
    ffprobeBin = strsplit(mfilename('fullpath'), filesep);
    ffprobeBin = fullfile(ffprobeBin{1:end-1}, 'ffmpeg/ffprobe.exe');
    if(ispc && ~exist(ffprobeBin, 'file'))
        error('nrsh:ffprobe', ['Error in nrsh: please ensure that an ffprobe binary is present at: ' strrep(ffprobeBin, '\', '\\')])
    elseif(ismac || isunix)
        ffprobeBin = 'ffprobe';
        [status, out] = system(['which ' ffprobeBin]);
        if(status || isempty(out))
            error('nrsh:ffprobe', ['Error in nrsh: please ensure that ffprobe is installed and in the path. ' out])
        end
    end
    
    ffmpegBin = strsplit(mfilename('fullpath'), filesep);
    ffmpegBin = fullfile(ffmpegBin{1:end-1}, 'ffmpeg/ffmpeg.exe');
    if(ispc && ~exist(ffmpegBin, 'file'))
        error('nrsh:ffmpeg', ['Error in nrsh: please ensure that an ffmpeg binary is present at: ' strrep(ffmpegBin, '\', '\\')])
    elseif(ismac || isunix)
        ffmpegBin = 'ffmpeg';
        [status, out] = system(['which ' ffmpegBin]);
        if(status || isempty(out))
            error('nrsh:ffmpeg', ['Error in nrsh: please ensure that ffprobe is installed and in the path. ' out])
        end
    end
    
    
    siPerSide = targetRes(:).' - [0, padCenter];
    siPerSide(2) = siPerSide(2)/2;
    
    siLeft = getVideoSize(infile_gt);
    padLeft = siPerSide(:) - siLeft(:);
    
    siRight = getVideoSize(infile_dist);
    padRight = siPerSide(:) - siRight(:);
    
    tmpOut1 = ['padded1_' infile_gt];
    tmpOut2 = ['padded2_' infile_dist];
    
    %% Pad GT
    [status, out] = system([ffmpegBin ' -y -i ' infile_gt   ' -vf "pad=' num2str(siPerSide(2)+padCenter) ':' num2str(siPerSide(1)) ':' num2str(round(padLeft(2)/2)) ':' num2str(round(padLeft(1)/2)) ':color=gray" -c:v libx264 -qp 0 ' tmpOut1]);
    if(status ~= 0), error(out), end
    
    %% Pad Dist
    [status, out] = system([ffmpegBin ' -y -i ' infile_dist ' -vf "pad=' num2str(siPerSide(2)+padCenter) ':' num2str(siPerSide(1)) ':' num2str(round(padRight(2)/2)) ':' num2str(round(padRight(1)/2)) ':color=gray" -c:v libx264 -qp 0 ' tmpOut2]);
    if(status ~= 0), error(out), end
    
   
    [status, out] = system([ffmpegBin ' -y -i ' tmpOut1 ' -vf "pad=' num2str(2*siPerSide(2)+padCenter) ':' num2str(siPerSide(1)) ' [left] ; ' ...
        'movie=' tmpOut2 ' [right]; '...
        '[left][right] overlay=' num2str(siPerSide(2)) '+' num2str(padCenter) '" -c:v libx264 -qp 0 ' outfilename]);
    if(status ~= 0), error(out), end
    
    delete(tmpOut1);
    delete(tmpOut2);
    
    
    %% Auxiliary functions
    function si = getVideoSize(infile)
        [status, outL] = system([ffprobeBin ' -v error -select_streams v:0 -show_entries stream=width,height -of default=nw=1 ' infile]);
    
        w = strfind(outL, 'width='); 
        h = strfind(outL, 'height=');

        w = outL(w+numel('width='):h-2);
        h = outL(h+numel('height='):end-1);
        si = [str2double(h), str2double(w)];
    end
end