% Data loaded from Fourier Analysis and make plots
% 2026-06-22
% S88
% baseDir = 'Session 88';
% dataDirs = {'Exp 1', 'Exp 2', 'Exp 3', 'Exp 4 - Rmin Redo', 'Exp 5'};
% dataName = '600bin_structFactor2D_variables_600bin.mat';
% tFlips = {30,27,24,19,28};
% index = 2;
% dataDir = fullfile(baseDir,dataDirs{index}, '5 FFT Analysis');
% % saveDir = 'Session 88';
% % saveName = 'Exp%i_FFT_10-18FramesBeforeT0.%s';
% saveDir = 'Session 88';
% saveName = 'Exp%i_FFT_0-18FramesBeforeT0.%s';
% saveBool = 0;
% qtzOrder = [1 2 3];
% % zInd = 5:4:25; 
% zInd = 14;

% S81
index = 2;
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 2';
dataName = '500bin_powerSpectra_variables.mat';
tFlips = {'',34};
% dataDir = fullfile(baseDir,dataDirs{index}, '5 FFT Analysis');
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 2';
saveName = 'Exp%i_FFT_4-24-2_FramesBeforeT0.%s';
saveBool = 0;
qtzOrder = [1 3 2];
% zInd = 2:2:6; 
zInd = 4; 
tFlip = 34;  deltaT = .5;

%% Load data
load(fullfile(dataDir,dataName));
storeMat = permute(storeMat,qtzOrder);

% figure
%% Plot Spectra over time range, avged select z values
% Select times for full color + transpacrency
% movkern = 5;
zInd = 4; 
tFlip = tFlips{index};             % index of T = 0, typically indicated by <max(rho)>
deltaT = 0.5; 
% botLim = min(30,tFlip-1);
% S81 E2
% selectTimes = sort([(tFlip-botLim):2:(tFlip-14) (tFlip -12):4:(tFlip)]);
% selectTimes = sort(tFlip - (20:botLim));
% S 84 E1
% selectTimes = sort([(tFlip-botLim):2:(tFlip-14) (tFlip -12):4:(tFlip)]);
% selectTimes = sort(tFlip - (10:20));
% S S88 E1
% selectTimes = sort([(tFlip-botLim):2:(tFlip-14) (tFlip -12):4:(tFlip)]);
% selectTimes = sort(tFlip - (10:16));

% selectTimes = 38:40;
% selectTimes = sort(tFlip - (10:18));          % For EARLY TIMES ALL S88
% selectTimes = sort(tFlip - [0:2:18] );
% selectTimes = sort(tFlip - [-6:0] );
validTs = (selectTimes > 0);
selectTimes = selectTimes(validTs);

xmin = 1/110;
movkern = 5;
spacerLen = 0;

% Display boundaries
% xBnds = [4*10^(-3) .4];
% yBnds = [10^4 10^10];
xBnds = [2.4*10^(-3) .35];
yBnds = [10^2 5*10^7];

% Define boundaries for recolor
alphaVal = 0.2;
colorStr = 'BuPu3';
% Prepare colormap 
colorLen = 1 + max(selectTimes) - min(selectTimes);
colorInds = selectTimes + 1 - min(selectTimes);
timeColorArray = othercolor(colorStr,colorLen);
tcaAlpha = [timeColorArray, .8*ones(size(timeColorArray,1),1)];


% Space lines, if requested
if spacerLen > 0
    spacerVec = spacerLen.^selectTimes;
    yBnds(end) = yBnds(end)*spacerVec(end);
else
    spacerVec = ones(numel(selectTimes),1);
end

% Approximate peaks
xCut = find(scaledK > xmin, 1);
currK = scaledK(xCut:end-1);
selMat  = storeMat(xCut:end,selectTimes,zInd);
zAvgMat = squeeze(mean(selMat,3));
avged = movmean(zAvgMat,movkern);
% [maxVals,maxInds] = max(zAvgMat,[],1);
[maxVals,maxInds] = max(avged,[],1);
medQmax = 1/median(currK(maxInds));
meanQmax = 1/mean(currK(maxInds));

% Display strings
% titleTag = sprintf('Scattering - Z:%i ',selZ(zInd));
titleTag = sprintf('Exp %i, Median q_{max} - %02.02f, Mean q_{max} - %02.02f', index, medQmax,meanQmax );
xtitle = 'q (1/um)';
ytitle = 'Mean FFT Profile';

% Plot
figure
    hold on
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currField = zAvgMat(:,tInd);
    colorInd = colorInds(tInd);
    % plot(currK, currField*spacerVec(tInd),'Color',tcaAlpha(colorInd,1:3));
    scatter(currK, currField*spacerVec(tInd),10,'filled','MarkerFaceColor',tcaAlpha(colorInd,1:3));
    hold on
    plot(currK, avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color',tcaAlpha(colorInd,1:3));
    scatter(currK(maxInds(tInd)),maxVals(tInd),40,'Marker','^',...
        'MarkerFaceColor',tcaAlpha(colorInd,1:3),'MarkerEdgeColor','k');
end

set(gca,'FontSize',15)

xlabel(xtitle)
ylabel(ytitle)
title(titleTag)
xlim(xBnds)
ylim(yBnds)
temp = gca;
% temp.YTickLabel = [];
% temp.XTickLabel = [];
cbh = colorbar;
colormap(timeColorArray(colorInds,:));
cbh.Ticks = ([min(selectTimes) max(selectTimes)] - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
% cbh.Ticks = (selectTimes - min(selectTimes))/(max(selectTimes)- min(selectTimes)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selectTimes) max(selectTimes)]-tFlip)*deltaT) ; 
set(gca,'XScale','log','YScale','log');
box on

if saveBool == 1
    saveas(gca,fullfile(saveDir,sprintf(saveName,index,'fig')));
    saveas(gca,fullfile(saveDir,sprintf(saveName,index,'png')));
    saveas(gca,fullfile(saveDir,sprintf(saveName,index,'svg')));
else
    fprintf('Figures not saved \n')
end

%% Get all peaks and store
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 2';
saveExts = {'fig','png','svg'};
saveBool = 1;
xmin = 1/110;
spacerLen = 0;
shftTimes = (selectTimes - tFlip)*deltaT;
% Space lines, if requested
if spacerLen > 0
    spacerVec = spacerLen.^selectTimes;
    yBnds(end) = yBnds(end)*spacerVec(end);
else
    spacerVec = ones(numel(selectTimes),1);
end

% Define boundaries for recolor
alphaVal = 0.2;
colorStrZ = 'YlGnBu5';
% Prepare colormap 
colorLenZ = 1 + max(selZ) - min(selZ);
colorIndsZ = selZ + 1 - min(selZ);
timeColorArrayZ = othercolor(colorLenZ,colorLenZ);
tcaAlphaZ = [timeColorArrayZ, .8*ones(size(timeColorArrayZ,1),1)];

% Approximate peaks
xCut = find(scaledK > xmin, 1);
currK = scaledK(xCut:end-1);
selMat  = storeMat(xCut:end,:,:);  % replace selecttimes, iterate over zInd
qAvged = movmean(selMat,movkern,1);
[maxVals,maxInds] = (max(selMat,[],1));
[maxValsAvgd,maxIndsAvgd] = (max(qAvged,[],1));

% Plot
figure
hold on
currField = 1./currK(squeeze(maxInds));
for zIndex = 1:numel(selZ)
    colorIndZ = colorIndsZ(zIndex);
    
    % plot(currK, currField*spacerVec(tInd),'Color',tcaAlpha(colorInd,1:3));
    scatter(shftTimes, currField(:,zIndex),20,...
        'MarkerFaceColor',tcaAlphaZ(colorIndZ,1:3),'MarkerEdgeColor','k');
    hold on

end
set(gca,'FontSize',15)
xlabel('Time (min)')
ylabel('1/q_{max} (um)')
cbh = colorbar;
colormap(timeColorArrayZ(colorIndsZ,:));
cbh.Ticks = ([min(selZ) max(selZ)] - min(selZ))/(max(selZ)- min(selZ)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selZ) max(selZ)])) ; 
box on
title('q_{max} from pure data')
ylim([0 100])
visualizationtools.export.figSaves(gca,saveDir,'PkQ_AllZandT_noAvg',saveExts,saveBool);


% Plot averaged
figure
hold on
currField = 1./currK(squeeze(maxIndsAvgd));
for zIndex = 1:numel(selZ)
    colorIndZ = colorIndsZ(zIndex);
    
    % plot(currK, currField*spacerVec(tInd),'Color',tcaAlpha(colorInd,1:3));
    scatter(shftTimes, currField(:,zIndex),20,...
        'MarkerFaceColor',tcaAlphaZ(colorIndZ,1:3),'MarkerEdgeColor','k');
    hold on

end
set(gca,'FontSize',15)
xlabel('Time (min)')
ylabel('1/q_{max} (um)')
cbh = colorbar;
colormap(timeColorArrayZ(colorIndsZ,:));
cbh.Ticks = ([min(selZ) max(selZ)] - min(selZ))/(max(selZ)- min(selZ)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selZ) max(selZ)])) ; 
box on
title('q_{max} after moving average in q')
ylim([0 100])
visualizationtools.export.figSaves(gca,saveDir,'PkQ_AllZandT_MovMeanQ',saveExts,saveBool);

%% Concatenate all of S88 data

% S88
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 88';
% dataDirs = {'Exp 1'};
dataDirs = {'Exp 1', 'Exp 2', 'Exp 3', 'Exp 4 - Rmin Redo', 'Exp 5'};
dataName = '600bin_structFactor2D_variables_600bin.mat';
tFlips = {30,27,24,19,28};
% saveDir = 'Session 88';
% saveName = 'Exp%i_FFT_10-18FramesBeforeT0.%s';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 88';
saveName = 'Exp%i_FFT_0-18FramesBeforeT0.%s';
saveBool = 0;
qtzOrder = [1 2 3];
deltaT = 0.5;
% zInd = 5:4:25; 
% zInd = 14;

% iterate over directories, concatenate data and make key
totMat = [];
timeKey = [];
for index = 1:numel(dataDirs)
    tFlip = tFlips{index};
    dataDir = fullfile(baseDir,dataDirs{index}, '5 FFT Analysis');
    load(fullfile(dataDir,dataName));
    storeMat = permute(storeMat,qtzOrder);
    totMat = [totMat, storeMat];                        % stitch data along time dimension
    timeKey = [timeKey, (selectTimes - tFlip)*deltaT];  % vector of times in min
end
frameKey = repmat(selectTimes,1,5);                     % vector of times in frames

%% Plot all q_max peaks across each z-slice at each time
saveBool = 0;
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 88';
saveExts = {'fig','png','svg'};
xmin = 1/110;
movkern = 5;
% Define boundaries for recolor
alphaVal = 0.2;
colorStrZ = 'YlGnBu5';
% Prepare colormap 
colorLenZ = 1 + max(selZ) - min(selZ);
colorIndsZ = selZ + 1 - min(selZ);
timeColorArrayZ = othercolor(colorStrZ,colorLenZ);
tcaAlphaZ = [timeColorArrayZ, .8*ones(size(timeColorArrayZ,1),1)];

% Approximate peaks
xCut = find(scaledK > xmin, 1);
currK = scaledK(xCut:end-1);
selMat  = totMat(xCut:end,:,:);  % replace selecttimes, iterate over zInd
qAvged = movmean(selMat,movkern,1);
[maxVals,maxInds] = (max(selMat,[],1));
[maxValsAvgd,maxIndsAvgd] = (max(qAvged,[],1));

% Plot
figure
hold on
currField = 1./currK(squeeze(maxInds));
for zIndex = 1:numel(selZ)
    colorIndZ = colorIndsZ(zIndex);
    
    % plot(currK, currField*spacerVec(tInd),'Color',tcaAlpha(colorInd,1:3));
    scatter(timeKey, currField(:,zIndex),100 - 3*zIndex,...
        'MarkerFaceColor',tcaAlphaZ(colorIndZ,1:3));
        % 'MarkerFaceColor',tcaAlphaZ(colorIndZ,1:3),'MarkerEdgeColor','k');
    hold on

end
set(gca,'FontSize',15)
xlabel('Time (min)')
ylabel('1/q_{max} (um)')
cbh = colorbar;
colormap(timeColorArrayZ(colorIndsZ,:));
cbh.Ticks = ([min(selZ) max(selZ)] - min(selZ))/(max(selZ)- min(selZ)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selZ) max(selZ)])) ; 
box on
title('q_{max} from pure data')
ylim([0 100])
visualizationtools.export.figSaves(gca,saveDir,'PkQ_AllZandT_noAvg',saveExts,saveBool);

% Plot averaged
figure
hold on
currField = 1./currK(squeeze(maxIndsAvgd));
for zIndex = 1:numel(selZ)
    colorIndZ = colorIndsZ(zIndex);
    
    % plot(currK, currField*spacerVec(tInd),'Color',tcaAlpha(colorInd,1:3));
    scatter(timeKey, currField(:,zIndex),20,...
        'MarkerFaceColor',tcaAlphaZ(colorIndZ,1:3),'MarkerEdgeColor','k');
    hold on

end
set(gca,'FontSize',15)
xlabel('Time (min)')
ylabel('1/q_{max} (um)')
cbh = colorbar;
colormap(timeColorArrayZ(colorIndsZ,:));
cbh.Ticks = ([min(selZ) max(selZ)] - min(selZ))/(max(selZ)- min(selZ)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selZ) max(selZ)])) ; 
box on
title('q_{max} after moving average in q')
ylim([0 100])
visualizationtools.export.figSaves(gca,saveDir,'PkQ_AllZandT_MovMeanQ',saveExts,saveBool);

%% Imagesc max matrices
% Sort matrix by global time
[sortTimes,sortOrder] = sort(timeKey);
currField = 1./currK(squeeze(maxIndsAvgd));
reorderField = currField(sortOrder,:);
cBnds = [0 100];

xtickNum = 10;      
tickLen = length(frameKey); tickSpace = round(tickLen)/xtickNum;
figure
imagesc(reorderField')
cbh = colorbar;
colormap(timeColorArrayZ(colorIndsZ,:));
clim(cBnds);
% cbh.Ticks = ([min(selZ) max(selZ)] - min(selZ))/(max(selZ)- min(selZ)) ; %Create 8 ticks from zero to 1
cbh.Ticks = ([min(selZ) max(selZ)] ) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(([min(selZ) max(selZ)])) ; 

axisHandle = gca;
axisHandle.XTick = tickSpace:tickSpace:tickLen;
axisHandle.XTickLabel = sortTimes(tickSpace:tickSpace:tickLen);



