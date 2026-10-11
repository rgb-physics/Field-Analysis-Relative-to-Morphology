%% This script takes in .h5 files and applies active contouring to generate
%a point cloud illustrating the interface between channels
% h5Dir = '<redacted original absolute path>';
h5Dir = 'Session 25, Exp 5';
h5NameForm = 'Time%06i_acOpt_Probabilities Stage 2.h5';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 25, Exp 5';
imgFile = 'Time000001_acOpt.tif';
selectTimes = 1;
chanSel = 2;            %Pick channel such that MTs are prob 1 and bg prob 0
cutOffValStart = 100/255;
cutOffVal2 = cutOffValStart;
cutPerimeter = 0;
perWidth = 4;

%% Load File
currData = h5read(fullfile(h5Dir,sprintf(h5NameForm,selectTimes(1))),'/exported_data');
%Load data set 1
selectData = permute(squeeze(currData(chanSel,cutPerimeter+1:end-cutPerimeter,cutPerimeter+1:end-cutPerimeter,:)),[2 1 3]);
%Binarize segmentation weights
BWDATA = imbinarize(selectData,cutOffValStart);
BWDATA = BWDATA(:,:,:);
%Load data set 2
flipData = 1-BWDATA;

%% Identify top and bottom layers
[topLayer,botLayer,topLayerZs,botLayerZs,centerSlice,centerSliceZs] = returnTopBottom2DSheets(BWDATA);
[xMat,yMat,zMat] = ndgrid(1:size(topLayer,1), 1:size(topLayer,2), 1:size(topLayer,3));
splitSlice = getCentralSlice(BWDATA);

%% Patch truncated portions
%Get intensity values in surface detected in step above
patchedZTop = selectData;
patchedZTop(~topLayer) = 0;
%Find holes in the detected sheet by finding max Z value for each (x,y)
topInside = max(topLayerZs,[],3);
%Patch holes and return Z value nearest sample center for each (x,y) that's
%a part of the thresholded surface/layer
[newSurfInds, holeIndVec] = returnCorrectedBinarizedSurfaceIndices(topInside, size(BWDATA));
if sum(holeIndVec) > 0
    [ogX, ogY, ogZ] = ind2sub(size(BWDATA), newSurfInds(~holeIndVec));
    [patchX, patchY, patchZ] = ind2sub(size(BWDATA), newSurfInds(holeIndVec));
    %Use a scattered interpolant object to fill holes in our surface
    holeFiller = scatteredInterpolant(ogX,ogY,ogZ,double(selectData(newSurfInds(~holeIndVec))));
    intVals = holeFiller(patchX, patchY, patchZ);
    patchedZTop(newSurfInds(holeIndVec)) = abs(intVals);
end
patchedZTopInds = logical(patchedZTop);

%Get intensity values in surface detected in step above
patchedZBot = selectData;
patchedZBot(~botLayer) = 0;
%Artifically set all zero-vals to value larger than largest Z to identify non-zero minimum values in regions without holes
minBotInside = botLayerZs; minBotInside(minBotInside == 0) = max(zMat(:))+2;
%Set max values (holes) to zero again to indicate holes
botInside = min(minBotInside,[],3); botInside(botInside == max(zMat(:))+2) = 0;
%Find holes in the detected sheet by finding min Z value for each (x,y)
[newSurfInds, holeIndVec] = returnCorrectedBinarizedSurfaceIndices(botInside, size(BWDATA));
if sum(holeIndVec) > 0
    [ogX, ogY, ogZ] = ind2sub(size(BWDATA), newSurfInds(~holeIndVec));
    [patchX, patchY, patchZ] = ind2sub(size(BWDATA), newSurfInds(holeIndVec));
    holeFiller = scatteredInterpolant(ogX,ogY,ogZ,double(selectData(newSurfInds(~holeIndVec))));
    intVals = holeFiller(patchX, patchY, patchZ);
    patchedZBot(newSurfInds(holeIndVec)) = abs(intVals);
end
patchedZBotInds = logical(patchedZBot);

%% Scale intensity in each layer
%Define top of image
topImg = zeros(size(selectData));
topImg(:,:,1:splitSlice) = selectData(:,:,1:splitSlice);
%Store values of image found only in "patched" surface to use for scaling
patchedSurfData = topImg;   patchedSurfData(~patchedZTopInds) = 0;
%Scale data for each x,y by max value in reconstructed z surface
intCorrTop = topImg./max(patchedSurfData,[],3);
% intCorrTopThresh = double(imbinarize(test1,cutOffValStart));

%Define top of image
botImg = zeros(size(selectData));
botImg(:,:,splitSlice+1:end) = selectData(:,:,splitSlice+1:end);
%Store values of image found only in "patched" surface to use for scaling
patchedSurfData = botImg;   patchedSurfData(~patchedZBotInds) = 0;
%Scale data for each x,y by max value in reconstructed z surface
intCorrBot = botImg./max(patchedSurfData,[],3);
% intCorrTopThresh = double(imbinarize(test1,cutOffValStart));

%% Combine image halves
analyzeImg = intCorrTop + intCorrBot;

%% Calculate median and mean binarized images
medianCutOff = median(analyzeImg(analyzeImg > 0));
threshMedianMat = imbinarize(analyzeImg,medianCutOff*1.5);
threshAnImg = analyzeImg;
threshAnImg(threshMedianMat) = 0;

meanCutOff = mean(analyzeImg(analyzeImg > 0));
threshMeanMat = imbinarize(analyzeImg,meanCutOff);
threshAnImgMean = analyzeImg;
threshAnImgMean(~threshMeanMat) = 0;

%% Pick desired method
threshImg = threshAnImgMean; 
threshImgInds = threshMeanMat;

%% Stitch half components
threshImgTopInds = threshImgInds; threshImgBotInds = threshImgInds;
threshImgTopInds(:,:,splitSlice+1:end) = 0;
threshImgBotInds(:,:,1:splitSlice) = 0;

topObjs = bwconncomp(threshImgTopInds); botObjs = bwconncomp(threshImgBotInds);

topProps = regionprops3(topObjs, "Volume");
topSmallInds = find(topProps.Volume < max(topProps.Volume));
topSmallObjs = [topObjs.PixelIdxList(topSmallInds)];
%Convert cell array of small obj pixels to single vector -> add pixels to
%bot layer. Then region props to remove objs that are not connected
topSmallPixInds = cell2mat(topSmallObjs');
threshImgBotIndsComb = threshImgBotInds;
threshImgBotIndsComb(topSmallPixInds) = 1;
newBotObjs = bwconncomp(threshImgBotIndsComb);
newBotProps = regionprops3(newBotObjs, "Volume");
[~,sizeInds] = sort([newBotProps.Volume]);
stitchedBotImg = false(size(threshImgBotInds)); 
stitchedBotImg(cell2mat(newBotObjs.PixelIdxList(sizeInds(end)))) = true;

botProps = regionprops3(botObjs, "Volume");
botSmallInds = find(botProps.Volume < max(botProps.Volume));
botSmallObjs = [botObjs.PixelIdxList(botSmallInds)];
%Convert cell array of small obj pixels to single vector -> add pixels to
%bot layer. Then region props to remove objs that are not connected
botSmallPixInds = cell2mat(botSmallObjs');
threshImgBotIndsComb = threshImgTopInds;
threshImgBotIndsComb(botSmallPixInds) = 1;
newTopObjs = bwconncomp(threshImgBotIndsComb);
newTopProps = regionprops3(newTopObjs, "Volume");
[~,sizeInds] = sort([newTopProps.Volume]);
stitchedTopImg = false(size(threshImgBotInds)); 
stitchedTopImg(cell2mat(newTopObjs.PixelIdxList(sizeInds(end)))) = true;

%% Get intensity matrices on stitched surfaces
fullThreshProbs = threshImg;
fullThreshProbs(~(stitchedTopImg + stitchedBotImg)) = 0;


%% 
threshImgTop = threshImg; threshImgBot = threshImg;

%% Remove small objects
objComps = bwconncomp(threshImg);
objProps = regionprops3(objComps, "Volume");
objSizes = [objProps.Volume];
[sortedSizes, sortedInds] = sort(objSizes);
validObjs = sortedInds(sortedSizes>max(sortedSizes)/5);

threshImgCut = zeros(size(threshImg));
validInds = cell2mat([objComps(1).PixelIdxList(validObjs)']);
threshImgCut(validInds) = analyzeImg(validInds);

%% Active contour to find interior volume
firstGuess = zeros(size(analyzeImg)); firstGuess(:,:,splitSlice) = 1;
insideCont = activecontour(threshImgCut, logical(firstGuess), 500);

%%
interfacePts = imdilate(insideCont, strel("sphere",1)) - insideCont;

%%
[xCoords,yCoords,zCoords] = ind2sub(size(interfacePts), find(interfacePts == 1));
ptCloud = pointCloud([xCoords, yCoords, zCoords]);
%%
% testMedian = activecontour(threshAnImg, testMedian, 150);
% 
%% Active contour of boundaries
erodeObj = strel("sphere",6);
firstGuess = imdilate(insideCont, erodeObj) - insideCont;
surfacesCont = activecontour(threshImgCut, logical(firstGuess), 300);

%%
testMedian = imerode(test,erodeObj);
erodeObj = strel("sphere",6);

%% Load image
currTif = tiffreadVolume(fullfile(imgDir,imgFile));





%% Get approximate boundaries of each layer
topBounds = false(size(BWDATA));
% Find inside of top layer
topInside = max(topLayerZs,[],3);
newSurfInds = returnCorrectedBinarizedSurfaceIndices(topInside, size(BWDATA));
topBounds(newSurfInds(:)) = true;
% Find outside of top layer
tempTop = topLayerZs;  tempTop(tempTop == 0) = max(zMat(:));
topOutside = min(tempTop,[],3);
newSurfInds = returnCorrectedBinarizedSurfaceIndices(topOutside, size(BWDATA));
topBounds(newSurfInds) = true;

%% Fill holes %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Top layer looks for zMat_max, bottom layer looks for zeros. For each body
% of connected pixels, define a perimeter of some radius, then query min z
% (for bottom layer) or max z (for top layer). Use the queried z values
% around these perimeters to generate scattered interpolant objects and
% fill in regions within queried perimeters using linear interpolation.
topMaxMat = max(topLayerZs,[],3);
topHoles = topMaxMat == 0;
botLayerZs(botLayerZs == 0) = max(zMat(:));
botMinMat =  min(botLayerZs,[],3);
botHoles = botMinMat == max(zMat(:));

%% Get hole properties
topProps = regionprops(topHoles);
botProps = regionprops(botHoles);

%% Generate perimeters and areas
topHolePerims = true(size(topHoles));
botHolePerims = topHolePerims;
topHoleAreas = topHolePerims;
botHoleAreas = topHolePerims;

%Generate size matrix
sizeMat = [size(topHolePerims,1) size(topHolePerims,2)];
% Generate top layer points for interpolating
for currHole = 1:numel(topProps)

    [currPerim, currArea] = generatePerimeterArea_BoundingBox(topProps(currHole).BoundingBox, sizeMat, perWidth);
    topHolePerims = topHolePerims | currPerim;
    topHoleAreas = topHoleAreas | currArea;

end
% Correct any areas overlapped by perimeters
topHolePerims(topHoleAreas) = 0;

% Generate bottom layer points for interpolating
for currHole = 1:numel(botProps)

    [currPerim, currArea] = generatePerimeterArea_BoundingBox(botProps(currHole).BoundingBox, sizeMat, perWidth);
    botHolePerims = botHolePerims | currPerim;
    botHoleAreas = botHoleAreas | currArea;

end
% Correct any areas overlapped by perimeters
botHolePerims(botHoleAreas) = 0;

%% Generate scattered interpolant objects
[x,y] = ind2sub(sizeMat, find(topHolePerims==1));
topPerZVals = topMaxMat(topHolePerims==1);
topScIntObj = scatteredInterpolant(x,y,topPerZVals);
[x,y] = ind2sub(sizeMat, find(topHoleAreas == 1));
newTopZVals = round(topScIntObj(x,y));
patchedTop = topLayer;
% patchedTop(x,y,size(patchedTop,3)-newTopZVals) = 1;
patchedTop(x,y,newTopZVals) = 1;
patchedTop(x,y,newTopZVals-20:newTopZVals+20) = 1;

% patchedTop(x,y,max(newTopZVals+1, size(patchedTop,3))) = 1;
% patchedTop(x,y,min(newTopZVals+1, 1)) = 1;

[x,y] = ind2sub(sizeMat, find(botHolePerims==1));
botPerZVals = botMinMat(botHolePerims==1);
botScIntObj = scatteredInterpolant(x,y,botPerZVals);
[x,y] = ind2sub(sizeMat, find(botHoleAreas == 1));
newBotZVals = round(botScIntObj(x,y));
patchedBot = botLayer;
patchedBot(x,y,newBotZVals) = 1;
% patchedBot(x,y,max(newBotZVals+1, size(patchedBot,3))) = 1;
% patchedpatchedBotTop(x,y,min(newBotZVals+1, 1)) = 1;

%% Make matrix of z coords
% [~,~,zMat] = ndgrid(1:size(cutData,1), 1:size(cutData,2), 1:size(cutData,3));
% oneInds = (layer1 == 1);
% zMat(~oneInds) = 0;
% avgLayer = sum(zMat,3)./sum(oneInds,3);
% 
% %% 
% 
% %% Top Guess
% [~, layerSliceCands] = findpeaks(squeeze(sumZ));
% [~,topSplitSliceInd] = min( (round(size(selectData,3)/2) - layerSliceCands));
% [~,botSplitSliceInd] = max( (round(size(selectData,3)/2) - layerSliceCands));
% topGuess = zeros(size(BWDATA));
% botGuess = zeros(size(BWDATA));
% topGuess(:,:,topSplitSliceInd) = 1;
% botGuess(:,:,botSplitSliceInd) = 1;
% 
% %% Contouring
% topCont = activecontour(double(cutData),topGuess,80);
% botCont = activecontour(double(cutData),botGuess,80);

