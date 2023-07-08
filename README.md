# Single-Phase-Reconstruction

Software aiming to reconstruct color holograms using a single matrix containing the hologram's phase information, instead of the three normally used.

*NOTE:* This README.md is a work in progress, any suggestions please open an issue tagged as `documentation`.

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

- `bin/` ─ Contains codec binaries and scripts to use them;
- `data/` ─ Input and output folders;
- `res/` ─ External projects location, contains all of the CTC and NRSH source code;
- `src/` ─ Source code.

## Usage

Before running the run.m script, it's necessary to follow these steps:
1. Download the holograms. The links for the supported holograms are the following (Download will begin automatically):
	1. [Biplane16k](http://ds.erc-interfere.eu/downloads/dataset3/CGH_Biplane16k_rgb.mat) (5.99 GB)
	2. [CGH_Venus](http://ds.erc-interfere.eu/downloads/dataset3/CGH_Venus.zip) (90 MB)
	3. [DeepDices16K, Amplitude-Phase](https://hologram-repository.labs.b-com.com/store/dices16k/dices16k-AP.zip) (1.43 GB)
	4. [DeepDices2K, Amplitude-Phase](https://hologram-repository.labs.b-com.com/store/deepDices2k/deepDices2k-AP.zip) (23.2 MB)
	6. [Lowiczanka_Doll](http://plenodb.jpeg.org/holo/WUT/WUT_color_digital_on-axis_holograms.tar.gz) (3.31 GB)
2. Place the holograms in `data/input/holograms/`;
3. On MATLAB IDE, change the current folder to  `src/holo_config` ;
4. Run the script `gen_config_files.m` (for more context read the 'Configuration Files' section below);
5. On MATLAB IDE, change the current folder to  `src/` ;
6. On the `run.m` script, change the following variables:
	1. `hologram_name: string` ─ can be either:
		1. Biplane16k
		2. CGH_Venus
		3. DeepDices16K
		4. DeepDices2K
		5. Lowiczanka_Doll
	2. `rec_dists: float` ─ reconstruction distance within each hologram range (see table in section 'Hologram Configuration').
	3. `h_pos, v_pos: array` ─ aperture position, values range from -1 to 1.
	4. `channel: int` ─ channel of the phase matrix to be used on the hologram reconstruction.
7. Run `run.m` script.
8. The output will be saved as a PNG file in `data/output/reconstruction`.

### *Configuration Files*
All the information needed to run the NRSH script is generated by the script `res/nrsh/getSettings.m` and stored as the variable **`info`**. This variable is often passed as argument between NRSH functions (which muddles which of the variables in `info` are needed for any given function).

To reconstruct each hologram, this project will create a dedicated .mat file with the
respective `info` variable for each hologram. To run this script, ***it's necessary to run the script*** `src/holo_config/gen_config_files.m` to generate said configuration files, which will be saved in `data/config/single_phase_config`.

### *Command Line*
These scripts can be run from the command line with the following command:
```
matlab -nodesktop -nojvm -nosplash -r "try, run(<path_to_script_name>.m), catch e, disp(e.message); end; quit"
```
Remember to `cd` to the project root directory, otherwise, MATLAB might not be able to add the correct paths to its PATH variable.

## Hologram Configuration

The following table presents the possible reconstruction distance in meters.

| Hologram        | Min Rec Dist (m) | Max rec Dist (m) |
|-----------------|:----------------:|:---------------:|
| Biplane16K      | 0.037            | 0.049            |
| CGH_Venus       | 0.2955           | 0.3045           |
| DeepDices16K    | 0.00338          | 0.0459           |
| DeepDices2K     | 0.00507          | 0.246            |
| Lowiczanka_Doll | 1.030            | 1.077            |
