import numpy as np
import matplotlib.pyplot as plt
import re
from hdf5storage import savemat
# from scipy.io import savemat

import PIL
PIL.Image.MAX_IMAGE_PIXELS = 268435460

def _convert_bmp(bmp_dir:str, output_dir:str):
    hol_name = re.search('bcom\/(\S+)-AP\/', bmp_dir).group(1)

    am_path = f'{bmp_dir}{hol_name}_ampli.bmp'
    ph_path = f'{bmp_dir}{hol_name}_phase.bmp'

    am = plt.imread(am_path)
    ph = 2.0 * np.pi * plt.imread(ph_path)

    data = am * np.exp(1j * ph)

    mat_file = f'{output_dir}{hol_name}.mat'
    savemat(mat_file, mdict={'data': data}, do_compression=True, format='7.3')

def convert():
    holo_dirs = [
        #'/mnt/data/Holograms/bcom/deepDices2k-AP/',
        '/mnt/data/Holograms/bcom/deepDices16k-AP/'
    ]

    for dir in holo_dirs:
        _convert_bmp(dir, dir)

convert()
