function [minMat] = farmConsMinValsLayer(dataMat, dimension)
%FARMCONSMINVALSLAYER Constructs a matrix with all smallest non-zero values
% Inputs:
%   dataMat         Input numeric array.
%   dimension       Array dimension over which to reduce values.
% Outputs:
%   minMat          Smallest nonzero values along the selected dimension.

% Get locations of all non-zero indices in dataMat, as well as max value
logicMat = logical(dataMat);
hiVal = (max(dataMat(:)) + 2);

% Get minimum values along desired dimension by setting zero-values to hiVal
minMat = squeeze(min(dataMat + (1 - logicMat) * hiVal, [], dimension));
% Set high values back to zero
minMat = farmConsMatLnB(minMat, ~(minMat == hiVal));

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMCONSMINVALSLAYER Constructs a matrix with all smallest non-zero values
% stored in dataMat along a given dimension. If a given "row" along the
% desired dimension is all zeros, return 0 for that "row"
% Rémi Boros
