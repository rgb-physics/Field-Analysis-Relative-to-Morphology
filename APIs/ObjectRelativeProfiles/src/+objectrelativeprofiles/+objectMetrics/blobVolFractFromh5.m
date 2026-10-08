%% Calculates simple quantities like fraction occupied by blobs over time
% 2023/10/18 - 2023/10/26

% Data info
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 84';
h5Name = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 84';
imgName = 't%03i_illBleachCorr16bit_560.tif';
saveFileName = 'VolumeFracs_MTs.mat';

timeRange = 25;

h5Chans = 2;
% h5Chans = [1 2 3];
threshVal = 0.5;

outInOn = [3 1 2];  smoothBool = 0;

saveBool = 1;

%% From three channel segmentations (second pass)
allVols = zeros(numel(h5Chans),numel(timeRange));
allInts = zeros(numel(h5Chans),numel(timeRange));
totalInts = zeros(1,numel(timeRange));
for tInd = 1:numel(timeRange)
    % Load segmentation, if it exists
    currT = timeRange(tInd);
    currName = fullfile(h5Dir,sprintf(h5Name,currT));
    if isfile(currName)
        currTif = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        currSeg = loadH5(currName,'/exported_data',h5Chans);
    else
        timeRange(tInd) = -1;
        continue
    end
    % Store volumes of each partition
    if smoothBool == 1                                                                                                                      
        [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
            imresize3_4mat(currSeg,size(currTif)),outInOn,threshVal,2,1);
        allVols(:,tInd) = [sum(cleanOns(:)); sum(cleanOuts(:)); sum(cleanIns(:))];
        % Needs to be implemented for non-smooth case
        allInts(:,tInd) = [sum(consMatLnB(currTif, cleanOns),'all'); ...
            sum(consMatLnB(currTif, cleanOuts),'all'); ...
            sum(consMatLnB(currTif, cleanIns),'all')];
    else
        binSeg = imbinarize3_4D(imresize3(currSeg,size(currTif),'nearest'),threshVal);
        allVols(tInd) = sum(binSeg,'all');
        allInts(tInd) = sum(consMatLnB(currTif,binSeg),'all');
    end
    totalInts(tInd) = sum(currTif,'all');
end

timeRange = timeRange(timeRange>-1);    allVols = allVols(:,timeRange);
% totalInts = totalInts(timeRange);    
allInts = allInts(:,timeRange);
totalPix = numel(currTif);
save(fullfile(h5Dir,saveFileName),'timeRange','allVols','allInts','totalPix','totalInts');

%% Intensity distributions per region over time
% distSaveDir = '<redacted original absolute path>';
distSaveDir = 'Session 56, Exp 1';
distSaveName = 'T%03i_inoutonDists.%s';
for tInd = 1:numel(timeRange)
    % Load segmentation, if it exists
    currT = timeRange(tInd);
    currName = fullfile(h5Dir,sprintf(h5Name,currT));
    if isfile(currName)
        currTif = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        currSeg = loadH5(currName,'/exported_data',h5Chans);
    end
    % Generate distributions                                                                                                              
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
        imresize3_4mat(currSeg,size(currTif)),outInOn,threshVal,2,1);

    sampIns = consMatLnB(currTif,cleanIns);
    sampOuts = consMatLnB(currTif,cleanOuts);
    sampOns = consMatLnB(currTif,cleanOns);
    
    [inbin,inedge] = histcounts(sampIns(sampIns>0));
    [outbin,outedge] = histcounts(sampOuts(sampOuts>0));
    [onbin,onedge] = histcounts(sampOns(sampOns>0));

    scatter(inedge(1:end-1), inbin/sum(inbin),'filled');
    hold on
    scatter(outedge(1:end-1), outbin/sum(outbin),'filled');
    scatter(onedge(1:end-1), onbin/sum(onbin),'filled');
    legend('in','out','on')
    xlabel('Intensity')
    ylabel('Normalized Counts in Region')
    ylim([0 .25])
    title(sprintf('Intensity Distributions Time %03i',currT));
    set(gca,'FontSize',15)
    hold off

    saveas(gca,fullfile(distSaveDir,sprintf(distSaveName,currT,'png')));
    saveas(gca,fullfile(distSaveDir,sprintf(distSaveName,currT,'fig')));

end

%% Rescale Images
% figDir = '<redacted original absolute path>';
figDir = 'Session 56, Exp 1';
% pngDir = '<redacted original absolute path>';
pngDir = 'Session 56, Exp 1';
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    openfig(fullfile(figDir,sprintf(distSaveName,currT,'fig')));
    xlim([5000 32000])
    ylim([0 0.05])
    saveas(gca,fullfile(pngDir,sprintf(distSaveName,currT,'png')));
    saveas(gca,fullfile(distSaveDir,sprintf(distSaveName,currT,'fig')));
    close all
end



%% From two channel segmentations (first pass)
allVols2ch = zeros(size(timeRange));
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    currSeg = loadH5(fullfile(h5Dir2ch,sprintf(h5Name2ch,currT)),'/exported_data',h5Chans2ch);
    
end
totalPix2 = numel(currSeg(:,:,:,outIn(2)));
save(fullfile(h5Dir2ch,'VolumeFracs.mat'),'timeRange','allVols2ch','totalPix2');

