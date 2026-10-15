function [] = farmPlotMeanStdPoly(meanVals,stdVals,xVals,currColor,alphaVal,lineColor)
%FARMPLOTMEANSTDPOLY Sloppy bundle function to plot meanVals with a bounding
%polygon of +/- stdVals.
% 2025-02-13 Rémi Boros

if nargin == 5
    lineColor = currColor;
end

% Generate a polynomial for background standard deviation
[stdPolyX,stdPolyY] = farmGetPolyCoords(meanVals,stdVals,xVals);
nonanLogic = ~isnan(stdPolyY);
currPoly = polyshape(stdPolyX(nonanLogic),stdPolyY(nonanLogic));

% Plot
polyPlot = plot(currPoly);
hold on
polyPlot.FaceAlpha = alphaVal;
polyPlot.EdgeColor = 'none';
polyPlot.FaceColor = currColor;
plot(xVals,meanVals,'Color',lineColor,'LineWidth',2,'LineStyle','--','Marker','none')

end

