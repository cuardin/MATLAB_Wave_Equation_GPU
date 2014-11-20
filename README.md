=Wave equation flashy demo

This folder contains two demos that use the wave equation. For 
troubleshooting, see further down.

==Requirements:
MATLAB

===Recommended:
Parallel Computing Toolbox + supported GPU
Image Acquisition Toolbox with the OS Generic Video Interface hadware 
support package + Webcam.
MATLAB Coder

==standalone_script.m
This file runs the wave equation continuously with motion captured by a 
webcamera as input. Experience shows that it workes best when people are 
about 3-7m away from the camera.

This file is intended to run on a computer with a webcamera and a GPU with
at least the power of a C2050. The code is very simple and contains no 
error check other than that it crashes if the conditions are not met.

Start it, run it in full-screen, leave it.

==wave_equation_gui.m
This is a fully featured UI with several modes that can run both on CPU 
and GPU. The program detectes the processor and GPU models used and give 
speedup figures. If there is an error connecting to the webcamera (or none 
exists) that option is not made availible. Same with GPU.

In addition to the camera mode, there is a random mode that handles itself, 
and an interactive mode that is fun to play with.

Modern CPUs tend to run best at 512x512 resolution. Fermi Teslas at 1024. 
The wave equation parameters are optimized for these resolutions as well.

==Troubleshooting:

* If there is an error with the camera or no camera option appears in the 
UI, edit setupCamera.m as needed to return a videoinput object that produces 
grayscale images.

* If the wave pattern keeps getting excited, even when there is no movement
in the image whhen in Camera mode, open prepCameraImpulse.m and raise the 
value of noiseThreshold.

* If there is no response in Camera mode even when you wave your arms 
around, open prepCameraImpulse.m. First lower the noiseThreshold to 0. 
Check if there is an improvement. Otherwise, increase the scaleFactor.

Copyright 2013-2014 The MathWorks, Inc.