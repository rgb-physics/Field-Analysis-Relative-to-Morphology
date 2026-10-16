function combined = farmAttachByKeys(base, additional, keys, options)
%FARMATTACHBYKEYS Attach columns by explicit keys, retaining destination row order.
% Inputs:
%   base            Destination table whose row order is retained.
%   additional      Table containing incoming keyed values.
%   keys            Names of table columns that jointly identify each row.
%   options         Operation settings struct.
% Outputs:
%   combined        Destination rows with the requested incoming columns attached.

if nargin < 4
    options = struct();
end
o = farmSUOptions(options, struct('MissingPolicy', 'error', 'Overwrite', false, ...
                                 'AllowRepeatedBase', false, 'Columns', {{}}, 'ErrorPrefix', 'sharedutilities', 'ErrorNames', struct()));
o.MissingPolicy = validatestring(o.MissingPolicy, {'error', 'missing'});
validateattributes(o.Overwrite, {'logical'}, {'scalar'});
validateattributes(o.AllowRepeatedBase, {'logical'}, {'scalar'});
keys = cellstr(string(keys));
v = struct('AllowRepeated', o.AllowRepeatedBase, 'ErrorPrefix', o.ErrorPrefix, 'ErrorNames', o.ErrorNames);
farmValidateTableKeys(base, keys, v);
v.AllowRepeated = false;
farmValidateTableKeys(additional, keys, v);
[present, position] = ismember(base(:, keys), additional(:, keys));
if any(~present) && strcmp(o.MissingPolicy, 'error')
    farmSUKeyError(o, 'MissingMatches', '%d destination identities lack an incoming match.', nnz(~present));
end
if isempty(o.Columns)
    columns = setdiff(additional.Properties.VariableNames, keys, 'stable');
else
    columns = cellstr(string(o.Columns));
end
if numel(unique(columns)) ~= numel(columns) || any(ismember(columns, keys)) || ...
        ~all(ismember(columns, additional.Properties.VariableNames))
    farmSUKeyError(o, 'MissingColumns', 'Columns must name unique incoming non-key columns.');
end
combined = base;
for k = 1:numel(columns)
    name = columns{k};
    if ismember(name, base.Properties.VariableNames) && ~o.Overwrite
        farmSUKeyError(o, 'ExistingColumn', 'Column %s already exists.', name);
    end
    values = additional.(name);
    if ~ismatrix(values)
        farmSUKeyError(o, 'MissingType', 'Table columns must be row-indexable 2D arrays.');
    end
    if all(present)
        combined.(name) = values(position, :);
        continue
    end
    if isinteger(values) || islogical(values)
        values = double(values);
    end
    shape = [height(base), size(values, 2)];
    if isnumeric(values)
        fill = nan(shape, 'like', values);
    elseif isstring(values)
        fill = strings(shape);
        fill(:) = missing;
    elseif iscell(values)
        fill = cell(shape);
    elseif isdatetime(values)
        fill = NaT(shape, 'TimeZone', values.TimeZone);
        fill.Format = values.Format;
    elseif isduration(values)
        fill = seconds(nan(shape));
        fill.Format = values.Format;
    elseif iscategorical(values)
        fill = categorical(nan(shape), 1:numel(categories(values)), categories(values), 'Ordinal', isordinal(values));
    else
        farmSUKeyError(o, 'MissingType', 'Unsupported missing-column type: %s.', class(values));
    end
    fill(present, :) = values(position(present), :);
    combined.(name) = fill;
end
combined.Properties.UserData = struct('Base', {base.Properties.UserData}, 'Added', {additional.Properties.UserData});
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMATTACHBYKEYS Attach columns by explicit keys, retaining destination row order.
% Additional keys must be unique; repeated base keys are opt-in (parent mapping).
% Columns defaults to all non-key columns. MissingPolicy='error'|'missing'.
% Integer/logical missing columns become double NaN; finite zero remains zero.
%
% MATCHING RESULTS
% -------------------------------------------------------------------------
% Keys establish row identity only. Matching identities or array dimensions
% do not prove spatial registration.
