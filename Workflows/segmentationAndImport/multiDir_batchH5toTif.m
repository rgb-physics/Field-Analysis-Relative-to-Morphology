%% Takes in superdirectory of directories containing .h5s. Makes .tifs
% 2023-11-13, Rémi Boros
% baseDir = '<redacted original absolute path>';
baseDir = '';
dirNames = dir(fullfile(baseDir,'*Segmentations'));
saveDirForm = '%s Tifs';
h5Query = '*.h5';  h5String = '/exported_data';
h5Chans = 2;
h5Thresh = 0.6;
binarizeBool = 1; distinguishBool = 1;
scaleFacts = [1 1 1];

%% Iterate through directories, convert contents
for dirInd = 1:numel(dirNames)
    currDir = fullfile(baseDir,dirNames(dirInd).name);
    fileNames = dir(fullfile(currDir,h5Query));
    currSaveDir = sprintf(saveDirForm,currDir);
    if exist(currSaveDir) == 0
        mkdir(currSaveDir);
    end
    % Iterate through each file in the current directory; load, convert, save
    for fileInd = 1:numel(fileNames)
        [~,currFileName,fileExt] = fileparts(fileNames(fileInd).name);
        currSeg = loadH5(fullfile(currDir,[currFileName fileExt]),h5String,h5Chans);
        currTif = h5toTif(currSeg,scaleFacts,binarizeBool,h5Thresh,distinguishBool);
        save3DTiff(currTif, fullfile(currSaveDir,[currFileName '.tif']));
    end

end