function [selectDataOut,newSurfInds,holeIndVec] = consPatchedSheetSurface_Flat(rawData,selectDataIn,surfPerim)
%CONSPATCHEDSHEETSURFACE_FLAT Takes in a matrix of 3D raw data and a 2D 
%matrix corresponding to a perimeter of a sheet in the raw data. This
%function returns interpolated values at points where surfPerim is zero. It
%is assumed that in some representation, dimensions 1 and 2 are inputs
%while the surface perimeter was taken with respect to dimension 3.
% Rémi Boros

selectDataOut = consMatLnB(rawData,selectDataIn);
%Get indices and interpolated values of holes in outer boundary
[newSurfInds, holeIndVec] = returnCorrectedBinarizedSurfaceIndices(surfPerim, size(rawData));
%Patch holes and return Z value nearest sample center for each (x,y) that's
%a part of the thresholded surface/layer
if sum(holeIndVec) > 0
    [ogX, ogY, ogZ] = ind2sub(size(rawData), newSurfInds(~holeIndVec));
    [patchX, patchY, patchZ] = ind2sub(size(rawData), newSurfInds(holeIndVec));
    %Use a scattered interpolant object to fill holes in our surface
    holeFiller = scatteredInterpolant(ogX,ogY,ogZ,double(rawData(newSurfInds(~holeIndVec))));
    holeIntVals = holeFiller(patchX, patchY, patchZ);
    selectDataOut(newSurfInds(holeIndVec)) = abs(holeIntVals);
end

end

