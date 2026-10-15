function [subCoords] = farmConfineMeshInMat(matCoords,matDims)
%FARMCONFINEMESHINMAT Takes in an NxM array corresponding to N
%vertices/coordinates embedded in M-space, along with a vector of length M
%corresponding to the desired matrix dimensions. This function returns an
%LxM array containing all coordinates confined within the bounded matrix.
%It is assumed that the units in the original NxM array are in unit
%indices; i.e. a row [5 3 -11] would be stored in the index (5,3,-11) in a
%matrix with the given dimensions. The top left corner of the matrix is
%assumed to be [1 1 1]

% Generate max and min matrices for comparison
maxMat = repmat(matDims, [size(matCoords,1), 1]);
minMat = ones(size(maxMat));
% Get indices of rows with components out of bounds
invLogicMat = min((matCoords > maxMat) | (matCoords < minMat), [], 2);
% Store and return subset of valid rows
subCoords = matCoords(~invLogicMat, :);

end

