function combined=concatenateResults(tables)
%CONCATENATERESULTS Append same-schema results; check full component identities.
if ~iscell(tables)||isempty(tables), error('objectrelativeprofiles:InvalidTables','Supply a nonempty cell of tables.'); end
keys={'DatasetID','Frame','ObjectID'};
if istable(tables{1})&&ismember('ComponentID',tables{1}.Properties.VariableNames), keys{end+1}='ComponentID'; end
combined=sharedutilities.structsAndTables.concatenateByKeys(tables,keys,struct('ErrorPrefix','objectrelativeprofiles'));
end
