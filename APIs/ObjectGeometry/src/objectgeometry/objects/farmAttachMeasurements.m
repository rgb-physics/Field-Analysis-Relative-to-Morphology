function combined = farmAttachMeasurements(base, additional, options)
%FARMATTACHMEASUREMENTS Attach properties by DatasetID/Frame/ObjectID, retaining order.
% Inputs:
%   base            Destination table whose row order is retained.
%   additional      Table containing incoming keyed values.
%   options         Optional scalar struct with the fields:
%                   MissingPolicy = character vector or string scalar;
%                   Overwrite = logical scalar;
% Outputs:
%   combined        Measurement table with incoming columns attached by object identity.

if nargin < 3
    options = struct();
end
options = farmOGOptions(options, struct('MissingPolicy', 'error', 'Overwrite', false));
options.ErrorPrefix = 'objectgeometry';
options.ErrorNames = struct('MissingMatches', 'MissingMeasurements', 'ExistingColumn', 'ExistingProperty', ...
                            'MissingType', 'MissingColumnType');
combined = farmAttachByKeys(base, additional, ...
                            {'DatasetID', 'Frame', 'ObjectID'}, options);
combined.Properties.UserData = struct('BaseMetadata', {base.Properties.UserData}, 'AdditionalMetadata', {additional.Properties.UserData});
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMATTACHMEASUREMENTS Attach properties by DatasetID/Frame/ObjectID, retaining order.
% MissingPolicy='error'|'missing', Overwrite=false. Grid compatibility is separate.
