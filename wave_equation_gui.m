% Copyright 2013-2014 The MathWorks, Inc.
function varargout = wave_equation_gui(varargin)
    % WAVE_EQUATION_GUI MATLAB code for wave_equation_gui.fig
    %      WAVE_EQUATION_GUI, by itself, creates a new WAVE_EQUATION_GUI or raises the existing
    %      singleton*.
    %
    %      H = WAVE_EQUATION_GUI returns the handle to a new WAVE_EQUATION_GUI or the handle to
    %      the existing singleton*.
    %
    %      WAVE_EQUATION_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in WAVE_EQUATION_GUI.M with the given input arguments.
    %
    %      WAVE_EQUATION_GUI('Property','Value',...) creates a new WAVE_EQUATION_GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before wave_equation_gui_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to wave_equation_gui_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES
    
    % Edit the above text to modify the response to help wave_equation_gui
    
    % Last Modified by GUIDE v2.5 09-Apr-2014 13:41:48
    
    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
        'gui_Singleton',  gui_Singleton, ...
        'gui_OpeningFcn', @wave_equation_gui_OpeningFcn, ...
        'gui_OutputFcn',  @wave_equation_gui_OutputFcn, ...
        'gui_LayoutFcn',  [] , ...
        'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
    
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    % End initialization code - DO NOT EDIT
end

% --- Executes just before wave_equation_gui is made visible.
function wave_equation_gui_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to wave_equation_gui (see VARARGIN)
    
    %*****************************************************
    useCoder = true; %Change to not have coder appear as an option
    %*****************************************************
    
    % Choose default command line output for wave_equation_gui
    handles.output = hObject;
    gpuName = '--';
    try
        dev = gpuDevice();
        handles.device = dev;        
        gpuName = handles.device.Name;
    catch ME %#ok
        % Disable the GPU radio button
        set( handles.rbGPU, 'Enable', 'off' );
    end
    
    cpuName = cpuInfo();
    set ( handles.txtHardware, 'String', ...
        sprintf ( '[CPU: %s] [GPU: %s]', cpuName.Name, gpuName ) );
        
    
    if ( useCoder )
        coderAvail = false;
        % Check if the coder compiled file exists
        if ( exist('wave_equation_core_coder_mex', 'file' ) )
            coderAvail = true;
        else
            try
                disp ( 'Compiled version missing. Attempting to compile. This can take a minute.' );
                codegen ( 'wave_equation_core_coder.prj' );
                coderAvail = true;
            catch ME %#ok
                disp ( 'Error compiling. Do you have Coder installed and configured?' );
            end
        end
        if ( ~coderAvail )
            set ( handles.rbCoder, 'Enable', 'off' );
        end
    else
        set ( handles.rbCoder, 'Visible', 'off' ); %#ok
        set ( handles.txtKernel, 'Visible', 'off' );
        set ( handles.txtKernelName, 'Visible', 'off' );
    end
    
    % Initialize the camera
    try 
        handles.ia = setupCamera(true);
        %Add Camera as a mode
        modes = get( handles.popMode, 'String' );
        modes(end+1) = {'Camera'};
        set( handles.popMode, 'String', modes );
    catch ME %#ok
        % Do nothing.
    end
    
    % Initialize the grid.
    selected = get(handles.popGridSize,'Value');
    n = 2^(selected+7);
    setappdata( handles.axes1, 'n', n);
    handles.lBound = -25;
    handles.uBound = 25;
    initArea( handles );        
    
    %set ( handles.rbGPU, 'Value', true ); %Select GPU
    setappdata( handles.axes1, 'mode', 'CPU' );
    
    % Make sure we start with a reset.
    setappdata( handles.axes1, 'askToReset', true );
    
    %a = [jet(); [1 1 1]];
    %colormap( a );
    colormap( [mwColorMap(64); 1 1 1] );
    axis(handles.axes1, 'square');
    
    setappdata( handles.axes1, 'lastDragPos', [] );
    
    timerFcn([],[],handles ); % Call first iteration of the timer before we go visible.
    
    % Now create the timer object.
    handles.timer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.01, ...
        'TimerFcn', @(x,y)(timerFcn(x,y,handles)), 'StartDelay', 0.2, 'TasksToExecute', inf );
    
    % Update handles structure
    guidata(hObject, handles);
    
    start(handles.timer);
end

% Extract the name of the dot pattern from the selection box.
function [mode] = getModeName(handles)
    contents = cellstr(get(handles.popMode,'String'));
    mode = contents{get(handles.popMode,'Value')};
    mode = mode(mode~=13); %Hack to remove newlines that appear for some reason.
end

function u = placeDrop( u, x, y, strength, handles )
    [xGrid,yGrid] = meshgrid( ...
        linspace(handles.lBound, handles.uBound, size(u,2)), ...
        linspace(handles.lBound, handles.uBound, size(u,1)) );
    temp = 2*exp(-4.*((xGrid-x).^2+(yGrid-y).^2));
    temp(temp < 0.01) = 0; %Clamp to 0
    u = u + strength*temp;
end

function [u,ul,boundaries,scaleFactor,imageData] = initArea( handles )
    n = getappdata( handles.axes1, 'n' );
    
    [xGrid,yGrid] = meshgrid( ...
        linspace(handles.lBound, handles.uBound, n), ...
        linspace(handles.lBound, handles.uBound, n) );
    u = zeros(n, n);
    
    r2 = 0.7*0.7;  % Wave coeficient
    b = 0.002; % Dampening parameter
    
    % If we are doing random, make sure we start with one drop.
    if ( strcmp( getModeName(handles), 'Random' ) )
        u = placeDrop( u, ...
            rand(1)*48-24, ...
            rand(1)*48-24, ...
            0.1*(512/n)^1.5, handles );
        b = 0;
    end
    
    % Do the boundaries
    boundaries = ones(n, n);
    
    if ( strcmp( getModeName(handles), 'Camera' ) )
        if ( strcmp(handles.ia.Running,'off'))
            start(handles.ia);
        end
        b = 0.01; % Dampening parameter
    else
        if ( isfield(handles,'ia') && strcmp(handles.ia.Running,'on'))
            stop(handles.ia);
        end
        boundaries(xGrid<-6&xGrid>-7&yGrid>-15) = 0;
        boundaries(xGrid>6&xGrid<7&yGrid>-15) = 0;
    end
        
    ul = 0*u;
    
    scaleFactor = max(1,n/256);
    axis(handles.axes1, [0 n/scaleFactor 0 n/scaleFactor] );
    imageData = imagesc ( 0*u(1:scaleFactor:end,1:scaleFactor:end), ...
        'Parent', handles.axes1 );
    axis(handles.axes1,'off');
    axis(handles.axes1, 'square');
    
    setappdata( handles.axes1, 'r2', r2 );
    setappdata( handles.axes1, 'b', b );
end

% --- Outputs from this function are returned to the command line.
function varargout = wave_equation_gui_OutputFcn(hObject, eventdata, handles)
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Get default command line output from handles structure
    varargout{1} = handles.output;
end

% --- Executes on selection change in popGridSize.
function popGridSize_Callback(hObject, eventdata, handles)
    % hObject    handle to popGridSize (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns popGridSize contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from popGridSize
    setappdata( handles.axes1, 'GPUTime', [] );
    setappdata( handles.axes1, 'CPUTime', [] );
    
    selected = get(hObject,'Value');
    n = 2^(selected+7);
    setappdata( handles.axes1, 'n', n);
    setappdata( handles.axes1, 'askToReset', true );
    
end

% --- Executes during object creation, after setting all properties.
function popGridSize_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to popGridSize (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
end

% --- Executes on button press in btnReset.
function btnReset_Callback(hObject, eventdata, handles)
    % hObject    handle to btnReset (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    setappdata( handles.axes1, 'GPUTime', [] );
    setappdata( handles.axes1, 'CPUTime', [] );
    setappdata( handles.axes1, 'askToReset', true );
    
end

% --- Executes on button press in btnCompare.
function btnCompare_Callback(hObject, eventdata, handles)
    % hObject    handle to btnCompare (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    visdiff( 'wave_equation_core_gpu.m', 'wave_equation_core_cpu.m' );
end

% --- Executes on selection change in popMode.
function popMode_Callback(hObject, eventdata, handles)
    % hObject    handle to popMode (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Hints: contents = cellstr(get(hObject,'String')) returns popMode contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from popMode
    setappdata( handles.axes1, 'askToReset', true );
    modeName = getModeName(handles);
    if ( strcmp ( modeName, 'Interactive' ) )
        set ( handles.btnStartStop, 'Enable', 'off' );
    else
        set ( handles.btnStartStop, 'Enable', 'on' );
    end
    set ( handles.btnStartStop, 'String', 'Stop' );
    
    % If a camera has been detected.
    if ( isfield(handles,'ia') )        
        if ( strcmp ( modeName, 'Camera' ) )
            % If we enter camera mode, start the camera.        
            start(handles.ia);
        else
            % If we leave camera mode, stop the camera.      
            stop(handles.ia);
        end
    end
end

% --- Executes during object creation, after setting all properties.
function popMode_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to popMode (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    
    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    
end

function timerFcn(obj, event, handles )
    persistent u;
    persistent ul;
    persistent boundaries;
    persistent scaleFactor;
    persistent imageDataHandle;
    persistent framesSinceLastReset;
    persistent wave_kernel;
        
    if ( isempty(wave_kernel) )
        wave_kernel = [0 1 0; 1 -4 1; 0 1 0];    
    end
    
    r2 = getappdata(handles.axes1, 'r2' );
    b = getappdata(handles.axes1, 'b' );
    
    % If the start/stop button has the text start, then we should not run.
    if ( strcmp( get(handles.btnStartStop,'String'), 'Start' ) );
        return
    end
    
    askToReset = getappdata( handles.axes1, 'askToReset' );
    if ( askToReset )
        setappdata( handles.axes1, 'askToReset', false );
        [u,ul,boundaries,scaleFactor,imageDataHandle] = initArea(handles);
        framesSinceLastReset = 0;
    end
    framesSinceLastReset = framesSinceLastReset + 1;
    
    %Ask if we are to use GPU or CPU for computing.
    useGPU = getappdata( handles.axes1, 'useGPU' );
        
    try
        n = getappdata( handles.axes1, 'n' );
        
        useCamera = false;
        
        modeName = getModeName(handles);
        if ( strcmp( modeName, 'Random' ) && framesSinceLastReset > 1000*n/1024 )
            setappdata( handles.axes1, 'askToReset', true );
        elseif ( strcmp( modeName, 'Interactive' ) )
            cp = getappdata( handles.axes1, 'lastDragPos' );
            setappdata( handles.axes1, 'lastDragPos', [] );
            if ( ~isempty(cp) )
                u = placeDrop( u, ...
                    cp(1)/5-25, ...
                    cp(2)/5-25, ...
                    0.1*(512/n)^1.5, handles );
            end
        elseif ( strcmp( modeName, 'Camera' ) )
            imageDataRaw = getCameraImpulse(handles.ia,1,useGPU);            
            useCamera = true;
        end
        
        if ( isfield(handles,'device') )
            wait(handles.device); %Make sure no GPU tasks are trailing
        end
        
        if ( useCamera )
            impulse = prepCameraImpulse( imageDataRaw, size(u), useGPU );
            u = u + impulse;            
        end
        
        mode = getappdata( handles.axes1, 'mode' );
        if ( strcmp( mode, 'CPU' ) )            
            tic;
            [u,ul,wave_kernel,boundaries] = wave_equation_core_cpu( u, ul, boundaries, wave_kernel, r2, b );
            cpuTime = toc;
            setappdata( handles.axes1, 'CPUTime', cpuTime );
            set( handles.txtCPU, 'String', sprintf ( '%0.1f ms', cpuTime*1000) );
        elseif ( strcmp( mode, 'GPU' ) )            
            wait(handles.device);        
            tic;
            [u,ul,wave_kernel,boundaries] = wave_equation_core_gpu( u, ul, boundaries, wave_kernel, r2, b );
            wait(handles.device);                    
            gpuTime = toc;            
            cpuTime = getappdata( handles.axes1, 'CPUTime' );
            set( handles.txtGPU, 'String', sprintf ( '%0.1f ms %0.2fx', ...
                gpuTime*1000, cpuTime/gpuTime) );
        elseif ( strcmp( mode, 'Kernel' ) )            
            wait(handles.device);        
            tic;
            [u,ul,wave_kernel,boundaries] = wave_equation_core_kernel( u, ul, boundaries, wave_kernel, r2, b );
            wait(handles.device);                    
            kernelTime = toc;            
            cpuTime = getappdata( handles.axes1, 'CPUTime' );
            set( handles.txtKernel, 'String', sprintf ( '%0.1f ms %0.2fx', ...
                kernelTime*1000, cpuTime/kernelTime) );
        elseif ( strcmp( mode, 'Coder' ) )
            u = gather(u);
            ul = gather(ul);
            boundaries= gather(boundaries);
            wave_kernel = gather(wave_kernel);
            tic;
            [u,ul] = wave_equation_core_coder_mex( u, ul, boundaries, wave_kernel, r2, b );            
            coderTime = toc;            
            cpuTime = getappdata( handles.axes1, 'CPUTime' );
            set( handles.txtCoder, 'String', sprintf ( '%0.1f ms %0.2fx', ...
                coderTime*1000, cpuTime/coderTime) );
        end                                
                
        % Update the graph
        temp = gather(u); %Get the data back from the GPU
        temp(temp>0.1) = 0.1; %Cap all values to witin +-0.1
        temp(temp<-0.1) = -0.1;
        temp(boundaries==0) = 0.11; %Make the boundaries clearly visible.        
        temp = temp(1:scaleFactor:end,1:scaleFactor:end); %Limit the resolution.
        temp(1) = -0.11; %Make sure we span the entire color range.
        temp(2) = 0.11;
        set ( imageDataHandle, 'CData', temp );
                
        drawnow('update');
    catch ME
        disp ( 'Error detected in timer func:' );
        disp ( ME.message )
        disp ( ME.stack(1) );
    end
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    stop ( handles.timer );
    delete( handles.timer );
    if ( isfield(handles,'ia') )
        delete(handles.ia);
    end
    
    pause(0.1);
    
    % Hint: delete(hObject) closes the figure
    delete(hObject);
end


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    if ( ishandle(handles.axes1) )
        cp = get(handles.axes1,'CurrentPoint');
        cp = [cp(1,1) cp(1,2) now];
        setappdata( handles.axes1, 'lastDragPos', cp );
    end
end


% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    if ( ishandle(handles.axes1) )
        if ( ~isempty(getappdata( handles.axes1, 'lastDragPos' ) ) )
            cp = get(handles.axes1,'CurrentPoint');
            cp = [cp(1,1) cp(1,2) now];
            setappdata( handles.axes1, 'lastDragPos', cp );
        end
    end
end


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonUpFcn(hObject, eventdata, handles)
    % hObject    handle to figure1 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    %setappdata( handles.axes1, 'lastDragPos', [] );
end


% --- Executes when selected object is changed in uipanel1.
function uipanel1_SelectionChangeFcn(hObject, eventdata, handles)
    % hObject    handle to the selected object in uipanel1
    % eventdata  structure with the following fields (see UIBUTTONGROUP)
    %	EventName: string 'SelectionChanged' (read only)
    %	OldValue: handle of the previously selected object or empty if none was selected
    %	NewValue: handle of the currently selected object
    % handles    structure with handles and user data (see GUIDATA)
    
    if ( get( handles.rbCPU, 'Value') == 1 )
        setappdata( handles.axes1, 'mode', 'CPU' );        
    elseif ( get( handles.rbGPU, 'Value') == 1 )
        setappdata( handles.axes1, 'mode', 'GPU' );        
    elseif ( get( handles.rbKernel, 'Value') == 1 )
        setappdata( handles.axes1, 'mode', 'Kernel' );        
    elseif ( get( handles.rbCoder, 'Value') == 1 )
        setappdata( handles.axes1, 'mode', 'Coder' );        
    end
    
end


% --- Executes on button press in btnStartStop.
function btnStartStop_Callback(hObject, eventdata, handles)
    % hObject    handle to btnStartStop (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Change the title on the button
    currentText = get( handles.btnStartStop, 'String' );
    if ( strcmp( currentText, 'Stop' ) )
        set( handles.btnStartStop, 'String', 'Start' );
    else
        set( handles.btnStartStop, 'String', 'Stop' );
    end
end
