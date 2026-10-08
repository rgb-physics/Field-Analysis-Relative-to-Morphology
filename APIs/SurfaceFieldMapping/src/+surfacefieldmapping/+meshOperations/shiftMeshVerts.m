%% Define data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 12, Exp 4';
fileName = 'T%i Object.ply';
outName = 'T%i Object Shifted.ply';
% outDir = '<redacted original absolute path>';
outDir = 'Session 12, Exp 4';

timeRange = [1 11 17 23 27];
firstCoMBool = 1;           % Use CoM from vertices in first .ply as all
flipBool = 1;
shiftDim = 3;
shiftVals = (0:4)*104;

%% Iterate through obj structures and save ply structures
for tInd = 1:numel(timeRange)
    
    % Load*
    currT = timeRange(tInd);
    currPly = read_ply_mod(fullfile(dataDir,sprintf(fileName,currT)));
    currVerts = currPly.v;
    if flipBool == 1
        newVerts = fliplr(currVerts);
    else
        newVerts = (currVerts);
    end
    newVerts(:,shiftDim) = newVerts(:,shiftDim) - shiftVals(tInd);
    % Rewrite ply objects
    plywrite(fullfile(outDir,sprintf(outName,currT)),currPly.f,newVerts);   


end

fclose all