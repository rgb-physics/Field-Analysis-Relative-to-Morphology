function [currentSurface] = farmRescalePatch(currentSurface,rescaleFactor)
%FARMRESCALEPATCH Takes in logical matrix corresponding to 1s where there is
%material and 0s where there is not. Returns patched version of said matrix
%wherein holes* are filled with a quick and dirty value calculated from a
%scaled down version of the original object. Not suitable for large holes,
%but faster than scattered interpolation.
% 2024-08-28 Rémi Boros

% Clean up and instantiation
if nargin == 1
    rescaleFactor = 8;
end
imgSize = size(currentSurface);
[~,~,depthGrid] = ndgrid(1:imgSize(1),1:imgSize(2),1:imgSize(3));

% Find locations in xy plane with no patch anywhere in z
holeCheck = sum(currentSurface,3);
patchInds = find(holeCheck == 0);
[patchrows,patchcols] = ind2sub(size(holeCheck),patchInds);
% Map object to z coordinates at each index = 1
patchZs = farmConsMatLnB(depthGrid,currentSurface);
% Approximate z value for each x-y
scaledAvgHeights = sum(patchZs,3)./sum(currentSurface,3);
scaledAvgHeights(patchInds) = 0;
% downscale z-value matrix to smooth over holes, the re-upscale
tempScaled = imresize(scaledAvgHeights,round(imgSize(1:2)/rescaleFactor));
tempScaled = imresize(tempScaled,imgSize(1:2));
% Sample smoothed matrix, then find replacement z-coordinates in holes
scaledAvgHeights(patchInds) = round(tempScaled(patchInds));
% Get appropriate coordinates in 3-space to patch, then replace
replaceInds = sub2ind(size(currentSurface),patchrows(:),patchcols(:),scaledAvgHeights(patchInds));
currentSurface(replaceInds) = 1;

end

