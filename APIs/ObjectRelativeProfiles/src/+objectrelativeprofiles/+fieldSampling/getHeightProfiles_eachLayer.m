%% This script returns the height profile in each protein sheet from indices stored in segmentation structures
%The script does take overhangs into account
%Directory info
% structDir = '<redacted original absolute path>';
structDir = 'Session 25, Exp 5';
structNameForm = 'Time%06i_regionsStruct.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
saveNameForm = "%s_heightInfo_redo.tif";
selectTimes = 1:100;

%% Iterate over time
for timeInd = 1:numel(selectTimes)
    %Load segmentation-structure data
    currT = selectTimes(timeInd);
    currStruct = load(fullfile(structDir, sprintf(structNameForm,currT)));
    imgDims = size(currStruct.outputStruct.topInds);
    
    % Generate storage matrices and height matrix
    if timeInd == 1
        topHeights = zeros(imgDims(1), imgDims(2), numel(selectTimes));
        botHeights = topHeights;
        meanHeights = zeros( numel(selectTimes),2); %col 1 top, col 2 bot
        zMat = permute( repmat(1:imgDims(3), [imgDims(1), 1, imgDims(2)]), [1 3 2]);
    end
    
    %Define matrices of segmented indices in layers with associated heights
    zValsTop = consMatLnB(zMat, currStruct.outputStruct.topInds);
    zValsBot = consMatLnB(zMat, currStruct.outputStruct.botInds);
    zValsBot = zValsBot + consMatLnB( (imgDims(3)+1)*ones(size(zMat)), ~currStruct.outputStruct.botInds);
    
    %Get max height in each layer, accounting for direction of each layer
    topZMaxes = max(zValsTop,[],3); topHeights(:,:,timeInd) = topZMaxes;
    botZMaxes = min(zValsBot,[],3); botHeights(:,:,timeInd) = botZMaxes;
   
    %Get mean height of each layer surface
    meanHeights(timeInd,:) = [mean(topZMaxes(:)),mean(botZMaxes(:))];

end

%% Plot some things

currMids = ones(1,1,numel(selectTimes));

figure
scatter(1:size(meanHeights,1), imgDims(3)-meanHeights(:,1),'filled');
hold on
scatter(1:size(meanHeights,1), imgDims(3)-meanHeights(:,2),'filled');

figure
currMids(1,1,:) = meanHeights(:,1);
orthosliceViewer(-(topHeights-currMids));

figure
currMids(1,1,:) = meanHeights(:,2);
orthosliceViewer(-(botHeights-currMids));

%% Save as tifs
save3DTiff( uint8(topHeights), fullfile(saveDir,sprintf(saveNameForm,"TopSurface")));
save3DTiff( uint8(imgDims(3)-botHeights), fullfile(saveDir,sprintf(saveNameForm,"BotSurface")));


