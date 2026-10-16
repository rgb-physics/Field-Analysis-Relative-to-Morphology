function [selected, summary] = farmSelectTrajectories(membership, options)
%FARMSELECTTRAJECTORIES Post-tracking selection without renumbering identities.
% Inputs:
%   membership      Detection/trajectory membership table.
%   options         Operation settings struct.
% Outputs:
%   selected        Membership rows passing the requested selection.
%   summary         Per-trajectory observation/span summary.

if nargin < 2
    options = struct();
end
options = farmOGOptions(options, struct('MinDetections', 1, 'MinFrameSpan', 1));
validateattributes(options.MinDetections, {'numeric'}, {'scalar', 'integer', 'nonnegative'});
validateattributes(options.MinFrameSpan, {'numeric'}, {'scalar', 'integer', 'nonnegative'});
if height(membership) == 0
    selected = membership;
    summary = table(strings(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), false(0, 1), ...
                    'VariableNames', {'DatasetID', 'TrajectoryID', 'ObservationCount', 'FirstFrame', 'LastFrame', 'FrameSpan', 'Selected'});
    return
end
[groups, dataset, trajectory] = findgroups(membership.DatasetID, membership.TrajectoryID);
count = splitapply(@numel, membership.Frame, groups);
first = splitapply(@min, membership.Frame, groups);
last = splitapply(@max, membership.Frame, groups);
span = last - first + 1;
valid = count >= options.MinDetections & span >= options.MinFrameSpan;
summary = table(dataset, trajectory, count, first, last, span, valid, ...
                'VariableNames', {'DatasetID', 'TrajectoryID', 'ObservationCount', 'FirstFrame', 'LastFrame', 'FrameSpan', 'Selected'});
selected = membership(valid(groups), :);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSELECTTRAJECTORIES Post-tracking selection without renumbering identities.
% MinDetections=1; MinFrameSpan=1. FrameSpan=end-start+1; ObservationCount counts
% actual rows, including gaps. Selection leaves original TrajectoryIDs intact.
