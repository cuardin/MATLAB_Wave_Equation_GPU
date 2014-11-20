// Copyright 2014 The MathWorks, Inc.
#include "computeWaveStep.h"
#include <mex.h>
#include <iostream>
#include <gpu/mxGPUArray.h>


// A function to compute the mean of all the elements of a uint8 matrix on the gpu. 
// Returns a single scalar value on the GPU.
void mexFunction ( const int nlhs, mxArray* plhs[], const int nrhs, 
		const mxArray * const prhs[] )
{	
	//Ensure the GPU system is initialized.
	int mwGpuStat = 0;
	mwGpuStat = mxInitGPU();
	
	if ( mwGpuStat != 0 )
		mexErrMsgTxt( "Error initializing MW GPU system" );
	
    //Check that we have exactly two outputs
	if ( nlhs != 2 )
		mexErrMsgTxt( "Need exactly two output arguments" );		    
    
    //Check we get five inputs
	if ( nrhs != 6 )
		mexErrMsgTxt( "Need exactly six input arguments" );	
    //Check if first three inputs are gpuArrays    
	if ( !mxGPUIsValidGPUData( prhs[0] ) )
		mexErrMsgTxt( "Input data 1 is not valid GPU data" );    
	if ( !mxGPUIsValidGPUData( prhs[1] ) )
		mexErrMsgTxt( "Input data 2 is not valid GPU data" );
    if ( !mxGPUIsValidGPUData( prhs[2] ) )
		mexErrMsgTxt( "Input data 3 is not valid GPU data" );
    if ( !mxGPUIsValidGPUData( prhs[3] ) )
		mexErrMsgTxt( "Input data 4 is not valid GPU data" );
    
    //Check that the last two parameters are doubles
    if ( !mxIsDouble( prhs[4] ) )
        mexErrMsgTxt( "Input data 5 must be a double" );
    if ( !mxIsDouble( prhs[5] ) )
        mexErrMsgTxt( "Input data 6 must be a double" );
    
    //Get the parameters from the last values
    double r2 = mxGetScalar( prhs[4] );
    double b = mxGetScalar( prhs[5] );
    
	//Now convert to gpuArray
	mxGPUArray * const input  = mxGPUCopyFromMxArray( prhs[0] );	
    mxGPUArray * const inputOld  = mxGPUCopyFromMxArray( prhs[1] );	
    const mxGPUArray * const kernel = mxGPUCreateFromMxArray( prhs[2] );	
    const mxGPUArray * const boundary = mxGPUCreateFromMxArray( prhs[3] );	
    
	//Get the data type, and ensure it is double
	if (mxGPUGetClassID(input) != mxDOUBLE_CLASS)
        mexErrMsgTxt("Input data must be double");        
    if (mxGPUGetClassID(inputOld) != mxDOUBLE_CLASS)
        mexErrMsgTxt("Input data must be double");        
	if (mxGPUGetClassID(kernel) != mxDOUBLE_CLASS)
        mexErrMsgTxt("Kernel data must be double");    
    if (mxGPUGetClassID(boundary) != mxDOUBLE_CLASS)
        mexErrMsgTxt("Boundary data must be double");    
	
    //Check that the input matrices have 2 dimensions
	if ( mxGPUGetNumberOfDimensions(input) != 2 )
		mexErrMsgTxt("Input data must be 2D");    
    if ( mxGPUGetNumberOfDimensions(inputOld) != 2 )
		mexErrMsgTxt("Input data must be 2D");    
    if ( mxGPUGetNumberOfDimensions(kernel) != 2 )
		mexErrMsgTxt("Kernel data must be 2D");    
    if ( mxGPUGetNumberOfDimensions(boundary) != 2 )
		mexErrMsgTxt("Boundary data must be 2D");    
	
    //Now get the size of the data
	const mwSize * const size = mxGPUGetDimensions( input );
	const unsigned int width = (unsigned int)size[0]; //Swap row and column notation here
	const unsigned int height = (unsigned int)size[1];
        
	//Check that the second data matrix has the right size
    mwSize const * size2 = mxGPUGetDimensions( inputOld );
	if (size2[0] != width || size2[1] != height )
        mexErrMsgTxt( "Input data matrices are not of equal size" );
    
    //Check that the boundary data matrix has the right size
    size2 = mxGPUGetDimensions( boundary );
	if (size2[0] != width || size2[1] != height )
        mexErrMsgTxt( "Input data matrices are not of equal size" );
   
    //Check that the kernel matrix has the right size
    const mwSize * const kSize = mxGPUGetDimensions( kernel );	
    if ( kSize[0] != 3 || kSize[1] != 3 )
        mexErrMsgTxt("Kernel must be a 3x3 matrix");
    
	//And get pointers to the data
	double * const d_data = 
			(double*)mxGPUGetData( input );
    double * const d_dataOld = 
			(double*)mxGPUGetData( inputOld );
    const double * const d_kernel = 
			(double*)mxGPUGetDataReadOnly( kernel );
    const double * const d_boundary = 
			(double*)mxGPUGetDataReadOnly( boundary );
	
    //Allocate some buffer storage to compute our spatial differential
    const mwSize dims[2] = {width, height};
	mxGPUArray * const diff = mxGPUCreateGPUArray(2, dims, 
			mxDOUBLE_CLASS, mxREAL, MX_GPU_INITIALIZE_VALUES);
	double * const d_diff = (double*)mxGPUGetData( diff );

    //**********************************
    // Call the actual wave step
    try {
        computeWaveStep( d_data, d_dataOld, d_diff, d_kernel, d_boundary, width, height, 
            r2, b );	
    } catch ( CustomException e ) {
        mexErrMsgTxt( e.errMsg.c_str() );
    }    
    // Done calling the actual wave step
    //**********************************

    //Create the return mxArrays
	plhs[0] = mxGPUCreateMxArrayOnGPU(input);
    plhs[1] = mxGPUCreateMxArrayOnGPU(inputOld);
	
	//Clean up memory.
	mxGPUDestroyGPUArray(input);
    mxGPUDestroyGPUArray(inputOld);
    mxGPUDestroyGPUArray(diff);
    mxGPUDestroyGPUArray(kernel);	
    mxGPUDestroyGPUArray(boundary);	
}


