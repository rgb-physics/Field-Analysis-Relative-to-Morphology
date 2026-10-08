function [outMat] = nonZeroMean(inMat, selDim)
%NONZEROFLATTEN Takes in a matrix and dimension, calculates the mean along
%the desired dimension, ignoring zero-valued indices when weighting
% Rémi Boros - 2024-11-01

sumMat = (sum(inMat,selDim));
countsMat = sum(logical(inMat),selDim);
outMat = sumMat./countsMat;

end

