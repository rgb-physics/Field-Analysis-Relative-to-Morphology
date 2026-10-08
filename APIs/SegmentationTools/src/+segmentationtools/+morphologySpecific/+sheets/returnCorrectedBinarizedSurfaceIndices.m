function [newInds,holeLocVec] = returnCorrectedBinarizedSurfaceIndices(surfaceInds,imgSize)
%RETURNCORRECTEDSURFACE Takes in the indices corresponding to the surface
%of an object (point cloud) and returns the indices of any holes in said
%surface, calculated using scattered interpolant objects. A hole is defined
%as a location where the the surface location corresponds to a value of 0.
% Rémi Boros

% Get indices of surface with zero and non-zero values
[nonZeroX, nonZeroY] = find(surfaceInds ~= 0);
[x2D, y2D] = ndgrid(1:size(surfaceInds,1), 1:size(surfaceInds,2));
noHoleBoolean = numel(nonZeroX) == numel(surfaceInds);
%Skip if there are no holes
if noHoleBoolean
    newSurface = surfaceInds;
else
    [zeroX, zeroY] = find(surfaceInds == 0);
    %Find interpolated values in holes
    ogZ = surfaceInds(surfaceInds~=0);
    sctIntObj = scatteredInterpolant(nonZeroX, nonZeroY, ogZ);
    filledZ = round(sctIntObj(zeroX, zeroY));
    filledInds = sub2ind(size(surfaceInds), zeroX, zeroY);
    %Generate corrected surfaces using scattered interpolant objects
    newSurface = surfaceInds;
    newSurface(filledInds) = filledZ;

end

%Get indices
newInds = sub2ind(imgSize, x2D(:), y2D(:), newSurface(:));

%Locate holes
if noHoleBoolean
    holeLocVec = false(numel(newInds),1);
else
    filledInds3D = sub2ind(imgSize, zeroX, zeroY, filledZ);
    holeLocVec = ismember(newInds,filledInds3D);
end


end

