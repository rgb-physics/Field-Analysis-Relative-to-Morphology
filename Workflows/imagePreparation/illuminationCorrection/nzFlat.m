function [flatMat] = nzFlat(inMat,dim)
%NZFLAT Weighted average of input matrix along desired dimension. By
%default, dim is 3. 
% Rémi Boros - 2024-11-19

if nargin == 1
    dim = 3;
end
% Sum and divide by non-zero elements along desired dimension
sumMat = (sum(inMat,dim));
countMat = sum(logical(inMat),dim);
flatMat = consMatLnB(sumMat./countMat,logical(countMat));

end

