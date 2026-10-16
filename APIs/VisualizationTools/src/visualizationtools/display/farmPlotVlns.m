function [allMeans, allMeds] = farmPlotVlns(xData, yData, xSuperBin, yBin, maxNorm)
%FARMPLOTVLNS Takes in two vectors (xData, yData) and two arguments for binning
% Inputs:
%   xData           X coordinates or samples used to position/group the plot.
%   yData           Y samples corresponding to xData.
%   xSuperBin       X histogram edges used to group violin plots.
%   yBin            Y histogram edges within each X group.
%   maxNorm         Scale for the plotted violin width.
% Outputs:
%   allMeans        Per-X-bin means.
%   allMeds         Per-X-bin medians.

% Bin xData to determine super-bins
[~, ~, superBins] = histcounts(xData, xSuperBin);
unqBins = unique(superBins(superBins > 0));

% Iterate over each unique superbin and plot a violing plot with the
% corresponding yData within the super bin
allMeans = unqBins;
allMeds = unqBins;
figure
hold on
for index = 1:numel(unqBins)

    % Sub-sample indices that belong in the current bin
    currBin = unqBins(index);
    binLogic = superBins == currBin;
    currX = mean(xData(binLogic));
    currY = yData(binLogic);

    % Plot each violin plot individually
    [allMeans(index), allMeds(index)] = farmManVlnPlot(currX, currY, yBin, maxNorm);

end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMPLOTVLNS Takes in two vectors (xData, yData) and two arguments for binning
% (xSuperBin, yBin). The function plots a series of violin plots at each point
% along the x-axis, one at each point x' determined by binning xData via
% xBin. Likewise, violin plot is constructed by binning the corresponding
% yData for the current super-bin (x) using yBin
% maxNorm scales the violing plots
% 2026-06-24 - Rémi Boros
