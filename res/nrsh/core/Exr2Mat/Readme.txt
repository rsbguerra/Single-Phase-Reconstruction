The conversion script *should* work with python 2.7 and python 3+. It was tested with python 3.7.

Dependencies:

python3-h5py
python3-scipy
python3-numpy
python3-hdf5storage
libopenexr-dev
openexr


1) Install OIIO

oiio, (https://sites.google.com/site/openimageio/home) for build instructions see 
        https://github.com/OpenImageIO/oiio/blob/master/INSTALL.md

git clone https://github.com/OpenImageIO/oiio /*root*/oiio
cd /*root*/oiio
make -j4

# Don't use pybind from official Debian stable repositories because it's at the present (03.07.2021) outdated.
# Use the standalone version of pybind11 proposed by the installer instead.
# Make sure that the installer found your openexr installation and that it build the python bindings.


2) 
# Check your python2/3 path via
ipython -c "import sys; print(sys.path)" # for Python <3.0
ipython3 -c "import sys; print(sys.path)" # for Python >=3.0


3) 
# Copy the python binding module from 
# /*root*/oiio/build/.../lib/python 
# into any folder from your python path


4) 
Run exr2mat.py using the appropriate python version. For help call 

exr2mat -h
