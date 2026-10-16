function [] = farmFigSaves(figHandle, saveDir, saveName, fileExts, saveBool)
%FARMFIGSAVES Takes in a figure handle (eg. gca) and saves it at the
% Inputs:
%   figHandle       Graphics handle accepted by the selected export operation.
%   saveDir         Destination folder for exported figures.
%   saveName        Output name used when saving.
%   fileExts        Requested figure export extensions.
%   saveBool        Selector controlling whether results are written.
% Outputs:
%   None. Requested file or graphics side effects occur during the call.

if saveBool == 1
    if iscell(fileExts)
        for index = 1:numel(fileExts)
            saveas(figHandle, fullfile(saveDir, saveName), fileExts{index});
        end
    else
        saveas(figHandle, fullfile(saveDir, saveName), fileExts);
    end
else
    fprintf('Figures not saved \n')
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMFIGSAVES Takes in a figure handle (eg. gca) and saves it at the
% desired directory with the desired name in all file formats stored in
% fileExts. saveBool=true writes files; false prints a message without saving.
%
% BEHAVIOR
% -------------------------------------------------------------------------
% This operation can write files. Review saveDir, saveName, fileExts and
% saveBool before calling; existing export behavior is preserved.
