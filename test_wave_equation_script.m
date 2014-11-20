%%
% Copyright 2013-2014 The MathWorks, Inc.
clear;
close all;
%%
u = zeros(256);
ul = zeros(256);
boundaries = ones(256);

u(10,10) = 1;
u = imfilter(u,fspecial('gaussian',10,2));
wave_equation_core_cpu(0.5,0.0001);

%%
for i = 1:100;
    [u,ul,boundaries] = wave_equation_core_cpu(u,ul,boundaries);
    ut = u;
    ut(1) = 0.01;
    imagesc( ut );
    drawnow;
end