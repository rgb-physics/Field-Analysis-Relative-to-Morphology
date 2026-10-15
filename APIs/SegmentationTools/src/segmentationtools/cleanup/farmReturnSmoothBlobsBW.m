function outBounds = farmReturnSmoothBlobsBW(ogBW, layerMean, layerWidth, gKern)
%FARMRETURNSMOOTHBLOBSBW Historical signed-distance cleanup for binary masks.
%   INPUT must have isotropic voxels: layerMean, layerWidth, and Gaussian
%   sigma are all in those voxel units. The historical operation returns
%   samples below layerMean + abs(layerWidth); 

signedDist = farmSignedBWDist(ogBW);
layerWidth = abs(layerWidth);
if size(ogBW,3) > 1
    smDist = imgaussfilt3(signedDist, gKern);
else
    smDist = imgaussfilt(signedDist, gKern);
end
outBounds = smDist < (layerMean + layerWidth);
end
