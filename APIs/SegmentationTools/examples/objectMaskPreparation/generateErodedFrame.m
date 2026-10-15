%% Take in a frame that can be reduced using logical, return eroded objects
% Load the tif of interest, load the segmentation (tif) of interest to
% locate chamber interior. Apply Ricker wavelet to raw tif, get drop
% interiors. Overlay with segmentation to isolate objects INSIDE chamber.
% Iteratively erode and dilate with a growing disk radius. Iterate through
% objects of different sizes 
% rawDir = '<redacted original absolute path>';
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this saved script.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

rawDir = '';
rawName = 'img_%09i_Default_000.tif';
% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = 'BlobMat_t%03i_Beads.tif';
% saveDir = '<redacted original absolute path>';
saveDir = '';
saveName = 'eroded_T%03i.tif';
erodeRad = 4;
selectTime = 215;

%% Load tif, erode, save tif
strelObj = strel('disk',erodeRad);
currRaw = tiffreadVolume(fullfile(rawDir,sprintf(rawName,selectTime)));

        logMat = -farmLOG(currRaw, 3);

currTif = logical(tiffreadVolume(fullfile(dataDir,sprintf(dataName,selectTime))));


%% 
chamberLogic = imdilate(imerode(currTif,strel('disk',5)),strel('disk',5));
baseMat = imfill(logMat<0,'holes');
sumMat = baseMat<0;
for index = 1:2:10
    % erodeRad =6;
    strelObj = strel('disk',index);
    sumMat = sumMat + imdilate(imerode(baseMat,strelObj),strelObj);
    % imagesc(imdilate(imerode(logMat<0,strelObj),strelObj) + (logMat<0));
end

subSampObjs = farmConsMatLnB(sumMat,logical(chamberLogic));

%% Iterate through each index value, regionprops, keep objects that are circles
uniqueInds = unique(subSampObjs(subSampObjs>0));
cutOffArea = 9;
cutOffAR = 3;
for currInd = 1:numel(uniqueInds)
% Calculate connected objs and region properties
    currProps = regionprops(subSampObjs == currInd,'Centroid','Area','MajorAxisLength','MinorAxisLength');
    currObjs = bwconncomp(subSampObjs == currInd);
    % % currProps = farmAddFieldsStruct(currProps,'ErodeRad',mat2cell(currInd*ones(1,numel(currProps)),1,numel(currProps)));
% Collate aspect ratios and areas
    currMajs = vertcat(currProps(:).MajorAxisLength);
    currMins = vertcat(currProps(:).MinorAxisLength);
    currRatios = currMajs./currMins;
    currAreas = vertcat(currProps(:).Area);
% Generate logic vector to keep "good" objects only
    arLogic = currRatios <= cutOffAR;
    areaLogic = currAreas >= cutOffArea;
    fullLogic = arLogic & areaLogic;
% Subsample objects and properties
        numNew = sum(fullLogic,'all');
    if currInd == 1
        allProps = currProps(fullLogic,:);
        allObjs = currObjs;
        allObjs.NumObjects = 0;
        allObjs.PixelIdxList = currObjs.PixelIdxList(fullLogic);
    else
        allProps = [allProps; currProps(fullLogic,:)];
        allObjs.PixelIdxList((end+1):(end+numNew)) = deal(currObjs.PixelIdxList(fullLogic)');
    end
    allObjs.NumObjects = allObjs.NumObjects + numNew;

    % if currInd == 1
        % figure
        % imagesc(subSampObjs);
        % hold on
        % currCens = vertcat(currProps(:).Centroid);
        % scatter(currCens(fullLogic,1),currCens(fullLogic,2),15,'filled')
    % end
end

%% Generate tif with unique IDs per sphere
idTif = zeros(allObjs.ImageSize);
for idInd = 1:numel(allProps)
    idTif = idTif + farmConsMatLnB(ones(allObjs.ImageSize)*idInd,allObjs.PixelIdxList{idInd});
end
save3DTiff(uint16(idTif),fullfile(saveDir,sprintf(saveName,selectTime)));
save(fullfile(saveDir,'Object_IDs_Properties.mat'),'allObjs','allProps');

