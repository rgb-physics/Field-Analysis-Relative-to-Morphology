%% data info
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
saveDir = dataDir;
dataName = 'Time000003_SegWeights.tif';
saveNameFormat = 'Frame 2 2D Background avg Channel %i.tif';

%Output from object classification
h5ObjInfo = 'Exp 1 confocal time 40 rescaled cropped.h5';
gaussRad = 5;      %For generating mask data
chanNum = 2;

%% Load data
tiffData = tiffreadVolume(fullfile(dataDir,dataName));
objData = h5read(fullfile(dataDir,h5ObjInfo),'/table');
tiffData = tiffData(:,:,chanNum:2:end);

%% Generate contour mask
maskMat = zeros(size(tiffData));
objCenters = [objData.CenterOfTheObject_1,objData.CenterOfTheObject_0,objData.CenterOfTheObject_2]; %in pixels
imgDims = size(tiffData);           %In [rows, cols, depth]
maskSize = [imgDims(2:-1:1), imgDims(3)];    %For meshgrid
for currObj = 1:size(objCenters,1)

    maskMat = maskMat + generate3DGaussian(maskSize, objCenters(currObj,:), gaussRad,1);

end

%% Binarize as first guess
firstPass = imbinarize(maskMat);

%% Active contours
test = activecontour(tiffData, firstPass,200,'edge');