function [outMat] = farmMesh2mat(verts,matDims)
%FARMMESH2MAT Takes in verts, a matrix of vertices corresponding to the
%coordinates of vertices, and matDims, the desired dimension of the output
%matrix (can be left undefined). Returns a matrix with vertices shifted
%approximately indices. Useful for visualization, but should be used with
%caution for computations

% Define dimensions of output matrix if undefined
if nargin == 1
    matDims = ceil(max(verts)) - floor(min(verts));
    verts = verts - min(verts) + 1;
end

% Constrain vertices to mat boundaries
matCoords = round(farmConfineMeshInMat(verts,matDims));
% % Convert vertices to matrix coordinates, removing points outside of the
% % bounds of a matrix given
% matCoords = round(verts);
% for currDim = 1:numel(size(matDims))
%     matCoords(:,currDim) = max(min(matCoords(:,currDim),matDims(currDim)),0);
% end
% matCoords = matCoords(min(matCoords,[],2) >= 1, :);

% Get matrix indices
if numel(matDims) == 3
    matInds = sub2ind(matDims, matCoords(:,1), matCoords(:,2), matCoords(:,3));
elseif numel(matDims) == 2
    matInds = sub2ind(matDims, matCoords(:,1), matCoords(:,2));
end

% Define output matrix
outMat = zeros(matDims);
outMat(matInds) = 1;

end

