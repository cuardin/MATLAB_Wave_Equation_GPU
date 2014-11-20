// Copyright 2014 The MathWorks, Inc.
#ifndef _COMPUTE_DIFF_
#define _COMPUTE_DIFF_

#include <cuda.h>
#include <npp.h>
#include "util.h"

//**************************************************************
// A function wrapper around the NPP-function nppiFilter_64f_C1R().
// Computes a 2d convolution of doubles
//**************************************************************
void computeDiff( const double* const d_data, const double* const d_kernel, 
        const int width, const int height, 
        double* d_diff )
{
    NppStatus stat;
    
    //Create a ROI that covers the entire image
    NppiSize region;
    region.height = height-1;
    region.width = width-1;
    
    NppiSize kernelSize;
    kernelSize.height = 3;
    kernelSize.width = 3;
        
    NppiPoint anchor;
    anchor.x = 1;
    anchor.y = 1;
    
    //Compute the convolution
    //The kernel parameters are expected in reverse order, but our kernel is 
    //symmetric, so it doesn't matter.
    stat = nppiFilter_64f_C1R (d_data, width*sizeof(double), d_diff, width*sizeof(double), region, d_kernel, 
            kernelSize, anchor);
    
    if ( stat != NPP_NO_ERROR ) {        
        throw CustomException( "Error calling nppiFilter_64f_C1R" );
    }    
}

//*******************************************************************
// A kernel that computes the next time step in the wave equation.
// Inputs are the current time step, the last time step, and the 
// current spatial differential.
//**************************************************************
__global__
        void computeNextStep( double * const p_u,
        double * const p_ul, const double * const p_diff,
        const double * const p_boundary, const unsigned int numRows, 
        const unsigned int numCols,
        const double r2, const double b )
{
    // Work out which pixel we are working on.
    const int rowIdx = blockIdx.x * blockDim.x + threadIdx.x;
    const int colIdx = blockIdx.y * blockDim.y + threadIdx.y;
    
    // Check this thread isn't off the image
    if( rowIdx >= numRows || colIdx >= numCols ) {
        return;
    }
                    
    // Compute the index of my element
    const unsigned int linearIdx = rowIdx + colIdx*numRows;
    
    //If we are an edge pixel, set to 0
    if ( rowIdx == 0 || rowIdx == numRows-1 || 
            colIdx == 0 || colIdx == numCols-1 ) {
        p_u[linearIdx] = 0;
        p_ul[linearIdx] = 0;
        return;
    }        
    
    //Load the relevant values into local cache.
    double u = p_u[linearIdx];
    double ul = p_ul[linearIdx];
    double diff = p_diff[linearIdx];
    double boundary = p_boundary[linearIdx];
    
    // Compute the value of the next step
    double n = 2*u - ul + r2*diff - b*(u-ul);
    
    //Clamp at boundaries
    n *= boundary;
            
    // Write the new values to global memory
    p_u[linearIdx] = n;
    p_ul[linearIdx] = u;
}

//************************************************************************
// A wrapper fcuntion that computes an entire step of the wave equation.
// Pointers are device pointers and it is up to the caller to ensure that 
// memory is properly allocated/deallocated.
//************************************************************************
void computeWaveStep( double * const d_data, double * const d_dataOld, 
        double * const d_diff, double const * const d_kernel, 
        const double* const d_boundary, const int width, const int height, 
        double const r2, double const b )
{
    //Do the filter.	
	computeDiff( d_data, d_kernel, width, height, d_diff );    
    
    //Set up the kernel parameters for the time differential kernel.
    const double blockSize = 16;
    const dim3 dimBlock((int)blockSize,(int)blockSize,1);
    const dim3 dimGrid((int)ceil(height/blockSize), (int)ceil(width/blockSize), 1);
        
    computeNextStep<<<dimGrid,dimBlock>>>( d_data, d_dataOld, d_diff,
        d_boundary, height, width, r2, b );        
    if ( cudaSuccess != cudaGetLastError() )
        throw new CustomException ( "Error calling applyScaleFactorsKernel" );
}

#endif