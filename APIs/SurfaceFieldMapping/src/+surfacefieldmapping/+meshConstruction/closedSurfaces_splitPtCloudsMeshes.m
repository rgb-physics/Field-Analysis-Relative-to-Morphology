%% A first pass on how to extract surfaces of roughly drop-like objects
% Ideally, this is will iterate through .h5s, then return point clouds
% corresponding to the drop surfaces. Finally, these point clouds are
% converted into mesh objects. This method will save point clouds of each
% object defined by regionprops, convert them into meshes, ensure the
% normals of these meshes are consistent, then recombine all objects into a
% single mesh object for each time point
% 10/04/2023
%% Data info
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 45, Exp 3';
segDir = fullfile(baseDir,'7 Ilastik Training\Second Pass - 2');
segName = 'PassOne_t%03i_16bitSubSamp_Probabilities.h5';
ptDir = fullfile(baseDir, '10 Point Clouds\Split Objects');       mkdir(ptDir);
meshDirBase = fullfile(baseDir, '11 Mesh Objects');     mkdir(meshDirBase);
meshDirObjs = fullfile(meshDirBase,'From Split Objects');   mkdir(meshDirBase);
meshDirComb = fullfile(meshDirBase,'Recombined Meshes');    mkdir(meshDirComb);
meshDirCombResc = fullfile(meshDirBase, 'Rescaled Recombined Meshes'); mkdir(meshDirCombResc);
ptName = 'Time%03i_Obj%03i_pointCloud.ply';     searchTerm = '*Time%03i*';
meshName = 'Time%03i_meshObjs.ply';
% meshLabDir = '<redacted original absolute path>';
meshLabDir = '';
ply2Mesh = 'batch_pointCloud2Mesh - MATLABexec.py';    
funcName = 'Ray_PointCloud2Mesh_ScreenedPoisson.mlx';

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 45, Exp 3';
imgName = 't%03i_illBleachCorr16bit.tif';

timeRange = 1:20;
chanNums = [2 3];
h5String = '/exported_data';
probThresh = .6;
pixDims = [.37 .37 1.5];      %In um/pixel in [x,y,z]
% normalSign = 1 corresponds to normals pointing TOWARD CoM
normalSign = -1;              % 1 or -1, ensures mesh normals are consistent across all objects over time

% Erosion info - "dig" into object to define skeleton
strelRadius = 3;    
strelObj = strel('sphere',abs(strelRadius));

%% Iterate through time, generate .ply objects of point clouds
% for tInd = 1:numel(timeRange)    
tInd = 8;
    % Load data from current time point
    currT = timeRange(tInd);
    currh5Name = fullfile(segDir,sprintf(segName,currT));
    selSegs = sum(loadH5(currh5Name,'/exported_data',[2 3],1),4);

    % To remove erroneous overhangs near blob exteriors, erode then dilate
    ogBlobs = imbinarize(sum(selSegs,4),probThresh);
    erodedBlobs = imerode(ogBlobs,strelObj);
    reconstructedBlobs = imfill(imdilate(erodedBlobs,strelObj),'holes');
    % Generate skeletonization of blob perimeters
    [skelMat,a,b] = skel3DPop(logical(reconstructedBlobs - erodedBlobs),.5);    

    % Get region properties to split objects
    objInfo = bwconncomp(reconstructedBlobs);
    % Save skeletonizations as point clouds for each object
    for objInd = 1:objInfo.NumObjects
        logic2Ply(consMatLnB(skelMat,objInfo.PixelIdxList{objInd}), fullfile(ptDir,sprintf(ptName,currT,objInd)));
    end
    
% end
fclose all;

%% Convert vertices into mesh - This may not work well; consider splitting objects
scriptLoc = fullfile(meshLabDir, ply2Mesh);
funcLoc = fullfile(meshLabDir, funcName);
pyrunfile(scriptLoc, dataDir = ptDir, saveDir = meshDirObjs, scriptName = funcLoc)

%% Clean up and recombine meshes
% Iterate through all objects at each time point, check that normals are
% self-consistent using functions from imsane/tubular/DEC, then recombine
% into a single mesh
%Iterate through time
for tInd = 1:numel(timeRange)
    % Instantiate matrices for current time point
    currT = timeRange(tInd);
    currObjs = dir(fullfile(meshDirObjs,sprintf(searchTerm,currT)));
    combVerts = []; combFaces = [];
    %Iterate through objects
    for objInd = 1:numel(currObjs)
        % Instantiate matrices for current object
        currMeshName = fullfile(meshDirObjs,currObjs(objInd).name);
        mesh = read_ply_mod(currMeshName);
        currVerts = mesh.v; currFaces = mesh.f;
        % Define center of mass of current object, get distances of each
        % vertex in current object to center of mass
        CoM = mean(currVerts,1); deltaVecs = currVerts - CoM;
        % Compute face normals using tubular/imsane/DEC functions
        vtxNormals = per_vertex_normals(currVerts, currFaces);
        % Project displacements along normals, then deduce sign
        projVec = deltaVecs.*vtxNormals;
        % Update sign of normals based on avg sign of projections
        % normalSign = 1 corresponds to normals pointing TOWARD COM
        if sign(sum(projVec,'all')) == normalSign
            currFaces(:,2:3) = currFaces(:,3:-1:2);
        end
        %Combine info
        combFaces = [combFaces; (currFaces + size(combVerts,1))];
        combVerts = [combVerts; currVerts];
    end
    %Save combined mesh
    plywrite(fullfile(meshDirComb,sprintf(meshName,currT)), combFaces, combVerts);
end
fclose all;

%% Load mesh, rescale vertices, save as mesh
%Iterate through time
for tInd = 1:numel(timeRange)
    % Instantiate matrices for current time point
    currT = timeRange(tInd);
    currMeshName = fullfile(meshDirComb,sprintf(meshName,currT));
    mesh = read_ply_mod(currMeshName);
    %Save combined mesh
    plywrite(fullfile(meshDirCombResc,sprintf(meshName,currT)), mesh.f, (mesh.v).*pixDims);
end
fclose all;


