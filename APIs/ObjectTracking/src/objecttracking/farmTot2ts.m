function trajStruct = farmTot2ts(input,minTrajLength)
%FARMTOT2TS Historical mapping converter, preserving explicit trajectory identity.
% Accepts numeric [time object trajectory] or named legacy/canonical table.
% Minimum length counts observations, not elapsed frame span. Default 1.
if nargin<2, minTrajLength = 1; end
validateattributes(minTrajLength,{'numeric'},{'scalar','integer','nonnegative'});
if istable(input)
    names = input.Properties.VariableNames;
    if all(ismember({'Frame','ObjectID','TrajectoryID'},names))
        input = [input.Frame input.ObjectID input.TrajectoryID];
    elseif all(ismember({'Time','Object','Trajectory'},names))
        input = [input.Time input.Object input.Trajectory];
    elseif all(ismember({'Time','ObjectID','Trajectory'},names))
        input = [input.Time input.ObjectID input.Trajectory];
    else
        error('objecttracking:MappingColumns','Use named time/object/trajectory columns.');
    end
end
validateattributes(input,{'numeric'},{'real','finite','integer','nonnegative','2d'});
if size(input,2)~=3, error('objecttracking:MappingColumns','Use three columns: time, object, trajectory.'); end
if any(input(:,2:3)<=0,'all'), error('objecttracking:MappingIDs','Object/trajectory IDs must be positive.'); end
prototype = struct('objIDs',[],'Frames',[],'TrajLen',0,'TrajectoryID',0);
trajStruct = repmat(prototype,0,1);
for id = unique(input(:,3)).'
    rows = input(input(:,3)==id,:);
    [~,order] = sort(rows(:,1)); rows = rows(order,:);
    if size(rows,1)<minTrajLength, continue; end
    record = prototype; record.objIDs = rows(:,2); record.Frames = rows(:,1);
    record.TrajLen = size(rows,1); record.TrajectoryID = id;
    trajStruct(end+1,1) = record; %#ok<AGROW>
end
end
