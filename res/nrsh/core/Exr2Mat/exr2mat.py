#!/usr/bin/python3

# Conversion from 1 or 2 exr files to complex valued "data" entry stored as mat (v6 or v7.3) file.
#
# Tobias Birnbaum
# ETRO, imec
# Version 1.00
# 03.06.2021


try:
    import OpenImageIO as oiio
except:
    import sys
    print(sys.path)
    sys.exit()

import numpy as np

#Required for v6
import scipy.io


# Required for v7.3
import h5py
import hdf5storage

import sys, getopt, os

# OIIO API: https://openimageio.readthedocs.io/en/v2.2.14.0/pythonbindings.html
# SCIPY API: https://docs.scipy.org/doc/scipy/reference/tutorial/io.html

def printHelp():
    print("Default: exr2mat.py -6 --algebraic --iR <inputReal> --iI <inputImag> -o <output>")
    print("Inputs parameters: ")
    print("-6/--6 ... Mat file v6")
    print("-7/--7 ... Mat file v7.3 (>2GB possible)")
    print("-r/--iR <inputReal> ... real part or absoute value")
    print("-i/--iI <inputImag> ... imag part or phase")
    print("Either -i or -r can also be omitted in case of a pure phase/amplitude/real/imag dataset")
    print("-p/--polar ... use polar coordinate interpretation of complex numbers; c = abs * exp(1i*phase)")
    print("-a/--algebraic ... use algebraic interpretation of complex numbers; c = re + 1i * im")


def main(argv):
    ifileR = ''
    ifileI = ''
    ofile = ''
    version = '6'
    real = np.empty(0)
    imag = np.empty(0)
    
    doV6 = True
    realExist = False
    imagExist = False
    doPolar = False

    try:
        opts, args = getopt.getopt(argv, "hap67r:i:o:", ["iR=", "iI=", "ofile=", "6", "7", "polar", "algebraic"])
    except getopt.GetoptError as err:
        print(err)
        printHelp()
        sys.exit(2)
    for opt, arg in opts:
        if opt == "-h":
            printHel()
            sys.exit()
        elif opt in ("-p", "--polar"):
            doPolar = True
        elif opt in ("-a", "--algebraic"):
            doPolar = False
        elif opt in ("-6", "--6"):
            doV6 = True
        elif opt in ("-7", "--7"):
            doV6 = False
        elif opt in ("-r", "--iR"):
            ifileR = arg
        elif opt in ("-i", "--iI"):
            ifileI = arg
        elif opt in ("-o", "--ofile"):
            ofile = arg

    if doV6:
        version = '6'
    else:
        version = '7.3'

    print("Converting " + ifileR + " and " + ifileI + " to " + ofile + " using MAT-file version "+ version +" ...")

    if ifileR:
        dataR = oiio.ImageInput.open(ifileR)
        if dataR == None:
            print("Couldn't open input file " + ifileR + "  " + oiio.geterror())
            return
        real = dataR.read_image()
        if real.size == 0:
            print("Couldn't parse input file " + ifileR + "  " + oiio.geterror())
        else:
            realExist = True


    if ifileI:
        dataI = oiio.ImageInput.open(ifileI)
        if dataI == None:
            print("Couldn't open input file " + ifileI + "  " + oiio.geterror())
            return
        imag = dataI.read_image()
        if imag.size == 0:
            print("Couldn't parse input file " + ifileI + "  " + oiio.geterror())
        else:
            imagExist = True

    if realExist and imagExist:
        if not doPolar:
            data = real + 1j * imag
        else:
            data = real * np.exp(1j * imag)
    elif realExist and not imagExist:
        data = real
    elif imagExist and not realExist:
        if not doPolar:
            data = 1j * imag
        else:
            data = np.exp(1j * imag)

    if doV6:
        scipy.io.savemat(ofile, mdict={'data':data}) 
    else:
        matfiledata = {}
        matfiledata[u'data'] = data
        try:
            os.remove(ofile)
        except Exception as e:
            1 

        hdf5storage.write(matfiledata, '.', ofile, store_python_metadata=True, matlab_compatible=True)

#        # Take care of the problem that a ___ struct is present in the top-layer
#        f = open('convert.m', 'w+')
#        f.write('data = load(\'' + ofile + '\');\n')
#        f.write('data = data.___.data;\n')
#        f.write('save(\'' + ofile + '\', \'-v7\', \'data\');\n')
#        f.close()
#
#        out = os.system("octave convert.m")
#        os.remove("convert.m")
        

    print('done!')

if __name__ == "__main__":
    main(sys.argv[1:])
