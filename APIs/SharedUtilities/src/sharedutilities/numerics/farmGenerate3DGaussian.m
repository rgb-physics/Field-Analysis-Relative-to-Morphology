function gaussMat = farmGenerate3DGaussian(gsize, centers, sigmas, coordMode)
%FARMGENERATE3DGAUSSIAN Evaluate a 3D Gaussian in the selected coordinate convention.
% Inputs:
%   gsize           Coordinate counts [NX NY NZ]; output is NY-by-NX-by-NZ.
%   centers         Gaussian center coordinates.
%   sigmas          Gaussian standard deviations.
%   coordMode       Historical coordinate-origin and Y-direction selector.
% Outputs:
%   gaussMat        Sampled 3D Gaussian in the selected coordinate convention.

% Do some cleanup
if numel(sigmas) < numel(centers)
    sigmas = repmat(sigmas(1), numel(centers), 1);
end

% Generate matrix boundaries and vectors
if coordMode == 0
    xiBegin = -round(gsize / 2);
elseif coordMode == 1
    xiBegin = [0 0 0];
elseif coordMode == 2
    xiBegin = [0 gsize(2) 0];
end
% Define length of array along each dimension
xiVec = xiBegin(1) + 1:xiBegin(1) + gsize(1);
yiVec = xiBegin(2) + 1:xiBegin(2) + gsize(2);
ziVec = xiBegin(3) + 1:xiBegin(3) + gsize(3);
% Flip y if mode 2
if coordMode == 2
    yiVec = flip(yiVec);
end

% Generate matrix
[xm, ym, zm] = meshgrid(xiVec - centers(1), ...
                        yiVec - centers(2), ziVec - centers(3));

%% calculating guassian
u = (xm / sigmas(1)).^2 + (ym / sigmas(2)).^2 + (zm / sigmas(3)).^2;
gaussMat = exp(-u / 2);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Uses meshgrid with the supplied XYZ coordinate counts.
% Mode 0 uses centered coordinate ranges; mode 1 uses 1:N ranges.
% Mode 2 uses flipped Y values gsize(2) + (1:gsize(2)); it does not
% merely reverse 1:gsize(2). The historical offsets are preserved.
% The sampled Gaussian is not normalized to unit sum.
