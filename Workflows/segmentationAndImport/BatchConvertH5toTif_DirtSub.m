%% This script takes in individual meshes saved in probability .h5 files
% and generates .ply files based on a given cutoff value

% FilePath = '<redacted original absolute path>';
FilePath = 'Session 25, Exp 5';
% DirtPath = '<redacted original absolute path>';
DirtPath = 'Session 25, Exp 5';
SaveDir = fullfile(FilePath, 'Prediction Weight Tiffs');

FileNameFormat = 'Time%0.6i_minBGSub_Probabilities.h5'; %The file name format
DirtName = 'Dirt Detection_Object Predictions.h5';
SaveNameFormat = 'Time%0.6i_SegWeights.tif';
fileRange = 2;
objChanNum = 1;
channelNum = 2; cutoffVal = .7;
xSpace = 1; ySpace = 1; zSpace = 1;

%% Save ply objects of generated isosurfaces
mkdir(SaveDir);
DirtData = squeeze(h5read(fullfile(DirtPath,DirtName),'/exported_data'))';
DirtData(DirtData~=objChanNum) = 0;
DirtData3D = extend2DTiffAlongZ(DirtData, 148, fullfile(DirtPath, "Trained Dirt Detection Stack.tif"));

%% Not finished

%%
for index = fileRange
   
    %Load data
    fprintf('Current object... %i\n',index)
    Data = h5read(fullfile(FilePath,sprintf(FileNameFormat,index)),'/exported_data');
    cData = permute(squeeze(Data(channelNum,:,:,:)),[2 1 3]);
    [xSize,ySize,zSize] = size(cData);
    cData = imresize3(cData, [xSpace*xSize, ySpace*ySize, zSpace*zSize]);
    cData = uint8(255*cData);

    %Save as tiff
    currSaveName = sprintf(SaveNameFormat, index);
    for zLayer = 1:size(cData,3)
        if zLayer == 1
            imwrite(cData(:,:,zLayer), fullfile(SaveDir, currSaveName));
        else
            imwrite(cData(:,:,zLayer), fullfile(SaveDir,currSaveName), 'WriteMode','append');
        end
    end

end


Data = h5read(fullfile(FilePath,sprintf(FileNameFormat,index)),'/exported_data');