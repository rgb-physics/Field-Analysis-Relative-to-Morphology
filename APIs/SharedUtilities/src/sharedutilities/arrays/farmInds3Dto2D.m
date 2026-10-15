function [outInds] = farmInds3Dto2D(inInds, size3D)
%FARMINDS3DTO2D Take in indices corresponding to coordinates in a 3D matrix,
%return indices corresponding to coordinates in a 2D matrix with same
%number of rows and columns
% 2025-05-06 - Rémi Boros

[rowMat, colMat, ~] = ind2sub(size3D, inInds);
outInds = sub2ind(size3D(1:2),rowMat,colMat);

end

