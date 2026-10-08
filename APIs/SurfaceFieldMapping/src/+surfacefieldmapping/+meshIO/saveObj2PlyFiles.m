%% Define data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 12, Exp 4';
fileName = 'T%i Object.obj';
outName = 'T%i Object.ply';
% outDir = '<redacted original absolute path>';
outDir = 'Session 12, Exp 4';

timeRange = [1 11 17 23 27];

%% Iterate through obj structures and save ply structures
for tInd = 1:numel(timeRange)
    
    currT = timeRange(tInd);
     currObj = read_obj_mod(fullfile(dataDir, sprintf(fileName,currT)));

     obj2ply(currObj, 1, outDir, sprintf(outName,currT));

end

fclose all