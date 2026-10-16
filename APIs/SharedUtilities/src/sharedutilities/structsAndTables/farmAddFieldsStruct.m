function structObj = farmAddFieldsStruct(structObj, fieldNames, fieldVals, structInds)
%FARMADDFIELDSSTRUCT Forward explicit indices for each source-indexed field.
% Inputs:
%   structObj       Structure array providing or receiving field values.
%   fieldNames      Field names used by the structure/table conversion.
%   fieldVals       Source-indexed values corresponding to structure entries.
%   structInds      Optional structure indices to update.
% Outputs:
%   structObj       Structure array with the selected fields updated.

fieldNames = cellstr(string(fieldNames));
if ~iscell(fieldVals) || numel(fieldNames) ~= numel(fieldVals)
    error('sharedutilities:Fields', 'Supply one value array per field name.');
end
for k = 1:numel(fieldNames)
    if nargin < 4
        structObj = farmAddFieldStruct(structObj, fieldNames{k}, fieldVals{k});
    else
        structObj = farmAddFieldStruct(structObj, fieldNames{k}, fieldVals{k}, structInds);
    end
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMADDFIELDSSTRUCT Forward explicit indices for each source-indexed field.
