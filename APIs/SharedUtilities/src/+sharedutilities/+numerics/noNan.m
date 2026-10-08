function [outMat] = noNan(inMat,replVal)
%NONAN Loads in a matrix and returns the corresponding matrix with replVal
%at each NaN value. replVal will default to 0 if not passed
% Rémi Boros - 2024-01-06
if nargin == 1
    replVal = 0;
end

logicMat = isnan(inMat);
outMat = consMatLnB(inMat,~logicMat) + replVal*logicMat;

end

