source_path = [pwd '/nrsh/core/MatlabEXR']

mex exrread.cpp -I/usr/include/OpenEXR -I/usr/include/Imath -L/usr/lib -lImath-3_1 -lopencv_core -lopencv_highgui -lopencv_videoio -lopencv_imgcodecs

% mex nrsh/core/MatlabEXR/exrread.cpp         -I/usr/include/OpenEXR -I/usr/include/Imath -L/usr/lib -lImath-3_1 -lopencv_core -lopencv_highgui -lopencv_videoio -lopencv_imgcodecs
% mex nrsh/core/MatlabEXR/exrinfo.cpp         -I/usr/include/OpenEXR -I/usr/include/Imath -L/usr/lib -lImath-3_1 -lopencv_core -lopencv_highgui -lopencv_videoio -lopencv_imgcodecs
% mex nrsh/core/MatlabEXR/exrreadchannels.cpp -I/usr/include/OpenEXR -I/usr/include/Imath -L/usr/lib -lImath-3_1 -lopencv_core -lopencv_highgui -lopencv_videoio -lopencv_imgcodecs
