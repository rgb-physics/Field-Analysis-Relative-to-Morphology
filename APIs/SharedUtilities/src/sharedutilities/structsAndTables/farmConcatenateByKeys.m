function combined = farmConcatenateByKeys(tables,keys,options)
%FARMCONCATENATEBYKEYS Append matching-schema tables; preserve keys/order/metadata.
if nargin<3, options = struct(); end
o = farmSUOptions(options,struct('ErrorPrefix','sharedutilities','ErrorNames',struct()));
if ~iscell(tables)||isempty(tables)
    farmSUKeyError(o,'InvalidTables','Supply a nonempty cell of tables.');
end
v = struct('ErrorPrefix',o.ErrorPrefix,'ErrorNames',o.ErrorNames);
metadata = cell(size(tables));
for k = 1:numel(tables)
    farmValidateTableKeys(tables{k},keys,v);
    if k>1&&~isequal(tables{k}.Properties.VariableNames,tables{1}.Properties.VariableNames)
        farmSUKeyError(o,'SchemaMismatch','Align table column schemas explicitly before concatenation.');
    end
    metadata{k} = tables{k}.Properties.UserData;
end
combined = vertcat(tables{:});
farmValidateTableKeys(combined,keys,v);
combined.Properties.UserData = struct('FrameMetadata',{metadata});
end
