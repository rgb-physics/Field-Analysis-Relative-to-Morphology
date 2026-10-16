function [superTable] = farmConcatTablesOverT(dataDir, dataName, selTimes, storeVar, saveBool, saveName)
%FARMCONCATTABLESOVERT Load and concatenate historical per-time tables.
% Inputs:
%   dataDir         Folder containing source files.
%   dataName        Filename or filename pattern used by this operation.
%   selTimes        Selected time/frame values used in source filenames.
%   storeVar        Name of the stored variable to load.
%   saveBool        Selector controlling whether results are written.
%   saveName        Output name used when saving.
% Outputs:
%   superTable      Concatenated historical per-time tables.

if nargin == 4
    saveBool = 0;
end

% Iterate through all times, concatenate, then save
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    currVar = load(fullfile(dataDir, sprintf(dataName, currT)), storeVar).(storeVar);
    if ~isa(currVar, 'table')
        currVar = array2table(currVar, 'VariableNames', {storeVar});
    end

    currVar.('Frame') = repmat(currT, size(currVar, 1), 1);
    if tInd == 1
        superTable = currVar;
        continue
    end
    superTable = [superTable; currVar];
end
if saveBool == 1
    save(fullfile(dataDir, saveName), 'superTable');
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMCONCATTABLESOVERT % Iterate through cc objects over times, concatenate
% data into a single table. Generate a column of corresponding times,
% then save
% 2025-04-22 - Rémi Boros
