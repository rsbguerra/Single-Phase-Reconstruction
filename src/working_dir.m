function [curr_dir] = working_dir()
    curr_dir = regexp(pwd, "\/\w+$", 'split');
    curr_dir = [curr_dir{1} '/'];
end
