%% Takes in a directory and name of 3D tifs along with a desired z
% Saves a single tif as a compilation of all z slices from the desired 3D
% tifs
% 2024-01-30 Rémi Boros

%% Data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 81, Exp 3';
dataName = 't%03i_illBleachCorr16bit_488.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveName = 'Z%03i-K4_11-17SliceProj.tif';
selZ = 11:17;
timeRange = 1:40;
binaryBool = 0;

% pixRegion =  {[410 1 510],[200 1 340], [min(selZ) max(selZ)]};
pixRegion =  {[1 1 inf], [1 1 inf], [min(selZ) max(selZ)]};
% pixRegion =  {[1 1 (775)], [11 1 (775+10)], [min(selZ) max(selZ)]};
%% Iterate over time
for tInd = 1:numel(timeRange)

    currT = timeRange(tInd);
    currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)),...
            'PixelRegion', pixRegion);
    currTif = squeeze(max(currTif,[],3));
    % currTif = squeeze(mean(currTif,3));
    if binaryBool == 1
        currTif = logical(sum(currTif,3));
    end
    if tInd == 1
        saveTif = zeros([size(currTif),numel(timeRange)]);
        saveTif(:,:,1) = currTif;
    else
        saveTif(:,:,tInd) = currTif;
    end

end

% Save
save3DTiff(uint16(saveTif),fullfile(saveDir,sprintf(saveName,mean(selZ))));

