# Single-Phase-Reconstruction

Software aiming to reconstruct color holograms using a single matrix containing the hologram's phase information, instead of the three normally used.

## Project organization

```
│
├── bin/
│   └── codecs/
├── data/
│   ├── config/
│   ├── input/
│   └── output/
├── res/
│   ├── ctc/
│   └── nrsh/
├── src/
│   ├── holo_config/
│   ├── reconstruction/
│   └── utils/
└── utils/
```

- `bin/` ─ Contains codec binaries and scripts used to use them;
- `data/` ─ Input and output folders;
- `res/` ─ External projects location, contains all of the CTC and NRSH source code;
- `src/` ─ Source code.

## Usage

### *Configuration Files*
The hologram path and all the information needed to run the NRSH script is stored in a dedicated .mat file for each hologram. To run this script, ***it's necessary to run the script*** `src/holo_config/gen_config_files.m` to generate said configuration files, which will be saved in `data/config/single_phase_config`.

### *MATLAB IDE*
Remember to move to the `src/` folder before executing the script.

### *Command Line*
Run the following command from the project root:
```
matlab -nodesktop -nojvm -nosplash -r "try, run('src/run.m'), catch e, disp(e.message); end; quit"
```

## Hologram Configuration

| Hologram | Min Rec Dist (m) | Max rec Dist (m) |
|-         |-                 |-                 |
| Biplane16K | 0.037  | 0.049 |
| CGH_Venus | 0.2955  | 0.3045 |
| DeepDices2K | 0.00507 | 0.246 |