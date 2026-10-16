function combined = farmConcatenateResults(tables)
%FARMCONCATENATERESULTS Append same-schema results; check full component identities.
% Inputs:
%   tables          Nonempty cell array of tables with matching schemas.
% Outputs:
%   combined        Appended result table with unique full sampling identities.

if ~iscell(tables) || isempty(tables)
    error('objectrelativeprofiles:InvalidTables', 'Supply a nonempty cell of tables.');
end
keys = {'DatasetID', 'Frame', 'ObjectID'};
if istable(tables{1}) && ismember('ComponentID', tables{1}.Properties.VariableNames)
    keys{end + 1} = 'ComponentID';
end
combined = farmConcatenateByKeys(tables, keys, struct('ErrorPrefix', 'objectrelativeprofiles'));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMCONCATENATERESULTS Append same-schema results; check full component identities.
