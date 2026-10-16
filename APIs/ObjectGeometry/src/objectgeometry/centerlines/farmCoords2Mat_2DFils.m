function [filMat, filamentInds, validLogic] = farmCoords2Mat_2DFils(currFils, initBoxDims, outMatSideLen)
%FARMCOORDS2MAT_2DFILS Rasterize endpoint-defined filaments on a scaled 3D grid.
% Inputs:
%   currFils        MATLAB table with 3D endpoint coordinates in columns 4:9.
%   initBoxDims     Original spatial box dimensions.
%   outMatSideLen   Requested output matrix side length.
% Outputs:
%   filMat          Matrix containing rasterized filament IDs.
%   filamentInds    Rasterized filament locations.
%   validLogic      Selection flags for unique filament samples.

% 2025-06-20, Rémi Boros
% adapted from aLENS reading code dat2Mat_Fils.m

% Instantiate out matrix and scale factors
scaleFactor = outMatSideLen / initBoxDims(1);
zScale = initBoxDims(:, 3) / initBoxDims(:, 1);
scaledMatSize = [outMatSideLen, outMatSideLen, round(outMatSideLen * zScale)];
% Count filaments
numFils = size(currFils, 1);

% Filament lengths, CoMs, and vector lengths
mtCoords = table2array(currFils(:, 4:9));
mtVecs = zeros(numFils, 3);
for currDim = 1:3
    mtVecs(:, currDim) = mtCoords(:, 3 + currDim) - mtCoords(:, currDim);
end
mtLens = sqrt(sum(mtVecs.^2, 2));

% Store coordinates of all filaments for scaled matrix (i,j,k)
scaledCoords = (mtCoords) * scaleFactor;
scaledLens = mtLens * scaleFactor;
allCoords = -ones(numFils, ceil(max(scaledLens)), 3);
for currFil = 1:numel(mtLens)
    currCoords = zeros(round(scaledLens(currFil)), 3);
    for currDim = 1:3
        currCoords(:, currDim) = linspace(scaledCoords(currFil, currDim), scaledCoords(currFil, currDim + 3), round(scaledLens(currFil)));
        % Bound coords to positive definite values
        currCoords(:, currDim) = min(scaledMatSize(currDim), farmMod1b(currCoords(:, currDim), scaledMatSize(currDim)));
    end
    keptCoords = unique(round(currCoords), 'rows');
    numKept = size(keptCoords, 1);
    allCoords(currFil, 1:numKept, :) = keptCoords;
end

% Get indices from non-degenerate coordinates (indices)
cSizes = size(allCoords);
coordVecs = reshape(allCoords, prod(cSizes(1:2)), cSizes(3));
nondegenVecs = coordVecs(coordVecs(:, 1) > -1, :);
filamentInds = sub2ind(scaledMatSize, nondegenVecs(:, 1), nondegenVecs(:, 2), nondegenVecs(:, 3));
% Get indices of non-degenerate filament vectors
validLogic = allCoords(:, :, 1) > -1;

% % Assign filament IDs to out matrix
[filMat, filamentInds, validLogic] = farmFieldOnObjs(1:numFils, scaledMatSize, filamentInds, validLogic);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Despite its name, this implementation uses three-dimensional endpoints
% from table columns 4:9. Coordinates are scaled, wrapped, rounded and
% deduplicated before calling farmFieldOnObjs to assign filament IDs.
