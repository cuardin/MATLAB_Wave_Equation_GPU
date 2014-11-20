% Copyright 2013-2014 The MathWorks, Inc.

%% Set some parameters
% Tip: Set cameraImageScal to 0.5 if you do not have a GPU.
% Tip: Experiment with setting wave- and impulseScaleFactor for different
% visual looks. 

cameraImageScaleFactor = 1; %How much we scale size of the camera image before processing.
waveScaleFactor = 1; %Set this to 0 to not show waves.
impulseScaleFactor = 0; %Set this to 0 to not show edges. Set to 1 (ore more) to show.
forceGrayscale = false; %Do we use grayscale images. Faster, but perhaps not as pretty.

%% video writer
% Uncommend this cell, as well as the getfram and close at the bottom to
% enable the recording of the visualization to disc. Note that you cannot
% resize the display window while recording.

%writerObj = VideoWriter('SC13waves.avi');
%open(writerObj);


%% Open the webcam
ia = setupCamera(forceGrayscale);

% Begin aquiring
start(ia);

% Check if we have GPU
useGPU = false;
try
    gpuDevice();
    useGPU = true;
catch ME %#OK
end

%% Initialize the datasets
temp = getCameraImpulse(ia,cameraImageScaleFactor,useGPU);
u = zeros(size(temp(:,:,1)));
ul = zeros(size(u));
boundaries = ones(size(u));

if ( useGPU )
    u = gpuArray(u);
    ul = gpuArray(ul);
    boundaries = gpuArray(boundaries);
end

%% Initialize the figure
f = gcf;
set ( f, ...
    'Name', 'Wave propagation', 'NumberTitle', 'off', ...
    'Toolbar', 'none', 'Menubar', 'none');
a = axes('Parent', f );
set ( a, 'Units', 'Normalized' );
set ( a, 'Position', [0 0 1 1] );
set ( f, 'Color', 'k' );
h = image( temp/256 );
axis( 'image' );
axis( 'off' );
colormap( gray(256) );
prepCameraImpulse(); %Initialize

while ( true && ishandle(f) )    
    %Do a fliplr to get the effect of a mirror.
    imageDataRaw = getCameraImpulse(ia,cameraImageScaleFactor,useGPU);           
    
    [u,ul,boundaries,outImage] = doCompleteStep( imageDataRaw, u, ul, ...
        boundaries, useGPU, waveScaleFactor, impulseScaleFactor);
    
    if ishandle(h)
        set ( h, 'cdata', gather(outImage) );                
        drawnow;
    end
    
    %frame = getframe;
    %writeVideo(writerObj,frame);
    
end
stop(ia);
delete(ia);

%close(writerObj);

