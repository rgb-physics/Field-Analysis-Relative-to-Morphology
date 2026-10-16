function farmValidateTableKeys(t, keys, options)
%FARMVALIDATETABLEKEYS Validate explicit scalar keys and optional uniqueness.
% Inputs:
%   t               Table whose identity columns are to be validated.
%   keys            Names of table columns that jointly identify each row.
%   options         Operation settings struct.
% Outputs:
%   None. Invalid keys raise an error.

if nargin < 3
    options = struct();
end
o = farmSUOptions(options, struct('AllowRepeated', false, ...
                                 'ErrorPrefix', 'sharedutilities', 'ErrorNames', struct()));
validateattributes(o.AllowRepeated, {'logical'}, {'scalar'});
keys = cellstr(string(keys));
if isempty(keys) || numel(unique(keys)) ~= numel(keys)
    farmSUKeyError(o, 'MissingKeys', 'Specify unique key column names.');
end
if ~istable(t) || ~all(ismember(keys, t.Properties.VariableNames))
    farmSUKeyError(o, 'MissingKeys', 'Table lacks required identity columns.');
end
for k = 1:numel(keys)
    name = keys{k};
    value = t.(name);
    if size(value, 2) ~= 1 || ~ismatrix(value)
        farmSUKeyError(o, 'InvalidKeys', 'Key %s must be one scalar column.', name);
    end
    if strcmp(name, 'DatasetID')
        valid = isstring(value) && ~any(ismissing(value));
    elseif ismember(name, {'Frame', 'ObjectID', 'ComponentID'})
        valid = isnumeric(value) && isreal(value) && all(isfinite(value)) && all(value == fix(value));
        if strcmp(name, 'ObjectID')
            valid = valid && all(value > 0) && all(value <= flintmax);
        else
            valid = valid && all(value >= 0);
        end
    elseif isnumeric(value) || islogical(value)
        valid = isreal(value) && all(isfinite(value));
    elseif isstring(value) || iscategorical(value) || isdatetime(value) || isduration(value)
        valid = ~any(ismissing(value));
    else
        valid = false;
    end
    if ~valid
        farmSUKeyError(o, 'InvalidKeys', 'Key %s has an invalid value or type.', name);
    end
end
if ~o.AllowRepeated && height(unique(t(:, keys))) ~= height(t)
    farmSUKeyError(o, 'DuplicateKeys', 'Duplicate identity keys.');
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMVALIDATETABLEKEYS Validate explicit scalar keys and optional uniqueness.
% Known object keys use DatasetID string, nonnegative integer Frame/ComponentID,
% positive integer ObjectID. TrajectoryID is a property unless explicitly keyed.
