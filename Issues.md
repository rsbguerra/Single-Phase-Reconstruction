# Issues
## aperture_angle_checker: Not enough input arguments.
```
info = getSettings('cfg_file', '/mnt/data/code/Single-Phase-Reconstruction/data/config/nrsh_config/bcom/specular_car8k_000.txt', ...
    'apertureinpxmode', false, ...
    'ap_sizes', 7, ...
    'h_pos', -10:10:10, ...
    'v_pos', -8:8:8);

nrsh(data, 0.0023, info)

```

```
[TEST] Running /mnt/data/code/Single-Phase-Reconstruction/tests/nrsh/car_angle.m test script.
Config file parsed.
******************************************************************************************
**************************Configuration setup:**************************
******************************************************************************************
                          rec_dists : 0.0023
                           ap_sizes : 7
                   apertureinpxmode : 0
                               apod : 1
                          bit_depth : 16
                           cfg_file : nrsh_config/bcom/specular_car8k_000.txt
                           clip_max : -1
                           clip_min : -1
                            dataset :
                          direction : forward
                                fps : 10
                              h_pos : -10   0  10
                       hist_stretch : 1
                           isBinary : 0
                        isFourierDH : 0
                             method : ASM
                        name_prefix :
                      offaxisfilter : h
                       orthographic : 0
                      outfolderpath : ./figures
                          perc_clip : 1
                         perc_value : 98
                        pixel_pitch : 4e-07
                         reffronorm : 1  1  1
                         resize_fun :
                      save_as_image : 1
                        save_as_mat : 0
                     save_intensity : 0
                               show : 0
                          targetres : 8192  8192
                          usagemode : exhaustive
          use_first_frame_reference : 1
                              v_pos : -8  0  8
                               wlen : 6.4e-07    5.32e-07    4.73e-07
                           zero_pad : 1

[ERROR] /mnt/data/code/Single-Phase-Reconstruction/tests/nrsh/car_angle.m exited with:

Error in aperture_angle_checker (line 27)
    if (verbosity)

Error in nrsh (line 341)
                rec_par_idx = aperture_angle_checker(size(hol, 1), size(hol, 2), rec_par_idx, ...

Error in car_angle (line 9)
nrsh(data, 0.0023, info)

Error in run (line 91)
evalin('caller', strcat(script, ';'));

Error in run_nrsh_test (line 34)
        run(convertStringsToChars(script));
```

## defaultSettings: Expected targetres to be one of these types:
```
info = getSettings('cfg_file', 'nrsh_config/bcom/DeepDices8k4k_000.txt', ...
    'resize_fun', 'DR', ...
    'targetres', {[4096 4096]},  ...
    'h_pos', [-0.5,0.5], ...
    'v_pos', [-0.75, 0.75]);

nrsh(data, 0.086, info)
```

```
[TEST] Running /mnt/data/code/Single-Phase-Reconstruction/tests/nrsh/dices.m test script.
Config file parsed.

[ERROR] /mnt/data/code/Single-Phase-Reconstruction/tests/nrsh/dices.m exited with:
Error using nrsh
Expected targetres to be one of these types:

double, single, uint8, uint16, uint32, uint64, int8, int16, int32, int64

Instead its type was cell.

Error in defaultSettings (line 103)
            validateattributes(info.targetres,{'numeric'},{'row', 'nonempty', 'integer', 'positive', 'numel', 2},'nrsh','targetres');

Error in nrsh (line 208)
    info = defaultSettings(hol, rec_dists, info);

Error in dices (line 9)
nrsh(data, 0.00329, info)

Error in run (line 91)
evalin('caller', strcat(script, ';'));

Error in run_nrsh_test (line 34)
        run(convertStringsToChars(script));
```

## B-com unable to reconstruct different views
```
info = getSettings('cfg_file', '/mnt/data/code/Single-Phase-Reconstruction/data/config/nrsh_config/bcom/DeepDices8k4k_000.txt', ...
    'resize_fun', 'DR', ...
    'ap_sizes', [4320 7680],  ...
    'targetres', [4320 7680],  ...
    'h_pos', [-1 0 1], ...
    'v_pos', [0]);

nrsh(data, 0.331, info)
```

![[Pasted image 20230718153838.png]]

```
info = getSettings('cfg_file', '/mnt/data/code/Single-Phase-Reconstruction/data/config/nrsh_config/bcom/DeepDices16k_000.txt', ...
    'resize_fun', 'DR', ...
    'targetres', [16384 16384], ... % from ctc test data
    'h_pos', [-1 0 1], ...
    'v_pos', 0);

nrsh(data, 0.0185, info)

```

## JPEG Pleno Holography Test Data not up to date
And the b-com links are broken.
# CTC tests
## Test data for subjective tests

| holograms | Status| dwld? | dataset | ap_size | rec_dist(m) |
| - |:-:| - | - | - | -:|
| DeepCornellBox_16K       | Fail | Y | Interfere-V | [4096x4096]| 0.250 |
| CornellBox3_16K          | Fail | Y | Interfere-V | [4096x4096]| 0.250 |
| DeepChess                | Fail | Y | Interfere-IV | [2048x2048]| 0.3964 |
| Biplane16k               | Fail | Y | Interfere-III | [2048x2048]| 0.0455 |
| Dices16k                 | PASS | Y | b-com | [2048x2048] | 0.01
| DeepDices2k              | Fail | Y | b-com | [2048x2048] | 0.867 |
| Piano16k                 | PASS | Y | b-com | [16384x16384]| 0.01 |
| Breakdancers8k4k         | Fail | Y | b-com | [7680x4320] | 0.025 |
| Astronaut                | Fail | Y | EmergImg-HoloGrail | [1940x2588] | -0.172 |
| Lowiczanka Doll (OnAxis) | Fail | Y | WUT | [2016x2016] | 1.06 |

