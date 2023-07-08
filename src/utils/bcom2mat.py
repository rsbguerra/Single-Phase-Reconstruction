import re
from os.path import exists
from os import getcwd
from sys import argv

import matplotlib.pyplot as plt
import numpy as np
import PIL
from hdf5storage import savemat

PIL.Image.MAX_IMAGE_PIXELS = 268435460

WORKING_DIR = re.search('(^\S+\/Single\-Phase\-Reconstruction)',getcwd()).group(1)
OUT_DIR = WORKING_DIR + '/data/input/holograms/'

def _convert_bmp(bmp_dir:str, output_dir:str):
    # Matches any word characters preceded by '-AP'
    hol_name = re.search('\w+(?=-AP)', bmp_dir).group(0)

    if not bmp_dir[-1] == '/':
        bmp_dir = bmp_dir + '/'

    am_path = f'{bmp_dir}{hol_name}_ampli.bmp'
    ph_path = f'{bmp_dir}{hol_name}_phase.bmp'

    am = plt.imread(am_path)/255
    ph = 2.0 * np.pi * (plt.imread(ph_path)/255)

    data = am * np.exp(1j * ph)

    mat_file = f'{output_dir}{hol_name}.mat'
    savemat(mat_file, mdict={'data': data}, do_compression=True, format='7.3')

def convert(holo_dirs):
    for dir in holo_dirs:
        if exists(dir):
            _convert_bmp(dir, OUT_DIR)
        else:
            print(f'[WARNING] Unable to find {dir}.')

# convert()

if __name__ == "__main__":
    if len(argv) > 1:
        convert(argv[1:])
    else:
        print('[ERROR] No arguments passed.')