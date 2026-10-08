%% Take in .h5s and images, return skeletons.
% Expects geometry of segmentations to be predominantly sheet-like
% Rémi Boros
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 28, Exp 6';
imgDir = fullfile(baseDir,'6 Illumination Bleach Corrected 16bit');
imgNameForm = 't%03i_illBleachCorr16bit.tif';
segDir = fullfile(baseDir,'7 Ilastik Segmentation 2');
segNameForm  = 'Rescaled_t%03i_illCorr8bit_Probabilities Stage 2.h5';
% saveBase = '<redacted original absolute path>';
saveBase = 'Session 28, Exp 6';
plyDir = fullfile(saveBase,'8 Ply Objects'); 
meshDir = fullfile(saveBase,'9 Split Meshes');  
saveName = '%sskel_vertices_t%03i_AND.ply';
mkdir(plyDir);   
mkdir(meshDir);
% meshLabDir = '<redacted original absolute path>';
meshLabDir = '';
ply2Mesh = 'batch_pointCloud2Mesh - MATLABexec.py';    
funcName = 'Ray_PointCloud2Mesh_ScreenedPoisson.mlx';

selectTimes = 282:292;
chanNum = 2;        % h5 from ilastik
threshVal = .6;
segThickCO = 4;     %Cut off distance for vertices inside segmentation to be considered for point cloud
strelRad = 1;
ogVoxSize = [0.3667 0.3667 1.5];

saveSegsBool = 1;

% Generate morphological strel
strelObj = strel('sphere',strelRad);

%% time iteration
for tInd = 1:numel(selectTimes)

    % Load and format seg matrix
    currT = selectTimes(tInd);
    currPath = fullfile(segDir,sprintf(segNameForm,currT));
    selSegs = double(loadH5(currPath,'/exported_data',chanNum));
    % segData = h5read(,'/exported_data');
    % selSegs = permute(squeeze(segData(chanNum,:,:,:)),[2 1 3]);
    if tInd == 1
        currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgNameForm,currT))));
        imgSize = size(currImg);
        segSize = size(selSegs);
        segVoxSize = imgSize./segSize.*ogVoxSize;
    end

% Binarize
    binSegs = imbinarize(selSegs,threshVal);

% Match segmentation and image dims, if necessary
    % if sum(size(binSegs) == size(currImg)) < size(size(binSegs))
    %     binSegs = imresize3(binSegs, size(currImg));
    % end
    % ALERNATIVE: assume segmentation has cubic voxels; rescaled vertices
    
    %Generate operation matrices to be used in all frames
    if tInd == 1
        [~,~,zMat] = ndgrid(1:size(binSegs,1), 1:size(binSegs,2), 1:size(binSegs,3));
        % boundMat = circshift(consMatLnB(true(size(binSegs,1),size(binSegs,2),size(binSegs,3)+2), find(true(size(binSegs)))),1,3);
    end

% Morpho operations to remove "loosely" connected components
    goBinSegs = binSegs;
    % Initial erosion
    erodedSegs = imerode(binSegs,strelObj);
    erObjs = bwconncomp(erodedSegs);
    erObjSizes = cellIndSizes(erObjs.PixelIdxList',1);
    erObjKey = erObjSizes < mean(erObjSizes);
    % dilate disconnected small objects, then remove
    smallObjsOnly = consMatLnB(ones(segSize), vertcat(erObjs.PixelIdxList{erObjKey}));
    dilSmall = imdilate(smallObjsOnly, strelObj);
    binSegs = logical(max(0,binSegs - dilSmall));
    % Re-erode by small kernel to remove free-floating pixels
    binSegs = imerode(binSegs, strel('sphere',1));

% Identify top and bottom layers and generate references matrices - 2.1s
    [topLayer,botLayer,topLayerZs,botLayerZs,~,~,splitSlice] = returnTopBottom2DSheets(binSegs);
    topProbs = consMatLnB(binSegs, ~(zMat>splitSlice)); botProbs = consMatLnB(binSegs, zMat>splitSlice);

% Display progress
    if mod(currT,10) == 1
        fprintf("Current frame: %i... Current split Z slice: %i...\n", selectTimes(tInd),splitSlice);
    end

% Patch truncated portions - 2.3s
    %Get indices of outer boundary along z for top layer
    topOutside = consMinValsLayer(topLayerZs,3);
    %Fill in outer boundary and return patched surface
    patchedTopProbs = consPatchedSheetSurface_Flat(binSegs,topLayer,topOutside);
    
    %Get indices of outer boundary along z for bottom layer
    botOutside = max(botLayerZs,[],3);
    %Fill in outer boundary and return patched surface
    patchedBotProbs = consPatchedSheetSurface_Flat(binSegs,botLayer,botOutside);

    % Full patched segs
    freeObjs = (patchedBotProbs | patchedTopProbs | binSegs) - patchedTopProbs - patchedBotProbs;

% Stitch floating objects to layers, if they connect - .9s
    %Get layers and indices of all other disconnected objects
    [topLayerPatch,~] = removeConObjs(patchedTopProbs | logical(freeObjs),1,"large");     
    [botLayerPatch,~] = removeConObjs(patchedBotProbs | logical(freeObjs),1,"large");
    %Stitch layers to disconnected objects from other layers, then keep only
    %largest object (layer + reconnected sections/objects)
%     topCorrInds = removeConObjs(logical(topLayerPatch) | consMatLnB(true(size(topLayerPatch)),botDiscInds), 1, "large");
%     botCorrInds = removeConObjs(logical(botLayerPatch) | consMatLnB(true(size(botLayerPatch)),topDiscInds), 1, "large");

% Generate top, bottom, middle, topsheet and bottomsheet
    if saveSegsBool == 1
        if tInd == 1
            objSaveDir = fullfile(segDir,'Split Objects');
            if ~exist(objSaveDir,'dir')
                mkdir(objSaveDir);
            end
        end
        % Patch sheets, if needed
        sumDownTop = logical(cumsum(topLayerPatch,3));
        sumUpTop = logical(cumsum(topLayerPatch,3,'reverse'));
        holeCheckTop = sum(sumUpTop,3);
        if sum(holeCheckTop == 0,'all') > 0
            [topLayerPatch] = rescalePatch(topLayerPatch,8);
        end
        sumDownBot = logical(cumsum(botLayerPatch,3));
        sumUpBot = logical(cumsum(botLayerPatch,3,'reverse'));
        holeCheckBot = sum(sumUpBot,3);
        if sum(holeCheckBot == 0,'all') > 0
            [botLayerPatch] = rescalePatch(botLayerPatch,8);
        end
    
    % Logical separation
        topRegion = (sumUpTop - sumDownTop - topLayerPatch) == 1;
        botRegion = (-sumUpBot + sumDownBot - botLayerPatch) == 1;
        botSheet = botLayerPatch; topSheet = topLayerPatch;
        midRegion = ~topRegion & ~botRegion & ~topSheet & ~botSheet;
        
    % Save
        regionStruct = struct();
        regionStruct.TopRegion = find(topRegion);
        regionStruct.TopSheet = find(topSheet);
        regionStruct.BotRegion = find(botRegion);
        regionStruct.BotSheet = find(botSheet);
        regionStruct.MidRegion = find(midRegion);
        save(fullfile(objSaveDir,sprintf('SplitRegions_Time%06i.mat',currT)),"regionStruct",'segVoxSize');
    end

% Skeletonization
    [topCloud, topSkelOR, topSkelAND] = skel3DPop(topLayerPatch, .5, segThickCO);
    [botCloud, botSkelOR, botSkelAND] = skel3DPop(botLayerPatch, .5, segThickCO);

% Generate .ply - requires imsane
    logic2Ply(topCloud, fullfile(plyDir,sprintf(saveName,'top',currT)));
    logic2Ply(botCloud, fullfile(plyDir,sprintf(saveName,'bot',currT)));

end

%% Save metadata
save(fullfile(objSaveDir,'metadata.mat'),'segSize','imgSize','ogVoxSize','segVoxSize');
save(fullfile(meshDir,'metadata.mat'),'ogVoxSize','segVoxSize','threshVal','segThickCO');

%% Convert vertices into mesh
scriptLoc = fullfile(meshLabDir, ply2Mesh);
funcLoc = fullfile(meshLabDir, funcName);
pyrunfile(scriptLoc, dataDir = plyDir, saveDir = meshDir, scriptName = funcLoc)
