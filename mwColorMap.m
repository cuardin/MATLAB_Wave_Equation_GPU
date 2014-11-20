% Copyright 2013-2014 The MathWorks, Inc.
function [ colormap ] = mwColorMap( nElements )
    
    
    midPoint = round(nElements/2);
    mwBlue = [18 86 135]/256;
	%mwGray = [85 85 85]/256;
	mwOrange = [210 120 0]/210;
    
    gamma = 1;
    gammaCurve = 1-(linspace(1,0,midPoint)).^gamma;
    gammaCurve2 = -gammaCurve(end:-1:1);
    %plot ( [gammaCurve2 gammaCurve] );
    
    colormap = [bsxfun(@times,-gammaCurve2',mwBlue); ...
        bsxfun(@times,gammaCurve',mwOrange)];
    %rgbplot( colormap );
    
    
	
    
end

