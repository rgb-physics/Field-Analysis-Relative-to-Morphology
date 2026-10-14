function [meanLogXVals,meanLogYVals]=loglogBin(xVals,yVals,numBins)
%LOGLOGBIN Compatibility wrapper; canonical implementation is FieldAnalysis.
[meanLogXVals,meanLogYVals]=fieldanalysis.statistics.loglogBin(xVals,yVals,numBins);
end
