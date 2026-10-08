%% Takes in .mats with van Hove data; plots correlation functions
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 56, Exp 1';
dataName = 'xyCorrs.mat';

timeRange = 1:100;

%% Generate colormat
colorMat = [];
colorMat = [colorMat; meldNcolors([1 0 0;0 0 1],numel(1:41))];
colorMat = [colorMat; meldNcolors([0 0 1;0 1 0],numel(41:70)-1)];
colorMat = [colorMat; meldNcolors([0 1 0;0 0 0],numel(70:100)-1)];

%% Plot Correlation
selTimes = 1:3:100;
figure
load(fullfile(dataDir,dataName));
plot(repmat(radialEdges(1,:),size(xyCorrs(:,selTimes),2),1)',xyCorrs(:,selTimes)./max(xyCorrs(:,selTimes),[],1),'LineWidth',3)
colororder(colorMat(selTimes,:));
xlabel('\Deltar (um)')
title('Spatial Intensity Correlation Raw Image')
set(gca,'FontSize',15)

figure
plot(repmat(radialEdges(1,:),size(xyBlobCorrs(:,selTimes),2),1)',xyBlobCorrs(:,selTimes)./max(xyBlobCorrs(:,selTimes),[],1),'LineWidth',3)
colororder(colorMat(selTimes,:));
xlabel('\Deltar (um)')
title('Spatial Intensity Correlation Sub-sampled Image')
set(gca,'FontSize',15)

