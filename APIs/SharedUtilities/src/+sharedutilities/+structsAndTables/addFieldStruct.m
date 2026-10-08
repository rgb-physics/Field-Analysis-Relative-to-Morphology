function [structObj] = addFieldStruct(structObj,fieldName,fieldVals,structInds)
%ADDFIELDSTRUCT Simple for loop to add variables to field of a
%structure structObj with the name fieldName. structInds is an optional
%parameter corresponding to indices over which to add said values

if nargin == 3
    structInds = 1:numel(fieldVals);
end

if isa(fieldVals, 'cell')
    [structObj(1:numel(fieldVals)).(fieldName)] = fieldVals{:};
else
    for currInd = structInds
        structObj(currInd).(fieldName) = fieldVals(currInd);
    end
end

end

