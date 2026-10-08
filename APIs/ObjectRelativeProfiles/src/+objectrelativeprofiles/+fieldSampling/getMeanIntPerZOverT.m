%% Iterate over a series of tifs (each time point) and store/plot the mean intensity for each z
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
dataNameForm = 'Time%06i_16bitcropped.tif';
selectTimes = 1:250;
glassTop = 8;
glassBot = 0;
pixelScale = 11*4/60;
timeScale = 30;

%% Load first image and instantiate storage matrix
currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,selectTimes(1))));
storageMat = zeros(size(currTif,3), numel(selectTimes));

%% Iterate through times and store in matrix
for currT = 1:numel(selectTimes)

    currTif = tiffreadVolume(fullfile(dataDir, sprintf(dataNameForm,selectTimes(currT))));
    storageMat(:,currT) = squeeze(mean(mean(currTif,1),2));

end

%% Plot Mean heights per Heght over T
figure
hold on
for currT = 1:numel(selectTimes)

    plot(1:size(currTif,3), storageMat(:,currT), ...
        'Color', [currT/numel(selectTimes), 0, (1-currT/numel(selectTimes))]);
end
xlabel('Height (voxel)')
ylabel('Intensity (16bit)')
set(gca, 'FontSize',15)


%% Surface plot of above
figure
[zCoords, tCoords] = ndgrid(1:size(storageMat,1), 1:size(storageMat,2));
surf(zCoords, tCoords, storageMat, 'EdgeColor','none','FaceAlpha',.8)
xlabel('Height (voxel)')
ylabel('Time (frame)')
zlabel('Intensity (16bit)')
set(gca, 'FontSize',15)

%% Plot mean height after normalization at T=1
scaledMat = bsxfun(@rdivide,storageMat,storageMat(:,1));

figure
hold on
for currT = 1:numel(selectTimes)

    plot(1:size(currTif,3), scaledMat(:,currT), ...
        'Color', [currT/numel(selectTimes), 0, (1-currT/numel(selectTimes))]);
end
xlabel('Height (voxel)')
ylabel('Normalized by Int at T=1')
set(gca, 'FontSize',15)

%% Bleach rate
bleachRate = mean(storageMat,1); bleachMat = repmat(bleachRate, [size(storageMat,1) 1]);

%% Surface with bleach correction
figure
scaledscaledMat = scaledMat./bleachMat;
[zCoords, tCoords] = ndgrid(1:size(storageMat,1), 1:size(storageMat,2));
surf(zCoords, tCoords, scaledscaledMat, 'EdgeColor','none','FaceAlpha',.8)
xlabel('Height (voxel)')
ylabel('Time (frame)')
zlabel('Intensity (16bit)')
set(gca, 'FontSize',15)

%% Look at log-log of bleach rate over time
allTimes = 1:numel(bleachRate);
logAllTimes = log(allTimes);
numBins = 30;
figure
subplot(1,2,1)
[~,logEdges,binInds] = histcounts(logAllTimes,numBins);
meanBinLogTimes = zeros(1,numel(logEdges)-1);
meanBinLogInts = meanBinLogTimes;
for currBin = 1:max(binInds)

    meanBinLogTimes(currBin) = mean(logAllTimes(binInds == currBin));
    meanBinLogInts(currBin) = mean(log(bleachRate(binInds == currBin)));

end
meanBinLogTimes = meanBinLogTimes(~isnan(meanBinLogTimes));
meanBinLogInts = meanBinLogInts(~isnan(meanBinLogInts));
% plot(log(allTimes), log(bleachRate)./log(max(bleachRate(:))))
plot(log(allTimes)/log(10), log(bleachRate)/log(10))
hold on
% scatter(meanBinLogTimes,meanBinLogInts./log(max(bleachRate(:))),'filled')
scatter(meanBinLogTimes/log(10),meanBinLogInts/log(10),'filled')
title('Log-log Time vs. Intensity')
xlabel('Time (powers of ten frames)')
ylabel('Intensity (powers of ten 16bit)')
set(gca,'FontSize',15)
subplot(1,2,2)
scatter(exp(meanBinLogTimes(1:end-1)), exp(diff(meanBinLogInts)./diff(meanBinLogTimes)),'filled')
% scatter(meanBinLogTimes(1:end-1)/log(10), diff(meanBinLogInts)./diff(meanBinLogTimes)*1/log(10),'filled')
title('Time vs. Change in Intensity')
xlabel('Time (frames)')
ylabel('Intensity (16bit/frame)')
set(gca,'FontSize',15)

%% 
testScale = permute(repmat(storageMat(:,1),[1, size(currTif,1), size(currTif,2)]),[2 3 1]);
scaledTif = double(currTif)./testScale;

%% Starting at last t, when peaks are most pronounced, detect peaks as nearest neighboring peaks over time
peakStore = zeros(numel(selectTimes),2);
scaledPeakStore = peakStore;
locStore = peakStore;
scaledLocStore = peakStore;
%Iterate through time
for currT = numel(selectTimes):-1:1

    [currPks,currLocs] = findpeaks(scaledMat(glassTop:end-glassBot,currT));
    if numel(currLocs) > 1
        if currT == numel(selectTimes)
            [~,sortedLocs] = sort(currPks);
            scaledPeakStore(currT,:) = currPks(sortedLocs((end-1):end));
            scaledLocStore(currT,:) = currLocs(sortedLocs(end-1:end));
        else
            dist1 = abs(currLocs - scaledLocStore(currT+1,1));
            dist2 = abs(currLocs - scaledLocStore(currT+1,2));
            [~,sortDists] = sort(dist1);
            scaledLocStore(currT,1) = currLocs(sortDists(1));
            [~,sortDists] = sort(dist2);
            scaledLocStore(currT,2) = currLocs(sortDists(1));
            scaledPeakStore(currT,:) = scaledMat(scaledLocStore(currT,:)+glassTop,currT);
        end
    end
end

%Shift back if sampling only part of the chamber
scaledLocStore = scaledLocStore + glassTop;

%% Plot separation of peaks over time
figure
plot(selectTimes*timeScale,movmean(scaledLocStore(:,1) - scaledLocStore(:,2),5)*pixelScale*.5);
xlabel('Time (hours)')
ylabel('Peak Separation (um)')
set(gca,'FontSize',15)

%% Verify detected peak locations
tmat = repmat([1:250]', [1 2]);
figure
[zCoords, tCoords] = ndgrid(1:size(scaledMat,1), 1:size(scaledMat,2));
surf(zCoords, tCoords, scaledMat, 'EdgeColor','none','FaceAlpha',.8)
xlabel('Height (voxel)')
ylabel('Time (frame)')
zlabel('Intensity (16bit)')
set(gca, 'FontSize',15)
hold on
scatter3(scaledLocStore(:), tmat(:), scaledPeakStore(:), 'filled','r')

%% Look at average intensity profile reflected around peak midpoint
midPoints = sum(scaledLocStore,2)/2;
figure
hold on
for index = 1:numel(midPoints)

    plot(scaledMat(glassTop:midPoints(index),index),'Color',[index/numel(midPoints) 0 (1 - index/numel(midPoints))])
    plot(scaledMat((end-glassBot):-1:midPoints(index),index),'--','Color',[index/numel(midPoints) 0 (1 - index/numel(midPoints))])

end

%difference in intensity
% figure
% for index = 1:numel(midPoints)
%     plot( scaledMat(glassTop:(glassTop + 50),index) - scaledMat((end-glassBot):-1:(end-glassBot - 50),index),'Color',[index/numel(midPoints) 0 (1 - index/numel(midPoints))])
%     hold on
% end

%% Get average intensity profile over some time range during which peak separation is relatively static
timeRange = 140:215;
meanProfile = mean(scaledMat(glassmeanTop:(end-glassBot),timeRange),2);
meanPeaks = round(mean(scaledLocStore(timeRange,:) - glassTop));
meanCenter = mean(meanPeaks);



%% Construct matrices to indicate regions inside and outside of detected peaks
tempMat = zeros(size(scaledMat));
peak1Inds = sub2ind(size(scaledMat), scaledLocStore(:,1),tmat(:,1));
tempMat(peak1Inds) = 1;
sheet1 = logical(cumsum(tempMat));

tempMat = zeros(size(scaledMat));
peak2Inds = sub2ind(size(scaledMat), scaledLocStore(:,2),tmat(:,2));
tempMat(peak2Inds) = 1;
sheet2 = logical(cumsum(tempMat,'reverse'));

innerSheet = ~(sheet1 | sheet2);
outerSheets = ~innerSheet;

%% Store mean values in and out
outMat1 = consMatLnB(scaledMat, sheet1);
outMat2 = consMatLnB(scaledMat, sheet2);
inMat = consMatLnB(scaledMat,innerSheet);


%% Iterate through time and store a size view to see if glass is detected when rescaled

%% 

% %% Look at log-log of bleach rate over time
% allTimes = 1:numel(bleachRate);
% numBins = 30;
% figure
% subplot(1,2,1)
% [~,edgeVals,binInds] = histcounts((allTimes),numBins);
% meanBinTimes = zeros(1,numel(edgeVals)-1);
% meanBinInts = meanBinTimes;
% for currBin = 1:max(binInds)
% 
%     meanBinTimes(currBin) = mean(allTimes(binInds == currBin));
%     meanBinInts(currBin) = mean(bleachRate(binInds == currBin));
% 
% end
% loglog((allTimes), (bleachRate)./(max(bleachRate(:))))
% hold on
% % scatter(meanBinTimes,meanBinInts./(max(bleachRate(:))),'filled')
% subplot(1,2,2)
% loglog(meanBinTimes(1:end-1), diff( meanBinInts./( max( meanBinInts(:) ) ) )./diff(meanBinTimes))

%% Store peak heights in storage and scaled matrices at each time
% peakStore = zeros(numel(selectTimes),2);
% scaledPeakStore = peakStore;
% locStore = peakStore;
% scaledLocStore = peakStore;
% 
% for currT = 1:numel(selectTimes)
%     
%     %Find peak vals to approximate position of height
%     [currPks,currLocs] = findpeaks(storageMat(glassTop:end-glassBot,currT));
%     [~,sortedLocs] = sort(currPks);
%     if numel(sortedLocs) > 1
%         peakStore(currT,:) = currPks(sortedLocs((end-1):end));
%         locStore(currT,:) = currLocs(sortedLocs(end-1:end));
%     else
%         peakStore(currT,:) = 0;
%         locStore(currT,:) = 0;
%     end
% 
%     [currPks,currLocs] = findpeaks(scaledMat(glassTop:end-glassBot,currT));
%     [~,sortedLocs] = sort(currPks);
%     if numel(sortedLocs) > 1
%         scaledPeakStore(currT,:) = currPks(sortedLocs((end-1):end));
%         scaledLocStore(currT,:) = currLocs(sortedLocs(end-1:end));
%     end
% 
% end
% 
% locStore(locStore>0) = locStore(locStore>0) + glassTop;
% scaledLocStore(scaledLocStore > 0) = scaledLocStore(scaledLocStore > 0) + glassTop;
