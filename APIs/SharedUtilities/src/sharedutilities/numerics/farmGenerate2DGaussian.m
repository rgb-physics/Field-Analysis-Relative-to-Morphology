function gaussMat = farmGenerate2DGaussian(gsize, xc, yc, sigmax, sigmay)
%FARMGENERATE2DGAUSSIAN Evaluate the historical sampled 2D Gaussian.
% Inputs:
%   gsize           Side length of the square output image.
%   xc              Gaussian center along X.
%   yc              Gaussian center along Y.
%   sigmax          Gaussian standard deviation along X.
%   sigmay          Gaussian standard deviation along Y.
% Outputs:
%   gaussMat        Sampled 2D Gaussian array.

xbegin = -round(gsize / 2);
ybegin = -round(gsize / 2);
x = (xbegin + 1:1:xbegin + gsize);
y = (ybegin + 1:1:ybegin + gsize);

% Generate x,y matrix
[xm, ym] = meshgrid((x - xc), (y - yc));

%% calculating guassian
u = (xm / sigmax).^2 + (ym / sigmay).^2;
gaussMat = exp(-u / 2);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Uses centered coordinate vectors and meshgrid to evaluate
% exp(-((x - xc).^2 / sigmax^2 + (y - yc).^2 / sigmay^2) / 2).
% The sampled array is not normalized to unit sum.
