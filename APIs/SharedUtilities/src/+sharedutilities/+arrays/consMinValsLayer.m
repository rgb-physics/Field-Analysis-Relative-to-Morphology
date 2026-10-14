function [minMat] = consMinValsLayer(dataMat,dimension)
%CONSMINVALSLAYER Constructs a matrix with all smallest non-zero values
%stored in dataMat along a given dimension. If a given "row" along the
%desired dimension is all zeros, return 0 for that "row"
% Rémi Boros

% Get locations of all non-zero indices in dataMat, as well as max value
logicMat = logical(dataMat);
hiVal = (max(dataMat(:))+2);

% Get minimum values along desired dimension by setting zero-values to hiVal
minMat = squeeze(min(dataMat + (1-logicMat)*hiVal, [], dimension));
% Set high values back to zero
minMat = sharedutilities.arrays.consMatLnB(minMat, ~(minMat==hiVal));

end

