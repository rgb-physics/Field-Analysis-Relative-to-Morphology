%% General info
% 2023/11/08
% Directory info
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 81, Exp 3';
tifNameForm = 'T%06i_trackedIDs.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';
saveNameForm = 'T%06i_cropped.tif';

% Range info
selectTimes = 1:50;
% For scaling segmentation to image dimensions
scaleFact = [1 1 1];
leftCorner = round(scaleFact.*([61 68 1]));
botCorner = round(scaleFact.*([159   166    69]));
winSize =  botCorner - leftCorner + [1 1 1];
% For cropping image dimensions version
% maxCorn = [500, 500, 85];
% scaleFact = [1 1 1];
% leftCorner = round(scaleFact.*[122 400 1]);
% winSize = [150 150 81];

% Save?
saveBool = 1;
if saveBool == 1
    mkdir(saveDir)
end

%% Iterate through time and crop images (and save)
saveName = '';
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    if saveBool == 1
        saveName = fullfile(saveDir, sprintf(saveNameForm,currT));
    end
    currTif = tiffreadVolume(fullfile(tifDir, sprintf(tifNameForm,currT)));
    cropTiffSave(currTif, leftCorner, winSize, saveBool, saveName);
end

if saveBool == 1
    save(fullfile(saveDir, "metadata.mat"), "leftCorner", "winSize", '-mat')
end


