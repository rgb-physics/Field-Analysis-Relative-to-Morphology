function [structObj] = addFieldsStruct(structObj,fieldNames,fieldVals,structInds)
%ADDFIELDSSTRUCT Takes in a structure, adds the values stored in fieldVals
%to the fields with names stored in fieldNames. Both of the latter two
%variables should be cell arrays ordered with corresponding name and values
%in the same indices. structInds is an optional parameter indicating which
%indices to assign passed fieldVals to. By default, structInds will span
%the entire struct
% 2023-11-16
if nargin == 3
    structInds = numel(fieldVals{1});
end

% Iterate through each field and add corresponding values to struct
for fieldInd = 1:numel(fieldNames)
    currField = fieldNames{fieldInd};
    currVals = fieldVals{fieldInd};
    structObj = addFieldStruct(structObj,currField,currVals);
end

end

