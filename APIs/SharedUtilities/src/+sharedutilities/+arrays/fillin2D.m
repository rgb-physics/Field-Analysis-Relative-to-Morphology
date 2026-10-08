function [outSlice] = fillin2D(inSlice,logicSlice)
%FILLIN2D Takes in a 2D matrix and (optional) a 2D logic matrix. The
%function uses a scattered interpolant object to fill in holes in the
%matrix dictated either by zeros in the input matrix or by the logic matrix
%passed in.

%Define logic matrix if not passed
if nargin == 1
    logicSlice = (inSlice == 0);
end
%Convert indices into row, column form
[dataX, dataY] = ind2sub(size(inSlice), find(~logicSlice));
[zeroX, zeroY] = ind2sub(size(inSlice), find(logicSlice));
%Generate scattered interpolant object and fill in slice
currInt = scatteredInterpolant(dataX,dataY,inSlice(~logicSlice));
currIntVals = currInt(zeroX, zeroY);
outSlice = inSlice;
outSlice(logicSlice) = currIntVals;

end

