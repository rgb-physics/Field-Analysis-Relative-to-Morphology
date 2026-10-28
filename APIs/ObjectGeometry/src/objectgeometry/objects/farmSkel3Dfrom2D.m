function [orMat,andMat] = farmSkel3Dfrom2D(inputMat, preferredAxis)
%FARMSKEL3DFROM2D Takes in a binarized 3D matrix and returns skeletonizations
%derived from 2D reslices of the matrix in xz and yz. The union of these
%skeletonizations is returned as "orMat" and the intersection as "andMat"
% preferredAxis is 'Z' (default), 'X', or 'Y', the approximate thin axis.
% Preserves the historical flattened-reslice calculation, including adjacency
% between flattened sections. This is not independent per-section thinning.

if nargin < 2, preferredAxis = 'Z'; end
preferredAxis = validatestring(preferredAxis, {'X','Y','Z'});
validateattributes(inputMat, {'logical','numeric'}, {'real','nonempty','nonsparse'});
if ndims(inputMat) > 3 || any(inputMat(:) ~= 0 & inputMat(:) ~= 1)
    error('objectgeometry:InvalidMask', 'Provide one binary YXZ volume.');
end
axisDim = find('YXZ' == preferredAxis);
order = [setdiff(1:3, axisDim, 'stable'), axisDim];
inputMat = permute(logical(inputMat), order);

matDims = [size(inputMat,1), size(inputMat,2), size(inputMat,3)];
% Skeletonization along resliced xz
reshaped1 = reshape(inputMat,[matDims(1)*matDims(2) matDims(3)]);
temp = bwskel(reshaped1);
unshaped1 = reshape(temp,matDims);
% Skeletonization along resliced yz
reshaped2 = reshape(permute(inputMat,[2 1 3]),[matDims(1)*matDims(2) matDims(3)]);
temp = bwskel(reshaped2);
unshaped2 = permute(reshape(temp,[matDims(2) matDims(1) matDims(3)]),[2 1 3]);
% Get union and intersection of both skeletonizations
orMat = unshaped1 | unshaped2;
andMat = unshaped1 & unshaped2;
orMat = ipermute(orMat, order);
andMat = ipermute(andMat, order);

end

