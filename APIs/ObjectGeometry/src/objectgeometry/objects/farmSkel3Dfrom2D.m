function [orMat,andMat] = farmSkel3Dfrom2D(inputMat)
%FARMSKEL3DFROM2D Takes in a binarized 3D matrix and returns skeletonizations
%derived from 2D reslices of the matrix in xz and yz. The union of these
%skeletonizations is returned as "orMat" and the intersection as "andMat"

matDims = size(inputMat);
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

end

