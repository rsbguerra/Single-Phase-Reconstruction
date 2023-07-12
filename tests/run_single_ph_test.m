clear; clc

parent_dir = regexp(pwd, "[^\/]+$", 'split');
parent_dir = parent_dir{1};

addpath([parent_dir 'src/utils'])
add_paths(parent_dir, ["res/nrsh/" ...
                           "res/nrsh/core/" ...
                           "res/nrsh/core/WUT_lib/" ...
                           "src/reconstruction/" ...
                           "src/utils/"
                       ])
log_dir = "single_phase_rec/logs/";

folder_info = dir('single_phase_rec/*.m');

for i = 1:size(folder_info, 1) % allFiles has one row per file, so loop over those
    script_name = folder_info(i).name;
    script_path = sprintf("%stests/single_phase_rec/%s", parent_dir, script_name);

    log_dir = "single_phase_rec/logs/"+script_name(1:end - 2);
    time = string(datetime('now', 'Format', 'dd-MMM-y_HH:mm:ss.SSS'));
    log_path = sprintf("%s/%s.log", log_dir, time);

    if ~exist(log_dir, 'dir')
        mkdir(log_dir);
    end

    diary(convertStringsToChars(log_path))

    try
        fprintf(1, "\n[TEST] Running %s test script.\n", script_path);
        run(convertStringsToChars(script_path));
        fprintf(1, "\n[PASS] %s exited with 0.\n", script_path);
        diary off

    catch error
        fprintf(1, "\n[ERROR] %s exited with:\n", script_path);
        disp(getReport(error, 'extended', 'hyperlinks', 'off'))
        diary off
    end

end
