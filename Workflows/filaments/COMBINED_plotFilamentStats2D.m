
% 2023-12-05
% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 56, Exp 1';
timeRange = 1:100;
imgSize = [740 750 75];
pixSize = 11*2/60;
deltarBins = -60:2:30;

timeColorVec = [1 0 0; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
timeColorStamps = [1 6 20 32 80 100];
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);


%% load data
load(fullfile(filDataDir,'Concatenated_2D_Info.mat'))
load(fullfile(filDataDir,'FilamentAlignment_AngleData.mat'));
allThetaDiffs = bndmod(allThetas - gradThetas,-pi/2,pi/2);
% orderParam = cos(allThetaDiffs);
orderParam = -1/2*(3*cos(allThetaDiffs).^2 - 1).*sin(allThetaDiffs);     % x = cos(t), dx = -sin(t) 

%% Mean alignment w/ errorbars per delta r over time
meanStore = zeros(numel(deltarBins),numel(timeRange));
stdStore = meanStore;   countStore = meanStore;
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    timeFilt = generalFilt & (objInds == currT);
    currAligns = orderParam(timeFilt);
    currDeltaRs = deltaRs(timeFilt);
    [currBins,~,currInds] = histcounts(currDeltaRs,deltarBins);
    for rInd = 1:numel(deltarBins)
        currSel = currAligns(currInds == rInd);
        if numel(currSel) > 0
            meanStore(rInd,currT) = mean(currAligns(currInds == rInd));
            stdStore(rInd,currT) = std(currAligns(currInds == rInd));
        end
        countStore(1:end-1,tInd) = currBins(:)/sum(timeFilt);
    end
end

%% Distributions of deltaRs over time
selRange = 1:5:numel(timeRange);
figure
hold on
for tInd = 1:numel(selRange)
    currT = selRange(tInd);
    timeFilt = generalFilt & (objInds == currT);
    currN = countStore(1:(end-1),currT);
    % plot((deltarBins(1:end-1) + deltarBins(2:end))/2,currN/sum(timeFilt),'Color',[tInd/numel(timeRange) 0 (1 - tInd/numel(timeRange))],'LineWidth',3)
    plot((deltarBins(1:end-1) + deltarBins(2:end))/2*pixSize,currN/sum(timeFilt),'LineWidth',3)
end
colororder(timeColorArray(selRange,:))
xlabel('Filament Distances from Blob Bounds (um)')
ylabel('Filament Fraction')
title('Distributions of Filament Positions Over Time')
set(gca, 'FontSize', 15)
xlim([-21 10])

%% Mean alignments with errorbars over time
selTimes = 1:numel(timeRange);
figure
hold on
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    timeFilt = generalFilt & (objInds == currT);
    currMeans = meanStore(1:end-1,currT);    currStds = stdStore(1:end-1,currT);
    % plot((deltarBins(1:end-1) + deltarBins(2:end))/2,currN/sum(timeFilt),'Color',[tInd/numel(timeRange) 0 (1 - tInd/numel(timeRange))],'LineWidth',3)
    errorbar((deltarBins(1:end-1) + deltarBins(2:end))/2*pixSize,currMeans,currStds);
    % errorbar((deltarBins(1:end-1) + deltarBins(2:end))/2*pixSize,currMeans,currStds,'.','MarkerSize',10);
    % scatter((deltarBins(1:end-1) + deltarBins(2:end))/2*pixSize,currMeans,25,'filled')
    % scatter((deltarBins(1:end-1) + deltarBins(2:end))/2*pixSize,currStds,35)
end
% currColorArray = zeros(2*numel(selTimes),3);
% currColorArray(1:2:end,:) = timeColorArray(selRange,:);
% currColorArray(2:2:end,:) = timeColorArray(selRange,:);
currColorArray = timeColorArray(selTimes,:);
colororder(currColorArray)
ylabel('Mean Filament Alignment per \Deltar')
xlabel('Distance to Surface (um)')
title('Mean Alignment Over Time')
set(gca, 'FontSize', 20)
xlim([-21 10])
ylim([0 1])

%% Heat map of distribution of deltaRs over time
figure
imagesc(countStore)
xlabel('Time')
ylabel('\Deltar bin')
colorbar
set(gca,'FontSize',20)

%% Distribution of alignments in bins around deltaR = 0 (in, on, out regions)
onRange = [-3 10];  alignEdges = 0:.02:1;
storeMat = zeros(numel(alignEdges), numel(timeRange));
figure
hold on
for tInd = 1:numel(timeRange)
    timeFilt = generalFilt & (objInds == tInd);
    onFilt = timeFilt & (deltaRs >= min(onRange)) & (deltaRs <= max(onRange));
    storeMat(1:end-1,tInd) = histcounts(allAligns(onFilt),alignEdges);
    % [storeMat(1:end,tInd),~,currInds] = histcounts(deltaRs(onFilt),min(onRange):max(onRange));
end
colorVec = [0 0 1; 1 0 0];  
colorarray = meldNcolors(colorVec,numel(timeRange));
plot(alignEdges,storeMat./sum(storeMat,1));
colororder(colorarray)

%% Distribution of angles diffs in bins around deltaR = 0 (in, on, out regions)
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';
saveStr = 'SPARSE Theta Difference %s micelle perimeter over time.%s';
onRange = [-3 10];  diffEdges = -pi/2:pi/60:pi/2;
ylimrange = [0 0.05];   xlimrange = [-pi/2 pi/2];
selRange = 1:80; lineWidthVal = 3;
saveBool = 0;
currColorArray = timeColorArray(selRange,:);

currStr = 'ON'; currRange = '(-1.1 to 3.7 um)';
storeMatON = zeros(numel(diffEdges), numel(selRange));
figure
hold on
for tInd = 1:numel(selRange)
    currT = selRange(tInd);
    timeFilt = generalFilt & (objInds == currT);
    onFilt = timeFilt & (deltaRs >= min(onRange)) & (deltaRs <= max(onRange));
    storeMatON(1:end-1,tInd) = histcounts(allThetaDiffs(onFilt),diffEdges);
end
plot(diffEdges,storeMatON./sum(storeMatON,1),'LineWidth',lineWidthVal);
colororder(currColorArray)
title(sprintf('Theta Difference %s Drop Perimeter %s',currStr,currRange))
subtitle('')
xlabel('Angle Difference')
ylabel('Fraction of Sampled Filaments')
set(gca,'FontSize',15)
ylim(ylimrange);  xlim(xlimrange);
set(gcf,'Position',[100 100 900 800])
if saveBool == 1
    exportgraphics(gcf,fullfile(saveDir,sprintf(saveStr,currStr,'png')));
    saveas(gca,fullfile(saveDir,sprintf(saveStr,currStr,'fig')));
end

currStr = 'INSIDE'; currRange = '(above 3.7um)';
storeMatIN = zeros(numel(diffEdges), numel(selRange));
figure
hold on
for tInd = 1:numel(selRange)
    currT = selRange(tInd);
    timeFilt = generalFilt & (objInds == currT);
    onFilt = timeFilt & (deltaRs >= max(onRange));
    storeMatIN(1:end-1,tInd) = histcounts(allThetaDiffs(onFilt),diffEdges);
end
plot(diffEdges,storeMatIN./sum(storeMatIN,1),'LineWidth',lineWidthVal);
colororder(currColorArray)
title(sprintf('Theta Difference %s Drop Perimeter %s',currStr,currRange))
subtitle('')
xlabel('Angle Difference')
ylabel('Fraction of Sampled Filaments')
set(gca,'FontSize',15)
ylim(ylimrange);  xlim(xlimrange);
set(gcf,'Position',[100 100 900 800])
if saveBool == 1
    exportgraphics(gcf,fullfile(saveDir,sprintf(saveStr,currStr,'png')));
    saveas(gca,fullfile(saveDir,sprintf(saveStr,currStr,'fig')));
end

currStr = 'OUTSIDE'; currRange = '(below -1.1um)';
storeMatOUT = zeros(numel(diffEdges), numel(selRange));
figure
hold on
for tInd = 1:numel(selRange)
    currT = selRange(tInd);
    timeFilt = generalFilt & (objInds == currT);
    onFilt = timeFilt & (deltaRs <= min(onRange));
    storeMatOUT(1:end-1,tInd) = histcounts(allThetaDiffs(onFilt),diffEdges);
end
plot(diffEdges,storeMatOUT./sum(storeMatOUT,1),'LineWidth',lineWidthVal);
colororder(currColorArray)
title(sprintf('Theta Difference %s Drop Perimeter %s',currStr,currRange))
subtitle('')
xlabel('Angle Difference')
ylabel('Fraction of Sampled Filaments')
set(gca,'FontSize',15)
ylim(ylimrange);  xlim(xlimrange);
set(gcf,'Position',[100 100 900 800])
if saveBool == 1
    exportgraphics(gcf,fullfile(saveDir,sprintf(saveStr,currStr,'png')));
    saveas(gca,fullfile(saveDir,sprintf(saveStr,currStr,'fig')));
end

figure
currStr = 'ALL'; currRange = 'All';
storeMatALL = zeros(numel(diffEdges), numel(selRange));
hold on
for tInd = 1:numel(selRange)
    currT = selRange(tInd);
    timeFilt = generalFilt & (objInds == currT);
    allFilt = timeFilt;
    storeMatALL(1:end-1,tInd) = histcounts(allThetaDiffs(allFilt),diffEdges);
end
plot(diffEdges,storeMatALL./sum(storeMatALL,1),'LineWidth',lineWidthVal);
colororder(currColorArray)
title(sprintf('Theta Difference %s Drop Perimeter %s',currStr,currRange))
subtitle('')
xlabel('Angle Difference')
ylabel('Fraction of Sampled Filaments')
set(gca,'FontSize',15)
ylim(ylimrange);  xlim(xlimrange);
set(gcf,'Position',[100 100 900 800])
if saveBool == 1
    exportgraphics(gcf,fullfile(saveDir,sprintf(saveStr,currStr,'png')));
    saveas(gca,fullfile(saveDir,sprintf(saveStr,currStr,'fig')));
end

%% Smooth storemats
figure
currField = storeMatON; rollWin = 5;
smoothField = movmean(currField,rollWin,1);
normField = smoothField./sum(smoothField,1);
plot(diffEdges,normField,'LineWidth',2);
colororder(timeColorArray)

%% Plot order parameter over time in 3 regions
selRange = 1:80;
currStr = 'ON'; currRange = '(-1.1 to 3.7 um)';
storeMat = zeros(3, numel(selRange));
stdMat = storeMat;
onRange = [-3 10];  diffEdges = -pi/2:pi/60:pi/2;

figure
% hold on
for tInd = 1:numel(selRange)
    currT = selRange(tInd);
    timeFilt = generalFilt & (objInds == currT);
    onFiltSub = (deltaRs(timeFilt) >= min(onRange)) & (deltaRs(timeFilt) <= max(onRange));
    inFiltSub = (deltaRs(timeFilt) >= max(onRange));
    outFiltSub = (deltaRs(timeFilt) <= min(onRange));
    onFilt = timeFilt & (deltaRs >= min(onRange)) & (deltaRs <= max(onRange));
    inFilt = timeFilt & (deltaRs >= max(onRange));
    outFilt = timeFilt & (deltaRs <= min(onRange));
    % Sample f(theta) from corresponding smoothfield
    [~,~,inds] = histcounts(allThetaDiffs(timeFilt),diffEdges);
    f_of_th = normField(inds,currT);
    orderScaledON = orderParam(onFilt).*f_of_th(onFiltSub)';
    orderScaledIN = orderParam(inFilt).*f_of_th(inFiltSub)';
    orderScaledOUT = orderParam(outFilt).*f_of_th(outFiltSub)';
    storeMat(:,tInd) = [mean(orderScaledON),...
        mean(orderScaledIN), mean(orderScaledOUT)];
    stdMat(:,tInd) = [std(orderScaledON),...
        std(orderScaledIN), std(orderScaledOUT)];
end
% errorbar(selRange,storeMat,stdMat)
plot(selRange,storeMat)

%% Distribution of difference in theta_fil and theta_segGradient
selTimes = 10:5:100;
selRs = -60:10:30;      rWidth = 2;
binEdges = 0:pi/30:pi;
diffStore = zeros(numel(selRs),numel(selTimes));

colorVec = [128,128,0; 200 15 210]/255;  
colorarray = meldNcolors(colorVec,numel(selRs));

% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';

for tInd = 1:numel(selTimes)
    figure
    hold on
    timeFilt = generalFilt & (objInds == tInd);
    for rInd = 1:numel(selRs)
        currFilt = (timeFilt & (deltaRs <= selRs(rInd) + rWidth) & (deltaRs >= selRs(rInd) - rWidth));
        currDiffs = allThetaDiffs(currFilt);
        temp = histcounts(currDiffs,binEdges);
        plot(binEdges(1:end-1),temp/sum(temp),'Color',colorarray(rInd,:),'LineWidth',3)
        title(sprintf('Time %03i delR %03i',selTimes(tInd),selRs(rInd)))
    end
    ylim([0 0.2])
    set(gcf,'Position',[100 100 900 800])
    
    exportgraphics(gcf,fullfile(saveDir,[sprintf('Time %03i delR %03i',selTimes(tInd),selRs(rInd)) '.png']));
    close();

end

