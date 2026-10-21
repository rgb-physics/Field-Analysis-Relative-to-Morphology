function combined = farmAttachResults(base, additional, options)
%FARMATTACHRESULTS Component-aware keyed join; absent ComponentID means parent (0).
% Inputs:
%   base            Destination table whose row order is retained.
%   additional      Table containing incoming keyed values.
%   options         Optional scalar struct with the fields:
%                   MissingPolicy = character vector or string scalar;
%                   Overwrite = logical scalar;
% Outputs:
%   combined        Sampling results joined by dataset/frame/object/component identity.

if nargin < 3
    options = struct();
end
options = farmOGOptions(options, struct('MissingPolicy', 'error', 'Overwrite', false));
primary = {'DatasetID', 'Frame', 'ObjectID'};
v = struct('AllowRepeated', true, 'ErrorPrefix', 'objectrelativeprofiles');
farmValidateTableKeys(base, primary, v);
farmValidateTableKeys(additional, primary, v);
hadComponent = ismember('ComponentID', base.Properties.VariableNames);
if ~hadComponent
    base.ComponentID = zeros(height(base), 1);
end
if ~ismember('ComponentID', additional.Properties.VariableNames)
    additional.ComponentID = zeros(height(additional), 1);
end
options.ErrorPrefix = 'objectrelativeprofiles';
options.ErrorNames = struct('MissingMatches', 'MissingResults', 'MissingType', 'MissingType');
combined = farmAttachByKeys(base, additional, ...
                            [primary, {'ComponentID'}], options);
if ~hadComponent && all(combined.ComponentID == 0)
    combined = removevars(combined, 'ComponentID');
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMATTACHRESULTS Component-aware keyed join; absent ComponentID means parent (0).
% MissingPolicy='error'|'missing', Overwrite=false. Spatial alignment is separate.
