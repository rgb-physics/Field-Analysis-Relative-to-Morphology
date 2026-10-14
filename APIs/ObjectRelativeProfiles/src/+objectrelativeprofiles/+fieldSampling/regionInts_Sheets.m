% Rough: sample intensities in different regions of sheets and get
% statistics

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 28, Exp 6';
imgName = 't%03i_illBleachCorr16bit.tif';
% splitSegDir = '<redacted original absolute path>';
splitSegDir = 'Session 28, Exp 6';
splitSegName = 'SplitRegions_Time%06i.mat';
% meshDir = '<redacted original absolute path>';
meshDir = 'Session 28, Exp 6';
meshData = 'DataStoreStructT%03i_scatInt_top.mat';

% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';

binEdges = 0:100:32000;
selTimes = 150:280;
% Matrix sizes stored in metadata
load(fullfile(splitSegDir,'metadata.mat'));
structVar = 'regionStruct';
fieldNames = {'TopSheet','TopRegion','BotRegion','BotSheet','MidRegion'};

% Int to mg conversion 
int2uM = 41/10000;

%% Iterate over time, sample intensities, save histograms from segmentations
% histSaveDir = '<redacted original absolute path>';
histSaveDir = 'Session 28, Exp 6';
histNames = 'T%06i_ints.%s';
saveFormats = {'svg','tif'};

if ~exist(histSaveDir,'dir')
    mkdir(histSaveDir);
end
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    % Load
    currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    currStruct = load(fullfile(splitSegDir,sprintf(splitSegName,currT)),structVar).(structVar);

    % Iterate over each field
    figure
    for index = 1:numel(fieldNames)
        currField = fieldNames{index};
        currInds = currStruct.(currField);
        imgInds = rescaleCoords_Inds(currInds,segSize,imgSize);
        sampInts = currImg(imgInds);
        binCounts = histcounts(sampInts,binEdges);
        plot(binEdges(1:end-1)*int2uM,binCounts/sum(binCounts));
        % histogram(sampInts,binEdges);
        hold on
    end
    legend(fieldNames)
    xlabel('[MT] (uM)')
    ylabel('Fraction')
    title(sprintf('Frame: %i',currT));
    set(gca,'FontSize',15);
    for index = 1:numel(saveFormats)
        currForm = saveFormats{index};
        saveas(gcf,fullfile(histSaveDir,sprintf(histNames,currT,currForm)));
    end
    close()

end

%% From meshes, plot mean intensity vs height
% histSaveDir = '<redacted original absolute path>';
histSaveDir = 'Session 28, Exp 6';
histNames = 'T%06i_ints.%s';
saveFormats = {'svg','tif'};
structVar = 'currStruct';
meanHeights = zeros(numel(selTimes),1);
hBins = 0:2.5:75;
dispInds = 1:2:numel(hBins);
intBins = 0:100:18000;
if ~exist(histSaveDir,'dir')
    mkdir(histSaveDir);
end
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    % Load
    currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    currStruct = load(fullfile(meshDir,sprintf(meshData,currT)),structVar).(structVar);
    % Load vertices and intensities
    vertLocs = currStruct.v;
    vertInts = currStruct.intV;
    % Get indices of vertices in scaled matrix
    vertInds = sub2ind(round(imgSize.*ogVoxSize),round(vertLocs(:,2)),round(vertLocs(:,1)),round(vertLocs(:,3)));
    % Get mean sheet height
    meanHeights(tInd) = mean(vertLocs(:,3));
    % Bin heights
    hBinsShft = hBins - meanHeights(tInd);
    [binNum,test,binInds] = histcounts(vertLocs(:,3) - meanHeights(tInd),hBinsShft);

    figure
    for currDisp = (dispInds)
        % Select indices for current height bin
        currInds = binInds == currDisp;
        currBin = hBinsShft(currDisp);
        % Convert indices to image space, then sample
        if sum(currInds) > 1000
            indsImg = rescaleCoords_Inds(vertInds(currInds),round(imgSize.*ogVoxSize),imgSize);
            currInts = currImg(indsImg);
            visualizationtools.display.manVlnPlot(currBin,currInts*int2uM,intBins*int2uM,2)
            hold on
        else
            continue
        end

    end
    xlabel('Distance to Mean H (um)')
    ylabel('Intensity (uM)')
    title(sprintf('Frame: %i',currT))
    ylim([0 80])
    xlim([-20 30])
    set(gca,'FontSize',15)
    % Save
    for index = 1:numel(saveFormats)
        currForm = saveFormats{index};
        % saveas(gcf,fullfile(histSaveDir,sprintf(histNames,currT,currForm)));
    end
    close();
end

%% From meshes, plot mean intensity vs Curvature at select heights
% histSaveDir = '<redacted original absolute path>';
histSaveDir = 'Session 28, Exp 6';
histNames = 'T%06i_ints.%s';
saveFormats = {'svg','tif'};
structVar = 'currStruct';
meanHeights = zeros(numel(selTimes),1);
hvBins = -.15:.01:.15;
dispInds = 1:2:numel(hvBins);
intBins = 0:100:18000;
hRangeFromMean = [-15 -5];

if ~exist(histSaveDir,'dir')
    mkdir(histSaveDir);
end
for tInd = 1:numel(selTimes)


    currT = selTimes(tInd);
    % Load
    currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    currStruct = load(fullfile(meshDir,sprintf(meshData,currT)),structVar).(structVar);
    % Load vertices and intensities
    vertLocs = currStruct.v;
    vertInts = currStruct.intV;
    % Get indices of vertices in scaled matrix
    vertInds = sub2ind(round(imgSize.*ogVoxSize),round(vertLocs(:,2)),round(vertLocs(:,1)),round(vertLocs(:,3)));
    % Get curvature
    smoothHV = currStruct.curvV;
    [binNum,~,binInds] = histcounts(smoothHV,hvBins);

    % Get mean sheet height
    meanHeights(tInd) = mean(vertLocs(:,3));
    % Shft heights, then cutoff
    shftH = vertLocs(:,3) - meanHeights(1);
    hLogic = (shftH > min(hRangeFromMean)) & (shftH < max(hRangeFromMean));
        
    figure
    for currDisp = (dispInds)
        % Select indices for current height bin
        currInds = (binInds == currDisp) & hLogic;
        currBin = hvBins(currDisp);
        % Convert indices to image space, then sample
        if sum(currInds) > 200
            indsImg = rescaleCoords_Inds(vertInds(currInds),round(imgSize.*ogVoxSize),imgSize);
            currInts = currImg(indsImg);
            visualizationtools.display.manVlnPlot(currBin,currInts*int2uM,intBins*int2uM,.02)
            hold on
        else
            continue
        end

    end
    xlabel('Curvature')
    ylabel('Intensity (uM)')
    title(sprintf('Frame: %i',currT))
    ylim([35 60])
    xlim([-.15 .15])
    set(gca,'FontSize',15)
    % Save
    for index = 1:numel(saveFormats)
        currForm = saveFormats{index};
        saveas(gcf,fullfile(histSaveDir,sprintf(histNames,currT,currForm)));
    end
    close();
    
end

%% View curvature vs density 

% histSaveDir = '<redacted original absolute path>';
histSaveDir = 'Session 28, Exp 6';
histNames = 'T%06i_ints.%s';
saveFormats = {'svg','tif'};
structVar = 'currStruct';
meanHeights = zeros(numel(selTimes),1);
hvBins = -.15:.01:.15;
dispInds = 1:2:numel(hvBins);
intBins = 0:100:18000;
if ~exist(histSaveDir,'dir')
    mkdir(histSaveDir);
end
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    % Load
    currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    currStruct = load(fullfile(meshDir,sprintf(meshData,currT)),structVar).(structVar);
    % Load vertices and intensities
    vertLocs = currStruct.v;
    vertInts = currStruct.intV;
    % Get indices of vertices in scaled matrix
    vertInds = sub2ind(round(imgSize.*ogVoxSize),round(vertLocs(:,2)),round(vertLocs(:,1)),round(vertLocs(:,3)));
    % Get curvature
    smoothHV = currStruct.curvV;
    [binNum,test,binInds] = histcounts(smoothHV,hvBins);

    figure
    for currDisp = (dispInds)
        % Select indices for current height bin
        currInds = binInds == currDisp;
        currBin = hvBins(currDisp);
        % Convert indices to image space, then sample
        if sum(currInds) > 200
            indsImg = rescaleCoords_Inds(vertInds(currInds),round(imgSize.*ogVoxSize),imgSize);
            currInts = currImg(indsImg);
            visualizationtools.display.manVlnPlot(currBin,currInts*int2uM,intBins*int2uM,.02)
            hold on
        else
            continue
        end

    end
    xlabel('Curvature')
    ylabel('Intensity (uM)')
    title(sprintf('Frame: %i',currT))
    ylim([35 60])
    xlim([-.15 .15])
    set(gca,'FontSize',15)
    % Save
    for index = 1:numel(saveFormats)
        currForm = saveFormats{index};
        saveas(gcf,fullfile(histSaveDir,sprintf(histNames,currT,currForm)));
    end
    close();
    
end



%% Pearson covariance - cov(a,b)/(std(a)*std(b))

structVar = 'currStruct';
iBnds = [8000 18000];
curvBnds = [-.25 .25];
test = selTimes;
test2 = test;
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    currStruct = load(fullfile(meshDir,sprintf(meshData,currT)),structVar).(structVar);
    currInts = currStruct.intV;
    currHV = currStruct.curvV;
    currV = currStruct.v;

    % Get data points in boundaries
    iLogic = (currInts > iBnds(1)) & (currInts < iBnds(2));
    curvLogic = (currHV > curvBnds(1)) & (currHV < curvBnds(2));
    totLogic = iLogic & curvLogic;
    cutInts = currInts(totLogic);
    cutHV = currHV(totLogic); 

    cutHeights = currV(totLogic,3);

    temp = corrcoef(cutHV,cutInts);
    test(tInd) = temp(2);
    temp = corrcoef(cutHeights,cutInts);
    test2(tInd) = temp(2);

end

figure
scatter(selTimes,test)
hold on
scatter(selTimes,test2);

%% Display select scatter plots


structVar = 'currStruct';
iBnds = [8000 18000];
curvBnds = [-.25 .25];
selT = [43 59 72 101 115];
for tInd = 1:numel(selT)

    currT = selTimes(selT(tInd));
    currStruct = load(fullfile(meshDir,sprintf(meshData,currT)),structVar).(structVar);
    currInts = currStruct.intV;
    currHV = currStruct.curvV;
    currV = currStruct.v;

    % Get data points in boundaries
    iLogic = (currInts > iBnds(1)) & (currInts < iBnds(2));
    curvLogic = (currHV > curvBnds(1)) & (currHV < curvBnds(2));
    totLogic = iLogic & curvLogic;
    cutInts = currInts(totLogic);
    cutHV = currHV(totLogic); 
    a = histcounts2(cutHV,cutInts);

   figure
   % scatter(cutHV,cutInts,'filled');
   imagesc(a);
   title(sprintf('Frame: %i',currT));

end



