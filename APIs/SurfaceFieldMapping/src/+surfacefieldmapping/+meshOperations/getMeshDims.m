function [objInfo] = getMeshDims(meshObj, pixDim, flipNorms)
%GETMESHDIMS This function takes in a structure MESH with Nx3 f and Mx3 v
%fields containing face pointers and vertex coordinates,respectively.
%PIXDIMS is an optional scalar denoting the size of each voxel in units of 
%length/pixel. The mesh must be defined wrt isotropic voxels or else
%surface are will not be accurately returned.
%FLIPNORMS is a boolean denoting whether or not to flip the face normals of
%the mesh.
%The function returns a structure OBJINFO containing 
%           - Volume
%           - Surface Area
%           - Total number of bodies located
%           - Euler Characteristic
%           - Boolean value denoting whether or not the mesh is manifold
%           - Boolean value denoting whether or not the mesh borders bounds
%           - Size of pixels
%           - Centroid coordinates (CoM)

% External dependencies:
%       gut_matlab by Noah P. Mitchell and Dillon Cislo https://github.com/npmitchell/gut_matlab
%       inpolyhedron https://www.mathworks.com/matlabcentral/fileexchange/37856-inpolyhedron-are-points-inside-a-triangulated-volume
% By Rémi Boros, 01-19-2022

%% Define pixDims, if necessary
if nargin == 1
    pixDim = 1;
    flipNorms = 0;
elseif nargin == 2
    flipNorms = 0;
end

%% Generate meshgrid data
[xmin] = min(meshObj.v);
[xmax] = max(meshObj.v);

[rowMat, colMat, zMat] = meshgrid(xmin(1):xmax(1), xmin(2):xmax(2), xmin(3):xmax(3));
XYZ = [rowMat(:) colMat(:) zMat(:)];

%% Check surface content
meshObj.vertices = meshObj.v; meshObj.faces = meshObj.f;
contentVec = inpolyhedron(meshObj, XYZ, 'flipNormals',flipNorms);
logicMat = reshape(contentVec, size(rowMat));
% orthosliceViewer(logicMat);

%% Get volume and surface info
[objInfo] = regionprops3( bwconncomp(logicMat),'SurfaceArea','Volume','Centroid');
objInfo.SurfaceArea = objInfo.SurfaceArea*pixDim^2;
objInfo.Volume      = objInfo.Volume*pixDim^3;

%Shift Centroid
objInfo.Centroid = objInfo.Centroid + xmin;

%Scale and store volume and surface area
if numel(objInfo) > 2
    surfAreas = objInfo.SurfaceArea;
    vols =      objInfo.Volume;
    objInfo(2:end,:) = [];
    objInfo.SurfaceArea = sum(surfAreas);
    objInfo.Volume      = sum(vols);
    objInfo.bodies      = numel(vols);
else
    objInfo.bodies = 1;
end
    
%% Store other object info
objInfo.ec = eulerCharacteristic(meshObj);
[objInfo.maniB,objInfo.borderB] = isManifoldMesh(meshObj.v, meshObj.f);
objInfo.pixDim = pixDim;

end

