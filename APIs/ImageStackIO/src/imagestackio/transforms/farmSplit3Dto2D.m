function [outputArg1, outputArg2] = farmSplit3Dto2D(inputMat, saveNameForm, rangeVec)
%FARMSPLIT3DTO2D Write selected Z slices as separate 2D images.
% Inputs:
%   inputMat       3D array in YXZ order.
%   saveNameForm   Output path pattern, including extension and slice format.
%   rangeVec       Optional slice selections; defaults to all Z slices.
% Outputs:
%   None supported. The historical declared outputs are not assigned;
%   call this function without output arguments.
%
% See also farmWriteTiff

% 2023-11-13, Rémi Boros

% Define rangeVec if not passed
if nargin == 2
    rangeVec = 1:size(inputMat, 3);
end

% Make directory, if necessary
[fileDir, fileNameForm, fileExt] = fileparts(saveNameForm);
if exist(fileDir) == 0
    mkdir(fileDir);
end

% Save each selected Z slice using the slice index in its filename.
for index = rangeVec
    imwrite(inputMat(:, :, index), ...
        fullfile(fileDir, [sprintf(fileNameForm, index) fileExt]));
end


end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Creates the output folder if absent. Uses imwrite directly and can replace
% existing files; choose a fresh folder before calling. This differs from
% farmWriteTiff's default overwrite protection and is preserved here.
% No calibration metadata is propagated. Slices retain YX array orientation.
%
% EXAMPLE
% -------------------------------------------------------------------------
% outputFolder = tempname;
% farmSplit3Dto2D(uint16(ones(8, 10, 3)), ...
%     fullfile(outputFolder, 'slice%03i.tif'), [1 3]);
