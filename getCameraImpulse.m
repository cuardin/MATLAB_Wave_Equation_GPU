% Copyright 2013-2014 The MathWorks, Inc.
function [ imageData ] = getCameraImpulse( ia, scaleFactor, useGPU )
    %GETCAMERAIMPULSE Summary of this function goes here
    %   Detailed explanation goes here    

    imAvail = ia.FramesAvailable;
    while ( imAvail < 1 )
        pause(0.01);
        imAvail = ia.FramesAvailable;
    end
    imageDataRaw = peekdata(ia,1);
    flushdata(ia, 'all');      
    
    if ( useGPU )
        imageData = double(gpuArray(imageDataRaw));
    else
        imageData = double(imageDataRaw);
    end
    
    % Resize the image to our wanted size.
    imageData = imresize(imageData, scaleFactor, 'cubic' );
    
    % Flip the image to get a mirror-effect.
    imageData = flipdim(imageData,2);
    
end

