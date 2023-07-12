parent_dir = regexp(pwd, "[^\/]+$", 'split');
parent_dir = parent_dir{1};

addpath([parent_dir 'src/'])

add_paths(parent_dir, ["res/nrsh/" ...
                         "res/nrsh/core/" ...
                         "res/nrsh/core/WUT_lib/" ...
                         "src/reconstruction/" ...
                         "src/utils/"
                     ])

% folder_info = dir('nrsh/*.m');
folder_info = dir('nrsh/lowiczanak_doll.m');

for i = 1:size(folder_info, 1) % allFiles has one row per file, so loop over those
    script = folder_info(i).name;
    
    try
        disp(['[TEST] Running ' script ' test script.']);
        eval(['nrsh/' script]);
    catch error
        warning(['[ERROR] ' script ' failed with:']);
        rethrow(error)
    end
end
