function [outMat] = getUnitVecs(inMat)
%GETUNITVECS Normalizes an array corresponding to rows of unit vectors. The
%output is an array. Row_i outMat is vector-normalized Row_i of inMat
% 2025-02-22 - Rémi Boros

rowMags = vecnorm(inMat')';
outMat = inMat./rowMags;

end

