%% From Jakob's suggestion, plot integral of rho r dr over segmented bounds
% Uses corrected images for rho and blob segmentations for masks and
% distance
% 2026-06-24 - Rémi Boros

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 81, Exp 3';
imgName = 't%03i_illBleachCorr16bit_560.tif';
% maskDir = '<redacted original absolute path>';
maskDir = 'Session 81, Exp 3';
maskName = 'T%03i_trajIDs.tif';
% skelDir = '<redacted original absolute path>';
skelDir = 'Session 81, Exp 3';
skelName = 'T%03i_IDedSkelMat.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';

selTimes = 35;
layerMean = 0;  layerWidth = 0; gKern = 2;  spdMethod = 'fast';

ColumnContents = {'Object ID','Frame','Boundary Frame','Skeleton Frame','Blob Masses'};
%% Iterate over time
objInertias = zeros(1,5);
nextInd = 1;
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    currBlobs = tiffreadVolume(fullfile(maskDir,sprintf(maskName,currT)));
    currSkels = tiffreadVolume(fullfile(skelDir,sprintf(skelName,currT)));
    
    % Smooth segmentations/mask
    rsSmthBlobs = returnSmoothBlobsIDed(currBlobs,layerMean,layerWidth,gKern,spdMethod);
    
    % Generate distance field  - Should compare to flipping dist boundaries
    distMapBnds = bwdist(~(rsSmthBlobs > 0));
    distMapSkels = bwdist(currSkels);
    rsBlobs = imresize3(rsSmthBlobs,size(currImg),'nearest');
    rsDistBnds = imresize3(distMapBnds,size(currImg),'nearest');
    rsDistSkels = imresize3(distMapSkels,size(currImg),'nearest');
    
    % Generate product field
    prodField1 = rsDistBnds.*currImg;
    prodField2 = rsDistSkels.*currImg;
    
    % iterate over object IDs and sample product fields over corresponding objs
    unqIDs = unique(rsBlobs(rsBlobs>0));
    for index = 1:numel(unqIDs)
        objInertias(nextInd,1) = unqIDs(index);
        objInertias(nextInd,2) = currT;
        IDlogic = rsBlobs == unqIDs(index);
        objInertias(nextInd,3) = sum(prodField1(IDlogic),'all');
        objInertias(nextInd,4) = sum(prodField2(IDlogic),'all');
        objInertias(nextInd,5) = sum(currImg(IDlogic),'all');
        nextInd = nextInd + 1;
    end

end
save(fullfile(saveDir,'InertiaStore.mat'),'objInertias','ColumnContents')
save(fullfile(saveDir,'metadata.mat'),'selTimes','ColumnContents',...
    'layerMean','layerWidth','gKern','spdMethod')

%% 

frameZero = 34;
deltaT = .5;
xVals = (objInertias(:,2)-frameZero)*deltaT;    
xBins = (selTimes - frameZero)*deltaT;
plotVlns(xVals,objInertias(:,3)./objInertias(:,5),xBins,30,1);
box on
title('Boundary Coordinates')
ylabel('<sum(\rho r)/sum(\rho) (um)>')
xlabel('Time (min)')
set(gca,'FontSize',12)
% ylim([0 10^10])
plotVlns(xVals,objInertias(:,4)./objInertias(:,5),xBins,30,1);
box on
title('Skeleton Coordinates')
ylabel('<sum(\rho r)/sum(\rho) (um)>')
xlabel('Time (min)')
set(gca,'FontSize',12)
% ylim([0 3*10^10])

%% Compare violins to aspect ratios
% sphDir = '<redacted original absolute path>';
sphDir = 'Session 81, Exp 3';
sphName = 'trajSorted_RMin_Anisotropy.mat';

% Load anisotropy data
load(fullfile(sphDir,sphName));

% Calculate mean r and anisotropy values in statStruct
selFields = {'MinAxStats','FAs','Sphs'};
meanMat = zeros(numel(statStruct),numel(selFields));
medMat = meanMat;
% Iterate over objects
for index = 1:numel(statStruct)
    %Iterate over fields
    for jdex = 1:numel(selFields)
    % Load current object data
        currData = statStruct(index).(selFields{jdex});
    % Calculate means and store
        meanMat(index,jdex) = mean(currData);
        medMat(index,jdex) = median(currData);
    end
end


% Isolate IDs and Frames for sorting
sphCoords = [[statStruct(:).BlobID]' [statStruct(:).Frame]'];
% Map indices of objects in objInertias to indices in statStruct
[existLogic,mapVec] = ismember(objInertias(:,1:2),sphCoords,'rows');

%% Plot average blob quants against r from objInertias (colored by time)
subTimes = 24:4:60;
plotField = 2;
timeColorArray = othercolor('BuPu3',max(subTimes));
figure
hold on
for tInd = 1:numel(subTimes)
    currT = subTimes(tInd);
    % Add time logic
    tLogic = objInertias(:,2) == currT;
    totLogic = existLogic & tLogic;
    fieldOne = objInertias(totLogic,4)./objInertias(totLogic,5);
    fieldTwo = meanMat(mapVec(totLogic),plotField);
    % fieldTwo = medMat(mapVec(totLogic),plotField);
    scatter(fieldOne,fieldTwo,20,timeColorArray(currT,:),'filled');
end

box on
xlabel('r from first moment (um)')
ylabel(sprintf('StatStruct Field - %s',selFields{plotField}))
set(gca,'FontSize',15)

% sphCoords(mapVec(existLogic),:)

