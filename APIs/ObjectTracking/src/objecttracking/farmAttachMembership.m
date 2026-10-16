function combined = farmAttachMembership(measurements, membership)
%FARMATTACHMEMBERSHIP Attach DetectionID/TrajectoryID; replicate parent keys for components.
% Inputs:
%   measurements    Measurement table identified by dataset, frame and object.
%   membership      Detection/trajectory membership table.
% Outputs:
%   combined        Measurements with DetectionID and TrajectoryID attached.

farmOGValidateKeys(membership);
for name = {'DetectionID', 'TrajectoryID'}
    column = name{1};
    if ~ismember(column, membership.Properties.VariableNames)
        error('objecttracking:MissingMembership', 'Membership lacks %s.', column);
    end
    validateattributes(membership.(column), {'numeric'}, {'real', 'finite', 'integer', 'positive', '<=', flintmax, 'column'});
end
options = struct('AllowRepeatedBase', true, 'Columns', {{'DetectionID', 'TrajectoryID'}}, ...
                 'ErrorPrefix', 'objecttracking', 'ErrorNames', struct('MissingMatches', 'MissingMembership', ...
                                                       'ExistingColumn', 'ExistingMembership'));
combined = farmAttachByKeys(measurements, membership, ...
                            {'DatasetID', 'Frame', 'ObjectID'}, options);
combined.Properties.UserData = struct('Measurements', {measurements.Properties.UserData}, 'Tracking', {membership.Properties.UserData});
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMATTACHMEMBERSHIP Attach DetectionID/TrajectoryID; replicate parent keys for components.
% DatasetID/Frame/ObjectID identify detections; TrajectoryID is attached, not keyed.
