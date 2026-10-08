%% Take in .h5s and images, return skeletons.
% NOTE: THIS SCRIPT IS LIKELY OBSOLETE and can be run with functions such
% as skel3DPop. 
% Expects geometry of segmentations to be predominantly sheet-like; i.e.
% this script will return point clouds along object CENTERS, not perimeters
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 45, Exp 3';
imgDir = fullfile(baseDir,'4 Illumination Corrected 8bit Downscaled');
imgNameForm = 't%03i_illCorr8bit.tif';
segDir = fullfile(baseDir,'7 Ilastik Training\Second Pass - 2');
segNameForm  = 'PassOne_t%03i_16bitSubSamp_Probabilities.h5';
plyDir = fullfile(baseDir,'10 Ply Objects'); 
meshDir = fullfile(baseDir,'11 Split Meshes');  
saveName = 'skel_vertices_t%03i_AND.ply';
mkdir(plyDir);   
mkdir(meshDir);
% meshLabDir = '<redacted original absolute path>';
meshLabDir = '';
ply2Mesh = 'batch_pointCloud2Mesh - MATLABexec.py';    
funcName = 'Ray_PointCloud2Mesh_ScreenedPoisson.mlx';

selectTimes = 1:20;
chanNums = [2 3];
threshVal = .6;
segThickCO = 1;     %Cut off distance for vertices inside segmentation to be considered for point cloud
strelRad = 2;

%% Generate morphological strel
strelObj = strel('sphere',strelRad);

%% time iteration
for tInd = 1:numel(selectTimes)

    %% Load and format seg matrix
    currT = selectTimes(tInd);
    segData = h5read(fullfile(segDir,sprintf(segNameForm,currT)),'/exported_data');
    selSegs = permute(squeeze(sum(segData(chanNums,:,:,:),1)),[2 1 3]);
    % Define image for first frame only
    if tInd == 1
        firstImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgNameForm,currT))));
    end

    %% Binarize
    binSegs = imbinarize(selSegs,threshVal);

    %% Match segmentation and image dims, if necessary
    if sum(size(binSegs) == size(firstImg)) < size(size(binSegs))
        binSegs = imresize3(binSegs, size(firstImg));
    end

    %% Morpho operations to remove "loosely" connected components
%     goBinSegs = binSegs;
%     erodedSegs = imerode(binSegs,strelObj);
%     erObjs = bwconncomp(erodedSegs);
%     erObjSizes = cellIndSizes(erObjs.PixelIdxList',1);
%     erObjKey = erObjSizes < mean(erObjSizes);
%     smallObjsOnly = consMatLnB(ones(size(currImg)), vertcat(erObjs.PixelIdxList{erObjKey}));
%     dilSmall = imdilate(smallObjsOnly, strelObj);
%     binSegs = logical(max(0,binSegs - dilSmall));

    %% skeletonization via reshaping - faster
    matDims = size(binSegs);
    reshaped1 = reshape(binSegs,[matDims(1)*matDims(2) matDims(3)]);
    temp = bwskel(reshaped1);
    unshaped1 = reshape(temp,matDims);
    reshaped2 = reshape(permute(binSegs,[2 1 3]),[matDims(1)*matDims(2) matDims(3)]);
    temp = bwskel(reshaped2);
    unshaped2 = permute(reshape(temp,[matDims(2) matDims(1) matDims(3)]),[2 1 3]);
    orMat = unshaped1 | unshaped2;
    andMat = unshaped1 & unshaped2;
    
    %% Scale orMat values by distance transform
    segDist = bwdist(~binSegs);
    cutoffOR = find(segDist.*orMat >= segThickCO);
    subSampOR = randsample(cutoffOR,round(numel(find(andMat))));
    ptCloud = consMatLnB(ones(size(firstImg)),[subSampOR; find(andMat)]);

    %% Isolate disconnected vertices and remove them
    objNBHoods = bwdist(ptCloud) < segThickCO;
    connComps = bwconncomp(objNBHoods);
    objs = connComps.PixelIdxList;
    objSizes = cell2mat(cellfun(@size,objs,'UniformOutput',false)');
    % Isolate objects larger than a std larger than median object size
    bigObjs = objs(objSizes(:,1) > (median(objSizes(:,1)) + std(objSizes(:,1))) );
    % Reconstruct logic matrix with appropriate objects only
    trimInds = vertcat(bigObjs{:});
    ogInds = find(ptCloud(:)==1);
    allInds = intersect(trimInds, ogInds);
    trimSkel = zeros(size(binSegs));
    trimSkel(allInds) = 1;
    
    %% Generate .ply
    logic2Ply(trimSkel, fullfile(plyDir,sprintf(saveName,currT)));
end

%% Convert vertices into mesh
scriptLoc = fullfile(meshLabDir, ply2Mesh);
funcLoc = fullfile(meshLabDir, funcName);
pyrunfile(scriptLoc, dataDir = plyDir, saveDir = meshDir, scriptName = funcLoc)




