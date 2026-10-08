% Iterate through cc objects over times, concatenate data into a single
% table. Generate a column of corresponding times, then save
% 2025-04-22

% dataDir = '<redacted original absolute path>';
dataDir = 'Session 88, Exp 4';
dataName = 'Filament Statistics %03i.mat';

ccField = 'rp3D';       rField = 'rAtCens';
selTimes = 1:70;

%% Iterate through all times, concatenate, then save
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    currCCs = load(fullfile(dataDir,sprintf(dataName,currT)),ccField).(ccField);
    currRs = load(fullfile(dataDir,sprintf(dataName,currT)),rField).(rField);

    currCCs.(rField) = currRs;
    currCCs.('Frame') = repmat(currT,numel(currRs),1);
    if tInd == 1
        superTable = currCCs;
        continue
    end
    superTable = [superTable; currCCs];
end
save(fullfile(dataDir,'Concatenated_3DFilsRs.mat'),'superTable');


