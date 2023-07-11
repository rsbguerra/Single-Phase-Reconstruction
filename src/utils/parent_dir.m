function [parent_dir] = parent_dir()
    parent_dir = regexp(pwd, "[^\/]+$", 'split');
    parent_dir = parent_dir{1};
end
