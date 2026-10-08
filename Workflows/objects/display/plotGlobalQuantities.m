% Simple script to plot global volume, intensity, density fractions
% 2024-09-06 - Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName = 'VolumeFracs_MTs_withMasksDil1.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 84';
saveBool = 0;

deltaT = 30;

%% Load data
load(fullfile(dataDir,dataName));

%% Rescale and define
if ~exist('maskedInts','var')
    maskedInts = 0;
    maskedVols = 0;
end

intFracIn = (allInts)./totalInts; intFracOut = 1 - intFracIn;
volFracIn = (allVols)./totalPix;  volFracOut = 1 - volFracIn;
denseIn = (allInts)./(allVols);     
denseOut = (totalInts - allInts)./(totalPix - allVols);
denseInNorm = intFracIn./volFracIn; denseOutNorm = intFracOut./volFracOut;

scaledMaskIntsI = maskedIntsIn./totalInts;
scaledMaskIntsO = maskedIntsOut./totalInts;
scaledAllInts = allInts./totalInts;
scaledBGInts = 1 - (scaledAllInts + scaledMaskIntsI + scaledMaskIntsO);

scaledMaskVolsI = maskInVols./totalPix;
scaledMaskVolsO = maskOutVols./totalPix;
scaledAllVols = allVols./totalPix;
scaledBGVols = 1 - (scaledAllVols + scaledMaskVolsI + scaledMaskVolsO);

staticSubInts = (allInts - maskedInts(1))./totalInts;
staticSubVols = max(0,(allVols - maskedVols))./totalPix;

denseInNorm = (scaledAllInts)./(scaledAllVols);
denseOutNorm = (1 - (scaledMaskIntsO + scaledAllInts + scaledMaskIntsI))./(1 - ( scaledAllVols + scaledMaskVolsI + scaledMaskVolsO) );

%% Plot all the things

xVec = log(timeRange*deltaT);
currField = log(denseInNorm);
currField2 = log(denseOutNorm);

figure
box on
scatter(xVec,currField,'filled','black')
hold on
scatter(xVec,currField2,'filled','red')
hold off
xlabel('Time (sec)')
ylabel('Densities')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
    saveas(gca,fullfile(saveDir,'LOGDense.png'));
else
    figure
end

xVec = (timeRange*deltaT);

currField = (denseIn);
currField2 = (denseOut);
scatter(xVec,currField,'filled','black')
box on
hold on
scatter(xVec,currField2,'filled','red')
hold off
xlabel('Time (sec)')
ylabel('Densities')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,'Dense.png'));
else
    figure
end

currField = (allInts./allVols);
currField2 = (totalInts-  allInts)./(totalPix - allVols);
scatter(xVec,currField,'filled','black')
box on
hold on
scatter(xVec,currField2,'filled','red')
hold off
xlabel('Time (sec)')
ylabel('Densities')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,'Dense.png'));
else
    figure
end

currField = (volFracIn);
currField2 = (volFracOut);
saveString = 'Volumes';
scatter(xVec,currField,'filled','black')
box on
hold on
scatter(xVec,currField2,'filled','red')
hold off
xlabel('Time (sec)')
ylabel(saveString)
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

currField = (intFracIn);
currField2 = (intFracOut);
saveString = 'Intensities';
scatter(xVec,currField,'filled','black')
box on
hold on
scatter(xVec,currField2,'filled','red')
hold off
xlabel('Time (sec)')
ylabel(saveString)
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

currField = [0 diff(intFracIn')'];
saveString = 'Intensities_Slopes';
scatter(xVec,currField,'filled','black')
box on
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

currField = [0 diff(volFracIn')'];
saveString = 'Volumes_Slopes';
scatter(xVec,currField,'filled','black')
box on
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

currField = [0 diff(denseIn')'];
saveString = 'Densities_Slopes';
scatter(xVec,currField,'filled','black')
box on
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

currField = denseIn./denseOut;
saveString = 'Densities_Fraction';
scatter(xVec,currField,'filled','black')
box on
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

currField = (denseIn - denseOut)./(denseIn + denseOut);
saveString = 'Densities_Difference';
scatter(xVec,currField,'filled','black')
box on
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

currField = denseInNorm./denseOutNorm;
saveString = 'Densities_Fraction_Norm';
scatter(xVec,currField,'filled','black')
box on
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

currField = (denseInNorm - denseOutNorm)./(denseInNorm + denseOutNorm);
saveString = 'Densities_Difference';
scatter(xVec,currField,'filled','black')
box on
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDir,sprintf('%s.png',saveString)));
else
    figure
end

%% Plot all the things with HIGHLIGHTED timepoints
addDir = 'With Special';
color1 = [160 35 52]/255;
color2 = ([140 196 170]-20)/255;
specTs = [6 9 12 15 20 23 71];
colorSpec = [255 173 96]/255;

saveBool = 0;
saveDirPlus = fullfile(saveDir,addDir);
if ~exist(saveDirPlus,'dir')
    mkdir(saveDirPlus);
end


xVec = log(timeRange*deltaT);
currField = log(denseInNorm);
currField2 = log(denseOutNorm);

figure
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec,currField2,'filled','MarkerFaceColor',color2)
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
scatter(xVec(specTs),currField2(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel('Densities')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
    saveas(gca,fullfile(saveDirPlus,'LOGDense.png'));
else
    figure
end

currField = log(volFracIn);
currField2 = log(volFracOut);

scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec,currField2,'filled','MarkerFaceColor',color2)
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
scatter(xVec(specTs),currField2(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel('Volumes')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
    saveas(gca,fullfile(saveDirPlus,'LOGVols.png'));
else
    figure
end

currField = log(intFracIn);
currField2 = log(intFracOut);

scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec,currField2,'filled','MarkerFaceColor',color2)
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
scatter(xVec(specTs),currField2(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel('Intensities')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
    saveas(gca,fullfile(saveDirPlus,'LOGInts.png'));
else
    figure
end

xVec = (timeRange*deltaT);

currField = (denseIn);
currField2 = (denseOut);
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec,currField2,'filled','MarkerFaceColor',color2)
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
scatter(xVec(specTs),currField2(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel('Densities')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,'Dense.png'));
else
    figure
end

currField = (allInts./allVols);
currField2 = (totalInts-  allInts)./(totalPix - allVols);
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec,currField2,'filled','MarkerFaceColor',color2)
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
scatter(xVec(specTs),currField2(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel('Densities')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,'Dense.png'));
else
    figure
end

currField = (volFracIn);
currField2 = (volFracOut);
saveString = 'Volumes';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec,currField2,'filled','MarkerFaceColor',color2)
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
scatter(xVec(specTs),currField2(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

currField = (intFracIn);
currField2 = (intFracOut);
saveString = 'Intensities';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec,currField2,'filled','MarkerFaceColor',color2)
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
scatter(xVec(specTs),currField2(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

currField = [0 diff(intFracIn')'];
saveString = 'Intensities_Slopes';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

currField = [0 diff(volFracIn')'];
saveString = 'Volumes_Slopes';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

currField = [0 diff(denseIn')'];
saveString = 'Densities_Slopes';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

currField = denseIn./denseOut;
saveString = 'Densities_Fraction';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

currField = (denseIn - denseOut)./(denseIn + denseOut);
saveString = 'Densities_Difference';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

currField = denseInNorm./denseOutNorm;
saveString = 'Densities_Fraction_Norm';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

currField = (denseInNorm - denseOutNorm)./(denseInNorm + denseOutNorm);
saveString = 'Densities_Difference';
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
box on
hold on
scatter(xVec(specTs),currField(specTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
hold off
xlabel('Time (sec)')
ylabel(saveString)
set(gca,'FontSize',15)
if saveBool == 1
saveas(gca,fullfile(saveDirPlus,sprintf('%s.png',saveString)));
else
    figure
end

%% Plot both volume fractions and mass fractions
selRange = 1:76;
currField2 = (volFracIn(selRange));
currField = (intFracIn(selRange));
fieldNames = { 'Mass Fraction','Volume Fraction'};
selSpecTs = [7 17 27 37]*2;     
% selSpecTs = specTs([1 4 6 7]);      
legSkip = cell(1,numel(selSpecTs));
color1 = ([160 35 52] + 10)/255;
color2 = ([140 196 170]-20)/255;
lineColor = [1 1 1]*.0;
hilite1 = 0;   hilite2 = 0;
saveBool = 1;
yBnds = [0 0.5];
xBnds = [0 38];

xVec = (selRange*deltaT/60);
currYs = yBnds;     % ybounds of dotted lines behind plots
for index = 1:numel(selSpecTs)
    currT = selSpecTs(index);
     % update ybounds of dotted lines behind plots
    currYs(1) = min(currField(currT), currField2(currT));
    % plot background lines
    plot(xVec([currT currT]), fliplr(currYs), '--','Color',lineColor);
    box on
    hold on
    legSkip{index} = '';
end
% Plot data
scatter(xVec,currField,'filled','MarkerFaceColor',color1)
scatter(xVec,currField2,'filled','MarkerFaceColor',color2)
% Plot highlighted data points
scatter(xVec(selSpecTs),currField(selSpecTs),'filled','MarkerFaceColor',[1 1 1]*hilite1,'SizeData',70)
scatter(xVec(selSpecTs),currField2(selSpecTs),'filled','MarkerFaceColor',[1 1 1]*hilite2,'SizeData',70)
scatter(xVec(selSpecTs),currField(selSpecTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)
scatter(xVec(selSpecTs),currField2(selSpecTs),'filled','MarkerFaceColor',colorSpec,'SizeData',20)

hold off
xlabel('Time (min)')
ylabel('Normalized Fraction')
fullLegend = [legSkip fieldNames];
legend(fullLegend,'Location','southeast')
set(gca,'FontSize',15)
ylim(yBnds)
xlim(xBnds)
if saveBool == 1
    saveas(gca,fullfile(saveDirPlus,'VOL_MASS_IN.fig'));
else
    figure
end

%% Plot things
figure

% currField = scaledMaskInts./scaledMaskVols;
% currField2 =  scaledAllInts./scaledAllVols;
% currField3 = (scaledAllInts - scaledMaskInts)./(scaledAllVols - scaledMaskVols);
% currField4 = (1 - (scaledAllInts + scaledMaskInts))./(1 - (scaledAllVols + scaledMaskVols));
% currField = scaledMaskIntsI;
% currField2 = scaledAllInts + scaledMaskIntsI;
% currField3 = scaledAllInts;
% currField = scaledMaskVolsI;
% currField2 = scaledAllVols + scaledMaskVolsI;
% currField3 = scaledAllVols;
currField = (scaledAllInts)./(scaledAllVols);
currField2 = (scaledAllInts + scaledMaskIntsI)./(scaledAllVols + scaledMaskVolsI);
currField3 = scaledMaskIntsI./scaledMaskVolsI;
% currField3 = (1 - (scaledMaskIntsO + scaledAllInts + scaledMaskIntsI))./(1 - ( scaledAllVols + scaledMaskVolsI + scaledMaskVolsO) );
currField4 = (1 - ( scaledAllInts + scaledMaskIntsI))./(1 - ( scaledAllVols + scaledMaskVolsI ) );

denseFracCorr = currField./currField3;
denseFracOg = currField2./currField4;

scatter(xVec,currField,'filled','black')
box on
hold on
scatter(xVec,currField2,'filled','red')
scatter(xVec,currField3,'filled','blue')
scatter(xVec,currField4,'filled','green')
hold off
xlabel('Time (sec)')
ylabel('Densities')
legend('Inside', 'Inside + Masked','Masked','BG')
set(gca,'FontSize',15)
if saveBool == 1
    saveas(gca,fullfile(saveDir,'LOGDense.png'));
else
    figure
end
%% 
xVec = (timeRange*deltaT);
figure
currField = denseInNorm./denseOutNorm;

box on
hold on
scatter(xVec,currField,'filled','red')
hold off
xlabel('Time (sec)')
ylabel('Densities')
legend('Objects', 'Bulk')
set(gca,'FontSize',15)
if saveBool == 1
    saveas(gca,fullfile(saveDir,'LOGDense.png'));
else
    figure
end



