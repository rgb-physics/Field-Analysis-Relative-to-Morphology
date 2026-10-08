function [outMat] = fillin3D(inMat,logicMat)
%FILLIN3D Takes in a 3D matrix and (optional) a 2D logic matrix. The
%function uses a scattered interpolant object to fill in holes in the
%matrix dictated either by zeros in the input matrix or by the logic matrix
%passed in.

%Define logic matrix if not passed
if nargin == 1
    logicMat = (inMat == 0);
end
%Convert indices into row, column form
[dataX, dataY, dataZ] = ind2sub(size(inMat), find(~logicMat));
[zeroX, zeroY, zeroZ] = ind2sub(size(inMat), find(logicMat));
%Generate scattered interpolant object and fill in slice
intObj = scatteredInterpolant(dataX,dataY,dataZ,inMat(~logicMat));
intVals = intObj(zeroX, zeroY, zeroZ);
outMat = inMat;
outMat(logicMat) = intVals;

end

