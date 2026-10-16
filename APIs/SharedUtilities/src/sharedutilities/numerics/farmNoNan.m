function outMat = farmNoNan(inMat, replVal)
%FARMNONAN Replace NaN only (not Inf), preserving input class and all other values.
% Inputs:
%   inMat           Input numeric array.
%   replVal         Value replacing NaN entries.
% Outputs:
%   outMat          Input with NaN replaced, preserving other values and input type.

if nargin < 2
    replVal = 0;
end
validateattributes(replVal, {'numeric'}, {'scalar'});
outMat = inMat;
outMat(isnan(inMat)) = replVal;
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMNONAN Replace NaN only (not Inf), preserving input class and all other values.
