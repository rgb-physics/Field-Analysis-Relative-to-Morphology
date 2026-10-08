%%Data info
setNum = 1;
% dataDir = '<redacted original absolute path>';
dataDir = '';
% dataNameForm = '8bit%0.4i.h5';
pixSegName = 'Set%i%04i_Probabilities.h5';
% saveDir = '<redacted original absolute path>';
saveDir = '';
saveName = 'Time%06i_Set%i.png';
% imgDir = '<redacted original absolute path>';
imgDir = '';
imgName = 'img_channel000_position000_time%09i_z000.tif';
selectTimes = 0:3;
setBins = 1:.2:10;
pixScale = 6.45*2/60;
selChan = 2;
segThresh = 0.4;
dispBool=1;
colorLims = [1100 2200];
% colorLims = [2700 9500];
% Cutoff info
cutAR = 1.5;
minArea = 10;
minLen = 2; maxLen = 50;

%% Use regionprobs and pixel segmentation
allMajorAxes = [];
allMinorAxes = [];
storeStruct = struct();
for index = 1:numel(selectTimes)
    currT = selectTimes(index);
    currName = sprintf(pixSegName, setNum, currT);
    currData = loadH5(fullfile(dataDir,currName),'/exported_data',selChan);
    axisInfo = regionprops(currData>segThresh,'MajorAxisLength', 'MinorAxisLength','Centroid','Orientation','Area');

    storeStruct(index).MajAxes = [axisInfo.MajorAxisLength];
    storeStruct(index).MinAxes = [axisInfo.MinorAxisLength];
    allCens = [axisInfo.Centroid];
    storeStruct(index).Cens = reshape(allCens,2,numel(allCens)/2);
    storeStruct(index).Oris = [axisInfo.Orientation];
    storeStruct(index).Areas = [axisInfo.Area];

    % Display and save?
    if dispBool == 1
        currImg = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
        currCoMs = [storeStruct(index).Cens];
        currOris = deg2rad([storeStruct(index).Oris]);
        currMajs = [storeStruct(index).MajAxes];
        currMins = [storeStruct(index).MinAxes];
        currAreas = [storeStruct(index).Areas];
        % Keep only filaments that fall in cutoff
        arLogic = currMajs./currMins > cutAR;
        lenLogic = (currMajs > minLen) & (currMajs < maxLen);
        areaLogic = currAreas > minArea;
        totLogic = arLogic & lenLogic & areaLogic;
        [bbXs, bbYs] = filBackBones2D(currCoMs(:,totLogic),currMajs(totLogic),currOris(totLogic));
        % display
        figure('Units', 'pixels', 'Position', [100, 100, 1000, 1000])
        imagesc(currImg)
        colormap('gray')
        clim(colorLims)
        % imagesc(currData>segThresh)
        hold on
        plot(bbXs,bbYs,'red')
        axis equal
        % Save
        exportgraphics(gca,fullfile(saveDir,sprintf(saveName,currT,setNum)));
        
    end
end
save(fullfile(saveDir,sprintf('storeStruct_Set%i.mat',setNum)),'storeStruct');

%% % histogram
allMajs = [storeStruct(:).MajAxes];
allMins = [storeStruct(:).MinAxes];
allOris = [storeStruct(:).Oris];
allAreas = [storeStruct(:).Areas];

% Keep only filaments that fall in cutoff
arLogic = allMajs./allMins > cutAR;
lenLogic = (allMajs > minLen) & (allMajs < maxLen);
areaLogic = allAreas > minArea;
totLogic = arLogic & lenLogic & areaLogic;

figure
histogram(allMajs(totLogic)*pixScale,setBins);
hold on
[binCounts, binEdges] = histcounts(allMajs(totLogic)*pixScale,setBins);

set(gca,'FontSize',15)
xlabel('MT Length (um)')
ylabel('Counts')
title(sprintf('Mean Filament Len: %2.2fum',mean(allMajs(totLogic)*pixScale)))

%% Plot filaments over seg
index = 1;
allComs = [storeStruct(:).Cens];
currCoMs = [storeStruct(index).Cens];
currOris = deg2rad([storeStruct(index).Oris]);
currMajs = [storeStruct(index).MajAxes];

[bbXs, bbYs] = filBackBones2D(currCoMs,currMajs,currOris);

figure
imagesc(currData>segThresh)
hold on
plot(bbXs,bbYs,'red')

%% Fit log normal
meanVal = mean(bigAxes)*pixScale;
stdVal = std(bigAxes)*pixScale;
% distVals = 1./(binEdges(2:end)*stdVal*sqrt(2*pi))*exp( - (log(binEdges(2:end) - meanVal).^2)/(2*stdVal^2));
normTerm = ones(size(binEdges(2:end)))./(binEdges(2:end)*stdVal*sqrt(2*pi));
distTerm =  exp( - ( (log(binEdges(2:end)) - meanVal).^2)/(2*stdVal^2) );
logNorm = normTerm.*distTerm;

% scatter(binEdges(2:end), logNorm*sum(binCounts),'filled')
hold off
