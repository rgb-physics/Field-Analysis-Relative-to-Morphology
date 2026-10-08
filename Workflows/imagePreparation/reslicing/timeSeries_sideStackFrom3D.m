%% Takes in 3D tifs over time and returns a side view over time
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 28, Exp 6';
imgName = 't%03i_illBleachCorr16bit.tif';

% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveName = 'tifSideView_3.tif';

% Sample dimensions and ranges
% Static dimension = 1 cooresponds to single row; dim = 2 is a single col
staticDim = 1; staticCoord = 196;
% sampleRange = round([85 85+480]/2);
sampleRange = [1 inf];
zRange = [1 inf];
% timeRange = [1 5 10 21 57 100];
% timeRange = [18 33 40 55 67 90];
timeRange = 150:280;
% Rescale info
% ogScaleInfo = [1 1 1];
ogScaleInfo = [1 1 4]/2;

%% Generate vertex coordinate cell
coordCell = cell(1,3);
coordCell{staticDim} = [staticCoord staticCoord];
coordCell{mod1b(staticDim+1,2)} = sampleRange;
coordCell{3} = zRange;

%% Iterate through each time/3D stack and store sideview 
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    currName = fullfile(dataDir,sprintf(imgName,currT));
    if tInd == 1
        currSlice = squeeze(tiffreadVolume(currName,'PixelRegion',coordCell))';
        storeMat3D = zeros([size(currSlice),numel(timeRange)]);
        storeMat3D(:,:,tInd) = currSlice;
    else
        storeMat3D(:,:,tInd) = squeeze(tiffreadVolume(currName,'PixelRegion',coordCell))';
    end
end

%% Save the matrix
saveMat3D = imresize3(storeMat3D,[ogScaleInfo(3) ogScaleInfo(staticDim) 1].*size(storeMat3D));
% save3DTiff(uint8(saveMat3D),fullfile(saveDir,saveName));
save3DTiff(uint16(saveMat3D),fullfile(saveDir,saveName));
% currData = tiffreadVolume


