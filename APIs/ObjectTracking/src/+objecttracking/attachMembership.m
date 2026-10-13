function combined = attachMembership(measurements, membership)
%ATTACHMEMBERSHIP Add temporal identity to existing object/query tables by keys.
% Requires full matches, never assigns IDs by row position. For component-level
% query rows, parent membership is intentionally replicated through those rows.
keys={'DatasetID','Frame','ObjectID'};
objectgeometry.internal.validateKeys(membership);
[found,position]=ismember(measurements(:,keys),membership(:,keys));
if any(~found), error('objecttracking:MissingMembership','A measurement row has no tracked identity.'); end
combined=measurements;
for name={'DetectionID','TrajectoryID'}
    column=name{1};
    if ismember(column,combined.Properties.VariableNames), error('objecttracking:ExistingMembership','Column %s already exists.',column); end
    combined.(column)=membership.(column)(position);
end
combined.Properties.UserData=struct('Measurements',measurements.Properties.UserData,'Tracking',membership.Properties.UserData);
end
