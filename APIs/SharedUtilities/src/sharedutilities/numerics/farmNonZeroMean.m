function [outMat] = farmNonZeroMean(inMat, selDim)
%FARMNONZEROMEAN Takes in a matrix and dimension, calculates the mean along
% Inputs:
%   inMat           Input numeric array.
%   selDim          Array dimension over which to calculate the nonzero mean.
% Outputs:
%   outMat          Mean along selDim, excluding zero-valued samples.

sumMat = (sum(inMat, selDim));
countsMat = sum(logical(inMat), selDim);
outMat = sumMat ./ countsMat;

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMNONZEROMEAN Takes in a matrix and dimension, calculates the mean along
% the desired dimension, ignoring zero-valued indices when weighting
% Rémi Boros - 2024-11-01
