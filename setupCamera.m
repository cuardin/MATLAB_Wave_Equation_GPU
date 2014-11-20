% Copyright 2013-2014 The MathWorks, Inc.
function [ ia ] = setupCamera(forceGrayscale)
    %% Clear any cameras previously opened
    a = imaqfind();
    delete(a);    
    
    %% Open the webcam
    try
        ia = videoinput('winvideo', 1);
    catch ME        
        error ( 'No winvideo camera with ID 1 availible. Connect one or run imaqhwinfo to find out what is wrong.' );        
    end
    ia.FramesPerTrigger = inf;
    if ( forceGrayscale )
        ia.ReturnedColorSpace = 'grayscale';    
    end
        
end

