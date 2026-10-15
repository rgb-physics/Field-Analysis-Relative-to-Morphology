function [progressObj] = farmProgressBar(currInd,totalInds,progressObj,updatePrct)
%FARMPROGRESSBAR Generates a waitbar object to show progress on a loop. The
%waitbar object is instantiated for currInd = 1, the first iteration, and
%is closed on the final iteration. updatePrct is a number corresponding to
%the percentage of iterations over which the waitbar should be updated.
% Rémi Boros, 2024-04-30

% Instantiate edge cases
if nargin == 3
    updatePrct = 5;
end
if numel(totalInds) > 1
    totalInds = numel(totalInds);
end
updateBreaks = 0:updatePrct:100;
% Calculate precent done from current index and total indices
prctDone = round(100*currInd/totalInds);
% Display percent done and clean up
if currInd == 1
    close(progressObj);
    progressObj = waitbar(0,progressObj,'Starting up...');
elseif currInd == totalInds
    close(progressObj)
    progressObj = '';
else
    updateIdx = find(updateBreaks<prctDone, 1,'last');
    currPrctBreak = updateBreaks(updateIdx);
    waitbar(currPrctBreak/100,progressObj,sprintf('Finished %02d%%...',currPrctBreak));
end
end

