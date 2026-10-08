% Load images, find CoMs from intensity, define indices of line passing
% through CoM for arbitrary angle
% 2024-01-06
%% Set parameters
% Data info
% dataDir = '<redacted original absolute path>';
dataDir = '';
nameInts = 'TimeStack_Fl_Ints.tif';
nameSHGs = 'TimeStack_SHG.tif';
% saveDir = '<redacted original absolute path>';
saveDir = '';
saveName = 'radialPolProfiles.mat';
% polDir = '<redacted original absolute path>';
polDir = '';
polName = 'polarizationData_T52Sample_HiPol1p0_LOCenterSHG.mat';

% Z slice info
selZ = 5;
zScale = 6;
numSlices = 5;
pixSize = .21;      % um/pix
timeScale = 50;     % seconds per frame
% Approximate steady state background density
bgFrac = 0.6;
% Line length over which to average
lineLen = 250;      %pixels
numRots = 25;
% Gauss smooth?
gKern = 1;  gKern2 = 1;
% Reflect or go through CoM?
reflBool = 1;
saveBool = 1;

%% Load data
intData = tiffreadVolume(fullfile(dataDir,nameInts),'PixelRegion',{[1 1 inf], [1 1 inf], [selZ numSlices numSlices*75]});
shgData = tiffreadVolume(fullfile(dataDir,nameSHGs),'PixelRegion',{[1 1 inf], [1 1 inf], [selZ numSlices numSlices*75]});
polData = load(fullfile(polDir,polName));
polMat = polData.polMat;
polMat = imgaussfilt(polMat,gKern2);
intData = double(intData);  shgData = double(shgData);
imgDims = size(intData);
midPoint = round(imgDims(1:2)/2);

%% Get total ints over time
sumInts = (sum(sum(intData,2),1));
avgInts = sumInts/prod(imgDims(1:2));

%% Smooth
if gKern > 0
    ogInts = intData;
    intData = imgaussfilt(intData,gKern);
end

%% Shift by mean intensity
shiftInts = max(0,intData - avgInts(1)*bgFrac);
% shiftInts = max(0,intData - avgInts);

%% Find center of mass of each slice
[yMat,xMat] = ndgrid(1:imgDims(1),1:imgDims(2));
xInts = shiftInts.*xMat;
yInts = shiftInts.*yMat;

xComs = (squeeze(sum(yInts,1)./sum(shiftInts,1)));
yComs = (squeeze(sum(xInts,2)./sum(shiftInts,2)));
yComs = noNan(yComs);   xComs = noNan(xComs);
xCom = round(nonZeroMean(xComs,1))';
yCom = round(nonZeroMean(yComs,1))';
CoMs = [yCom, xCom];

%% Generate lines along which to average
% Generate original vector along x-axis
baseVecsX = round(((-lineLen/2):(lineLen/2)))';
baseVecsY = zeros(numel(baseVecsX),1);

% Instantiate storage matrix for all unique rotated points
rotPtsMat = nan(numel(baseVecsX),2,numRots);
ptIndicesMat = nan(numel(baseVecsX),1,numRots);
% Rotate vase vector using quaternions
for rotNum = 1:numRots
    rotAmt = rotNum*180/numRots;
    currQuat = quaternion([0,0,rotAmt],'eulerd','XYZ','point');
    currPts = rotatepoint(currQuat,[baseVecsX,baseVecsY,zeros(size(baseVecsY))]);
    % Store only unique pairs after rounding
    [unqPairs,unqRowInds] = unique(round(currPts),'rows');
    numUPairs = size(unqPairs,1);
    rotPtsMat(1:numUPairs,1:2,rotNum) = unqPairs(:,1:2);
    ptIndicesMat(1:numUPairs,1,rotNum) = unqRowInds;
    % Store the starts and ends
    lineStarts(rotNum,:) = rotPtsMat(1,:,rotNum);
    lineEnds(rotNum,:) = rotPtsMat(numUPairs,:,rotNum);
end

%% For each slice, sample field along line
histVals = 1:2:250;
trueHistVals = 1:2:125;
dataStore = struct();

for sliceInd = 1:imgDims(3)
    % Load slice
    polSlice = polMat(:,:,sliceInd);
    intSlice = shiftInts(:,:,sliceInd);
    % currSlice = currField(:,:,sliceInd);
    % Shift rotations to current CoM
    currRotPts = rotPtsMat + [yCom(sliceInd),xCom(sliceInd)];

    % Reshape to make matrix of valid indices
    currSubs = reshape(permute(currRotPts,[1 3 2]),[numel(currRotPts)/2, 2]);
    indsInLine = ptIndicesMat(:);
    lineIDVec = genLenVec(1:numRots,repmat(size(currRotPts,1),numRots,1));

% Logic for valid unique indices in each line
    % non-nan coordinates
    nonNanRows = logical(sum(~isnan(currSubs),2));
   % Remove points outside of image boundaries
    outBnds = logical(sum((currSubs > min(imgDims(1:2))) | (currSubs < 1),2));
    % Combine the logic
    validLogic = logical(nonNanRows - outBnds);
    
    % Collect all valid points and their line indices
    validSubs = currSubs(validLogic,:);
    validLineInds = indsInLine(validLogic);
    % Convert to matrix indices to sample slice
    validInds = sub2ind(imgDims(1:2),validSubs(:,2),validSubs(:,1));

    % Find line end points and bound them in the image
    % Indices of first and last valid points in each line
    validLineIDs = lineIDVec(validLogic);
    [~,firstOccs] = unique(validLineIDs);
    [~,lastOccs] = unique(validLineIDs,'last');
    validStarts = validSubs(firstOccs,:);
    validEnds = validSubs(lastOccs,:);
    boundingXs = [validStarts(:,2), validEnds(:,2)];
    boundingYs = [validStarts(:,1), validEnds(:,1)];

    % Subsample data, then store in dataStore
    dataStore(sliceInd).LineIndices = validLineInds;
    dataStore(sliceInd).PolVals = polSlice(validInds);
    dataStore(sliceInd).IntVals = intSlice(validInds);
    dataStore(sliceInd).SampledInds = (validInds);
    dataStore(sliceInd).CoM_XY = CoMs(sliceInd,:);
    dataStore(sliceInd).LineBndX = boundingXs;
    dataStore(sliceInd).LineBndY = boundingYs;

end

%% Save data structure
if saveBool == 1
    save(fullfile(saveDir,saveName),'dataStore','numRots');
end

%% Display each profile over time

% selSlices = 60:2:75;
selSlices = [1 20 30 37 50 65];

xDisp = [0 240]*pixSize;
if reflBool == 1
    xDisp(2) = xDisp(2)/2;
else
    xDisp = xDisp-xDisp(2)/2;
end

% MT Density %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1)
clf
currField = intData(:,:,1:75);
yDisp = [0 60];
% colorVec = [10 10 40; 180 180 240]/255;
% timeColorArray = flipud(min(1,othercolor('Cat_12',numel(selSlices)+3)));
timeColorArray = flipud(min(1,othercolor('Cat_12',numel(selSlices)+7)));
% timeColorArray = flipud(min(1,othercolor('Greys5',numel(selSlices)+3)+[0 0 .1]));
xTitle = '\Deltar (um)';
yTitle = 'I_{MT}';
fieldStr = 'IntVals';

% SHG Signal %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure(2)
% clf
% currField = polMat(:,:,1:75);
% yDisp = [-0.1 1];
% % colorVec = [55 5 32 ;  255 75 92]/255;     % black red
% % timeColorArray = flipud(othercolor('Reds7',numel(selSlices)+3));
% timeColorArray = flipud(min(1,othercolor('Cat_12',numel(selSlices)+7)));
% xTitle = '\Deltar (um)';
% yTitle = 'Polarity';
% fieldStr = 'PolVals';

% colorVec = [5 32 155; 75 192 255 ]/255;     % Bez blue [ 55 132 255]

legLabels = cell(1,1);
for index = 1:numel(selSlices)
% for sliceInd = 1:2:imgDims(3)

% Load current data
    sliceInd = selSlices(index);
    currSlice = currField(:,:,sliceInd);
    currCoM = dataStore(sliceInd).CoM_XY;
    % currSlice(dataStore(sliceInd).SampledInds) = 0;
    currData = dataStore(sliceInd).(fieldStr);
    lineInds = dataStore(sliceInd).LineIndices;
    
    % Choose a representation
    if reflBool == 1
        % Make a representation of line indices symmetric about CoM
        mapVecSym = ifftshift(genReflVec(max(lineInds)));
        symLineInds = (mapVecSym(lineInds))';
        indices = symLineInds;
    else
        indices = lineInds;
        trueHistVals = (histVals);
    end

    % Bin along lines as a function of distance from CoM
    [~,binEdgesKey,binInds] = histcounts(indices,trueHistVals);

    meanVals = 1:numel(unique(binEdgesKey));    stdVals = meanVals;
    for index2 = 1:numel(unique(binEdgesKey))
        currInds = binInds == index2;
        meanVals(index2) = mean(currData(currInds));
        % stdVals(index) = std(currData(currInds));
        stdVals(index2) = std(currData(currInds))/sqrt(sum(currInds));
    end
    % Set bin values as x-axis values
    if reflBool == 1
        xVals = binEdgesKey*pixSize;
    else
        xVals = (binEdgesKey - 125)*pixSize;
    end
    
    % Generate a polynomial for background standard deviation
    stdPolyX = [xVals, fliplr(xVals)];
    stdPolyY = [meanVals - stdVals, fliplr(meanVals + stdVals)];
    nonanLogic = ~isnan(stdPolyY);
    stdPolyX = stdPolyX(nonanLogic);
    stdPolyY = stdPolyY(nonanLogic);
    currPoly = polyshape(stdPolyX,stdPolyY);


    % % Overlay CoM and Lines over Data
    % imagesc(currSlice)
    % axis equal
    % clim([0 60])
    % hold on
    % bwCMap = colormap('gray');
    % plot((dataStore(sliceInd).LineBndY)', (dataStore(sliceInd).LineBndX)','red')
    % % lineEnds;lineStarts
    % colormap(flipud(bwCMap));
    % scatter(currCoM(1),currCoM(2),'white','filled')
    % hold off
    % ginput();

    % Plot profiles
    currColor = timeColorArray(index,:);
    polyPlot = plot(currPoly);
    hold on
    polyPlot.FaceAlpha = 0.40;
    polyPlot.EdgeColor = 'none';
    polyPlot.FaceColor = currColor;
    plot(xVals,meanVals,'Color',currColor,'LineWidth',2,'LineStyle','--')
    % plot(xVals,meanVals,'Color',currColor,'LineWidth',2)
    xlabel(xTitle)
    ylabel(yTitle)
    xlim(xDisp)
    ylim(yDisp)
    box on
    set(gca,'FontSize',15)
    
    pause(.2)
    
    % Generate a legend
    currT = seconds(sliceInd*timeScale);
    currT.Format = 'hh:mm:ss';
    legLabels{2*index} = sprintf('%s',string(currT));
    legLabels{2*index-1} = '';
end

legend(legLabels)


