function [outputArg1,outputArg2] = farmSplit3Dto2D(inputMat,saveNameForm,rangeVec)
%FARMSPLIT3DTO2D Takes in a 3D array and saves 2D slices of said array along
%3rd dimension in the location stored in saveNameForm. saveNameForm is
%expected to be of the form 'directory/saveName' with some a variable to
%iterate over corresponding to the number of slices to be saved. rangeVec
%is an optional vector that determines which slices to save
% 2023-11-13, Rémi Boros

% Define rangeVec if not passed
if nargin == 2
    rangeVec = 1:size(inputMat,3);
end
% Make directory, if necessary
[fileDir, fileNameForm, fileExt] = fileparts(saveNameForm);
if exist(fileDir) == 0
    mkdir(fileDir);
end
% Loop over slices and save
for index = rangeVec
    imwrite(inputMat(:,:,index),...
        fullfile(fileDir,[sprintf(fileNameForm,index) fileExt]));
end

end

