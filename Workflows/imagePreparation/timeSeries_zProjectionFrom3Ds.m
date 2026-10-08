%% Time series from select z slices stored in 3D .tifs, each a given time
% 2023/10/24
% Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 56, Exp 1';
dataNameForm = 't%03i_illBleachCorr16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';

timeRange = 1:100;
zSlices = round([23 23]);
xSlices = round([1 740]);
ySlices = round([1 750]);
scaleVec = [1 1 1];
% scaleVec = [.5 .5 1];

%% Iterate through time, extract slice(s) of interest, save
for tInd = 1:numel(timeRange)
    % Define info for current time
    currT = timeRange(tInd);
    currFile = fullfile(dataDir,sprintf(dataNameForm,currT));
    % Instantiate storage matrix, if tInd = 1
    if tInd == 1
        tifInfo = imfinfo(currFile);
        combSlices = zeros((xSlices(end))-xSlices(1)+1, ...
            (ySlices(end)) - ySlices(1)+1, numel(timeRange));
        if zSlices(end) == inf
            zSlices(end) = numel(tifInfo);
        end
    end
    % Store max of z slices for current time in storage matrix
    combSlices(:,:,tInd) = max(tiffreadVolume(currFile, ...
        'PixelRegion',{xSlices, ySlices, zSlices}),[],3);
end
combSlices = imresize3(combSlices,size(combSlices).*scaleVec);

%% Save tif
save3DTiff(uint16(combSlices), fullfile(saveDir,...
    sprintf('t%03i-%03i_z%03i-%03i-%03i_segperim.tif',timeRange(1), timeRange(end),...
    zSlices(1),zSlices(2),zSlices(end))));
