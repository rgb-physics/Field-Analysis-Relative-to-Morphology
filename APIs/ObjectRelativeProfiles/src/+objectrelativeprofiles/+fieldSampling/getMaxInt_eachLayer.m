%% This script returns the maximum intensity at each x,y pixel in each 2D sheet at indices defined in a segmentation structure over time
%Directory info
% structDir = '<redacted original absolute path>';
structDir = 'Session 25, Exp 5';
structNameForm = 'Time%06i_regionsStruct.mat';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 25, Exp 5';
imgFile = 'Time%06i_16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
saveNameForm = "%s_maxProjection_redo.tif";
selectTimes = 1:100;
strelRad = 2;

%% Define strel object
if strelRad > 0
    strelObj = strel("sphere", strelRad);
end

%% Iterate over time

for timeInd = 1:numel(selectTimes)
    %Load intensity and segmentation-structure data
    currT = selectTimes(timeInd);
    currStruct = load(fullfile(structDir, sprintf(structNameForm,currT)));
    currTif = tiffreadVolume(fullfile(imgDir, sprintf(imgFile, currT)));
    
    % Generate storage matrices
    if timeInd == 1
        topMaxes = zeros(size(currTif,1), size(currTif,2), numel(selectTimes));
        botMaxes = topMaxes;
    end
    
    %Get max intensity projection of each layer
    topMaxes(:,:,timeInd) = max( consMatLnB(currTif, currStruct.outputStruct.topInds),[],3);
    botMaxes(:,:,timeInd) = max( consMatLnB(currTif, currStruct.outputStruct.botInds),[],3);

end

%% Save tifs after scaling
scaledTops = topMaxes./mean(mean(topMaxes,1),2);
scaledBots = botMaxes./mean(mean(botMaxes,1),2);

save3DTiff( uint16(scaledTops*(2^14-max(scaledTops(:)))), fullfile(saveDir, sprintf(saveNameForm,"TopSurface")));
save3DTiff( uint16(scaledBots*(2^14-max(scaledBots(:)))), fullfile(saveDir, sprintf(saveNameForm,"BotSurface")));

