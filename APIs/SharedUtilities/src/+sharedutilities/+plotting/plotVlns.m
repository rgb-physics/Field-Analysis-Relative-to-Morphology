function [allMeans,allMeds] = plotVlns(xData, yData, xSuperBin, yBin, maxNorm)
%PLOTVLNS Takes in two vectors (xData, yData) and two arguments for binning
%(xSuperBin, yBin). The function plots a series of violin plots at each point
%along the x-axis, one at each point x' determined by binning xData via
%xBin. Likewise, violin plot is constructed by binning the corresponding
%yData for the current super-bin (x) using yBin
% maxNorm scales the violing plots
% 2026-06-24 - Rémi Boros

% Bin xData to determine super-bins
[~,~,superBins] = histcounts(xData,xSuperBin);
unqBins = unique(superBins(superBins > 0));

% Iterate over each unique superbin and plot a violing plot with the
% corresponding yData within the super bin
allMeans = unqBins; allMeds = unqBins;
figure
hold on
for index = 1:numel(unqBins)

    % Sub-sample indices that belong in the current bin
    currBin = unqBins(index);
    binLogic = superBins == currBin;
    currX = mean(xData(binLogic));
    currY = yData(binLogic);
    
    % Plot each violin plot individually
    [allMeans(index),allMeds(index)] = manVlnPlot(currX,currY,yBin,maxNorm);
    
end

end

