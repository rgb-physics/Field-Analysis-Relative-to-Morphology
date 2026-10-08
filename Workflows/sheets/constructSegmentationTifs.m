%% Data dir
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
dataName = 'Time000040_regionsStruct.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 25, Exp 5';
saveNameForm = 'segmentation%i.tif';

%% Load segmentation structure
currData = load(fullfile(dataDir,dataName));

%% Split into segmentation objects
allFields = fieldnames(currData.outputStruct);
for currField = 1:numel(allFields)
    currLogic = currData.outputStruct.(allFields{currField});
    currTif = uint16(consMatLnB(ones(size(currLogic)), currLogic));
    save3DTiff(currTif,fullfile(saveDir, sprintf(saveNameForm, currField)));
end