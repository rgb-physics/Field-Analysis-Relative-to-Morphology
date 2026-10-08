% Batch analysis of average intensity as a function of perimeters of a
% series of objects over time. This version of the script takes in Tifs of
% objects that are or can readily be binarized using logical. 
% Rémi Boros, 2023-12-13, 2024-01-04, 2024-03-28, 2024-04-24

%% Directory info
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 81, Exp 3';
denseImgDir = fullfile(baseDir,'6 Illumination Bleach Corrected 16bit');
denseImgName = 't%03i_illBleachCorr16bit_%03i.tif';
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 81, Exp 3';
blobName = 't%03i_illBleachCorr16bit.tif';

% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveName = 't%i-%i_radialDensityDataNOMASK-%03i.mat';
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

selChan = 560;
timeRange = 1:125;
deltaT = 0.5;
pixSize = 11*2/60;
pixSize3D = [11*2/60 11*2/60 1.5];
deltaRBins = -30:.5:30;      % In um
dSmthKern = 2;        % Gaussian smooth distance transform, then bin
blobThresh = 50;
fastCalc = 0;               % Trade off speed for accuracy by ordering the rescaling

% Color map info
timeColorVec = [1 0.5 0.5; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
timeColorStamps = [1 8 22 38 100 270];
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

% timeColorVec = [1 0 0; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
% % timeColorStamps = [1 25 50 75 100];
% % timeColorStamps = [1 5 19 37 110 250];     % Session 81 exp 2
% timeColorStamps = [1 1 12 38 70 100];     % Session 84 exp 1

% timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

% Save bounded images
boundImgBool = 1;
boundSaveDir = fullfile(saveDir,'Blob Perimeters');
bndHalfWidth = .25;
if ~exist(boundSaveDir,'dir')
    mkdir(boundSaveDir);
end

%% Iterate and store distributions
sparseVoxCounts = zeros(numel(timeRange),numel(deltaRBins)-1);
sparseNorm = [];
denseVoxInts = zeros(numel(timeRange),numel(deltaRBins)-1);
denseVoxCounts = denseVoxInts;
tic
for tInd = 1:numel(timeRange)
    % tic
    % Load current objects
    currT = timeRange(tInd);
    currTif = tiffreadVolume(fullfile(denseImgDir,sprintf(denseImgName,currT,selChan)));
    blobMat = (tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT)))) > blobThresh;
    % blobMat = logical(tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT))));
    % Get matrix sizes
    if tInd == 1
        imgSize = size(currTif);
        segSizeD = size(blobMat);
        blobPixSize = imgSize./segSizeD(1:3).*pixSize3D;
        minDeltaR = min(diff(deltaRBins));
    end
    
    % Calculate distance trasnform (signed) from blob boundaries
    blobMatResc = imresize3(blobMat,round(blobPixSize.*segSizeD(1:3)/minDeltaR),'nearest');
    ogDistMat = distTransFromBoundary(blobMatResc, ~blobMatResc, false(size(blobMatResc)))*minDeltaR;
    smoothDist = imgaussfilt3(ogDistMat,dSmthKern);
    distMatResc = imresize3(smoothDist,imgSize);
    % ogDistMat = imresize3(distTransFromBoundary(blobMatResc, ~blobMatResc, false(size(blobMatResc)), 1),imgSize)*minDeltaR;
    % if dSmthKern > 0
    %     distMat = imgaussfilt3(distMat,dSmthKern);
    % end
        
    % Bin dense protein intensities by delta R in distMat
    [denseVoxCounts(tInd,:),~,binInds] = histcounts(distMatResc,deltaRBins);
    boundedDenseNorm = sum(currTif((distMatResc >= min(deltaRBins)) & (distMatResc <= max(deltaRBins))),'all');
    for rInd = 1:(numel(deltaRBins)-1)
        denseVoxInts(tInd,rInd) = sum(currTif(binInds == rInd),'all')/boundedDenseNorm;
    end
% toc
% tic
    % Save img with boundary
    if boundImgBool == 1
        segBounds = (distMatResc > -bndHalfWidth) & (distMatResc < bndHalfWidth);
        boundImg = consMatLnB(currTif,~segBounds);
        save3DTiff(boundImg,fullfile(boundSaveDir,sprintf([sprintf('NOMASK_GKern%02i_',dSmthKern) denseImgName],currT,selChan)));            % Takes a long time
    end

    if mod(tInd,10) == 1
        toc
        tic
    end
% toc
end

% Save
save(fullfile(saveDir,sprintf(saveName,min(timeRange),max(timeRange),selChan)),'denseVoxInts','denseVoxCounts','sparseVoxCounts','deltaRBins','sparseNorm')
save(fullfile(saveDir,sprintf('%03i_metadata.mat',selChan)),'timeRange',...
    'pixSize','fastCalc');
 toc   
  %% Load data

  % S81 - Exp2
% saveDir = 'Session 81, Exp 2';
% saveName = 't1-125_radialDensityData-560.mat';
% conConv = 1/(2.42*10^-8)*41;            % Convert avged intensity/count to uM
% ytitle = 'Average MT Concentration (uM)';
% titleTag = 'MT Intensity Profile';

% S81 - Exp3, K4
% saveDir = 'Session 81, Exp 3';
% saveName = 't1-100_radialDensityDataNOMASK-488.mat';
% ytitle = 'Average K4 Concentration (nM)';
% conConv = 1/(2.42*10^-8)*280;            % Convert avged intensity/count to nM
% titleTag = 'K4 Intensity Profile';

% S81 - Exp3, MTs
% saveDir = 'Session 81, Exp 3';
% saveName = 't1-100_radialDensityDataNOMASK-560.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveName = 't1-220_radialDensityDataNOMASK-560.mat';
conConv = 1/(2.42*10^-8)*41;            % Convert avged intensity/count to uM
ytitle = 'Average MT Concentration (uM)';
titleTag = 'MT Intensity Profile';

load(fullfile(saveDir,saveName));

%% Plot radial density distributions
% Adjustable parameters
% selTimes = 1:4:31;   
selTimes = 1:4:150;
% selTimes = 1:4:39;          
selTimes = fliplr(selTimes);  
xtitle = 'Distance From Surface (\mum)';
colorLen = 200 - min(selTimes) + 1;   colorOffSet = 15;
% colorLen = max(selTimes) - min(selTimes) + 1;   colorOffSet = 15;
% Reset color vector, if wanted
timeColorArray = othercolor('BuPu3',colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);
arrayInds = selTimes;

% selTimes = [40:10:100 120:20:200]+1;  
% selTimes = [37:4:70 80:10:200];     
% selTimes = 1:200;
% timeColorArray = meldNcolors([0.5333    0.3373    0.6549; 0 0 .2], numel(selTimes));
% arrayInds = 1:numel(selTimes);

fracCutOff = 0.0003;
% fracCutOff = 0.001;
% specialT = timeColorStamps(timeColorStamps <= max(selTimes));
patchColor = [193 0 114]/255;
% Display boundaries
xBnds = [-12 25];
% xBnds = [-20 20];
yBnds = [2 4.8]*10^(-8)*conConv;
% Display shaded patches?
patchBool = 0;
lnSpc = .25*10^-8;          % for shading
maxesBool = 0;

figure
hold on
% Plot region indicating vesicle interior
xPatchCoords = [xBnds(1) 0 0 xBnds(1)];
yPatchCoords = [yBnds(1) yBnds(1) yBnds(2) yBnds(2)];
sqArea = patch(xPatchCoords*1.1,yPatchCoords.*[1/1.1 1/1.1 1.1 1.1],patchColor);
% sqArea = patch(xPatchCoords*1.1,yPatchCoords.*[1/1.1 1/1.1 1.1 1.1],'black');
sqArea.FaceAlpha = 0.1; sqArea.LineStyle = "-";
sqArea.EdgeColor = patchColor; sqArea.LineWidth = 3;
% Prepare diagonal patches for background texture
if patchBool == 1
    ySpcs = yBnds(1):lnSpc:yBnds(2);
    if mod(numel(ySpcs),2) == 1
        ySpcs = [ySpcs max(ySpcs)+lnSpc];
    end
    yBots = repmat(ySpcs(1:2:end), 2, 1)';
    yTops =  repmat(ySpcs(2:2:end), 2, 1)';
    yShifts = repmat([0 lnSpc lnSpc 0],size(yBots,1),1);
    yShadeCoords = [yBots yTops] + yShifts;
    xShadeCoords = repmat(xPatchCoords,size(yShadeCoords,1),1);
    % Plot diagonal patches
    for index = 1:size(yShadeCoords,1)
        temp = patch(xShadeCoords(index,:),yShadeCoords(index,:),'black');
        temp.LineStyle = 'none'; temp.FaceAlpha = 0.1;
    end
end

% Plot radial plots - filter out samples with too few data points
fracLogic = denseVoxCounts(selTimes,:)./(sum(denseVoxCounts(selTimes,:),2))>fracCutOff;
cutOffVoxInts = consMatLnB(denseVoxInts(selTimes,:),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(selTimes,:),fracLogic);
% plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts,'--','LineWidth',2);
plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*conConv,'LineWidth',3);

% Store conc maxes
% [maxVals,maxInds] = max(cutOffVoxInts./cutOffVoxCounts,[],2);
[maxVals,maxInds] = max(cutOffVoxInts./cutOffVoxCounts*conConv,[],2);
if maxesBool == 1
    scatter(deltaRBins(maxInds),maxVals,60,'filled',...
        'MarkerFaceColor',[230 160 40]/255,'MarkerEdgeColor','black','Marker','^');
    % scatter(deltaRBins(maxInds),maxVals,'black','filled');
end

% Adjust plot parameters
colororder([ timeColorArray(arrayInds,:)])
title(titleTag)
xlabel(xtitle)
ylabel(ytitle)
set(gca,'FontSize',15)
xlim(xBnds)
ylim(yBnds)
box on

% Populate colorbar
% mapTs = sort(arrayInds);
% cbh = colorbar;
% colormap(timeColorArray(mapTs,:));
% cbh.Ticks = sort((mapTs - min(mapTs))/(max(mapTs)- min(mapTs))) ; %Create 8 ticks from zero to 1
% tickCell = cell(numel(mapTs),1);   
% [tickCell{[1 end]}] = deal(min(selTimes-1)*deltaT,max(selTimes-1)*deltaT);
% % [tickCell{[1 end]}] = deal((mapTs(1)-1)*deltaT,(mapTs(end)-1)*deltaT);
% cbh.TickLabels = tickCell;   

%% Scatter PeakInts and center to peaks over time
% Adjustable parameters 
specT = 1:4:37;
selTimes = 1:110;
fracCutOff = 0.0003;
% fracCutOff = 0.001;
% Colors for special times
specT = [20 30 40 60 80 100];
% specT = [20 30 40 60 80 100 120 160];   
specT = fliplr(specT);
colorLen = max(specT) - min(specT) + 1;   colorOffSet = 15;  
% Reset color vector, if wanted
timeColorArray = othercolor('BuPu3',colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);
arrayInds = specT;

% Get maxes
fracLogic = denseVoxCounts(selTimes,:)./(sum(denseVoxCounts(selTimes,:),2))>fracCutOff;
cutOffVoxInts = consMatLnB(denseVoxInts(selTimes,:),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(selTimes,:),fracLogic);
[maxVals,maxInds] = max(cutOffVoxInts./cutOffVoxCounts*conConv,[],2);
% Get distances peakint to cen
flatLogic = logical(cumsum(fracLogic')');
endInds = 1 + cumsum(~flatLogic')';
rInds = endInds(:,end);
cen2Pk = deltaRBins(maxInds) - deltaRBins(rInds);

figure
subplot(2,1,1)
scatter(selTimes*deltaT,maxVals,20,[20 20 20]/255,'filled')
% scatter(selTimes*deltaT,maxVals,20,[255 100 50]/255,'filled')
% scatter(selTimes*deltaT,maxVals,20,[255 100 50]/255,'filled','MarkerEdgeColor',[20 20 20]/255)
hold on
scatter(specT*deltaT,maxVals(specT),60,'filled',...
    'MarkerFaceColor',[230 160 40]/255,'MarkerEdgeColor','black','Marker','^');
box on
% xlabel('Time (min)')
ylabel('[MT]_{pk} (uM)')
ylim([35 85])

subplot(2,1,2)
hold on
% yyaxis right
% scatter(selTimes*deltaT,cen2Pk,20,[126 150 210]/255,'filled','MarkerEdgeColor',[20 20 20]/255);
scatter(selTimes*deltaT,cen2Pk,20,[126 150 210]/255,'filled');
scatter(specT*deltaT,cen2Pk(specT),60,'filled',...
    'MarkerFaceColor',[230 160 40]/255,'MarkerEdgeColor','black','Marker','^');
% scatter(selTimes*deltaT,cen2Pk,20,'black','filled')
ax = gca;
ax.YColor = 'black';
box on
xlabel('Time (min)')
ylabel('Minor Axis (um)')

%% Plot ratio of [MT]/[K4]
% Data storage info
saveNameK = 't1-100_radialDensityDataNOMASK-488.mat';
saveNameMT = 't1-100_radialDensityDataNOMASK-560.mat';
conConv = 1/(2.42*10^-8);            % Convert avged intensity/count to nM

% Adjustable parameters
selTimes = 1:60;          
selTimes = fliplr(selTimes);  
titleTag = '[Kif4]/[MT]';
xtitle = 'Distance From Surface (\mum)';
ytitle = 'Normalized Concentration Ratio';
colorLen = max(selTimes) - min(selTimes) + 1;   colorOffSet = 15;
fracCutOff = 0.0003;
specialT = timeColorStamps(timeColorStamps <= max(selTimes));
patchColor = [193 0 114]/255;
% Display boundaries
xBnds = [-12 25];
yBnds = [0.8 1.1];
% Display shaded patches?
patchBool = 0;
lnSpc = .25*10^-8;          % for shading

% Reset color vector, if wanted
timeColorArray = othercolor('BuPu3',colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);

% Load data, asign variables
k4Data = load(fullfile(saveDir,saveNameK));
mtData = load(fullfile(saveDir,saveNameMT));
% Store cutoff binned intensity data for K4 and MTs
fracLogicK = (k4Data.denseVoxCounts(selTimes,:))./(sum(k4Data.denseVoxCounts(selTimes,:),2))>fracCutOff;
fracLogicM = (mtData.denseVoxCounts(selTimes,:))./(sum(k4Data.denseVoxCounts(selTimes,:),2))>fracCutOff;
fracLogTot = fracLogicM & fracLogicK;
% Sample intensities over each bin for MTs and Kif4
cutOffVoxIntsK = consMatLnB(k4Data.denseVoxInts(selTimes,:),fracLogTot);
cutOffVoxIntsM = consMatLnB(mtData.denseVoxInts(selTimes,:),fracLogTot);
cutOffVoxCounts = consMatLnB(mtData.denseVoxCounts(selTimes,:),fracLogTot);
% Calculate average k4 and mt intensities for each bin
kRhos = cutOffVoxIntsK./cutOffVoxCounts*conConv;
mRhos = cutOffVoxIntsM./cutOffVoxCounts*conConv;
% Density boundaries for shifting
maxMs = max(mRhos,[],2);   minMs = min(mRhos,[],2);
maxKs = max(kRhos,[],2);   minKs = min(kRhos,[],2);
scaleMs = maxMs - minMs;
scaleKs = maxKs - minKs;
% Shift and rescale densities
kCurves = (kRhos - minKs)./scaleKs.*scaleMs + minMs;
mCurves = mRhos ;
% kCurves = (kRhos - minKs)./scaleKs;
% mCurves = (mRhos - minMs)./scaleMs;

% iDiff = cutOffVoxIntsK - cutOffVoxIntsM;    % Not scaled by ring size
% The two candidates
iRatio = kCurves./mCurves;        % Same as kRhos./mRhos
iDiff = kCurves - mCurves;
% iRatio = cutOffVoxIntsK./cutOffVoxIntsM;        % Same as kRhos./mRhos
% rhoDiff = iDiff./cutOffVoxCounts;
% rhoRatio = iRatio./cutOffVoxCounts;           % Makes no sense

selField = iDiff;
% selField = iRatio;
% selField = mCurves;

figure
hold on

% Plot region indicating vesicle interior
xPatchCoords = [xBnds(1) 0 0 xBnds(1)];
yPatchCoords = [yBnds(1) yBnds(1) yBnds(2) yBnds(2)];
sqArea = patch(xPatchCoords*1.1,yPatchCoords.*[1/1.1 1/1.1 1.1 1.1],patchColor);
% sqArea = patch(xPatchCoords*1.1,yPatchCoords.*[1/1.1 1/1.1 1.1 1.1],'black');
sqArea.FaceAlpha = 0.1; sqArea.LineStyle = "-";
sqArea.EdgeColor = patchColor; sqArea.LineWidth = 3;
% Prepare diagonal patches for background texture
if patchBool == 1
    ySpcs = yBnds(1):lnSpc:yBnds(2);
    if mod(numel(ySpcs),2) == 1
        ySpcs = [ySpcs max(ySpcs)+lnSpc];
    end
    yBots = repmat(ySpcs(1:2:end), 2, 1)';
    yTops =  repmat(ySpcs(2:2:end), 2, 1)';
    yShifts = repmat([0 lnSpc lnSpc 0],size(yBots,1),1);
    yShadeCoords = [yBots yTops] + yShifts;
    xShadeCoords = repmat(xPatchCoords,size(yShadeCoords,1),1);
    % Plot diagonal patches
    for index = 1:size(yShadeCoords,1)
        temp = patch(xShadeCoords(index,:),yShadeCoords(index,:),'black');
        temp.LineStyle = 'none'; temp.FaceAlpha = 0.1;
    end
end

% Plot radial plots - filter out samples with too few data points
plot(deltaRBins(1:(end-1))',selField,'LineWidth',3);

% Adjust plot parameters
colororder([ timeColorArray(selTimes,:)])
title(titleTag)
xlabel(xtitle)
ylabel(ytitle)
set(gca,'FontSize',15)
xlim(xBnds)
ylim(yBnds)
box on

% Populate colorbar
mapTs = sort(selTimes);
cbh = colorbar;
colormap(timeColorArray(mapTs,:));
cbh.Ticks = sort((mapTs - min(mapTs))/(max(mapTs)- min(mapTs))) ; %Create 8 ticks from zero to 1
tickCell = cell(numel(mapTs),1);   
[tickCell{[1 end]}] = deal((mapTs(1)-1)*deltaT,(mapTs(end)-1)*deltaT);
cbh.TickLabels = tickCell;   


[kVals,kMaxes] = max(iDiff,[],2);
[mVals,mMaxes] = max(mCurves,[],2);
scatter(deltaRBins(kMaxes),kVals,'black','filled');
% scatter(deltaRBins(mMaxes),mVals,'red','filled');


%% Plot spacings between max and min of [K4]/[MT] or [K4] - [MT]
[~,minInd] = min(iDiff,[],2);
[~,maxInd] = max(iDiff,[],2);
% [~,minInd] = min(iRatio,[],2);
% [~,maxInd] = max(iRatio,[],2);
k4MTSpace =  deltaRBins(minInd) - deltaRBins(maxInd);

figure
plot(selTimes*deltaT,k4MTSpace,'black')
hold on
scatter(selTimes*deltaT,k4MTSpace,40,timeColorArray(selTimes,:),'filled')
box on
xlabel('Time (min)')
ylabel('Peak Separation (\mum)')
set(gca,'FontSize',15)

%% Plot spacings from directly from rescaled concs.
[~,kMaxes] = max(kCurves,[],2);
[~,mMaxes] = max(mCurves,[],2);
maxDiffs = deltaRBins(mMaxes) - deltaRBins(kMaxes);

figure
plot(selTimes*deltaT,maxDiffs,'black')
hold on
scatter(selTimes*deltaT,maxDiffs,40,timeColorArray(selTimes,:),'filled')
box on
xlabel('Time (min)')
ylabel('Peak Separation (\mum)')
set(gca,'FontSize',15)

%% Plot peak [MT] and [K4] over time
scaleK4 = 280;
scaleMT = 41;
[kVals,kMaxes] = max(kRhos,[],2);
[mVals,mMaxes] = max(mRhos,[],2);

figure
yyaxis left
scatter(selTimes*deltaT,deltaRBins(kMaxes),40,'blue','filled')
ylabel('[K4] Positions (\mum)')
ylim([-9 -4])
hold on
yyaxis right
scatter(selTimes*deltaT,deltaRBins(mMaxes),40,'black','filled')
ylim([-9 -5])
box on
xlabel('Time (min)')
ylabel('[MT] Positions (\mum)')
set(gca,'FontSize',15)

figure
yyaxis left
scatter(selTimes*deltaT,scaleK4*(kVals),40,'blue','filled')
ylabel('[K4] peaks (nM)')
hold on
yyaxis right
scatter(selTimes*deltaT,scaleMT*(mVals),40,'black','filled')
box on
xlabel('Time (min)')
ylabel('[MT] peaks (\muM)')
set(gca,'FontSize',15)

%% Plot derivative of density profiles
selTimes = 41:8:200;  titleTag = 'Coarsening - Approaching Sigmoidal Profile';
% selTimes = 27:2:39;  titleTag = 'Plateau - Evacuation/Rearrangement';
% selTimes = 39:4:75;  titleTag = 'Expansion - Density Drops';
selTimes = fliplr(selTimes);  
% selTimes = [1 5 10 15 20 hlTs];
tMax = max(selTimes);
maxesBool = 0;
boxBool = 1;
movWin = 5;
smoothBool = 0;
fracCutOff = .0003;
boxY= [-10 10];
absBool = 0;
patchColor = [193 0 114]/255;

% Reset color vector, if wanted
colorTs = selTimes;
colorLen = tMax + 1;   colorOffSet = 15;
% colorTs = selTimes - min(selTimes) + 1;
% colorLen = max(selTimes) - min(selTimes) + 1;   colorOffSet = 15;
timeColorArray = othercolor('BuPu3',colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);

figure
if boxBool == 1
    if absBool == 1
        boxY(1) = -1;
    end
    % Plot region indicating vesicle interior
    xPatchCoords = [xBnds(1) 0 0 xBnds(1)];
    yPatchCoords = [boxY(1) boxY(1) boxY(2) boxY(2)];
    sqArea = patch(xPatchCoords*1.1,yPatchCoords,patchColor);
    % sqArea = patch(xPatchCoords*1.1,yPatchCoords.*[1/1.1 1/1.1 1.1 1.1],'black');
    sqArea.FaceAlpha = 0.1; sqArea.LineStyle = "-";
    sqArea.EdgeColor = patchColor; sqArea.LineWidth = 1;
end
hold on

% Plot radial plots - filter out samples with too few data points
fracLogic = denseVoxCounts./(sum(denseVoxCounts,2))>fracCutOff;
cutOffVoxInts = consMatLnB(denseVoxInts,fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts,fracLogic);
denseDist = cutOffVoxInts./cutOffVoxCounts*conConv;
% deltaRBins should be in um/step, 
timeDerv = vertcat( zeros(size(denseDist,2),1)',diff(denseDist))./mean(diff(selTimes*deltaT));
denseDerv = horzcat( diff(denseDist')',zeros(size(denseDist,1),1))./mean(diff(deltaRBins));
% Pick a derivative
pickDerv = denseDerv;
% pickDerv = timeDerv;
cutOffDerv = consMatLnB(pickDerv,fracLogic);
cutOffDerv(~fracLogic) = NaN;
if absBool == 1
    cutOffDerv = abs(cutOffDerv);
end
allCutOffs =  cutOffDerv;   
cutOffDerv = cutOffDerv(selTimes,:);
meanField = movmean(cutOffDerv',movWin)';
% scatter(deltaRBins(1:(end-1))',cutOffDerv,20,'filled');
% plot(deltaRBins(1:(end-1))',cutOffDerv,'LineWidth',2);
% yyaxis right
% scatter(deltaRBins(1:(end-1))',plotField,20,'black','filled','MarkerFaceAlpha',.5);
plot(deltaRBins(1:(end-1))',cutOffDerv,'LineWidth',2);
if smoothBool == 1
    plot(deltaRBins(1:(end-1))',meanField,'black','LineStyle','--');
end
% Store conc maxes
[maxVals,maxInds] = max(cutOffVoxInts./cutOffVoxCounts*conConv,[],2);
if maxesBool == 1
    hold on
    dervInds = sub2ind(size(cutOffDerv),1:size(cutOffDerv,1),maxInds');
    scatter(deltaRBins(maxInds),cutOffDerv(dervInds),60,'filled',...
        'MarkerFaceColor',[230 160 40]/255,'MarkerEdgeColor','black','Marker','^');
end

colororder([ timeColorArray(colorTs,:)])
xlim([-15 25])
ylim(boxY + [1 -1]*.5)
box on
% title('Spatial Density Derivatives, Dense Label')
% subtitle(titleTag)
% xlabel('Distance from surface (um)')
% ylabel('Intensity (Nomalized)')
set(gca,'FontSize',15)

test = gca;
test.YColor = 'black';

mapTs = sort(colorTs);
cbh = colorbar;
colormap(timeColorArray(mapTs,:));
cbh.Ticks = sort((mapTs - min(mapTs))/(max(mapTs)- min(mapTs))) ; %Create 8 ticks from zero to 1
tickCell = cell(numel(mapTs),1);   
[tickCell{[1 end]}] = deal(mapTs(1)*deltaT,mapTs(end)*deltaT);
cbh.TickLabels = {''};  
% cbh.TickLabels = tickCell;   
%% Plot slope midline
rBnds = [-5 -0.5];
indLogic = (deltaRBins <  max(rBnds)) & (deltaRBins >  min(rBnds));
selDervs = cutOffDerv(:,indLogic);
meanDervs = mean(selDervs,2);
yVals = repmat(meanDervs,1,2);
xVals = repmat(rBnds,numel(meanDervs),1);
plot(xVals',yVals','Color','black','LineStyle','--')

%% Overlay mean slopes on images
rBnds = [-5 -0.5];
indLogic = (deltaRBins <  max(rBnds)) & (deltaRBins >  min(rBnds));
selDervs = cutOffDerv(:,indLogic);
meanDervs = mean(selDervs,2);
yVals = repmat(meanDervs,1,2);
xVals = repmat(rBnds,numel(meanDervs),1);
plot(xVals',yVals','Color','black','LineStyle','--')

%% Plot mean slope vs time
subTimes = 1:200;
selTimes = 29:4:37;
rBnds = [-5 -0.5];
patchColor = [40 40 40];

indLogic = (deltaRBins <  max(rBnds)) & (deltaRBins >  min(rBnds));
selDervs = allCutOffs(:,indLogic);
meanDervs = mean(selDervs,2);

figure
% Plot region indicating vesicle interior
xPatchCoords = [18 -1 -1 18];
yPatchCoords = [-9 -9 1 1];
sqArea = patch(xPatchCoords,yPatchCoords,[20 20 20]/255);
% sqArea = patch(xPatchCoords*1.1,yPatchCoords.*[1/1.1 1/1.1 1.1 1.1],'black');
sqArea.FaceAlpha = 0.1; sqArea.LineStyle = "-";
sqArea.EdgeColor = [20 20 20]/255; sqArea.LineWidth = 1;
hold on
scatter(subTimes*deltaT,meanDervs(subTimes),20,'black','filled')
scatter(selTimes*deltaT,meanDervs(selTimes),60,'filled',...
    'MarkerFaceColor',[230 160 40]/255,'MarkerEdgeColor','black','Marker','^');
box on
xlim([0 100])
ylim([-8 0])

%% Plot field quantities for given delta r's over time
currField = denseDerv;
checkInds = 21:5:50;
yShiftScale = 0;
% yShiftScale = 10^(-9);
selTimes = 1:2:100;
legendCell = cell(1,2*numel(checkInds));
saveBool = 1;
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
saveName = 'Derivative_atDeltaR_%.1fum.png';

% figure; box on; 
for index = 1:numel(checkInds)
    currInd = checkInds(index);
    plot(selTimes*deltaT,movmean(currField(selTimes,currInd) + index*yShiftScale,3),'black')
    hold on
    scatter(selTimes*deltaT,currField(selTimes,currInd) + index*yShiftScale,5*index,timeColorArray(selTimes,:),"filled")
    ylim([-10 6]*10^(-9))
    legendCell{2*index} = '';
    legendCell{2*index-  1} = string(sprintf('Delta r: %.1fum',deltaRBins(currInd)));
    if saveBool == 1
        saveas(gca,fullfile(saveDir,sprintf(saveName,deltaRBins(currInd))));
    end
    hold off
end
    legend([legendCell{:}])

%% Cross corr shifted and rescaled
% Shift each field by mean of values at t1
shiftData1 = dataSet1 - nansum(dataSet1(1,:))./sum(~isnan(dataSet1(1,:)));
shiftData2 = dataSet2 - nansum(dataSet2(1,:))./sum(~isnan(dataSet2(1,:)));
% Scale datasets by intensity maxima
rescData1 = shiftData1/max(shiftData1(:));      % Kif4
rescData2 = shiftData2/max(shiftData2(:));      % MTs

figure
hold on
plot(deltaRBins(1:(end-1))',rescData1','--','LineWidth',2);
plot(deltaRBins(1:(end-1))',rescData2','LineWidth',2);
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
%% Plot distributions
selTimes = 1:2:40;
figure
% plot(deltaRBins(1:end-1)*pixSize,(denseVoxInts./denseVoxCounts)')
plot(deltaRBins(1:(end-1)),(denseVoxInts(selTimes,:)))
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
