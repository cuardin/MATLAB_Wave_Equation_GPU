% Copyright 2013-2014 The MathWorks, Inc.
function [ u, ul, wave_kernel, boundaries ] = wave_equation_core_kernel( u, ul, boundaries, wave_kernel, r2, b )
    %WAVE_EQUATION_FUNCTION Do one step in the wave equation
    
    %Make sure data is in on GPU RAM.
    u = gpuArray(u);
    ul = gpuArray(ul);
    boundaries = gpuArray(boundaries);
    wave_kernel = gpuArray(wave_kernel);
    
    %Run 10 iterations of the wave equation.
    for i = 1:10
        [u,ul] = computeStepMEX(u,ul,wave_kernel,boundaries,r2,b);        
    end
end


