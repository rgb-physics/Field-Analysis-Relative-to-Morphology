% Scattering function/power spectra of I(q) are calculated in 
% batch_FFTAnalysis_samAdapted.m. This script looks at the scattering
% functions from radial intensity profiles calculated in 
% batch_densityDistributionAlongDeltaR_TIFS.m to compare high-q falloff
% Rémi Boros - 2025-04-09

% Data directory info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';

% dataName = 't1-100_radialDensityDataNOMASK-488.mat';
% ytitle = 'Average K4 Concentration (nM)';
% conConv = 1/(2.42*10^-8)*280;            % Convert avged intensity/count to nM
% titleTag = 'K4 Intensity Profile';

dataName = 't1-100_radialDensityDataNOMASK-560.mat';
conConv = 1/(2.42*10^-8)*41;            % Convert avged intensity/count to uM
ytitle = 'Average MT Concentration (uM)';
titleTag = 'MT Intensity Profile';

%% Load data
load(fullfile(dataDir,dataName));

%% Plot data 
% Adjustable parameters
selTimes = 1:39;    deltaT = 0.5;  
% Shift the profiles to split them in loglog?
logSpc = 0;
% Truncate deltar range or fft full range? 0 no, 1 or, 2 and
truncBool = 2;     
% selTimes = fliplr(selTimes);  
xtitle = 'Distance From Surface (\mum)';
colorLen = max(selTimes) - min(selTimes) + 1;   colorOffSet = 15;
fracCutOff = 0.0003;
patchColor = [193 0 114]/255;
% Display boundaries
xBnds = [-12 25];
yBnds = [2 4.6]*10^(-8)*conConv;
% Display shaded patches?
patchBool = 0;
lnSpc = .25*10^-8;          % for shading
maxesBool = 1;
% Reset color vector, if wanted
timeColorArray = othercolor('BuPu3',colorLen+colorOffSet);
timeColorArray = timeColorArray((colorOffSet-1):end,:);

% Filter out data with too few data points
fracLogic = denseVoxCounts(selTimes,:)./(sum(denseVoxCounts(selTimes,:),2))>fracCutOff;
cutOffVoxInts = consMatLnB(denseVoxInts(selTimes,:),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(selTimes,:),fracLogic);

% Fourier transform of each profile

% DeltarBins is supposed to already be in um
denseProfNaNs = cutOffVoxInts./cutOffVoxCounts*conConv;
denseProfs = consMatLnB(denseProfNaNs,~isnan(denseProfNaNs));

% Find range of valid rs
rMat = repmat(deltaRBins(1:end-1),numel(selTimes),1);
pass1Rs = rMat.*(fracLogic);
if truncBool == 1
    rLogic = (sum(pass1Rs) > 0);
    rStart = find(rLogic,1);    rEnd = find(rLogic,1,'last');
    selRange = rStart:rEnd;
elseif truncBool == 2
    rLogic = (sum(logical(pass1Rs)) == numel(selTimes));
    rStart = find(rLogic,1);    rEnd = find(rLogic,1,'last');
    selRange = rStart:rEnd;
else
    selRange = 1:numel(deltaRBins)-1;
end
% In range of valid rs, get qVec
% Generate qvec
% qVec = Fs/L*(-L/2:L/2-1), where Fs is 1/pixSize, L is number of ticks
validRs = deltaRBins(selRange);
rSpc = mean(diff(validRs));
sigLen = numel(validRs);
qRng = 1/(rSpc);
qVec = qRng/sigLen*(-sigLen/2:sigLen/2-1);

% Calculate fft of profiles
profsFFT = fftshift(fft(denseProfs(:,selRange)'));
% Shift curves for spacing
spcMat = repmat((0:numel(selTimes)-1)*logSpc,numel(selRange),1);
plotMat = profsFFT.*exp(spcMat);
% Reflect 
startInds = fliplr(1:floor(sigLen/2));
endInds = (ceil(sigLen/2)+1):sigLen;
meanMat = (plotMat(startInds,:)+plotMat(endInds,:))/2;
selQ = qVec(endInds);
if mod(size(qVec),2) == 1
    selQ = [0 selQ];
    meanMat = [plotMat(ceil(sigLen/2),:); meanMat];
end

% Plot q profiles
figure
subplot(1,2,1)
% plot(abs(qVec'),log(abs(plotMat))','LineWidth',3);
loglog(selQ,(abs(meanMat))','LineWidth',3);
% Adjust plot parameters
colororder([ timeColorArray(selTimes,:)])
% title(titleTag); xlabel(xtitle); ylabel(ytitle)
set(gca,'FontSize',15)
% xlim(xBnds); ylim(yBnds);
box on

% Plot profiles, if desired
% plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*conConv,'LineWidth',3);
subplot(1,2,2)
plot(deltaRBins(1:(end-1)),denseProfNaNs,'LineWidth',1,'Linestyle','--');
hold on
plot(validRs',denseProfNaNs(:,selRange)','LineWidth',3);
% plot(validRs',denseProfNaNs(:,selRange)','LineWidth',3);

% Adjust plot parameters
colororder([ timeColorArray(selTimes,:)])
title(titleTag); xlabel(xtitle); ylabel(ytitle)
set(gca,'FontSize',15)
xlim(xBnds); ylim(yBnds); box on

% Populate colorbar
mapTs = sort(selTimes); cbh = colorbar; colormap(timeColorArray(mapTs,:));
cbh.Ticks = sort((mapTs - min(mapTs))/(max(mapTs)- min(mapTs))) ; %Create 8 ticks from zero to 1
tickCell = cell(numel(mapTs),1);   
[tickCell{[1 end]}] = deal((mapTs(1)-1)*deltaT,(mapTs(end)-1)*deltaT);
cbh.TickLabels = tickCell;  

