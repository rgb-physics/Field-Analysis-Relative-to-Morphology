%% Plots data from estimateFirstInertiaMoment.m
% 2026-06-26 - Rémi Boros
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName = 'InertiaStore.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveBool = 0;
fileExts = {'fig','png','svg'};

%%
load(fullfile(dataDir,dataName),'objInertias','ColumnContents')
load(fullfile(dataDir,'metadata.mat'))

%% Violin plots over time
frameZero = 34;
deltaT = .5;
xVals = (objInertias(:,2)-frameZero)*deltaT;    
xBins = (selTimes - frameZero)*deltaT;
[bndMeans,bndMeds] = visualizationtools.display.plotVlns(xVals,objInertias(:,3)./objInertias(:,5),xBins,30,1);
box on
title('Boundary Coordinates')
ylabel('<sum(\rho r)/sum(\rho) (um)>')
xlabel('Time (min)')
set(gca,'FontSize',12)
visualizationtools.export.figSaves(gca,saveDir,'BndCoords_ViolinPlots_RvT',fileExts,saveBool)

% ylim([0 10^10])
[skelMeans,skelMeds] = visualizationtools.display.plotVlns(xVals,objInertias(:,4)./objInertias(:,5),xBins,30,1);
box on
title('Skeleton Coordinates')
ylabel('<sum(\rho r)/sum(\rho) (um)>')
xlabel('Time (min)')
set(gca,'FontSize',12)
% ylim([0 3*10^10])
visualizationtools.export.figSaves(gca,saveDir,'SkelCoords_ViolinPlots_RvT',fileExts,saveBool)

%% Compare violins to aspect ratios
% sphDir = '<redacted original absolute path>';
sphDir = 'Session 81, Exp 3';
sphName = 'trajSorted_RMin_Anisotropy.mat';

% Load anisotropy data
load(fullfile(sphDir,sphName));

% Calculate mean r and anisotropy values in statStruct
selFields = {'MinAxStats','FAs','Sphs'};
meanMat = zeros(numel(statStruct),numel(selFields));
medMat = meanMat;
% Iterate over objects
for index = 1:numel(statStruct)
    %Iterate over fields
    for jdex = 1:numel(selFields)
    % Load current object data
        currData = statStruct(index).(selFields{jdex});
    % Calculate means and store
        meanMat(index,jdex) = mean(currData);
        medMat(index,jdex) = median(currData);
    end
end

% Isolate IDs and Frames for sorting
sphCoords = [[statStruct(:).BlobID]' [statStruct(:).Frame]'];
% Map indices of objects in objInertias to indices in statStruct
[existLogic,mapVec] = ismember(objInertias(:,1:2),sphCoords,'rows');

%% Plot average blob quants against r from objInertias (colored by time)
subTimes = 24:4:60;
plotField = 1;
saveBool = 0;
saveName = 'SkelCoordsR_vs_MeanRmin';
% saveName = 'SkelCoordsR_vs_MeanSpherocity';
timeColorArray = othercolor('BuPu3',max(subTimes));
figure
hold on
for tInd = 1:numel(subTimes)
    currT = subTimes(tInd);
    % Add time logic
    tLogic = objInertias(:,2) == currT;
    totLogic = existLogic & tLogic;
    fieldOne = objInertias(totLogic,4)./objInertias(totLogic,5);
    fieldTwo = meanMat(mapVec(totLogic),plotField);
    % fieldTwo = medMat(mapVec(totLogic),plotField);
    scatter(fieldOne,fieldTwo,20,timeColorArray(currT,:),'filled');
end

box on
xlabel('r from first moment (um)')
ylabel(sprintf('StatStruct Field - %s',selFields{plotField}))
set(gca,'FontSize',15)
% xlim([0 25])
% ylim([0 25])
% Populate colorbar
% mapTs = sort(arrayInds);
cVals = (subTimes - frameZero)*deltaT;
cbh = colorbar;
cbh.Ticks = (cVals - min(cVals))/(diff(cVals([1 end])));
colormap(timeColorArray(subTimes,:));
tickCell = cell(numel(subTimes),1);   
[tickCell{[1 end]}] = deal(cVals(1),cVals(end));
cbh.TickLabels = tickCell;   

visualizationtools.export.figSaves(gca,saveDir,saveName,fileExts,saveBool)

% sphCoords(mapVec(existLogic),:)
%% Make violin plots of all objects that fall within 3um diff between methods
subTimes = 24:4:60;
plotField = 1;
saveBool = 0;
diffCut = 3;        % difference between MinAxStats and 1st moment in um
% saveName = 'SkelCoordsR_vs_MeanRmin';
% saveName = 'SkelCoordsR_vs_MeanSpherocity';
timeColorArray = othercolor('BuPu3',max(subTimes));
% Find "close" objects over all times
fieldOne = objInertias(existLogic,4)./objInertias(existLogic,5);
fieldTwo = meanMat(mapVec(existLogic),plotField);
% Define cut off
validLogic = abs(fieldOne - fieldTwo) < diffCut;

figure
hold on
for tInd = 1:numel(subTimes)
    currT = subTimes(tInd);
    % Add time logic
    tLogic = objInertias(existLogic,2) == currT;
    totLogic = tLogic & validLogic;
    % totLogic = validLogic & tLogic;
    firstMoment = fieldOne(totLogic);
    minAx = fieldTwo(totLogic);
    scatter(firstMoment,minAx,20,timeColorArray(currT,:),'filled');
end
title(sprintf('Fraction removed %2.2f',sum(validLogic)/sum(existLogic)));

%% Plot violin plots after removing data that are far apart in r-values
% Find "close" objects over all times
fieldOne = objInertias(existLogic,4)./objInertias(existLogic,5);
fieldTwo = meanMat(mapVec(existLogic),plotField);
validLogic = abs(fieldOne - fieldTwo) < diffCut;
newLogic = existLogic(validLogic);

frameZero = 34;
deltaT = .5;

xVals = (objInertias(newLogic,2)-frameZero)*deltaT;    
xBins = (selTimes - frameZero)*deltaT;
[bndMeans,bndMeds] = visualizationtools.display.plotVlns(xVals,objInertias(newLogic,3)./objInertias(newLogic,5),xBins,30,1);
box on
title('Boundary Coordinates')
ylabel('<sum(\rho r)/sum(\rho) (um)>')
xlabel('Time (min)')
set(gca,'FontSize',12)
visualizationtools.export.figSaves(gca,saveDir,'BndCoords_ViolinPlots_RvT',fileExts,saveBool)

% ylim([0 10^10])
[skelMeans,skelMeds] = visualizationtools.display.plotVlns(xVals,objInertias(newLogic,4)./objInertias(newLogic,5),xBins,30,1);
box on
title('Skeleton Coordinates')
ylabel('<sum(\rho r)/sum(\rho) (um)>')
xlabel('Time (min)')
set(gca,'FontSize',12)
% ylim([0 3*10^10])
visualizationtools.export.figSaves(gca,saveDir,'SkelCoords_ViolinPlots_RvT',fileExts,saveBool)

%% Plot violin plots after removing data that are not spheroidal
sphVals = meanMat(mapVec(existLogic),3);
validLogic = sphVals > 0.7;
newLogic = existLogic(validLogic);
xVals = (objInertias(newLogic,2)-frameZero)*deltaT;    
xBins = (selTimes - frameZero)*deltaT;
[bndMeans,bndMeds] = visualizationtools.display.plotVlns(xVals,objInertias(newLogic,3)./objInertias(newLogic,5),xBins,30,1);
box on
title('Boundary Coordinates')
ylabel('<sum(\rho r)/sum(\rho) (um)>')
xlabel('Time (min)')
set(gca,'FontSize',12)
visualizationtools.export.figSaves(gca,saveDir,'BndCoords_ViolinPlots_RvT',fileExts,saveBool)

% ylim([0 10^10])
[skelMeans,skelMeds] = visualizationtools.display.plotVlns(xVals,objInertias(newLogic,4)./objInertias(newLogic,5),xBins,30,1);
box on
title('Skeleton Coordinates')
ylabel('<sum(\rho r)/sum(\rho) (um)>')
xlabel('Time (min)')
set(gca,'FontSize',12)
% ylim([0 3*10^10])
visualizationtools.export.figSaves(gca,saveDir,'SkelCoords_ViolinPlots_RvT',fileExts,saveBool)


