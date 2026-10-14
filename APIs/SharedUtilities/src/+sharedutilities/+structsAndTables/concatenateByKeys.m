function combined=concatenateByKeys(tables,keys,options)
%CONCATENATEBYKEYS Append matching-schema tables; preserve keys/order/metadata.
if nargin<3, options=struct(); end
o=sharedutilities.internal.options(options,struct('ErrorPrefix','sharedutilities','ErrorNames',struct()));
if ~iscell(tables)||isempty(tables)
    sharedutilities.internal.keyError(o,'InvalidTables','Supply a nonempty cell of tables.');
end
v=struct('ErrorPrefix',o.ErrorPrefix,'ErrorNames',o.ErrorNames);
metadata=cell(size(tables));
for k=1:numel(tables)
    sharedutilities.structsAndTables.validateTableKeys(tables{k},keys,v);
    if k>1&&~isequal(tables{k}.Properties.VariableNames,tables{1}.Properties.VariableNames)
        sharedutilities.internal.keyError(o,'SchemaMismatch','Align table column schemas explicitly before concatenation.');
    end
    metadata{k}=tables{k}.Properties.UserData;
end
combined=vertcat(tables{:});
sharedutilities.structsAndTables.validateTableKeys(combined,keys,v);
combined.Properties.UserData=struct('FrameMetadata',{metadata});
end
