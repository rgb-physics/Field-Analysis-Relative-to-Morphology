% Data loaded from Fourier Analysis and make plots
% 2026-06-22

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 88, Exp 1';
dataName = '600bin_structFactor2D_variables_600bin.mat';

%% Load data
load(fullfile(dataDir,dataName));

%% Plot Spectra over time range, avged select z values
% Select times for full color + transpacrency
tFlip = 29;             % index of T = 0, typically indicated by <max(rho)>
deltaT = 0.5;
zInd = 2:2:8;  
botLim = min(30,tFlip-1);
% S81 E2
% selectTimes = sort([(tFlip-botLim):2:(tFlip-14) (tFlip -12):4:(tFlip)]);
% selectTimes = sort(tFlip - (20:botLim));
% S 84 E1
% selectTimes = sort([(tFlip-botLim):2:(tFlip-14) (tFlip -12):4:(tFlip)]);
% selectTimes = sort(tFlip - (10:20));
% S S88 E1
% selectTimes = sort([(tFlip-botLim):2:(tFlip-14) (tFlip -12):4:(tFlip)]);
selectTimes = sort(tFlip - (10:20));
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

% Display strings
titleTag = sprintf('Scattering - Z:%i ',selZ(zInd));
xtitle = 'q (1/um)';
ytitle = 'Mean FFT Profile';

% Space lines, if requested
if spacerLen > 0
    spacerVec = spacerLen.^selectTimes;
    yBnds(end) = yBnds(end)*spacerVec(end);
else
    spacerVec = ones(numel(selectTimes),1);
end

% Approximate peaks
xCut = find(scaledK > xmin, 1);
selMat  = storeMat(xCut:end,zInd,selectTimes);
zAvgMat = squeeze(mean(selMat,2));
avged = movmean(zAvgMat,movkern);

% Plot
figure
    hold on
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    currK = scaledK(xCut:end-1);
    currField = zAvgMat(:,tInd);
    colorInd = colorInds(tInd);
    scatter(currK, currField*spacerVec(tInd),10,'filled','MarkerFaceColor',tcaAlpha(colorInd,1:3));
    hold on
    plot(scaledK(xCut:end-1), avged(:,tInd)*spacerVec(tInd),'LineWidth',1,'Color',[.1 .1 .1]);
   
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
