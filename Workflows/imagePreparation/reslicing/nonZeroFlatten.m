%% Takes in a directory and name of 3D tifs along with a desired z
% Projects along the z axis, assigning mean non-zero values below
% 2024-10-23 Rémi Boros

%% Data info
% dataDir = '<redacted original absolute path>';
dataDir = '';
dataName = 'T%06i_clusterIDs.tif';
% saveDir = '<redacted original absolute path>';
saveDir = '';
saveName = 'T%06i_FLAT_clusterIDs.tif';
selZ = 1:52;
timeRange = 170:210;

pixRegion =  {[1 1 inf], [1 1 inf], [min(selZ) max(selZ)]};
%% Iterate over time
for tInd = 1:numel(timeRange)

    currT = timeRange(tInd);
    currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)),...
            'PixelRegion', pixRegion);
    sumTif = (sum(currTif,3));
    countTif = sum(logical(currTif),3);
    saveTif = sumTif./countTif;

% Save
save3DTiff(uint16(saveTif),fullfile(saveDir,sprintf(saveName,currT)));

end


