function [splitSlice] = getCentralSlice(inputData)
%GETCENTRALSLICE Given a binarized input data set, this function returns
%the slice with the least material nearest the center of the sample.

sumZ = sum(inputData, [1 2]);
[~, sliceCands] = findpeaks(squeeze(-sumZ));
[~,splitSliceInd] = min( abs(round(size(inputData,3)/2) - sliceCands));
splitSlice = sliceCands(min(splitSliceInd));


end

