function [meanLogXVals,meanLogYVals] = loglogBin(xVals,yVals,numBins)
%LOGLOGBIN Takes in a 1D data set yVals defined for some input range xVals 
%and bins these on a log scale over numBins bins. The function returns these
%spaced as linearly as possible on a log-log scale.

%Define x-values on log scale
logXVals = log(xVals);
%Bin log(x-values) using histcounts to determine spacing 
[~,logEdges,binInds] = histcounts(logXVals, numBins);
%Instantiate storage vectors
meanLogXVals = zeros(1,(numel(logEdges)-1));
meanLogYVals = meanLogXVals;

%Iterate over each bin and calculate approximate y-value
for currBin = 1:max(binInds)
    meanLogXVals(currBin) = mean(logXVals(binInds == currBin));
    meanLogYVals(currBin) = mean(log(yVals(binInds == currBin)));
end

%Remove NaNs
meanLogXVals = meanLogXVals(~isnan(meanLogXVals));
meanLogYVals = meanLogYVals(~isnan(meanLogYVals));

end

