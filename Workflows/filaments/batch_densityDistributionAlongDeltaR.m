% This script analyzes time sequences of 3D tifs. The script takes in
% directories of dense phase intensity images, sparse phase (filaments)
% intensity images, segmentations of the dense phase, and segmentations of
% the filaments. It returns distributions calculated over time/each 3D
% stack corresponding to the intensities in each ring delta r for the dense
% and sparse images with delta r defined at the boundaries of micelle
% surfaces and exteriors. 
% Rémi Boros, 2023-12-13, 2024-01-04, 2024-03-28, 2024-04-24

%% Directory info
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 81, Exp 2';
denseImgDir = fullfile(baseDir,'6 Illumination Bleach Corrected 16bit');
% sparseSegDir = '<redacted original absolute path>';
sparseSegDir = 'Session 56, Exp 1';
denseSegDir = fullfile(baseDir,'\7 Ilastik\T1-125 560 Training');
denseImgName = 't%03i_illBleachCorr16bit_560.tif';
sparseSegName = 'Time%06i_Filaments_gaussCrop_Probabilities.h5';
denseSegName = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';

% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 2';
saveName = 't1-125_radialDensityData-560.mat';

timeRange = 1:125;
denseH5Chans = [1 2 3];   denseThresh = 0.33;
sparseH5Chans = [];      sparseThresh = 0.6;
outInOnChans = [1 3 2];     % Order of dense segmentation out, in, and on channels
pixSize = 11*2/20;
deltaRBins = -150:150;
% deltaRBins = (-300:300)*pixSize;

segScale = [3 3 2.2];               % Quantity needed to rescale dense phase segmentations (can be scalar or vector)
fastCalc = 0;               % Trade off speed for accuracy by ordering the rescaling

% Color map info
timeColorVec = [1 0.5 0.5; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
timeColorStamps = [1 19 25 39 110 270];
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

% Save bounded images
boundImgBool = 1;
boundSaveDir = fullfile(saveDir,'Intensity and Segmentation Bounds');
if ~exist(boundSaveDir,'dir')
    mkdir(boundSaveDir);
end
segSaveBool = 0;
segSaveDir = fullfile(saveDir,'In On Out Segs');
if ~exist(segSaveDir,'dir')
    mkdir(segSaveDir);
end

%% Iterate and store distributions
sparseVoxCounts = zeros(numel(timeRange),numel(deltaRBins)-1);
sparseNorm = [];
denseVoxInts = zeros(numel(timeRange),numel(deltaRBins)-1);
denseVoxCounts = denseVoxInts;
for tInd = 1:numel(timeRange)
    
    % Load current objects
    currT = timeRange(tInd);
    currTif = tiffreadVolume(fullfile(denseImgDir,sprintf(denseImgName,currT)));
    currDenseSeg = loadH5(fullfile(denseSegDir,sprintf(denseSegName,currT)),'/exported_data',denseH5Chans);

    if ~isempty(sparseH5Chans)
        currSparseSeg = loadH5(fullfile(sparseSegDir,sprintf(sparseSegName,currT)),'/exported_data',sparseH5Chans);
    end

    if tInd == 1
        imgSize = size(currTif);
        segSizeD = size(currDenseSeg);
    end
    
    % Calculate blob perimeters from dense phase segmentation
    % This version is "more accurate" as it calculates the distance
    % transform from scaled up versions of the blob segmentations
    tic
    if fastCalc == 0
        [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(imresize3_4mat(currDenseSeg,...
            round(segScale.*segSizeD(1:3))),outInOnChans,denseThresh,1,1);
        distMat = imresize3(distTransFromBoundary(cleanOns|cleanIns, cleanOuts, false(size(cleanIns)), 1),imgSize);
        % distMatIO = imresize3(distTransFromBoundary(cleanIns, cleanOns|cleanOuts, false(size(cleanIns)), 1),imgSize);
        % distMatOO = imresize3(distTransFromBoundary(cleanOns|cleanIns, cleanOuts, false(size(cleanIns)), 1),imgSize);
    else
    % THIS CAN BE SPED UP BY CALCULATING DISTMAT BEFORE RESCALING, SCALING
    % DISTMAT ITSELF BY SEGSCALE, AND THEN RESIZING TO IMAGE SIZE
        [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(currDenseSeg,outInOnChans,denseThresh,1,1);
        distMat = imresize3(distTransFromBoundary(cleanOns|cleanIns, cleanOuts, false(size(cleanIns)), 1)*segScale,imgSize);
    end
toc
tic
    % Bin sparse filament locations (full filaments) by delta R in distMat
    if ~isempty(sparseH5Chans)
        sparseLogic = imbinarize(currSparseSeg,sparseThresh);
        sparseMat = consMatLnB(distMat,sparseLogic) + (min(min(deltaRBins),min(distMat(:)))-1)*(~sparseLogic);
        sparseNorm = sum(sparseLogic((sparseMat >= min(deltaRBins)) & (sparseMat <= max(deltaRBins))));
        sparseVoxCounts(tInd,:) = histcounts(sparseMat,deltaRBins);     
    end
        
    % Bin dense protein intensities by delta R in distMat
    [denseVoxCounts(tInd,:),~,binInds] = histcounts(distMat,deltaRBins);
    boundedDenseNorm = sum(currTif((distMat >= min(deltaRBins)) & (distMat <= max(deltaRBins))),'all');
    for rInd = 1:(numel(deltaRBins)-1)
        denseVoxInts(tInd,rInd) = sum(currTif(binInds == rInd),'all')/boundedDenseNorm;
    end
toc
tic
    % Save img with boundary
    if boundImgBool == 1
        segBounds = (distMat > -1) & (distMat < 1);
        boundImg = consMatLnB(currTif,~segBounds);
        save3DTiff(boundImg,fullfile(boundSaveDir,sprintf(denseImgName,currT)));            % Takes a long time
    end
    % Save segmentations
    if segSaveBool == 1
        cleanSegs = uint8(cleanOuts + 85*cleanIns + 170*cleanOns);
        save3DTiff(imresize3(cleanSegs,size(cleanSegs)/segScale),...
            fullfile(segSaveDir,sprintf(['DownscaledSeg_' denseImgName],currT)));
        save3DTiff(imresize3(cleanSegs,size(currTif)),...
            fullfile(segSaveDir,sprintf(denseImgName,currT)));
    end
toc
end

% Save
save(fullfile(saveDir,saveName),'denseVoxInts','denseVoxCounts','sparseVoxCounts','deltaRBins','sparseNorm')
save(fullfile(saveDir,'metadata.mat'),'timeRange','denseH5Chans','sparseH5Chans','denseThresh',...
    'sparseThresh','outInOnChans','pixSize','segScale','fastCalc');
    
%% Plot distributions
selTimes = 1:2:70;
figure
% plot(deltaRBins(1:end-1)*pixSize,(denseVoxInts./denseVoxCounts)')
plot(deltaRBins(1:(end-1))*pixSize,(denseVoxInts(selTimes,:)))
colororder(timeColorArray(selTimes,:))
ylim([0 0.04])
xlim([-55 18])
title('Spatial Intensity Distributions, Dense Label')
subtitle('Sampled Over Every Voxel')
xlabel('\Deltar (um)')
set(gca,'FontSize',15)
figure
% plot(deltaRBins(1:(end-1))*pixSize,sparseVoxCounts(selTimes,:)/sparseNorm);
colororder(timeColorArray(selTimes,:))
ylim([0 0.04])
xlim([-55 18])
title('Filament Position Distributions, Sparse Label')
subtitle('Using Filament Segmentations as Logic Mask')
xlabel('Distance from surface (um)')
set(gca,'FontSize',15)

%% Plot only density distributions
% selTimes = 40:2:100;  titleTag = 'Vesicle Expansion - Both';
selTimes = 14:30;  titleTag = 'Vesicle Formation - Both';
fracCutOff = .0002;

figure
hold on
% load(fullfile(saveDir,'t1-200_radialDensityData-488.mat'))
% fracLogic = denseVoxCounts(selTimes,:)./(sum(denseVoxCounts(selTimes,:),2))>fracCutOff;
% cutOffVoxInts = consMatLnB(denseVoxInts(selTimes,:),fracLogic);
% cutOffVoxCounts = consMatLnB(denseVoxCounts(selTimes,:),fracLogic);
% plot(deltaRBins(1:(end-1))'*pixSize,cutOffVoxInts./cutOffVoxCounts,'--','LineWidth',2);
% dataSet1 = cutOffVoxInts./cutOffVoxCounts;
load(fullfile(saveDir,saveName))
fracLogic = denseVoxCounts(selTimes,:)./(sum(denseVoxCounts(selTimes,:),2))>fracCutOff;
cutOffVoxInts = consMatLnB(denseVoxInts(selTimes,:),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(selTimes,:),fracLogic);
plot(deltaRBins(1:(end-1))'*pixSize,cutOffVoxInts./cutOffVoxCounts,'LineWidth',2);
dataSet2 = cutOffVoxInts./cutOffVoxCounts;

colororder([ timeColorArray(selTimes,:)])
% colororder([(timeColorArray(selTimes,:)*.7 + .1); timeColorArray(selTimes,:)])
ylim([1.5 3.5]*10^(-8))
xlim([-20 25])
title('Spatial Density Distributions, Dense Label')
subtitle(titleTag)
xlabel('Distance from surface (um)')
ylabel('Average Intensity (Nomalized)')
set(gca,'FontSize',15)


% plot(deltaRBins(1:(end-1))'*pixSize,denseVoxCounts(selTimes,:)/mean(sum(denseVoxCounts,2)),'LineWidth',2);
% plot(-deltaRBins(1:(end-1))'*pixSize,cutOffVoxInts(selTimes,:)./denseVoxCounts(selTimes,:),'LineWidth',2);

%% Cross corr shifted and rescaled
% Shift each field by mean of values at t1
shiftData1 = dataSet1 - nansum(dataSet1(1,:))./sum(~isnan(dataSet1(1,:)));
shiftData2 = dataSet2 - nansum(dataSet2(1,:))./sum(~isnan(dataSet2(1,:)));
% Scale datasets by intensity maxima
rescData1 = shiftData1/max(shiftData1(:));      % Kif4
rescData2 = shiftData2/max(shiftData2(:));      % MTs

figure
hold on
plot(deltaRBins(1:(end-1))'*pixSize,rescData1','--','LineWidth',2);
plot(deltaRBins(1:(end-1))'*pixSize,rescData2','LineWidth',2);
colororder([(timeColorArray(selTimes,:)*.7 + .1); timeColorArray(selTimes,:)])
% ylim([2 5]*10^(-8))
xlim([-15 25])
title('Rescaled-Shifted Spatial Density Distributions, Dense Label')
subtitle(titleTag)
xlabel('Distance from surface (um)')
ylabel('Average Intensity (Nomalized)')
set(gca,'FontSize',15)

storeMat = zeros(size(shiftData2));
for tInd = 1:numel(selTimes)
    currInds = nonNaNOverlap(tInd,:);
    storeMat(tInd,currInds) = conv(flipud(rescData2(tInd,currInds)),rescData1(tInd,currInds),'same');
end

figure
plot(deltaRBins(1:(end-1))'*pixSize,storeMat')
colororder(timeColorArray(selTimes,:))

%% Test subplot
figure
hold on
title('Spatial Density Distributions, Dense Label')
subplot(2,1,1)
plot(deltaRBins(1:(end-1))'*pixSize,dataSet1,'LineWidth',2);
colororder(timeColorArray(selTimes,:))
ylim([2 5]*10^(-8))
xlim([-15 25])
subplot(2,1,2)
plot(deltaRBins(1:(end-1))'*pixSize,dataSet2,'LineWidth',2);
colororder(timeColorArray(selTimes,:))
ylim([2 5]*10^(-8))
xlim([-15 25])

figure
hold on
title('Spatial Density Distributions, Dense Label')
subplot(2,1,1)
plot(deltaRBins(1:(end-1))'*pixSize,rescData1,'LineWidth',2);
colororder(timeColorArray(selTimes,:))
% ylim([2 5]*10^(-8))
xlim([-15 25])
subplot(2,1,2)
plot(deltaRBins(1:(end-1))'*pixSize,rescData2,'LineWidth',2);
colororder(timeColorArray(selTimes,:))
% ylim([2 5]*10^(-8))
xlim([-15 25])

%% Surface plot
figure
hold on
colormap(timeColorArray(selTimes,:));
surf(deltaRBins(1:(end-1))'*pixSize,selTimes,rescData1,repmat(selTimes',[1 size(rescData1,2)]),'LineStyle','none');
alpha 0.4
surf(deltaRBins(1:(end-1))'*pixSize,selTimes,rescData2,repmat(selTimes',[1 size(rescData1,2)]),'LineStyle','none');

%% Cross corr of two fields
shiftData1 = dataSet1 - nansum(dataSet1,2)./sum(~isnan(dataSet1),2);
shiftData2 = dataSet2 - nansum(dataSet2,2)./sum(~isnan(dataSet2),2);
nonNaNOverlap = ~isnan(shiftData1) & ~isnan(shiftData2);
storeMat = zeros(size(shiftData2));

for tInd = 1:numel(selTimes)
    currInds = nonNaNOverlap(tInd,:);
    storeMat(tInd,currInds) = conv(flipud(shiftData2(tInd,currInds)),shiftData1(tInd,currInds),'same');
    % storeMat(tInd,currInds) = conv(flipud(shiftData2(tInd,currInds)),shiftData1(tInd,currInds),'same');
     plot(deltaRBins(currInds)'*pixSize,dataSet2(tInd,currInds))
    hold on
    plot(deltaRBins(currInds)'*pixSize,dataSet1(tInd,currInds),'--')
end
colororder([(timeColorArray(selTimes,:)*.7 + .1); timeColorArray(selTimes,:)])

figure
plot(deltaRBins(1:(end-1))'*pixSize,storeMat')
colororder(timeColorArray(selTimes,:))
