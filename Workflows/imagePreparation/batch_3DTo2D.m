%% Takes in a directory of 3D tifs and generates directories of 2D tifs
% 2023-11-13
% baseDir = '<redacted original absolute path>';
baseDir = '';
dataDir = fullfile(baseDir,'Gauss and Tophat Cleanup');
saveDir = fullfile(baseDir,'Gauss and Tophat Cleanup Split Slices');

dataNames = dir(fullfile(dataDir,'*Gauss1_*.tif'));
saveName = 'Slice%s_%s';

%% Iterate, load, split, save
if exist(saveDir) == 0
    mkdir(saveDir);
end

for index = 1:numel(dataNames)
    currName = dataNames(index).name;
    [~,nameOnly,fileExt] = fileparts(currName);
    currTif = tiffreadVolume(fullfile(dataDir,currName));
    currSaveName = fullfile(saveDir,nameOnly,sprintf(saveName,'%03i',currName));
    split3Dto2D(currTif, currSaveName);
end