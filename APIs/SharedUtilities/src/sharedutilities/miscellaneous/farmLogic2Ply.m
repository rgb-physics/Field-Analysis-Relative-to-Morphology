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

% Keep historical one-based XYZ scaling (including the first voxel).
% 2-D supports export at z=0; PLY always requires three coordinate columns.
validateattributes(scaleMat,{'numeric'},{'real','finite','positive','vector'});
scaleMat = double(scaleMat(:).');
if isscalar(scaleMat), scaleMat = repmat(scaleMat,1,3); end
if ismatrix(logicMat)
    if numel(scaleMat)==2, scaleMat(3)=1; end
elseif numel(scaleMat)~=3
    error('sharedutilities:PLYScale','Use XYZ scale factors (XY also accepted for 2-D).');
end
if numel(scaleMat)~=3
    error('sharedutilities:PLYScale','Use two or three scale factors for 2-D, three for 3-D.');
end
vertices = farmMaskToPoints(logicMat);
if ismatrix(logicMat), vertices(:,3)=0; end
farmWritePointPly(saveDir,vertices.*scaleMat);

end

