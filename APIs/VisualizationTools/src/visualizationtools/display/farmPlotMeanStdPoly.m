function [] = farmPlotMeanStdPoly(meanVals, stdVals, xVals, currColor, alphaVal, lineColor)
%FARMPLOTMEANSTDPOLY Plot means and a filled spread polygon.
% Inputs:
%   meanVals        Mean values to plot.
%   stdVals         Offsets used for the displayed spread around the means.
%   xVals           X samples corresponding to yVals.
%   currColor       Color of the filled spread polygon.
%   alphaVal        Transparency of the polygon fill.
%   lineColor       Optional mean-line color; defaults to currColor.
% Outputs:
%   None. Requested file or graphics side effects occur during the call.

if nargin == 5
    lineColor = currColor;
end

% Generate a polynomial for background standard deviation
[stdPolyX, stdPolyY] = farmGetPolyCoords(meanVals, stdVals, xVals);
nonanLogic = ~isnan(stdPolyY);
currPoly = polyshape(stdPolyX(nonanLogic), stdPolyY(nonanLogic));

% Plot
polyPlot = plot(currPoly);
hold on
polyPlot.FaceAlpha = alphaVal;
polyPlot.EdgeColor = 'none';
polyPlot.FaceColor = currColor;
plot(xVals, meanVals, 'Color', lineColor, 'LineWidth', 2, 'LineStyle', '--', 'Marker', 'none')

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMPLOTMEANSTDPOLY Sloppy bundle function to plot meanVals with a bounding
% polygon of +/- stdVals.
% 2025-02-13 Rémi Boros
%
% BEHAVIOR
% -------------------------------------------------------------------------
% Uses the current axes and enables hold. Calculations and graphics side
% effects are preserved by this formatting/documentation pass.
