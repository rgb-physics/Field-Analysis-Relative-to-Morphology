%% Takes in multiple directories, each containing 2D tifs
% Returns a stitched collection of tifs, one from each directory
% Directory info
baseDir = '<yourBaseDirectory>';
subDirs = {'dir1','dir2','dir3'};           % Just the subfolders
fileNameForms = {'pos1_t%03i.tif','pos2_t%03i.tif','pos3_t%03i.tif'};
saveDir = '<directoryToSave>';              % Just the folder
saveName = 'nameform_t%04i.tif';
% Parameter info
timeRange = 1:100;
rowRange = [1 1 128];     % [start index spacing end index]
colRange = [1 1 127];
stackOrder = 1:numel(subDirs);

%% Iterate through time
% This is very coarse. All tifs are expected to be the same size
currStack = zeros(numel(rowRange(1):rowRange(2):rowRange(end)),...
    numel(colRange(1):colRange(2):colRange(end)),numel(subDirs));
if ~exist(saveDir,'dir')
    mkdir(fullfile(baseDir,saveDir));
end
% Iterate over time
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    % Load all tifs
    for dirInd = 1:numel(subDirs)
        currStack(:,:,dirInd) = tiffreadVolume(fullfile(baseDir,subDirs{dirInd},sprintf(fileNameForms{dirInd},currT)));
    end
    % Reshape tifs
    reshapedTifs = blockReshape2D(currStack(:,:,stackOrder),colRange(3));
    % Save tifs
    save3DTiff(reshapedTifs,fullfile(baseDir,saveDir,sprintf(saveName,currT)));
end


