function [outVal] = farmBndmod(inVal, floorVal, ceilVal)
%FARMBNDMOD Calculates modulo of inVal in the range bounded between floorVal
% Inputs:
%   inVal           Numeric values to wrap.
%   floorVal        Lower bound of the periodic interval.
%   ceilVal         Upper bound of the periodic interval.
% Outputs:
%   outVal          Values mapped into the requested periodic interval.

if floorVal == ceilVal
    outVal = floorVal;
else
    rangeSize = ceilVal - floorVal;
    outVal = mod(inVal - floorVal, rangeSize) + floorVal;
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMBNDMOD Calculates modulo of inVal in the range bounded between floorVal
% and ceilVal. For example, farmBndmod(3*pi/4,-pi/2,pi/2) maps 3*pi/4 to the
% periodic domain between -pi/2 and pi/2 and returns -pi/4. Note that
% floorVal and ceilVal are equal in the periodic domain.
