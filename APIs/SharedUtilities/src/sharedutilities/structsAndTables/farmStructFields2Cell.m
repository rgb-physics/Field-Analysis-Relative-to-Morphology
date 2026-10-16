function [cellObj] = farmStructFields2Cell(structObj, selFields, structRange)
%FARMSTRUCTFIELDS2CELL Takes in a structure structObj and samples values stored
% Inputs:
%   structObj       Structure array providing or receiving field values.
%   selFields       Names of structure fields to collect.
%   structRange     Optional indices of structure entries to collect.
% Outputs:
%   cellObj         Cell array of the selected structure-field contents.

% Define structRange if not passed by the user
if nargin == 2
    structRange = 1:numel(structObj);
end
% Case where all fields are requested
if any(strcmp(selFields, 'all'))
    selFields = fieldnames(structObj);
end
% Generate cross-reference of existing structure field names
allNames = fieldnames(structObj);
validFields = 1:numel(selFields);
% Instantiate output cell object
cellObj = cell(1, numel(selFields));

% Iterate over each field and convert contents to a cell, then store
for fieldInd = 1:numel(selFields)
    currField = selFields{fieldInd};
    if ~any(strcmp(allNames, currField))
        validFields(fieldInd) = -1;
        continue
    end
    cellObj{fieldInd} = {structObj(structRange).(currField)};
end

% Clean up (remove requested fields that are non-existent in the struct)
cellObj = cellObj(validFields ~= -1);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSTRUCTFIELDS2CELL Takes in a structure structObj and samples values stored
% in structRange (optional) from the fields stored in fieldNames. If
% structRange is not passed, the function defaults to sampling every index
% in structObj. cellObj will be a cell array of cell arrays, with the
% structure contents stored in the deeper layer of cell arrays.
% 2023-11-16
