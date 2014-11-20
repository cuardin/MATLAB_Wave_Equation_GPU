% Copyright 2013-2014 The MathWorks, Inc.
function [ u, ul] = wave_equation_core_coder( u, ul, boundaries, wave_kernel, r2, b )
    %WAVE_EQUATION_FUNCTION Do one step in the wave equation
    
    %Run 10 iterations of the wave equation.
    for i = 1:10
        %Propagate the wave one step.
        n = 2*u - ul + r2*conv2(u,wave_kernel,'same') - b*(u-ul);

        %Apply the boundary conditions
        n = n.*boundaries;

        % Set the edges to 0
        n([1 end],:) = 0;
        n(:,[1 end]) = 0;
        
        %Update the pointers.
        ul = u;
        u = n;
    end
end


