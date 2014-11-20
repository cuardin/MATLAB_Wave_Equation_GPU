% Copyright 2013-2014 The MathWorks, Inc.
clear functions
argumentList = '-largeArrayDims -L"C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v5.5\lib\x64" -lnppi computeStepMEX.cu';
eval( ['mex ' argumentList] );

