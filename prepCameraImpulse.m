% Copyright 2013-2014 The MathWorks, Inc.
function [ impulse ] = prepCameraImpulse( imageData, imSize, useGPU )
        
    persistent lastImage;
    persistent kernel;
    persistent usingGPU;
    
    if ( nargin == 0 )
        lastImage = [];
        kernel = [];
        usingGPU = [];
        return;
    end
    
    scaleFactor = 1/1000; %Default: 1/1000
    noiseThreshold = 50; %Default: 50
    
    if ( nargin < 3 )
        useGPU = false;
    end
    
    %If we have not been initialized, or if we have switched GPUyness
    if ( isempty(kernel) || useGPU ~= usingGPU )
        kR = 2;
        s = 1/3;
        kernel = bsxfun(@(x,y)exp(-s*(x.^2+y.^2)),-kR:kR,(-kR:kR)');
        kernel = kernel/sum(kernel(:));
        if ( useGPU )
            kernel = gpuArray(kernel);
        end
        usingGPU = useGPU;
    end
    
    %Scale the image down to simplify processing.
    imageData = imageData(1:4:end,1:4:end);
    
    % If we do not have a last image, or a last image of the wrong size,
    % make the last image identical to the current image.
    if ( isempty(lastImage) || ~all(size(imageData)==size(lastImage)) )
        lastImage = imageData;
    end
    
    % Calculate impulse using the low resolution image. Simple difference
    % in time, and low-pass and high-pass the image spatially.
    impulse = (imageData - lastImage)*scaleFactor;
    impulse(abs(impulse)<noiseThreshold*scaleFactor) = 0;
    impulse = conv2(impulse,kernel,'same');  %Filter to avoid sharp edges.  
    impulse = impulse - conv2(impulse,kernel,'same'); % Only keep edges.
    
    % Store the new image as a last one.
    lastImage = imageData;
    
    % Compute the image size scale factor. We use max to ensure impulse
    % image is larger than the wavey field.
    scaleFactor = max( imSize./size(impulse) );
    
    % Scale up the impulse to our input size. 
    impulse = imresize(impulse,scaleFactor, 'cubic');
    
    % And cut down the impulse to get right aspect ratio and thereby
    % exactly the same size as the wavy field.
    offsets = floor((size(impulse)-imSize)/2);
    impulse = impulse((1+offsets(1)):(offsets(1)+imSize(1)), ...
        (1+offsets(2)):(offsets(2)+imSize(2)) );
    
end

