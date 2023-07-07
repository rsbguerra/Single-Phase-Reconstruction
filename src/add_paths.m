function add_paths(root_dir, dirs)
    addpath(root_dir)

    for dir = dirs
        addpath(fullfile(root_dir, dir))
    end
end
