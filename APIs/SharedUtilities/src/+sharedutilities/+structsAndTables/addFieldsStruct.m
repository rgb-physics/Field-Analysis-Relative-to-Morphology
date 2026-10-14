function structObj=addFieldsStruct(structObj,fieldNames,fieldVals,structInds)
%ADDFIELDSSTRUCT Forward explicit indices for each source-indexed field.
fieldNames=cellstr(string(fieldNames));
if ~iscell(fieldVals)||numel(fieldNames)~=numel(fieldVals)
    error('sharedutilities:Fields','Supply one value array per field name.');
end
for k=1:numel(fieldNames)
    if nargin<4
        structObj=sharedutilities.structsAndTables.addFieldStruct(structObj,fieldNames{k},fieldVals{k});
    else
        structObj=sharedutilities.structsAndTables.addFieldStruct(structObj,fieldNames{k},fieldVals{k},structInds);
    end
end
end
