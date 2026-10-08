%% Takes in .h5 segmentation and int corrected .tif, returns int. profile
% This script expects .h5 segmentations of kinesin-4 macrostructures with
% segmentations distinguishing exteriors, interiors, and smectic layers.
% The script uses proximity approximations using distance transforms to
% orient sheets, then bin intensities
% 2023/10/17 - 20231018
% Looked at 2024-01-16, seems a little outdated

% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 56, Exp 1';
h5Name = 'PassOne_t%03i_16bitSubSamp_Probabilities Stage 2.h5';
% imgDir= '<redacted original absolute path>';
imgDir= 'Session 56, Exp 1';
imgName = 't%03i_illBleachCorr16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';
saveName = 'intData_t%03i.mat';
% figDir = '<redacted original absolute path>';
figDir = 'Session 56, Exp 1';

threshVal = 0.33;
timeRange = 1:100;
objChans = [1 2 3];
binRange = -150:3:80;   %pixels
pixSize = 11*2/60;
% in terms of number of channels above
outInOn = [1 2 3];
strelRad = 2;   strelObj = strel('sphere',strelRad);
scaleVec = [1 1 4]/2;

binBounds = [-80 25];

% Color map info
timeColorVec = [1 0 0; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
timeColorStamps = [1 14 30 45 90 100];
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

%% Iterate through time, get intensity and bin info around drop perimeters
for tInd = 1:numel(timeRange)

    % Load current frame info
    currT = timeRange(tInd);    
    if mod(tInd,10) == 1
        fprintf('Currently analyzing frame %i...\n',currT);
    end
    % For session 45 exp 3
    % if tInd > 49
    %     objChans = [3 1 2];
    % end
    currSeg = loadH5(fullfile(h5Dir,sprintf(h5Name,currT)),'/exported_data',objChans);
    currImg = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
    scaledImg = imresize3(currImg,round(size(currImg).*scaleVec));
    
    % Define smoothed regions, then get boundaries and distance transforms
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
        imresize3_4mat(currSeg,size(scaledImg)),outInOn,threshVal,strelRad,1);
    [distMat,globalDistMat,regionFlip,primbgInds,secbgInds,layLogicMat] = ...
        distTransFromBoundary(cleanOns, cleanOuts, cleanIns, strelRad);
    
    % Histogram bin and sample intensities
    [binCounts,binEdges,binInds] = histcounts(globalDistMat,binRange);
    
    % Store total intensities over indices in each bin
    allInt_layer = zeros(numel(binCounts),1); allInt_ins = allInt_layer;
    iobinCounts = allInt_ins;
    for currInd = 1:numel(allInt_layer)
        allInt_layer(currInd) = sum(scaledImg((binInds == currInd) & layLogicMat));
        allInt_ins(currInd) = sum(scaledImg((binInds == currInd) & ~layLogicMat));
        iobinCounts(currInd) = sum(((binInds == currInd) & ~layLogicMat),'all');
    end
    lobinCounts = binCounts(:) - iobinCounts(:);

    % Save data
    save(fullfile(saveDir,sprintf(saveName,currT)),...
        'binEdges','binCounts','binInds','lobinCounts',...
        'inChan','layerChan','outChan','strelRad',...
        'allInt_layer','allInt_ins','layLogicMat');

end

%% Overlayed plots of above
figure
hold on
% selTimes = timeRange;
selTimes = 1:5:100;
% selTimes = 41:2:70;
% selTimes = 70:100;
% selTimes = 21:2:49;
% selTimes = 20:2:41;
% selTimes = [17,18,19,32,33,34,39,40,41,56,57,58,99,100];
tMax = numel(selTimes);
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    load(fullfile(saveDir,sprintf(saveName,currT)));

    % subplot(1,2,1)
    % colorVec = [ (1 - tInd/tMax) 0 tInd/tMax]; %red to blue
    % colorVec = [0 tInd/tMax (1 - tInd/tMax)]; %blue to green
    % colorVec = [0 (1 - tInd/tMax) 0]; %green to black
    % scatter(binEdges(1:end-1),allInt_layer(:)./lobinCounts(:),'MarkerFaceColor',colorVec,'MarkerEdgeColor','none');
    plot(binEdges(1:end-1)*pixSize,allInt_layer(:)./lobinCounts(:),'LineWidth',2);
    % plot(binEdges(1:end-1),allInt_layer(:)./lobinCounts(:),'Color',colorVec,'LineWidth',3);
    % xlim([-80 40])
    % hold on
    % subplot(1,2,2)
    % plot(binEdges(1:end-1),allInt_ins(:)./(binCounts(:)-lobinCounts(:)),'Color',[currT/tMax 0 (1 - currT/tMax)]);
    % plot(binEdges(1:end-1),lobinCounts(:),'Color',[tInd/numel(timeRange) 0 (1 - tInd/numel(timeRange))]);
    % xlim([-80 40])
    hold on

end
xlim(binBounds)
box on
xlabel('\Deltar from Drop Perimeter')
ylabel('Mean Intensity')
title('Mean Drop Intensity Profiles')
set(gca,'FontSize',20)
xlim([-60 30])
ylim([0.6 2.4]*10^4)
colororder(timeColorArray(selTimes,:));
% legend('Frame 18 - 10:30','Frame 30 - 19:15','Frame 40 - 23:20','Frame 55 - 32:05','Frame 67 - 39:05','Frame 90 - 52:30')

%% Heat map representation and "heat matrix"
figure
selTimes = 1:100;
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    load(fullfile(saveDir,sprintf(saveName,currT)));
    validBinLogic = (binEdges > binBounds(1)) & (binEdges < binBounds(2));
    validEdges = binEdges(validBinLogic);
    if tInd == 1
        heatMat = zeros(numel(validEdges),numel(selTimes));
    end
    heatMat(:,tInd) = allInt_layer(validBinLogic)./lobinCounts(validBinLogic);

end
imagesc( [selTimes(1) selTimes(end)], [validEdges(1) validEdges(end-1)],heatMat);
box on
xlabel('Time')
ylabel('Distance from drop perimeter')
title('Average Intensity Profile over Time')
set(gca,'FontSize',20)
colorbar

%% Using heat matrix, plot max intensity
colorMat = [];
colorMat = [colorMat; meldNcolors([1 0 0;0 0 1],numel(1:41))];
colorMat = [colorMat; meldNcolors([0 0 1;0 1 0],numel(41:70)-1)];
colorMat = [colorMat; meldNcolors([0 1 0;0 0 0],numel(70:100)-1)];
selTimes = 1:100;
figure
scatter(selTimes,max(heatMat,[],1),80,colorMat,'filled')
xlabel('Time')
ylabel('Peak Intensity')
title('Peak Intensity over Time')
set(gca, 'FontSize',20)
box on

%% 3D scatter representation

colorMat = [];
colorMat = [colorMat; meldNcolors([1 0 0;0 0 1],numel(1:41))];
colorMat = [colorMat; meldNcolors([0 0 1;0 1 0],numel(41:70)-1)];
colorMat = [colorMat; meldNcolors([0 1 0;0 0 0],numel(70:100)-1)];

% figure
hold on
selTimes = 1:2:100;
tMax = numel(selTimes);
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    load(fullfile(saveDir,sprintf(saveName,currT)));
    % colorVec = [0 tInd/tMax (1 - tInd/tMax)]; %blue to green
    scatter3(currT*ones(numel(allInt_layer),1),binEdges(1:end-1),allInt_layer(:)./lobinCounts(:),'MarkerFaceColor',colorMat(currT,:),'MarkerEdgeColor','none');

end
box on
xlabel('Time')
ylabel('\Deltar')
zlabel('Average Intensity')
set(gca,'FontSize',15)
%% 3D surface plot representation (using heat matrix)
[xmesh,ymesh] = meshgrid(1:100,validEdges);
figure
% hold on
surf(xmesh,ymesh,heatMat,'edgecolor','none','FaceColor','interp');
xlabel('Time')
ylabel('\Deltar')
zlabel('Average Intensity')
set(gca,'FontSize',15)

%% 3D line plots over surface
colorMat = [];
colorMat = [colorMat; meldNcolors([1 0 0;0 0 1],numel(1:41))];
colorMat = [colorMat; meldNcolors([0 0 1;0 1 0],numel(41:70)-1)];
colorMat = [colorMat; meldNcolors([0 1 0;0 0 0],numel(70:100)-1)];

figure
hold on
selTimes = 1:2:100;
tMax = numel(selTimes);
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    load(fullfile(saveDir,sprintf(saveName,currT)));
    % colorVec = [0 tInd/tMax (1 - tInd/tMax)]; %blue to green
    % scatter3(currT*ones(numel(allInt_layer),1),binEdges(1:end-1),allInt_layer(:)./lobinCounts(:),'MarkerFaceColor',colorMat(currT,:),'MarkerEdgeColor','none');
    plot3(currT*ones(numel(allInt_layer),1),binEdges(1:end-1),allInt_layer(:)./lobinCounts(:),'Color',colorMat(currT,:),'LineWidth',2);

end
box on
xlabel('Time')
ylabel('\Deltar')
zlabel('Average Intensity')
set(gca,'FontSize',15)
% 3D surface plot representation (using heat matrix)
[xmesh,ymesh] = meshgrid(1:100,validEdges);
% figure
% hold on
surf(xmesh,ymesh,heatMat,'edgecolor','none','FaceColor','interp');
% surf(xmesh,ymesh,heatMat,'EdgeColor','none');
xlabel('Time')
ylabel('\Deltar')
zlabel('Average Intensity')
set(gca,'FontSize',15)




