function [outInds] = farmGenLineInds2D(matSize, cutInd, cutDim, lineStart, lineEnd)
%FARMGENLINEINDS2D Takes in the dimensions of a 2D matrix, an index
% Inputs:
%   matSize         Matrix dimensions in array-axis order.
%   cutInd          One-based location of the requested grid line.
%   cutDim          Historical X/Y selector for the grid line.
%   lineStart       Optional first location along the orthogonal dimension.
%   lineEnd         Optional last location along the orthogonal dimension.
% Outputs:
%   outInds         Linear indices along the requested grid line.

% Generate lineStart and lineEnd if not passed
if nargin < 4
    lineStart = 1;
end
if nargin < 5
    lineEnd = matSize(cutDim);
end

% Generate vector of indices along which to cut
if lineStart > lineEnd
    indVec = lineStart:-1:lineEnd;
else
    indVec = lineStart:lineEnd;
end

% Generate matrix of indices
indMat = reshape(1:prod(matSize), matSize);

% Access matrix and return valid indices
if cutDim == 1
    outInds = indMat(indVec, cutInd);
elseif cutDim == 2
    outInds = indMat(cutInd, indVec);
else
    outInds = [];
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGENLINEINDS2D Takes in the dimensions of a 2D matrix, an index
% corresponding to the desired line, and a number corresponding to x (1)
% or y (2). Optionally, the user can enter integers lineStart and
% lineEnd, corresponding to indices in the orthogonal direction to bound the
% lnie segment.
% Rémi Boros, 07/19/2023
