function [] = figSaves(figHandle,saveDir,saveName,fileExts,saveBool)
%FIGSAVES Takes in a figure handle (eg. gca) and saves it at the
%desired directory with the desired name in all file formats stored in
%fileExts. saveBool=true writes files; false prints a message without saving.

if saveBool == 1
    if iscell(fileExts)
        for index = 1:numel(fileExts)
            saveas(figHandle,fullfile(saveDir,saveName),fileExts{index});
        end
    else
        saveas(figHandle,fullfile(saveDir,saveName),fileExts);
    end
else
    fprintf('Figures not saved \n')
end


end

