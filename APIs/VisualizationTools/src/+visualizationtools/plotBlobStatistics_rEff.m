% Expects data from (test_)trajInfoFromOverlaps_MinAxis.m;
% storeMat contains one value per object ID for each time, while
% T%03i_sorted_RMinStatistics.mat contain the collection of all distance
% transform values sampled along blob skeletons, if this method was
% calculated.
% 2026-01-28 - Rémi Boros

%% Directory info, etc.
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 88, Exp 4';
statsDir = fullfile(baseDir,'4 Tracked Blobs');
rminDir = fullfile(statsDir,'RMinStats');

trajsMatName = 'sortedTraj_IntsVolsMinRs_ErodedScaled2.mat';
rminName = 'sorted_RMinStatistics.mat';

%% Load data, concatenate rmin statistics, if they exist
% Data stored in sortedMat: [ID, T, Vol, Ints, R_eff (scalar)]
load(fullfile(statsDir,trajsMatName));
load(fullfile(statsDir,rminName));
allFrames = unique(sortedMat(:,2));

%% Display r_min over time
subTimes = 2:60;
rmin = 2;
vmax = inf;
% vmax = 2.5*10^4;
validRs = (sortedMat(:,5) > rmin);
validVs = (sortedMat(:,3) < vmax);
% instantiate
meanRs = subTimes;      stdRs = meanRs;     medRs = meanRs;
validCounts = meanRs;
for tInd = 1:numel(subTimes)
    currT = subTimes(tInd);
    currLogic = sortedMat(:,2) == currT;
    filtLogic = validRs & validVs & currLogic;
    % Store
    meanRs(tInd) = mean(sortedMat(filtLogic,5));
    stdRs(tInd) = std(sortedMat(filtLogic,5));
    medRs(tInd) = median(sortedMat(filtLogic,5));
    validCounts(tInd) = max(1,sum(filtLogic));
end
figure
scatter(subTimes*timeStep,meanRs,'filled');
hold on
scatter(subTimes*timeStep,medRs,'filled');
% errorbar(subTimes*timeStep,meanRs,stdRs);
% hold on
% errorbar(subTimes*timeStep,medRs,stdRs);
% errorbar(subTimes*timeStep,meanRs,(stdRs.^(1/2)./validCounts));
% hold on
% errorbar(subTimes*timeStep,medRs,(stdRs.^(1/2)./validCounts));
legend('Mean Rs','Median Rs')
box on
set(gca,'FontSize',15)
xlabel('Time (min)')
ylabel('R_{min} (um)')

%% Approximate radii over time
% Plot mean values over histogram of value counts
% load(fullfile(labeledDir,'sortedTrajInfo.mat'),'sortedMat'  );

selRange = 20:60;
meanRads = [statStruct(:).medRad];     stdRhos = [statStruct(:).stdRad];
rScale = 1;
figure()   % scatter volumes over histogram of bins
scatter(1:numel(cutOffTimes),meanRads*rScale,'filled','red');
xticklabels({tempx*timeStep});  yticklabels({fliplr(rndV)});
xlabel('Time (min)')
ylabel(sprintf('Object Radius (\\mum^3)'));
% title(sprintf('Scaled y by 10^%i',vPower+1))
set(gca,'FontSize',15)

% Plot mass vs r
figure()   % scatter volumes over histogram of bins
% scatter(meanRads(selRange)*rScale,meanIs(selRange)*iScale,'filled','red');
scatter(meanRads(selRange)*rScale,meanRhos(selRange)*rhoScale,'filled','red');
% xticklabels({tempx*timeStep});  yticklabels({fliplr(rndV)});
xlabel('Radii (um)')
ylabel('Rho');
% title(sprintf('Scaled y by 10^%i',vPower+1))
set(gca,'FontSize',15)

% errorbar(1:numel(cutOffTimes),binNum - meanVs*vScale,stdVs'*vScale./stdScale,'black');
% errorbar((1:errSpc:numel(cutOffTimes)),...
%     binNum - meanVs(1:errSpc:end)*vScale,stdVs(1:errSpc:end)'*vScale./stdScale,'black');
% errorbar((2:2:numel(cutOffTimes)),binNum - meanVs(2:2:end)*vScale,stdVs(2:2:end)'*vScale./stdScale,'black');



%%

for tInd = 1:numel(allFrames)
    currT = allFrames(tInd);
    if ~exist(fullfile(rminDir,sprintf(rminName,currT)),'file')
        continue
    end
    load(fullfile(rminDir,sprintf(rminName,currT)));
    % currLogic = sortedMat(:,2) == 
    % [~,labelOrder] = sortedMat
end

%% Load data
load(fullfile(labeledDir,'sortedTraj_IntsVolsMinRs_Eroded.mat'),'sortedMat','imgDims'  );

% imgDims = [780 785 81];
% Based on the image dimensions, infer what the voxel volume should be
% voxelVolume = [1.1 1.1 1.5];
voxelVolume = [0.3667 0.3667 1.5];

%% 1) Look at volume fraction occupied over time by blobs of volume V_i
% %% Plot volume fraction occupied vs blob volume
% A rescaled way to view blob volume distributions over time
% Settings
cutOffTimes = [7 10 16];
% scaleTime = 20;
cutOffVolFrac = 17*10^6;
binNum = 80;
volylims = [0 cutOffVolFrac];
colorMat = othercolor('Dark24',numel(cutOffTimes));

% Define display bin edges
volEdges = volylims(1):diff(volylims)/binNum:volylims(end);
radEdges = (3/(4*pi)*volEdges).^(1/3);

% Define logic from settings
baseLogic = true(size(sortedMat,1),1);
validScaleTrajs = sortedMat(baseLogic,1);          % Trajectories that exist at scale time
scaleVols = sortedMat(baseLogic, 3);         % Vols at scale time

% scaleTimeLogic = ismember(sortedMat(:,2),scaleTime);    % Indices at scale time
% trajLogic =  ismember(sortedMat(:,1),validScaleTrajs);  % indices that valid trajectories can be found
% % Collect values at the reference time
% validCount = zeros(numel(cutOffTimes),1);

% close all
% Iterate through time, get mean values for each time and construct
% histograms at those times; instantiate storage structures
% statStruct = struct();
binVMat = zeros(numel(cutOffTimes),binNum); 
vFracs = binVMat;
allEdges = vFracs;
for tInd = 1:numel(cutOffTimes)
    % Access current time
    currTime = cutOffTimes(tInd);
    % Isolate data corresponding to current time
    currTLogic = sortedMat(:,2) == currTime;
    totalLogic = baseLogic & currTLogic;        % Combine time logic with valid logic
    % Access trajectories valid at current time point + their indices
    currTrajs = sortedMat(totalLogic,1);
    refInds = ismember(validScaleTrajs, currTrajs);
    % Get times, volumes, intensities for valid trajectories at curr time
    timeVec = sortedMat(totalLogic,2);
    currVols = sortedMat(totalLogic,3);
    % Identify and isolate trajectories that meet all criteria
    cutOffVolsInds = currVols < cutOffVolFrac;
    validVols = currVols(cutOffVolsInds);
    timeVec = timeVec(cutOffVolsInds);
    % Count how many 
    validCount(tInd) = sum(cutOffVolsInds(:));
    % Get bin counts
    [temp,newEdges,vInds] = (histcounts(validVols,binNum));
    % [temp,customEdges,vInds] = (histcounts(validVols,customEdges));
    binVMat(tInd,:) = fliplr(temp);
    % Get volume fractions occupied by blobs of each binned volume value
    for currV = 1:binNum
        currLogic = vInds == currV;
        vFracs(tInd,currV) = sum(validVols(currLogic));
    end
    allEdges(tInd,:) = newEdges(2:end);
end

figure   % scatter volumes over histogram of bins
% plot(fliplr(allEdges'),fliplr(vFracs'/prod(imgDims)),'LineWidth',2)
set(gca,'XScale','log')
% plot(allEdges',vFracs'/prod(imgDims),'LineWidth',2)
% scatter(allEdges',vFracs'/prod(imgDims),'filled')
loglog(volEdges(2:end),vFracs)
colororder(colorMat)
xlabel('Blob Volume')
ylabel('Constituitive Volume Fraction')
colorbar
colormap(flipud(colorMat));
% imagesc(binVMat'); clim(distCLim);   colorbar; hold on; box on
% figure
% scatter(1:numel(cutOffTimes),sum(vFracs,2)/prod(imgDims),'filled')

%% Plot volumes, intensities, densities, with option to filter by rescaled volume size
% Plot mean values over histogram of value counts
% load(fullfile(labeledDir,'sortedTrajInfo.mat'),'sortedMat'  );
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
% Settings
voxelVol = prod([1.1 1.1 1.5]);
cutOffTimes = 1:70;
scaleTime = 20;
% cutOffVolFrac = Inf;
cutOffVolFrac = 2.5;
binNum = 80;
distCLim = [0 150];
volylims = [0 2.2*10^4]*voxelVol;
intylims = [0 4*10^8];
denseylims = [0 1.5].*10^4;
cShft = .1;
yTkNum = 4;
sqrtNSc = 0;            % if 0, std; if 1, standard error
errSpc = 2;

% Define display bin edges
volEdges = volylims(1):diff(volylims)/binNum:volylims(end);
intEdges = intylims(1):diff(intylims)/binNum:intylims(end);
rhoEdges = denseylims(1):diff(denseylims)/binNum:denseylims(end);

% Define logic from settings
scaleTimeLogic = ismember(sortedMat(:,2),scaleTime);    % Indices at scale time
validScaleTrajs = sortedMat(scaleTimeLogic,1);          % Trajectories that exist at scale time
trajLogic =  ismember(sortedMat(:,1),validScaleTrajs);  % indices that valid trajectories can be found
% Collect values at the reference time
scaleVols = sortedMat(scaleTimeLogic, 3)*voxelVol;       % Vols at scale time
scaleInts = sortedMat(scaleTimeLogic, 4);       % Ints at scale time
meanDenses = zeros(numel(cutOffTimes),1);
validCount = zeros(numel(cutOffTimes),1);

close all
% Iterate through time, get mean values for each time and construct
% histograms at those times; instantiate storage structures
statStruct = struct();
binVMat = zeros(numel(cutOffTimes),binNum); 
binIMat = binVMat; binRhoMat = binVMat;
binRMat = binVMat;
for tInd = 1:numel(cutOffTimes)
    % Access current time
    currTime = cutOffTimes(tInd);
    % Isolate data corresponding to current time
    currTLogic = sortedMat(:,2) == currTime;
    totalLogic = trajLogic & currTLogic;        % Combine time logic with valid logic
    % Access trajectories valid at current time point + their indices
    currTrajs = sortedMat(totalLogic,1);
    refInds = ismember(validScaleTrajs, currTrajs);
    % Get times, volumes, intensities for valid trajectories at curr time
    timeVec = sortedMat(totalLogic,2);
    currVols = sortedMat(totalLogic,3)*voxelVol;
    currInts = sortedMat(totalLogic,4);
    % Rescale volumes  by those at reference time; 
    % used to determine which trajs fall within a relevant volume cutoff
    scaledVols = currVols./scaleVols(refInds);
    % Identify and isolate trajectories that meet all criteria
    cutOffVolsInds = scaledVols < cutOffVolFrac;
    validVols = currVols(cutOffVolsInds);
    validInts = currInts(cutOffVolsInds);
    validDense = validInts./validVols;
    validDense = validDense(~isnan(validDense));
    timeVec = timeVec(cutOffVolsInds);
    % Approximate radii
    validRads = (3/(4*pi)*validVols).^(1/3);
    % Count how many 
    validCount(tInd) = sum(cutOffVolsInds(:));
    % Get bin counts
    binVMat(tInd,:) = fliplr(histcounts(validVols,volEdges));
    binIMat(tInd,:) = fliplr(histcounts(validInts,intEdges));
    binRhoMat(tInd,:) = fliplr(histcounts(validDense,rhoEdges));
    % binRMat(tInd,:) = fliplr(histcounts(validRads,radEdges));
    
    % Store time
    statStruct(tInd).Time = currTime;
    % Store means and stds
    statStruct(tInd).meanV = mean(validVols(:));
    statStruct(tInd).meanI = mean(validInts(:));
    statStruct(tInd).meanRho = mean(validDense(:));
    statStruct(tInd).medV = median(validVols(:));
    statStruct(tInd).medI = median(validInts(:));
    statStruct(tInd).medRho = median(validDense(:));
    statStruct(tInd).stdV = std(validVols(:));
    statStruct(tInd).stdI = std(validInts(:));
    statStruct(tInd).stdRho = std(validDense(:));
    % Radius info
    statStruct(tInd).meanRad = mean(validRads(:));
    statStruct(tInd).medRad = median(validRads(:));
    statStruct(tInd).stdRad = std(validRads(:));
    % Store numel valid objects at current time
    statStruct(tInd).NumObjs = sum(binVMat(tInd,:));

end

% Access data for plotting
meanVs = [statStruct(:).medV];         stdVs = [statStruct(:).stdV];  
meanIs = [statStruct(:).medI];         stdIs = [statStruct(:).stdI];  
meanRhos = [statStruct(:).medRho];     stdRhos = [statStruct(:).stdRho];
% meanVs = [statStruct(:).meanV];         stdVs = [statStruct(:).stdV];  
% meanIs = [statStruct(:).meanI];         stdIs = [statStruct(:).stdI];  
% meanRhos = [statStruct(:).meanRho];     stdRhos = [statStruct(:).stdRho];
% Scale if requesting standard error
stdScale = 1;
if sqrtNSc == 1
    stdScale = sqrt(sum(binVMat,2));
end

% Rescale plot axes to make scatter and histograms overlap correctly
spacerNum = binNum - 1;
vBndDiff = diff(volylims);      vScale = spacerNum/vBndDiff;
iBndDiff = diff(intylims);      iScale = spacerNum/iBndDiff;
rhoBndDiff = diff(denseylims);  rhoScale = spacerNum/rhoBndDiff;

% Tick-vals
maxTk = size(binVMat,2);            % Number of bins is size of base image
yTkBase = 0:maxTk/yTkNum:maxTk;
vTicks = round(yTkBase/vScale-yTkBase(1)/vScale);
iTicks = round(yTkBase/iScale-yTkBase(1)/iScale);
rhoTicks = round(yTkBase/rhoScale-yTkBase(1)/rhoScale);
% Powers of ten - 1
vPower = round(max(log10(vTicks)))-2;
iPower = round(max(log10(iTicks)))-2;
rhoPower = round(max(log10(rhoTicks)))-2;
% Rounded
% rndV = 10^vPower*round(vTicks*10^(-vPower));      % Use these to display true values
% rndI = 10^iPower*round(iTicks*10^(-iPower));
% rndRho = 10^rhoPower*round(rhoTicks*10^(-rhoPower));
rndV = round(vTicks*10^(-vPower))/10;               % Use these to remove powers of 10 
rndI = round(iTicks*10^(-iPower))/10;
rndRho = round(rhoTicks*10^(-rhoPower))/10;

flipGray = (flipud(colormap('gray')) + [cShft/2 0 cShft])/(1 + cShft);
flipGray(1,:) = [1 1 1];

figure(1)   % scatter volumes over histogram of bins
imagesc(binVMat'); colormap(flipGray); clim(distCLim);   colorbar; hold on; box on
% ax = gca;
% ax.YAxis.Exponent = vPower + 1;
tempx = gca().XTick;  tempy = gca().YTick;
yticks(yTkBase); 
hold on
xticklabels({tempx*timeStep});  yticklabels({fliplr(rndV)});
xlabel('Time (min)')
ylabel(sprintf('Object Volume (\\mum^3)'));
title(sprintf('Scaled y by 10^%i',vPower+1))
set(gca,'FontSize',15)
scatter(1:numel(cutOffTimes),binNum - meanVs*vScale,'filled','red');
% errorbar(1:numel(cutOffTimes),binNum - meanVs*vScale,stdVs'*vScale./stdScale,'black');
errorbar((1:errSpc:numel(cutOffTimes)),...
    binNum - meanVs(1:errSpc:end)*vScale,stdVs(1:errSpc:end)'*vScale./stdScale,'black');
% errorbar((2:2:numel(cutOffTimes)),binNum - meanVs(2:2:end)*vScale,stdVs(2:2:end)'*vScale./stdScale,'black');

figure(2)   % scatter intensities
imagesc(binIMat'); colormap(flipGray); clim(distCLim);   colorbar; hold on; box on
scatter(1:numel(cutOffTimes),binNum - meanIs*iScale,'filled','red');
% errorbar(1:numel(cutOffTimes),binNum - meanIs*iScale,stdIs'*iScale./stdScale,'black');
errorbar((1:errSpc:numel(cutOffTimes)),...
    binNum - meanIs(1:errSpc:end)*iScale,stdIs(1:errSpc:end)'*iScale./stdScale,'black');
tempx = gca().XTick;  tempy = gca().YTick;  
yticks(yTkBase); 
xticklabels({tempx*timeStep});  yticklabels({fliplr(rndI)});
xlabel('Time (min)')
ylabel('Object Mass (u)')
title(sprintf('Scaled y by 10^%i',iPower+1))
set(gca,'FontSize',15)

figure(3)   % scatter densities
imagesc(binRhoMat'); colormap(flipGray); clim(distCLim);   colorbar; hold on; box on
ylim([10 60])
scatter(1:numel(cutOffTimes),binNum - meanRhos*rhoScale,'filled','red');
% errorbar(1:numel(cutOffTimes),binNum - meanRhos*rhoScale,stdRhos'*rhoScale./stdScale,'black');
errorbar((1:errSpc:numel(cutOffTimes)),...
    binNum - meanRhos(1:errSpc:end)*rhoScale,stdRhos(1:errSpc:end)'*rhoScale./stdScale,'black');
tempx = gca().XTick;  tempy = gca().YTick;  
yticks(yTkBase); 
xticklabels({tempx*timeStep});  yticklabels({fliplr(rndRho)});
xlabel('Time (min)')
ylabel('Object Density (u/\mum^3)')
set(gca,'FontSize',15)
title(sprintf('Scaled y by 10^%i',rhoPower+1))

%% Plot mean volumes and intensities on log-log
ylimVols = [100 30000];
ylimMass = [5*10^5 2.5*10^8];
cutOffTimes = 1:70;

figure(1)   % scatter volumes over histogram of bins
hold on; box on
% tempx = gca().XTick;  tempy = gca().YTick;
% yticks(yTkBase); 
% xticklabels({tempx*timeStep});  yticklabels({fliplr(rndV)});
xlabel('Time (min)')
ylabel(sprintf('Object Volume (\\mum^3)'));
% title(sprintf('Scaled y by 10^%i',vPower+1))
set(gca,'FontSize',15)
scatter(1:numel(cutOffTimes), meanVs,'filled','red');
ylim(ylimVols);
hold on
set(gca,'XScale','log','YScale','log');
% xticklabels({'','',''});    yticklabels({'','',''});
% errorbar(1:numel(cutOffTimes),binNum - meanVs*vScale,stdVs'*vScale./stdScale,'black');
% errorbar((1:errSpc:numel(cutOffTimes)),...
%     meanVs(1:errSpc:end),stdVs(1:errSpc:end)','black');
% errorbar((2:2:numel(cutOffTimes)),binNum - meanVs(2:2:end)*vScale,stdVs(2:2:end)'*vScale./stdScale,'black');

figure(2)   % scatter intensities 
hold on; box on
scatter(1:numel(cutOffTimes), meanIs,'filled','red');
ylim(ylimMass);
hold on
% errorbar(1:numel(cutOffTimes),binNum - meanIs*iScale,stdIs'*iScale./stdScale,'black');
% errorbar((1:errSpc:numel(cutOffTimes)),...
%         meanIs(1:errSpc:end),stdIs(1:errSpc:end)','black');
% tempx = gca().XTick;  tempy = gca().YTick;  
% yticks(yTkBase); 
% xticklabels({tempx*timeStep});  yticklabels({fliplr(rndI)});
xlabel('Time (min)')
ylabel('Object Mass (u)')
% title(sprintf('Scaled y by 10^%i',iPower+1))
set(gca,'FontSize',15)
set(gca,'XScale','log','YScale','log');
% xticklabels({'','',''});    yticklabels({'','',''});

% figure(3)   % scatter densities
% imagesc(binRhoMat'); colormap(flipGray); clim(distCLim);   colorbar; hold on; box on
% ylim([10 60])
% scatter(1:numel(cutOffTimes),binNum - meanRhos*rhoScale,'filled','red');
% % errorbar(1:numel(cutOffTimes),binNum - meanRhos*rhoScale,stdRhos'*rhoScale./stdScale,'black');
% errorbar((1:errSpc:numel(cutOffTimes)),...
%     binNum - meanRhos(1:errSpc:end)*rhoScale,stdRhos(1:errSpc:end)'*rhoScale./stdScale,'black');
% tempx = gca().XTick;  tempy = gca().YTick;  
% yticks(yTkBase); 
% xticklabels({tempx*timeStep});  yticklabels({fliplr(rndRho)});
% xlabel('Time (min)')
% ylabel('Object Density (u/\mum^3)')
% set(gca,'FontSize',15)
% title(sprintf('Scaled y by 10^%i',rhoPower+1))


%% Signal to noise over time
figure
plot(cutOffTimes*timeStep,meanVs./stdVs)
hold on
plot(cutOffTimes*timeStep,meanIs./stdIs)
xlabel('Time')
ylabel('Mean/Std')
set(gca,'FontSize',15)
figure
plot(cutOffTimes*timeStep,meanVs./stdVs)
hold on
plot(cutOffTimes*timeStep,meanIs./stdIs)
xlabel('Time')
ylabel('Mean/Std')
plot(cutOffTimes*timeStep,meanRhos./stdRhos,'black')
set(gca,'FontSize',15)

%% Plot volume distributions for select times
% Plot mean values over histogram of value counts
% load(fullfile(labeledDir,'sortedTrajInfo.mat'),'sortedMat'  );
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
% Settings
cutOffTimes = [7 10 16];
scaleTime = 20;
cutOffVolFrac = Inf;
binEdges = 0:500:10000;
volylims = [0 6*10^4];

% Define logic from settings
scaleTimeLogic = ismember(sortedMat(:,2),scaleTime);    % Indices at scale time
validScaleTrajs = sortedMat(scaleTimeLogic,1);          % Trajectories that exist at scale time
trajLogic =  ismember(sortedMat(:,1),validScaleTrajs);  % indices that valid trajectories can be found
% Collect values at the reference time
scaleVols = sortedMat(scaleTimeLogic, 3);       % Vols at scale time
validCount = zeros(numel(cutOffTimes),1);

close all
% Iterate through time, get mean values for each time and construct
% histograms at those times; instantiate storage structures
statStruct = struct();
fineBMat = zeros(numel(cutOffTimes),numel(binEdges)-1); 
for tInd = 1:numel(cutOffTimes)
    % Access current time
    currTime = cutOffTimes(tInd);
    % Isolate data corresponding to current time
    currTLogic = sortedMat(:,2) == currTime;
    totalLogic = trajLogic & currTLogic;        % Combine time logic with valid logic
    % Access trajectories valid at current time point + their indices
    currTrajs = sortedMat(totalLogic,1);
    refInds = ismember(validScaleTrajs, currTrajs);
    % Get times, volumes, intensities for valid trajectories at curr time
    timeVec = sortedMat(totalLogic,2);
    currVols = sortedMat(totalLogic,3);
    % Rescale volumes  by those at reference time; 
    % used to determine which trajs fall within a relevant volume cutoff
    scaledVols = currVols./scaleVols(refInds);
    % Identify and isolate trajectories that meet all criteria
    cutOffVolsInds = scaledVols < cutOffVolFrac;
    validVols = currVols(cutOffVolsInds);
    timeVec = timeVec(cutOffVolsInds);
    % Count how many 
    validCount(tInd) = sum(cutOffVolsInds(:));
    % Get bin counts
    [a,b] = histcounts(validVols);
    % fineBMat(tInd,:) = fliplr(histcounts(validVols,binEdges));

end

%% Plot Volume Distributions over time
% tempSave = '<redacted original absolute path>';
tempSave = 'Session 84';
binEdges = 10:50:2000;
allCounts = ones(numel(selectTimes),numel(binEdges)-1);
for index = 1:numel(selectTimes)
    currT = selectTimes(index);
    timeLogic = sortedMat(:,2) == currT;
    currVols = sortedMat(timeLogic,3);
    allCounts(index,:) =histcounts(currVols,binEdges);
    colorVec = [index/numel(selectTimes) 0 (1 -index/numel(selectTimes))];
    % figure(1)
    % semilogy(binEdges(2:end),allCounts(index,:),'Color',colorVec)
    % % scatter(currT,mean(currVols),'filled')
    % ylim([0 1000])
    % xlim([10 2000])
    scaledCounts = allCounts./sum(allCounts,2);
    plotField = scaledCounts;
    figure(2)
    semilogx(binEdges(2:end),plotField(max(1,index-(1:10)),:),'Color',[0.4 0.4 0.4],'LineStyle','--')
    alpha(0.2)
    hold on
    semilogx(binEdges(2:end),plotField(index,:),'Color',colorVec,'LineWidth',3)
    hold off
    ylim([0 0.5])
    xlim([50 2000])
    title(sprintf('Time %06i',timeStep*currT));
    xlabel('Volume (log)')
    ylabel('Fraction')
    set(gca,'FontSize',15)
    % ginput()
    exportgraphics(gca, fullfile(tempSave,sprintf('Fraction_T%06i.png',currT)));
end
save(fullfile(tempSave,'sourceInfo.mat'),'labeledDir','labeledName','imgDir','imgName')

%%
% Access data for plotting
meanVs = [statStruct(:).meanV];         stdVs = [statStruct(:).stdV];  
meanIs = [statStruct(:).meanI];         stdIs = [statStruct(:).stdI];  
meanRhos = [statStruct(:).meanRho];     stdRhos = [statStruct(:).stdRho];
% Rescale plot axes to make scatter and histograms overlap correctly
spacerNum = binNum - 1;
vBndDiff = diff(volylims);      vScale = spacerNum/vBndDiff;
iBndDiff = diff(intylims);      iScale = spacerNum/iBndDiff;
rhoBndDiff = diff(denseylims);  rhoScale = spacerNum/rhoBndDiff;

figure(1)   % scatter volumes over histogram of bins
imagesc(binVMat'); clim(distCLim);   colorbar; hold on; box on
scatter(1:numel(cutOffTimes),binNum - meanVs*vScale,'filled','red');
tempx = gca().XTick;  tempy = gca().YTick;  
xticklabels({tempx*timeStep});  yticklabels({fliplr(round(tempy/vScale))-tempy(1)/vScale});
% errorbar(1:numel(cutOffTimes),binNum - meanVs*vScale,binNum - stdVs'*vScale./sqrt(sum(binVMat,2)),'red');
figure(2)   % scatter intensities
imagesc(binIMat'); clim(distCLim);   colorbar; hold on; box on
scatter(1:numel(cutOffTimes),binNum - meanIs*iScale,'filled','red');
tempx = gca().XTick;  tempy = gca().YTick;   
xticklabels({tempx*timeStep});  yticklabels({fliplr(round(tempy/iScale))-tempy(1)/iScale});
figure(3)   % scatter densities
imagesc(binRhoMat'); clim(distCLim);   colorbar; hold on; box on
scatter(1:numel(cutOffTimes),binNum - meanRhos*rhoScale,'filled','red');
tempx = gca().XTick;  tempy = gca().YTick;   
xticklabels({tempx*timeStep});  yticklabels({fliplr(round(tempy/rhoScale))-tempy(1)/rhoScale});

%% Plot volumes, intensities, densities, with option to filter by rescaled volume size
% load(fullfile(labeledDir,'sortedTrajInfo.mat'),'sortedMat'  );
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

cutOffTimes = 1:70;
scaleTime = 20;
cutOffVolFrac = Inf;
% cutOffVol = Inf;
alphaVal = 0.01;
volylims = [0 6*10^4];
intylims = [0 6*10^8];
denseylims = [0.5 3].*10^4;

scaleTimeLogic = ismember(sortedMat(:,2),scaleTime);    % Indices at scale time
validScaleTrajs = sortedMat(scaleTimeLogic,1);          % Trajectories that exist at scale time
trajLogic =  ismember(sortedMat(:,1),validScaleTrajs);  % indices that valid trajectories can be found

scaleVols = sortedMat(scaleTimeLogic, 3);       % Vols at scale time
scaleInts = sortedMat(scaleTimeLogic, 4);       % Ints at scale time
meanDenses = zeros(numel(cutOffTimes),1);
validCount = zeros(numel(cutOffTimes),1);

close all
figure(1); box on; hold on
figure(2); box on; hold on
figure(3); box on; hold on
figure(4); box on; hold on
figure(5); box on; hold on
figure(6); box on; hold on

for tInd = 1:numel(cutOffTimes)

    currTime = cutOffTimes(tInd);

    currTLogic = sortedMat(:,2) == currTime;
    totalLogic = trajLogic & currTLogic;

    currTrajs = sortedMat(totalLogic,1);
    refInds = ismember(validScaleTrajs, currTrajs);

    timeVec = sortedMat(totalLogic,2);
    currVols = sortedMat(totalLogic,3);
    currInts = sortedMat(totalLogic,4);

    scaledVols = currVols./scaleVols(refInds);
    scaledInts = currInts./scaleInts(refInds);

    cutOffVolsInds = scaledVols < cutOffVolFrac;
    validVols = currVols(cutOffVolsInds);
    validInts = currInts(cutOffVolsInds);
    validDense = validInts./validVols;
    validDense = validDense(~isnan(validDense));
    timeVec = timeVec(cutOffVolsInds);

    validCount(tInd) = sum(cutOffVolsInds(:));
    alphaVal = max(0.0025,min(1,1/validCount(tInd)));

    figure(1)
    scatter(timeVec*timeStep,validVols,'filled','black','MarkerFaceAlpha',alphaVal);
    scatter(currTime*timeStep,mean(validVols),'filled','red');
    errorbar(currTime*timeStep,mean(validVols),std(validVols)/sqrt(numel(validVols)),'red');
    figure(2)
    scatter(timeVec*timeStep,validInts,'filled','black','MarkerFaceAlpha',alphaVal);
    scatter(currTime*timeStep,mean(validInts),'filled','red');
    errorbar(currTime*timeStep,mean(validInts),std(validInts)/sqrt(numel(validInts)),'red');
    figure(3)
    scatter(timeVec*timeStep,validInts./validVols,'filled','black','MarkerFaceAlpha',alphaVal);
    scatter(currTime*timeStep,mean(validDense),'filled','red');
    errorbar(currTime*timeStep,mean(validDense),std(validDense)/sqrt(numel(validDense)),'red');

    figure(4)
    scatter(log(currTime*timeStep),log(mean(validVols)),'filled','red');
    figure(5)
    scatter(log(currTime*timeStep),log(mean(validInts)),'filled','red');
    figure(6)
    scatter(log(currTime*timeStep),log(mean(validDense)),'filled','red');

    meanDenses(tInd) = mean(validDense);
end

xlims = [0 timeStep*cutOffTimes(end)];
figure(1)
title(sprintf('Volumes Normalized at T%i',scaleTime*timeStep))
ylim(volylims)
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)

figure(2)
title(sprintf('Intensities Normalized at T%i',scaleTime*timeStep))
ylim(intylims)
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)

figure(3)
title(sprintf('Densities Normalized at T%i',scaleTime*timeStep))
ylim(denseylims)
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)

if saveBool == 1
    figure(1)
    saveas(gca,fullfile(saveDir,'Volumes.png'))
    figure(2)
    saveas(gca,fullfile(saveDir,'Intensities.png'))
    figure(3)
    saveas(gca,fullfile(saveDir,'Densities.png'))
    figure(4)
    saveas(gca,fullfile(saveDir,'loglogVols.png'))
    figure(5)
    saveas(gca,fullfile(saveDir,'loglogInts.png'))
    figure(6)
    saveas(gca,fullfile(saveDir,'loglogDenses.png'))
end


%% Plot RESCALED volumes, intensities, densities
% load(fullfile(labeledDir,'sortedTrajInfo.mat'),'sortedMat'  );
saveBool = 0;
cutOffTimes = 1:70;
scaleTime = 20;
cutOffVolFrac = 2.5;

scaleTimeLogic = ismember(sortedMat(:,2),scaleTime);    % Indices at scale time
validScaleTrajs = sortedMat(scaleTimeLogic,1);          % Trajectories that exist at scale time
trajLogic =  ismember(sortedMat(:,1),validScaleTrajs);  % indices that valid trajectories can be found

scaleVols = sortedMat(scaleTimeLogic, 3);       % Vols at scale time
scaleInts = sortedMat(scaleTimeLogic, 4);       % Ints at scale time

meanScaledDenses = zeros(numel(cutOffTimes),1);
close all
figure(1)
hold on
figure(2)
hold on
figure(3)
hold on
for tInd = 1:numel(cutOffTimes)

    currTime = cutOffTimes(tInd);
    currTLogic = sortedMat(:,2) == currTime;
    totalLogic = trajLogic & currTLogic;

    currTrajs = sortedMat(totalLogic,1);
    refInds = ismember(validScaleTrajs, currTrajs);

    timeVec = sortedMat(totalLogic,2);
    currVols = sortedMat(totalLogic,3);
    currInts = sortedMat(totalLogic,4);

    scaledVols = currVols./scaleVols(refInds);
    scaledInts = currInts./scaleInts(refInds);

    cutOffVolsInds = scaledVols < cutOffVolFrac;
    scaledVols = scaledVols(cutOffVolsInds);
    scaledInts = scaledInts(cutOffVolsInds);
    timeVec = timeVec(cutOffVolsInds);

    scaledDense = scaledInts./scaledVols;
    if sum(isnan(scaledDense)) > 0
         sum(isnan(scaledDense))
    end
    scaledDense = scaledDense(~isnan(scaledDense));

    figure(1)
    scatter(timeVec*timeStep,scaledVols,'filled','black','MarkerFaceAlpha',.2);
    scatter(currTime*timeStep,mean(scaledVols),'filled','red');
    errorbar(currTime*timeStep,mean(scaledVols),std(scaledVols)/sqrt(numel(scaledVols)),'red');
    figure(2)
    scatter(timeVec*timeStep,scaledInts,'filled','black','MarkerFaceAlpha',.2);
    scatter(currTime*timeStep,mean(scaledInts),'filled','red');
    errorbar(currTime*timeStep,mean(scaledInts),std(scaledInts)/sqrt(numel(scaledInts)),'red');
    figure(3)
    scatter(timeVec*timeStep,scaledInts./scaledVols,'filled','black','MarkerFaceAlpha',.2);
    scatter(currTime*timeStep,mean(scaledDense),'filled','red');
    errorbar(currTime*timeStep,mean(scaledDense),std(scaledDense)/sqrt(numel(scaledDense)),'red');

    figure(4)
    scatter(log(currTime*timeStep),log(mean(scaledVols)),'filled','red');
    box on
    hold on
    figure(5)
    scatter(log(currTime*timeStep),log(mean(scaledInts)),'filled','red');
    box on
    hold on
    figure(6)
    scatter(log(currTime*timeStep),log(mean(scaledDense)),'filled','red');
    box on
    hold on

    meanScaledDenses(tInd) = mean(scaledDense);
end

xlims = [0 timeStep*cutOffTimes(end)];
figure(1)
title(sprintf('Volumes Normalized at T%i',scaleTime*timeStep))
ylim([0 cutOffVolFrac])
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)
figure(2)
title(sprintf('Intensities Normalized at T%i',scaleTime*timeStep))
ylim([0 3])
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)
figure(3)
title(sprintf('Densities Normalized at T%i',scaleTime*timeStep))
ylim([0.5 1.5])
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)

if saveBool == 1
    figure(1)
    saveas(gca,fullfile(saveDir,'Volumes.png'))
    figure(2)
    saveas(gca,fullfile(saveDir,'Intensities.png'))
    figure(3)
    saveas(gca,fullfile(saveDir,'Densities.png'))
    figure(4)
    saveas(gca,fullfile(saveDir,'loglogVols.png'))
    figure(5)
    saveas(gca,fullfile(saveDir,'loglogInts.png'))
    figure(6)
    saveas(gca,fullfile(saveDir,'loglogDenses.png'))
end


%% Compare mean densities
shiftedLogDense = log(meanDenses) - (log(meanDenses(2)));
scaledLogDense = shiftedLogDense/max(shiftedLogDense);
shiftedLogDenseSc = log(meanScaledDenses) - (log(meanScaledDenses(2)));
scaledLogDenseSc = shiftedLogDenseSc/max(shiftedLogDenseSc);

figure
scatter(log(cutOffTimes*timeStep),scaledLogDense,'filled','red');
hold on
scatter(log(cutOffTimes*timeStep),scaledLogDenseSc,'filled','blue');
box on
legend('Density Trend Raw','Density Trend - Rescaled')
xlabel('Log Time (sec)')
ylabel('Density Trend (Scale-matched)')
set(gca,'FontSize',15)
%% Calculate DERIVATIVES (ugh) volumes, intensities, densities, with option to filter by rescaled volume size
% Get sortedMat, sort based on trajectories, get first times, take diffs of
% quantities and store (replace first time points with 0)
% sortedMat is already sorted by trajectory: [TRAJ_ID, TIME, VOLS, INTS]

% Add densities
sortedMat(:,5) = sortedMat(:,4)./sortedMat(:,3);
% Calculate difference of sortedMat: [TRAJEND_BOOL; D_TIME; D_VOLS, D_INTS; D_DENSE]
diffMat = diff(sortedMat);
trajStartInds = find([1; diffMat(:,1)] >= 1);       % Stitch 1 manually to locate trajectory starts
% Add volume difference and intensity difference columns to sortedMat
sortedMat(:,6:8) = [0 0 0; diffMat(:,3:5)];     
% Manually set difference values to 0 at start of new trajectories
sortedMat(trajStartInds,6:8) = 0;
% Add column for average density

%% Plot DERIVATIVES of volumes, intensities, densities, with option to filter by rescaled volume size
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

cutOffTimes = 1:70;
scaleTime = 20;
cutOffVolFrac = 2.5;
cutOffVol = 2.5;
alphaVal = 0.01;

scaleTimeLogic = ismember(sortedMat(:,2),scaleTime);    % Indices at scale time
validScaleTrajs = sortedMat(scaleTimeLogic,1);          % Trajectories that exist at scale time
trajLogic =  ismember(sortedMat(:,1),validScaleTrajs);  % indices that valid trajectories can be found

scaleVols = sortedMat(scaleTimeLogic, 3);       % Vols at scale time
scaleInts = sortedMat(scaleTimeLogic, 4);       % Ints at scale time

close all
figure(1); box on; hold on
figure(2); box on; hold on
figure(3); box on; hold on
% figure(4); box on; hold on
% figure(5); box on; hold on
% figure(6); box on; hold on

for currTime = cutOffTimes

    currTLogic = sortedMat(:,2) == currTime;
    totalLogic = trajLogic & currTLogic;

    currTrajs = sortedMat(totalLogic,1);
    refInds = ismember(validScaleTrajs, currTrajs);

    timeVec = sortedMat(totalLogic,2);
    currVols = sortedMat(totalLogic,3);
    currInts = sortedMat(totalLogic,4);
    currDVols = sortedMat(totalLogic,6);
    currDInts = sortedMat(totalLogic,7);
    currDDenses = sortedMat(totalLogic,8);

    scaledVols = currVols./scaleVols(refInds);

    cutOffVolsInds = scaledVols < cutOffVolFrac;
    validDVols = currDVols(cutOffVolsInds);
    validDInts = currDInts(cutOffVolsInds);
    validDDense = currDDenses(cutOffVolsInds);
    validDDense = validDDense(~isnan(validDDense));
    timeVec = timeVec(cutOffVolsInds);

    figure(1)
    scatter(timeVec*timeStep,validDVols,'filled','black','MarkerFaceAlpha',alphaVal);
    scatter(currTime*timeStep,mean(validDVols),'filled','red');
    errorbar(currTime*timeStep,mean(validDVols),std(validDVols)/sqrt(numel(validDVols)),'red');
    figure(2)
    scatter(timeVec*timeStep,validDInts,'filled','black','MarkerFaceAlpha',alphaVal);
    scatter(currTime*timeStep,mean(validDInts),'filled','red');
    errorbar(currTime*timeStep,mean(validDInts),std(validDInts)/sqrt(numel(validDInts)),'red');
    figure(3)
    scatter(timeVec*timeStep,validDDense,'filled','black','MarkerFaceAlpha',alphaVal);
    scatter(currTime*timeStep,mean(validDDense),'filled','red');
    errorbar(currTime*timeStep,mean(validDDense),std(validDDense)/sqrt(numel(validDDense)),'red');

    % figure(4)
    % scatter(log(currTime*timeStep),log(mean(validDVols)),'filled','red');
    % figure(5)
    % scatter(log(currTime*timeStep),log(mean(validInts)),'filled','red');
    % figure(6)
    % scatter(log(currTime*timeStep),log(mean(validDDense)),'filled','red');

end

xlims = [0 timeStep*cutOffTimes(end)];
figure(1)
title(sprintf('Volumes Normalized at T%i',scaleTime*timeStep))
ylim([-2000 2000])
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)
saveas(gca,fullfile(saveDir,'Derv_Volumes.png'))
figure(2)
title(sprintf('Intensities Normalized at T%i',scaleTime*timeStep))
ylim([-2 2]*10^7)
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)
saveas(gca,fullfile(saveDir,'Derv_Intensities.png'))
figure(3)
title(sprintf('Densities Normalized at T%i',scaleTime*timeStep))
ylim([-1000 1000])
xlim(xlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)
saveas(gca,fullfile(saveDir,'Derv_Densities.png'))


%% 
viewlims = [0 2.3];
xlims = [0 1750];
    figure(1)
    title(sprintf('Volumes Normalized at T%i',scaleTime*timeStep))
    ylim(viewlims)
    xlim(xlims)
    xlabel('Time (s)')
    set(gca, 'FontSize',15)
    figure(2)
    title(sprintf('Intensities Normalized at T%i',scaleTime*timeStep))
    ylim(viewlims)
    xlim(xlims)
    xlabel('Time (s)')
    set(gca, 'FontSize',15)
    figure(3)
    title(sprintf('Densities Normalized at T%i',scaleTime*timeStep))
    ylim([.85 1.2])
    xlim(xlims)
    xlabel('Time (s)')
    set(gca, 'FontSize',15)

%% Plot trajectory data - Volumes, ints, densities vs. Time cumsum
meanWin = 1;
selTrajs = 40:60;

figure(1)
hold on
figure(2)
hold on
figure(3)
hold on
for trajInd = selTrajs
    currInds = sortedMat(:,1) == trajInd;
    figure(1)
    plot(sortedMat(currInds,2),cumsum(sortedMat(currInds,3)));
    figure(2)
    plot(sortedMat(currInds,2),cumsum(sortedMat(currInds,4)));
    figure(3)
    plot(sortedMat(currInds,2),movmean(sortedMat(currInds,4)./sortedMat(currInds,3),meanWin));
end


%% Plot trajectory data - change in vols, ints vs. Time
meanWin = 1;
figure(1)
hold on
figure(2)
hold on
% figure(3)
% hold on
for trajInd = 1:(max(sortedMat(:,1))-5)
    currInds = sortedMat(:,1) == trajInd;
    timeVec = sortedMat(currInds,2);
    volVec = sortedMat(currInds,3);
    intVec = sortedMat(currInds,4);
    figure(1)
    plot(timeVec(2:end),diff(volVec));
    figure(2)
    plot(timeVec(2:end),diff(intVec));
    % figure(3)
    % plot(timeVec,movmean(sortedMat(currInds,4)./sortedMat(currInds,3),meanWin));
end

%% OLD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plot trajectory data - Volumes, ints, densities vs. Time
meanWin = 1;
selTrajs = 1:2000;
cutOffTimes = 1:70;
scaleTime = 20;
cutOffVolFrac = Inf;

figure(1)
hold on
figure(2)
hold on
figure(3)
hold on
for trajInd = selTrajs

    indexLogic = sortedMat(:,1) == trajInd;
    timeLogic = ismember(sortedMat(:,2),cutOffTimes);
    totalLogic = indexLogic & timeLogic;

    currTimes = sortedMat(totalLogic,2);
    [~,scaleIndexTimeFrame] = min(abs(currTimes - scaleTime));
    scaleCandidates = find(totalLogic);
    scaleIndex = scaleCandidates(scaleIndexTimeFrame);
    
    if ~isempty(scaleIndex)
        scalingVol = sortedMat(scaleIndex,3); scalingInt = sortedMat(scaleIndex,4);
    else
        scalingVol = 1; scalingInt = 1;
    end

    % if test(1)
    if sum(sortedMat(totalLogic,3)/scalingVol > cutOffVolFrac)
        continue
    end

    figure(1)
    plot(currTimes*timeStep,movmean(sortedMat(totalLogic,3)/scalingVol,meanWin));
    figure(2)
    plot(currTimes*timeStep,movmean(sortedMat(totalLogic,4)/scalingInt,meanWin));
    figure(3)
    plot(currTimes*timeStep,movmean(sortedMat(totalLogic,4)./sortedMat(totalLogic,3)*(scalingVol/scalingInt),meanWin));
end

viewlims = [-.2 2.5];
figure(1)
title(sprintf('Volumes Normalized at T%i',scaleTime*timeStep))
ylim(viewlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)
figure(2)
title(sprintf('Intensities Normalized at T%i',scaleTime*timeStep))
ylim(viewlims)
xlabel('Time (s)')
set(gca, 'FontSize',15)
figure(3)
title(sprintf('Densities Normalized at T%i',scaleTime*timeStep))
ylim([0.8 1.2])
xlabel('Time (s)')
set(gca, 'FontSize',15)

%% Plot mean values at each time point
for currTime = cutOffTimes

    currTLogic = sortedMat(:,2) == currTime;
    totalLogic = trajLogic & currTLogic;

    currTrajs = sortedMat(totalLogic,1);
    refInds = ismember(validScaleTrajs, currTrajs);

    timeVec = sortedMat(totalLogic,2);
    currVols = sortedMat(totalLogic,3);
    currInts = sortedMat(totalLogic,4);

    scaledVols = currVols./scaleVols(refInds);
    scaledInts = currInts./scaleInts(refInds);
    
    cutOffVolsInds = scaledVols < cutOffVolFrac;
    scaledVols = scaledVols(cutOffVolsInds);
    scaledInts = scaledInts(cutOffVolsInds);
    timeVec = timeVec(cutOffVolsInds);

    scaledDense = scaledInts./scaledVols;
    if sum(isnan(scaledDense)) > 0
         sum(isnan(scaledDense))
    end
    scaledDense = scaledDense(~isnan(scaledDense));

    figure(4)
    scatter(log(currTime*timeStep),log(mean(scaledVols)),'filled','red');
    box on
    hold on
    figure(5)
    scatter(log(currTime*timeStep),log(mean(scaledInts)),'filled','red');
    box on
    hold on
    figure(6)
    scatter(log(currTime*timeStep),log(mean(scaledDense)),'filled','red');
    box on
    hold on

    % if ~isempty(scaledVols)
    %     figure(1)
    %     violin(scaledVols,'x',currTime*timeStep);
    %     figure(2)
    %     violin(scaledInts,'x',currTime*timeStep);
    %     figure(3)
    %     violin(scaledDense,'x',currTime*timeStep);
    % end

end

%% With Jakob - min_r statistics - plot by time point
rBins = 2:1:30;
% min_r vs. mass at specific time
selT = [20:4:52];
% selT = 2*[3 7 8 12 16 20 24];
for tInd = 1:numel(selT)
    currT = selT(tInd);
    figure
    currLogic = sortedMat(:,2) == currT;
    % histogram(sortedMat(currLogic,5),rBins);
    scatter(sortedMat(currLogic,5),sortedMat(currLogic,4)./sortedMat(currLogic,3),5,sortedMat(currLogic,2),'filled')
    title(sprintf('Title %i',currT));
    xlabel('minr')
    ylabel('density')
    set(gca,'FontSize',15)
    box on
    
    currColor = [tInd/numel(selT) 0 (1-tInd/numel(selT))];
    % overlay mean "mass" for each r_bin
    subSelMat = sortedMat(currLogic,:);
    avgMass = 1:numel(unique(sortedMat(currLogic,5)));
    [~,~,indMat] = histcounts(sortedMat(currLogic,5),[0; (.1+unique(sortedMat(currLogic,5)))]);
    for index = 1:numel(avgMass)
        subLogic = indMat == index;      
        avgMass(index) = mean(subSelMat(subLogic,4)./subSelMat(subLogic,3));
    end
    nanLogic = isnan(avgMass);
    avgMass(nanLogic) = 0;
    hold on
    scatter(unique(sortedMat(currLogic,5)),avgMass,10,[.6 .6 .6],'filled')
    % scatter(unique(sortedMat(currLogic,5)),avgMass,10,[.6 .6 .6],'filled','MarkerEdgeColor',currColor.*[.6 .6 .6])

    % overlay mean "mass" calculated over evenly spaced bins
    [a,b,indMat] = histcounts(sortedMat(currLogic,5),rBins);
    uniqueInds = unique(indMat); validInds = uniqueInds(uniqueInds>0);
    evenMass = validInds;
    for index = 1:numel(evenMass)
        subLogic = indMat == index; 
        evenMass(index) = mean(subSelMat(subLogic,4)./subSelMat(subLogic,3));
    end
    nanLogic = isnan(evenMass);
    evenMass(nanLogic) = 0;
    hold on
    scatter(rBins(validInds),evenMass,45,'filled','diamond','MarkerFaceColor','black')
    % scatter(rBins(validInds),evenMass,45,'filled','diamond','MarkerFaceColor',currColor,'MarkerEdgeColor','black')

    % set(gca,'XScale','log','YScale','log');
    ylim([10^4 3*10^4])
    xlim([0 20])
end

%% With Jakob - min_r statistics - split steps

rBins = 2:1:30;
% min_r vs. mass at specific time
% selT = 30:6:80;
selT = 2*[8:2:24];
for tInd = 1:numel(selT)
    currT = selT(tInd);
    currLogic = sortedMat(:,2) == currT;
    subSelMat = sortedMat(currLogic,:);
    % histogram(sortedMat(currLogic,5),rBins);
    % scatter(sortedMat(currLogic,5),sortedMat(currLogic,4)./sortedMat(currLogic,3),5,sortedMat(currLogic,2),'filled')
    title(sprintf('Title %i',currT));
    xlabel('minr')
    ylabel('density')
    set(gca,'FontSize',15)
    box on
    
end

for tInd = 1:numel(selT)
    currT = selT(tInd);
    currLogic = sortedMat(:,2) == currT;
    currColor = [tInd/numel(selT) 0 (1-tInd/numel(selT))];
    % overlay mean "mass" for each r_bin
    subSelMat = sortedMat(currLogic,:);
    avgMass = 1:numel(unique(sortedMat(currLogic,5)));
    [~,~,indMat] = histcounts(sortedMat(currLogic,5),[0; (.1+unique(sortedMat(currLogic,5)))]);
    for index = 1:numel(avgMass)
        subLogic = indMat == index;      
        avgMass(index) = mean(subSelMat(subLogic,4)./subSelMat(subLogic,3));
    end
    nanLogic = isnan(avgMass);
    avgMass(nanLogic) = 0;
    hold on
    scatter(unique(sortedMat(currLogic,5)),avgMass,10,[.6 .6 .6],'filled')
    % scatter(unique(sortedMat(currLogic,5)),avgMass,10,[.6 .6 .6],'filled','MarkerEdgeColor',currColor.*[.6 .6 .6])

end

for tInd = 1:numel(selT)
    currT = selT(tInd);
    currLogic = sortedMat(:,2) == currT;
    currColor = [tInd/numel(selT) 0 (1-tInd/numel(selT))];
    subSelMat = sortedMat(currLogic,:);
    % overlay mean "mass" calculated over evenly spaced bins
    [a,b,indMat] = histcounts(sortedMat(currLogic,5),rBins);
    uniqueInds = unique(indMat); validInds = uniqueInds(uniqueInds>0);
    evenMass = validInds;
    for index = 1:numel(evenMass)
        subLogic = indMat == index; 
        evenMass(index) = mean(subSelMat(subLogic,4)./subSelMat(subLogic,3));
    end
    nanLogic = isnan(evenMass);
    evenMass(nanLogic) = 0;
    hold on
    scatter(rBins(validInds),evenMass,45,'filled','diamond','MarkerFaceColor',currColor,'MarkerEdgeColor','black')
end

    % set(gca,'XScale','log','YScale','log');
    ylim([10^4 3*10^4])
    xlim([0 20])

    %% 
%% With Jakob - min_r statistics - split steps
% imgSaveDir = '<redacted original absolute path>';
imgSaveDir = 'Session 81, Exp 3';
imgSaveName = 'T%03i_histogram.png';
rBins = 2:1:30;
% min_r vs. mass at specific time
selT = 1:100;
% selT = 2*[3 7 8 12 16 20 24];
for tInd = 1:numel(selT)
    currT = selT(tInd);
    currLogic = sortedMat(:,2) == currT;
    subSelMat = sortedMat(currLogic,:);
    histogram(sortedMat(currLogic,5),rBins);
    % scatter(sortedMat(currLogic,5),sortedMat(currLogic,4)./sortedMat(currLogic,3),5,sortedMat(currLogic,2),'filled')
    title(sprintf('Title %i',currT));
    xlabel('minr')
    ylabel('density')
    set(gca,'FontSize',15)
    box on
    pause(.01)
    ylim([0 30])
    saveas(gca,fullfile(imgSaveDir,sprintf(imgSaveName,tInd)));
    % ginput(1)
end


%% With Jakob - min_r vs density
% % min_r vs. mass at specific time
% selT = [18 20:6:60];
% % selT = 2*[3 7 8 12 16 20 24];
% for tInd = 1:numel(selT)
%     currT = selT(tInd);
%     figure
%     currLogic = sortedMat(:,2) == currT;
%     scatter(sortedMat(currLogic,5),sortedMat(currLogic,4)./sortedMat(currLogic,3),5,sortedMat(currLogic,2),'filled')
%     title(sprintf('Title %i',currT));
%     xlabel('minr')
%     ylabel('density')
%     set(gca,'FontSize',15)
%     box on
% 
%     % overlay mean "mass" for each r_bin
%     [a,b,indMat] = histcounts(sortedMat(currLogic,5),[0; (.1+unique(sortedMat(currLogic,5)))]);
%     subSelMat = sortedMat(currLogic,:);
%     avgMass = 1:numel(unique(sortedMat(currLogic,5)));
% 
%     for index = 1:numel(avgMass)
% 
%         subLogic = indMat == index;      
%         avgMass(index) = mean(subSelMat(subLogic,4)./subSelMat(subLogic,3));
% 
%     end
%     nanLogic = isnan(avgMass);
%     avgMass(nanLogic) = 0;
%     hold on
%     % scatter(unique(sortedMat(currLogic,5)),avgMass,30,unique(sortedMat(currLogic,2)).*ones(size(avgMass)),'filled')
%     scatter(unique(sortedMat(currLogic,5)),avgMass,10,'black','filled')
% 
%     % set(gca,'XScale','log','YScale','log');
%     ylim([10^4 3*10^4])
%     xlim([0 20])
% end
