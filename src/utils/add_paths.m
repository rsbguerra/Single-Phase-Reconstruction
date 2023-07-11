function add_paths(root_dir, dirs)
    addpath(root_dir)

    for i = dirs
        addpath(fullfile(root_dir, i))
    end
end
