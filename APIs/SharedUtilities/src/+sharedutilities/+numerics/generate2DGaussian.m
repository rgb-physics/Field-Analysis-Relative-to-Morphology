function gaussMat = generate2DGaussian(gsize, xc, yc, sigmax, sigmay)
 %GENERATE2DGAUSSIAN Takes in matrix size GSIZE and gaussian parameters and
 %returns a 2D gaussian centered at XC, YC with width sigmax, sigmay for x
 %and y, respectively.

    % Define x,y vectors for matrix boundaries
    xbegin  = -round(gsize / 2);
    ybegin  = -round(gsize / 2);
    x = (xbegin+1:1:xbegin+gsize);
    y = (ybegin+1:1:ybegin+gsize);

    % Generate x,y matrix
    [xm, ym] = meshgrid( (x-xc), (y-yc) );
    
    %%calculating guassian
    u  = (xm/sigmax).^2 + (ym/sigmay).^2;
    gaussMat = exp(-u/2);
    
end
