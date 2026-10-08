%% Load in files with name format 1 and replace with name format 2
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 88, Exp 5';
dataName = 't%03i_illCorr8bit_560_E5.tif';
outDir = dataDir;
outName =  't%03i_illCorr8bit_560.tif';
selectTimes = 1:100;
% expNum = 5;

if ~exist(outDir,'dir')
    mkdir(outDir);
end

%% Iterate
for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);  
    currName = fullfile(dataDir,sprintf(dataName,currT));
    if isfile(currName)
        movefile(currName, fullfile(outDir, sprintf(outName,currT)));
    else 
        continue
    end

end
