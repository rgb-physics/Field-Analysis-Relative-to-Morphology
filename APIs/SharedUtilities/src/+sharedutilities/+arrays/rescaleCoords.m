function [outCoords] = rescaleCoords(inCoords,ogDims,newDims)
%RESCALECOORDS Takes in matrix coordinates in a matrix with size ogDims and
%returns nearest corresponding coordinates in a matrix with size newDims.
% inCoords is an NxD matrix for N coordinates in D dimensions. ogDims are
% 1xD vectors each; inCoords are passed as (x,y,z), so must be converted to
% (row, col, depth) before scaling.
% 2025-04-17 - Rémi Boros

dimScale = newDims./ogDims;
tempCoords = inCoords;
tempCoords(:,1:2) = tempCoords(:,[2 1]);
outCoords = round(tempCoords.*dimScale);
outCoords(:,1:2) = outCoords(:,[2 1]);

end

