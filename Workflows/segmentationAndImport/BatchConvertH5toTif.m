%% This script takes in individual meshes saved in probability .h5 files
% and generates .ply files based on a given cutoff value
% ??? - 10/25/2023
% FilePath = '<redacted original absolute path>';
FilePath = 'Session 88, Exp 4';
% FilePath = 'Session 45, Exp 3';
% SaveDir = '<redacted original absolute path>';
SaveDir = 'Session 88, Exp 4';

% FileNameFormat = 'img_%09i_Default_000_Probabilities.h5'; %The file name format
FileNameFormat = 't%03i_illCorr8bit_560_Probabilities.h5'; %The file name format
% SaveNameFormat = 'Time%06i_Probabilities_chan%i.tif';
SaveNameFormat = 'Time%06i_3ChanSegs.tif';
fileRange = 1:70;
selChans = 1:3; 
% selChans = 2; 
binarizeBool = 1; 
smoothBool = 0;
distinguishBool = 1;
cutoffVal = .6;
domOrder = [1 2 3];
fillBool = 1;       fillChan = 2;
% cutoffVal = .6;
% xSpace = 2; ySpace = 2; zSpace = 2;         %Used if you want to rescale your stacks
% xSpace = .25; ySpace = .25; zSpace = 1;         %Used if you want to rescale your stacks
% xSpace = 1; ySpace = 1; zSpace = 1;         %Used if you want to rescale your stacks
% xSpace = 775/427; ySpace = 775/427; zSpace = 775/427;         %Used if you want to rescale your stacks
xSpace = 1; ySpace = 1; zSpace = 1;         %Used if you want to rescale your stacks

%% Generate .tifs from segmentations using parameters described above
mkdir(SaveDir);
for fileInd = 1:numel(fileRange)
    currfileNum = fileRange(fileInd);
    % Load data
    currName = fullfile(FilePath,sprintf(FileNameFormat,currfileNum));
    if isfile(currName)
        cData = loadH5(currName,'/exported_data',selChans);
        fprintf('Current object... %i\n',fileInd)
    else
        continue
    end
    % Instantiate save matrix
    [xSize,ySize,zSize,chanSize] = size(cData);
    if fileInd == 1
        newDims = round([xSpace*xSize, ySpace*ySize, zSpace*zSize]);
    end
    newData = zeros(newDims(1), newDims(2), newDims(3), numel(selChans));

    % Resize, if required
    if xSpace*ySpace*zSpace ~= 1
        cData = imresize3_4mat(cData,newDims);
    end
    
    % Calculate using three channel smooth, if requested
    if smoothBool == 1                                                                                                                      
        [newData(:,:,:,2),newData(:,:,:,1),newData(:,:,:,3)] = ...
            h5toSmooth3Chans(cData,domOrder,cutoffVal,3,1);
    end
    % Binarize each channel, if requested
    if binarizeBool == 1 && smoothBool == 0
        for chanInd = 1:numel(selChans)
            % Assign using "outInOn" order above
            newData(:,:,:,domOrder(chanInd)) = imbinarize(cData(:,:,:,chanInd), cutoffVal);
        end 
    end
    % Channel distinction
    if binarizeBool == 1 || smoothBool == 1
        [maxMat,indMat] = max(newData,[],4);
        if distinguishBool == 1
            newData = indMat.*consMatLnB(maxMat, ~(maxMat == 0));
        else
            newData = ~maxMat == 0;
        end
    % If not binarizing
    else
        newData = sum(cData, 4);
    end

    %Rescale to 8bit
    newData = uint8(255*newData/max(domOrder));

    % Fill zeros, if requested
    if fillBool == 1
        unqVals = unique(newData(:));
        newData(newData == 0) = unqVals(1+fillChan);
    end
    %Save as tiff
    % currSaveName = sprintf(SaveNameFormat, index,selChans);
    currSaveName = sprintf(SaveNameFormat, currfileNum);
    savePath = fullfile(SaveDir, currSaveName);
    save3DTiff(newData,savePath);

end


