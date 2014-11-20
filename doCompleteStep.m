% Copyright 2013-2014 The MathWorks, Inc.
function [ u,ul,boundaries,outImage] = doCompleteStep( imageDataRaw, u, ul, boundaries, useGPU, waveScaleFactor, impulseScaleFactor)    
    
    persistent xGrid    
    persistent yGrid
    persistent kernel;    
    
    if ( isempty(xGrid) )
        [xGrid,yGrid] = meshgrid(1:size(imageDataRaw,2),1:size(imageDataRaw,1));
        kernel = [0 1 0; 1 -4 1; 0 1 0];    
    end    
    if ( isa(xGrid,'gpuArray') ~= isa(u,'gpuArray') ) 
        if ( useGPU )
            xGrid = gpuArray(xGrid);
            yGrid = gpuArray(yGrid);
            kernel = gpuArray(kernel);
        else
            xGrid = gather(xGrid);
            yGrid = gather(yGrid);
            kernel = gather(kernel);
        end
    end
    
    r2 = 0.7*0.7;
    b = 0.01;
    
    % Convert the camera image to an edge-detected motion map.
    impulse = prepCameraImpulse( imageDataRaw, size(u), useGPU );     
    
    % Apply the detected motion to our wave surface    
    u = u + impulse;
    
    % Perform the wave equation (10 iterations)
    if ( useGPU )
        [u,ul,kernel,boundaries] = wave_equation_core_gpu(u,ul,boundaries, kernel, r2, b );        
    else
        [u,ul,kernel,boundaries] = wave_equation_core_cpu(u,ul,boundaries, kernel, r2, b );
    end
    
    % Composite the raw image with the wavyness and the impulse
    overlay = waveScaleFactor*5*256*u + abs(impulse)*10000*impulseScaleFactor;
    overlayX = xGrid + [diff(overlay,1,2) zeros(size(overlay,1),1)]/3;
    overlayY = yGrid + [diff(overlay,1,1);  zeros(1,size(overlay,2))]/3;        
    
    outImage = bsxfun(@plus,imageDataRaw,overlay/5);
    for ii = 1:size(outImage,3)
        outImage(:,:,ii) = interp2(outImage(:,:,ii),overlayX,overlayY,'nearest', 0);
    end
        
    % Trim the image to 256 shades.
    outImage(outImage>255) = 255;
    outImage(outImage<0) = 0;
    
    if ( size(outImage,3) > 1 )
        % True-color images have to be between 0 and 1. Grayscale between 0
        % and 255.
        outImage = outImage/256;
    end
    
end


