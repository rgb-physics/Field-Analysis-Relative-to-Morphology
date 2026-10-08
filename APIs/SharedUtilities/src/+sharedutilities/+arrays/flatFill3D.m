function [outMat] = flatFill3D(inMat,dimFills)
%FLATFILL3D Takes in a binarized 3D tiff inMat and fills in holes along the
%requested dimensions dimFills: 0 corresponds to xy, 1 corresponds to yz, 2
%corresponds to xz. dimFills can be a vector of these values.
% 2026-04-27 - Rémi Boros

% Define connectivity kernel
flatCon = zeros(3,3,3);
flatCon(:,:,2) = conndef(2,'minimal');
flatCon = logical(flatCon);
% Define permutation vector
permVec = 1:3;

% Iterate over dimensions to fill
outMat = double(inMat);
for index = dimFills
    currKernel = permute(flatCon,circshift(permVec,index));
    currFill = imfill(double(inMat),currKernel);
    outMat = outMat + currFill;
end

% Convert output back to logical
outMat = logical(outMat);

end

