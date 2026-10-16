function gaussMat = farmGenerate1DGaussian(gsize, xc, sigmax)
%FARMGENERATE1DGAUSSIAN Evaluate the historical sampled 1D Gaussian.
% Inputs:
%   gsize           Number of samples on the one-dimensional grid.
%   xc              Gaussian center along X.
%   sigmax          Gaussian standard deviation along X.
% Outputs:
%   gaussMat        Sampled 1D Gaussian array.

% Define x,y vectors for matrix boundaries
xbegin = -round(gsize / 2);
x = (xbegin + 1:1:xbegin + gsize);
xm = x - xc;

%% calculating guassian
u = (xm / sigmax).^2;
gaussMat = exp(-u / 2);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Samples x = -round(gsize / 2) + (1:gsize) and returns
% exp(-((x - xc) / sigmax).^2 / 2). This is not a normalized density.
