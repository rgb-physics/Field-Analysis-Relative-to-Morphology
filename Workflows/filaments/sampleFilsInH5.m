% This script takes in .h5 files of density segmentations, .h5 
% segmentations of single filaments, and tiffs of both dense MTs and 
% sparse MTs. It samples filaments in different density phase segmented
% regions, returning statistics on filament locations over time
% 9/29/2023
%% Data dir
% selFilsDir = '<redacted original absolute path>';
selFilsDir = 'Session 45, Exp 3';
selFilsName = 'Time%06i_filaments.tif';
% filSegsDir = '<redacted original absolute path>';
filSegsDir = 'Session 45, Exp 3';
filSegsName = 'Time%06i_gcorr_filaments_Probabilities.h5';
% denseSegDir = '<redacted original absolute path>';
denseSegDir = 'Session 45, Exp 3';
denseSegName = 'PassOne_t%03i_16bitSubSamp_Probabilities.h5';
% denseIntDir = '<redacted original absolute path>';
denseIntDir = 'Session 45, Exp 3';
denseIntName = 't%03i_illBleachCorr16bit.tif';

filh5chan = 2;
threshval = .7;

timeRange = 1:21;

saveBool = 1;
saveName = 'Time%03i_viewSegsFils.tif';
% saveDirAll = '<redacted original absolute path>';
saveDirAll = 'Session 45, Exp 3';
% saveDirSel = '<redacted original absolute path>';
saveDirSel = 'Session 45, Exp 3';

%% iterate through time using filtered filaments and dense segmentation
filFracVec = zeros(3,numel(timeRange));
intFracVec = filFracVec;
filFracVecSel = filFracVec;

for tInd = 1:numel(timeRange)
    %% Load segs and data
    currT = timeRange(tInd);
    currFils = tiffreadVolume(fullfile(selFilsDir,sprintf(selFilsName,currT)));
    currSegs = permute(h5read(fullfile(denseSegDir,sprintf(denseSegName,currT)),'/exported_data'),[1 3 2 4]);
    currFilSegs = permute(h5read(fullfile(filSegsDir,sprintf(filSegsName,currT)),'/exported_data'),[1 3 2 4]);     %Remember to permute x and y! 
    allFils = imbinarize(squeeze(currFilSegs(filh5chan,:,:,:)),threshval);
    currInts = double(tiffreadVolume(fullfile(denseIntDir,sprintf(denseIntName,currT))));
    segsDims = size(currSegs);
    
    %% Make 3D tensor of maxima
    [maxTensor, maxChanInds] = max(currSegs,[],1);
    scaledTensor = squeeze(maxTensor.*maxChanInds);
    
    %% Get volume fraction of sparse filaments in each seg
    binnedFils = allFils.*squeeze(maxChanInds);
    [numElmts, ~] = histcounts(binnedFils,1:(segsDims(1)+1));

    filFracVec(:,tInd) = numElmts/sum(numElmts);

    binnedFilsSel = logical(currFils).*squeeze(maxChanInds);
    [numElmts, ~] = histcounts(binnedFilsSel,1:(segsDims(1)+1));

    filFracVecSel(:,tInd) = numElmts/sum(numElmts);

    for chanInd = 1:segsDims(1)
        intFracVec(chanInd) = sum(consMatLnB(currInts,squeeze(maxChanInds)==chanInd),'all')/sum(currInts(:));
    end

    if saveBool == 1
        saveMatAll = 10*( squeeze(maxChanInds).*consMatLnB(ones(size(allFils)),~(allFils>0)) + 4*consMatLnB(ones(size(allFils)),allFils > 0) );
        save3DTiff(uint8(saveMatAll),fullfile(saveDirAll,sprintf(saveName,currT)));
        saveMatSel = 10*( squeeze(maxChanInds).*consMatLnB(ones(size(currFils)),~(currFils>0)) + 4*consMatLnB(ones(size(currFils)),currFils > 0) );
        save3DTiff(uint8(saveMatSel),fullfile(saveDirSel,sprintf(['Select_', saveName],currT)));
    end
end

%% Plot fracVec
figure
hold on
for regionInd = 1:segsDims(1)
    scatter(timeRange,filFracVec(regionInd,:),'filled');
end
xlabel('Region index')
ylabel('Fraction in region')
title('Fraction of ALL filament volumes in each segmented region')
set(gca,'FontSize',15)
legend('Outside','Inside','Surface')

%% Plot fracVec
figure
hold on
for regionInd = 1:segsDims(1)
    scatter(timeRange,filFracVecSel(regionInd,:),'filled');
end
xlabel('Region index')
ylabel('Fraction in region')
title('Fraction of SELECT filament volumes in each segmented region')
set(gca,'FontSize',15)
legend('Outside','Inside','Surface')


%% Plot fracVec
figure
hold on
for tInd = 1:numel(timeRange)
    plot(1:segsDims(1),filFracVecSel(:,tInd),'Color',[tInd/numel(timeRange) 0 (1 - tInd/numel(timeRange))]);
end
xlabel('Region index')
ylabel('Fraction in region')
title('Fraction of SELECT filament volumes in each segmented region')
set(gca,'FontSize',15)




