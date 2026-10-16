function [outSlice] = farmFillin2D(inSlice, logicSlice)
%FARMFILLIN2D Takes in a 2D matrix and (optional) a 2D logic matrix. The
% Inputs:
%   inSlice         Input 2D numeric slice.
%   logicSlice      Optional logical mask of holes to replace; other entries supply samples.
% Outputs:
%   outSlice        Slice with holes filled by scattered interpolation.

% Define logic matrix if not passed
if nargin == 1
    logicSlice = (inSlice == 0);
end
% Convert indices into row, column form
[dataX, dataY] = ind2sub(size(inSlice), find(~logicSlice));
[zeroX, zeroY] = ind2sub(size(inSlice), find(logicSlice));
% Generate scattered interpolant object and fill in slice
currInt = scatteredInterpolant(dataX, dataY, inSlice(~logicSlice));
currIntVals = currInt(zeroX, zeroY);
outSlice = inSlice;
outSlice(logicSlice) = currIntVals;

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMFILLIN2D Takes in a 2D matrix and (optional) a 2D logic matrix. The
% function uses a scattered interpolant object to fill in holes in the
% matrix dictated either by zeros in the input matrix or by the logic matrix
% passed in.
