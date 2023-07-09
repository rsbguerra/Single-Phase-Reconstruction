addpath('../../res/nrsh')
addpath('../../res/nrsh/core')

info = getSettings('cfg_file', '../../data/config/nrsh_config/emergimg/astronaut_000.txt', ...
                  'dataset', 'emergimg');
              
load('../../data/input/holograms/Astronaut_Hol_v2.mat')

nrsh (u1, 0.1721, info);
