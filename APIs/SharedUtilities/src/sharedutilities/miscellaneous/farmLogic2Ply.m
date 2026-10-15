function [] = farmLogic2Ply(logicMat,saveDir,scaleMat)
%FARMLOGIC2PLY Takes in a logical matrix and saves a ply object of vertices at
%logical 1 indices. saveDir must include the desired save name, as well as
%the directory in which to save. ScaleMat is an optional vector of scalars
%used to scale each dimension of vertices
% NOTE: rows and columns in an image correspond to y and x, respectively.
% These are manually flipped below

% Define scale matrix by default if not passed
if nargin == 2
    scaleMat = [1 1 1];
end

% Define vertices for 2D or 3D meshes
if numel(size(logicMat)) == 2
    [rows, cols] = ind2sub(size(logicMat), find(logicMat ~= 0));
    vertices = [cols, rows];
else
    [rows, cols, depths] = ind2sub(size(logicMat), find(logicMat ~= 0));
    vertices = [cols, rows, depths];
end
faces = [];

% write ply, from tubular package (Noah Mitchell)
plywrite(saveDir, faces, vertices.*scaleMat);

end

