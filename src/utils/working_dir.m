function [curr_dir] = working_dir()
    curr_dir = regexp(pwd, "^(\S+\/Single\-Phase\-Reconstruction\/)", 'match');
    curr_dir = curr_dir{1};
end
