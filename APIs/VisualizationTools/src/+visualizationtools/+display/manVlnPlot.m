function [meanVal,medVal] = manVlnPlot(xData,yDataSet,yBins,maxNorm)
%MANVLNPLOT Manually make violin plots since I'm using an old version of
%MATLAB. Makes violin plot along y, half
% 2025-07-29 - Rémi Boros

% hist counts
[binCnts, binEdges] = histcounts(yDataSet,yBins);
% Shift coordinates to xData position
xShft = xData - min(xData);
X = (binCnts + xShft)/max((binCnts + xShft))*maxNorm;
% Find bounding zeros
startInd = find(X>0,1); lastInd = numel(X) - find(fliplr(X)>0,1) + 1;
X = X(startInd:lastInd);
Y = binEdges(startInd:lastInd);

% Prepare polygons
tempVec = sharedutilities.coordinates.genReflVec(2*numel(X));
totX = X(tempVec);
totX(1:numel(X)) = -totX(1:numel(X));
tempVec = sharedutilities.coordinates.genReflVec(2*numel(Y));
totY = Y(tempVec);
fill(totX + xData,totY,'red')

hold on
meanVal = mean(yDataSet);
medVal = median(yDataSet);
scatter(xData,meanVal,10,'black','filled')
scatter(xData,medVal,10,[1 .8 .2],'filled')
end

