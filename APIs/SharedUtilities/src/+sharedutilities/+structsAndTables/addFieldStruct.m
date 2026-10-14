function structObj=addFieldStruct(structObj,fieldName,fieldVals,structInds)
%ADDFIELDSTRUCT Assign source-indexed values to selected structure indices.
% fieldVals(i) goes to structObj(i), including cell contents fieldVals{i}.
% A subset therefore needs the full source vector, not a compact subset.
if nargin<4, structInds=1:numel(fieldVals); end
if ~isstruct(structObj), error('sharedutilities:Struct','Supply a structure array.'); end
fieldName=char(string(fieldName));
if ~isvarname(fieldName), error('sharedutilities:FieldName','Invalid field name.'); end
if isempty(structInds), return; end
validateattributes(structInds,{'numeric'},{'vector','integer','positive','finite','<=',numel(fieldVals)});
if numel(unique(structInds))~=numel(structInds), error('sharedutilities:Indices','Selected indices must be unique.'); end
for index=structInds(:)'
    if iscell(fieldVals), structObj(index).(fieldName)=fieldVals{index};
    else, structObj(index).(fieldName)=fieldVals(index); end
end
end
