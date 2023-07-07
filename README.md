# Single-Phase-Reconstruction
Software aiming to reconstruct color holograms using only one of the phase's information

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
***MATLAB IDE:***
- Remember to move to the `src/` folder before executing the script;

***Command Line:***
- Run the following command from the project root:
```
matlab -nodesktop -nojvm -nosplash -r "try, run('src/run.m'), catch e, disp(e.message); end; quit"
```

## Hologram Configuration

| Hologram | Min Rec Dist (m) | Max rec Dist (m) |
|-|-|-|
| CGH_Venus | 0.2955  | 0.3045 |
| Biplane16K | 0.037  | 0.049 |
