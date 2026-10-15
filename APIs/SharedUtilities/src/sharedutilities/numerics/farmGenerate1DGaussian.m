function gaussMat = farmGenerate1DGaussian(gsize, xc, sigmax)
 %GENERATE2DGAUSSIAN Takes in matrix size GSIZE and gaussian parameters and
 %returns a 2D gaussian centered at XC, YC with width sigmax, sigmay for x
 %and y, respectively.

    % Define x,y vectors for matrix boundaries
    xbegin = -round(gsize / 2);
    x = (xbegin+1:1:xbegin+gsize);
    xm = x-xc;
    
    %%calculating guassian
    u = (xm/sigmax).^2;
    gaussMat = exp(-u/2);
    
end
