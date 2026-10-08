%% Messy first take of a script to convert drop segmentations to meshes
% The script takes in segmented .h5s (be sure to note which channel(s) 
% object probabilities is/are stored in), skeletonizes the surfaces by
% tiling cross sections of the thresholded probability field, and generates
% a point cloud. 
% The script  sends this point cloud to meshlab to undergo poisson disk
% elimination to reduce complexity of the object and normalize the spacing
% of vertices (especially useful if vertices are not isotropically  
% distributed in 3D, eg. 1x1x4 voxels). The meshlab script will also 
% calculate vertex normals. It is recommended to scale vertices before this
% stage such that voxel spacing is uniform.
% This info is saved in a new .ply object and passed back to MATLAB to
% enforce the direction of the norms. Norms are enforced in the following
% way: 
% First, the scaling of vertices is reversed to send coordinates back
% to original image coordinate space. Second, the distance transform of the
% thresholded probability field is taken to define a gradient in objects
% denoting distance to their exteriors. Finally, vertex normals are
% projected along this gradient sampled at each vertex. The vertex normals
% are flipped based on the sign of this projection. A new .ply object is
% saved with the corrected vertex normals and rescaled vertices.
% The new .ply is sent back to Meshlab, where it undergoes Poisson surface
% reconstruction to define mesh faces. 
% 10/10/2023
%% Data info
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 45, Exp 3';
segDir = fullfile(baseDir,'7 Ilastik Training\Second Pass - 2');
segName = 'PassOne_t%03i_16bitSubSamp_Probabilities.h5';
ptDir = fullfile(baseDir, '10 Point Clouds');       mkdir(ptDir);
ptDirInterm = fullfile(ptDir, 'Temp');              mkdir(ptDirInterm);
meshDir = fullfile(baseDir, '11 Mesh Objects');     mkdir(meshDir);
ptName = 'Time%03i_pointCloud.ply';
meshName = 'Time%03i_meshObjs.ply';
% meshLabDir = '<redacted original absolute path>';
meshLabDir = '';
vertFiltScript = 'batch_pcReduceFindNorms.py'; 
makeMeshScript = 'batch_pc2Mesh.py';

% Variable info
timeRange = 1:20;
chanNums = [2 3];
h5String = '/exported_data';
probThresh = .6;
scaleMat = [.37 .37 1.5];      %In um/pixel in [x,y,z]
normalSign = -1;    % -1 for positive curvature spheres to be hedgehogs

% Erosion info - "dig" into object to define skeleton
strelRadius = 3;    
strelObj = strel('sphere',abs(strelRadius));

%% Iterate through time, generate .ply objects of point clouds
sparseReconstruct = struct();
for tInd = 1:numel(timeRange)    
    % Load data from current time point
    currT = timeRange(tInd);
    currh5Name = fullfile(segDir,sprintf(segName,currT));
    selSegs = sum(loadH5(currh5Name,'/exported_data',[2 3],1),4);
    ogBlobs = imbinarize(sum(selSegs,4),probThresh);
    % To remove erroneous overhangs near blob exteriors, erode then dilate
    erodedBlobs = imerode(ogBlobs,strelObj);
    reconstructedBlobs = imdilate(erodedBlobs,strelObj);
    sparseReconstruct(tInd).indices = find(reconstructedBlobs == 1);
    % Generate skeletonization of blob perimeters
    [skelMat,a,b] = skel3DPop(logical(reconstructedBlobs - erodedBlobs),.5);  
    % Save skeletonizations as point clouds
    logic2Ply(skelMat, fullfile(ptDirInterm,sprintf(ptName,currT)),scaleMat);
end
fclose all;

%% Subsample vertices and calculate normals
scriptLoc = fullfile(meshLabDir, vertFiltScript);
pyrunfile(scriptLoc, dataDir = ptDirInterm, saveDir = ptDirInterm, sampNum = 25000, neighNum = 20)

%% Get vertex normals, then enforce normal direction
for tInd = 1:numel(timeRange)
    
    % Load current mesh from .ply
    currT = timeRange(tInd);
    mesh = read_ply_mod(fullfile(ptDirInterm,sprintf(ptName,currT)));      
    % Vertices are in x,y convention (col,row)
    vertices = mesh.v; vertNorms = mesh.vn;
    if numel(vertices) > 0
    
        % Load current logic matrix in row,col convention
        reconstructedBlobs = consMatLnB(ones(size(reconstructedBlobs)),sparseReconstruct(tInd).indices);
        % To project, we need to move everything to x,y OR row,col
        % Translate distMat to x,y (swap rows and cols)
        xyDistMat = permute(bwdist(~imfill(reconstructedBlobs,'holes')),[2 1 3]);
        % Gradients return [gradx (col), grady (row), gradz]
        [xGradRot, yGradRot, zGrad] = gradient(xyDistMat);
        % xyDistMat is permuted [2 1 3], so gradients must be flipped back
        gradVecs = [yGradRot(:), xGradRot(:), zGrad(:)];  
        % Note: this is probably a perfectly fine approximation of the surface
        % normals, so if one can do poisson disk elimination in MATLAB, there's no
        % need for the above call to MeshLab.
        
        % Vertex coordinates are in x,y
        % Rescale vertex dimensions to move back onto original integer grid
        ogVertCoords = num2cell(round( vertices./scaleMat ), [1 3]);
        ogVertInds = sub2ind(size(xyDistMat), ogVertCoords{:});
        
        % Project vertNorms along xyDistMat sampled at vertex coords
        vecProjs = dot(vertNorms,gradVecs(ogVertInds,:),2);
        newNorms = vertNorms.*sign(vecProjs)*normalSign;
        
        % Save new .ply
        currFile = fullfile(ptDir,sprintf(ptName,currT));
        plywrite_norms(currFile,mesh.f,vertices,newNorms)
    end
    
end
fclose all;

%% Generate meshes in Meshlab
scriptLoc = fullfile(meshLabDir, makeMeshScript);
pyrunfile(scriptLoc, dataDir = ptDir, saveDir = meshDir)





