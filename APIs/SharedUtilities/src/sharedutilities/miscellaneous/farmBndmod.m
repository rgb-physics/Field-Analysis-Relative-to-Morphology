function [outVal] = farmBndmod(inVal,floorVal,ceilVal)
%FARMBNDMOD Calculates modulo of inVal in the range bounded between floorVal
%and ceilVal. For example, farmBndmod(3*pi/4,-pi/2,pi/2) maps 3*pi/4 to the
%periodic domain between -pi/2 and pi/2 and returns -pi/4. Note that
%floorVal and ceilVal are equal in the periodic domain.

if floorVal == ceilVal
    outVal = floorVal;
else
    rangeSize = ceilVal - floorVal;
    outVal = mod(inVal - floorVal, rangeSize) + floorVal;
end

end

