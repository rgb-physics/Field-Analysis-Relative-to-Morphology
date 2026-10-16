function selection = farmSelectLineage(tracking, seed, options)
%FARMSELECTLINEAGE Directed reachability, not weak connected lineage expansion.
% Inputs:
%   tracking        Tracking result containing detections and accepted links.
%   seed            Explicit starting detection, object, trajectory or coordinate selection.
%   options         Operation settings struct.
% Outputs:
%   selection       Explicitly selected detections and selection diagnostics.

if nargin < 3
    options = struct();
end
options = farmOGOptions(options, struct('Direction', 'ancestors', 'IncludeSeed', true, 'Loader', []));
direction = validatestring(options.Direction, {'ancestors', 'descendants', 'both', 'self'});
validateattributes(options.IncludeSeed, {'logical'}, {'scalar'});
d = tracking.Detections;
ids = [];
background = zeros(0, 3);
if isfield(seed, 'DetectionIDs')
    ids = seed.DetectionIDs(:);
elseif isfield(seed, 'TrajectoryIDs')
    ids = d.DetectionID(ismember(d.TrajectoryID, seed.TrajectoryIDs));
elseif isfield(seed, 'ObjectIDs') && isfield(seed, 'Frame')
    ids = d.DetectionID(d.Frame == seed.Frame & ismember(d.ObjectID, seed.ObjectIDs));
elseif isfield(seed, 'CoordinatesYXZ') && isfield(seed, 'Frame')
    if ~isa(options.Loader, 'function_handle')
        error('objecttracking:SeedLoader', 'Coordinates require a frame loader.');
    end
    input = options.Loader(seed.Frame);
    if isstruct(input) && isfield(input, 'ObjectGeometryVersion')
        objects = input;
        if objects.Frame ~= seed.Frame || string(objects.DatasetID) ~= string(tracking.DatasetID)
            error('objecttracking:InputIdentity', 'Seed loader must return the requested frame/dataset.');
        end
    else
        objects = farmPrepareObjects(input, struct('Frame', seed.Frame, 'DatasetID', tracking.DatasetID));
    end
    coords = seed.CoordinatesYXZ;
    validateattributes(coords, {'numeric'}, {'2d', 'real', 'finite', 'integer', 'positive'});
    if size(coords, 2) ~= 3
        error('objecttracking:SeedCoordinates', 'Supply N-by-3 YXZ coordinates.');
    end
    sz = objects.Grid.Size;
    if numel(sz) == 2
        sz(3) = 1;
    end
    if any(coords > sz, 'all')
        error('objecttracking:SeedCoordinates', 'Seed outside current grid.');
    end
    indices = sub2ind(sz, coords(:, 1), coords(:, 2), coords(:, 3));
    for i = 1:numel(indices)
        owner = [];
        for j = 1:numel(objects.ObjectIDs)
            if ismember(indices(i), objects.Components.PixelIdxList{j})
                owner = objects.ObjectIDs(j);
                break
            end
        end
        if isempty(owner)
            background(end + 1, :) = coords(i, :); %#ok<AGROW>
        else
            ids = [ids; d.DetectionID(d.Frame == seed.Frame & d.ObjectID == owner)];
        end %#ok<AGROW>
    end
else
    error('objecttracking:InvalidSeed', 'Supply detection IDs, trajectory IDs, frame-local IDs, or YXZ coordinates.');
end
ids = unique(ids);
if any(~ismember(ids, d.DetectionID))
    error('objecttracking:UnknownDetection', 'Unknown seed detection.');
end
selected = ids;
if ismember(direction, {'ancestors', 'both'})
    selected = union(selected, localReach(ids, tracking.Links.TargetDetectionID, tracking.Links.SourceDetectionID));
end
if ismember(direction, {'descendants', 'both'})
    selected = union(selected, localReach(ids, tracking.Links.SourceDetectionID, tracking.Links.TargetDetectionID));
end
if ~options.IncludeSeed
    selected = setdiff(selected, ids);
end
status = "selected";
if isempty(ids)
    if ~isempty(background)
        status = "background selected (YXZ coordinates recorded)";
    else
        status = "no matching seed";
    end
end
selection = struct('Detections', d(ismember(d.DetectionID, selected), :), 'SeedDetectionIDs', ids, ...
                   'BackgroundCoordinatesYXZ', background, 'Status', status, 'Options', options);
end

function visited = localReach(seed, from, to)
% Internal helper.
visited = seed;
frontier = seed;
while ~isempty(frontier)
    next = unique(to(ismember(from, frontier)));
    next = setdiff(next, visited);
    visited = union(visited, next);
    frontier = next;
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSELECTLINEAGE Directed reachability, not weak connected lineage expansion.
% SEED struct: ObjectIDs+Frame, TrajectoryIDs, DetectionIDs, or CoordinatesYXZ
% +Frame. Coordinates require OPTIONS.Loader=@(frame) -> prepared objects.
% Direction='ancestors'|'descendants'|'both'|'self'; IncludeSeed=true.
% Background coordinates yield no seed and report coordinates/status. Traversal
% never switches direction at an ancestor to collect unrelated siblings.
%
% BEHAVIOR
% -------------------------------------------------------------------------
% Ancestry navigation follows the explicit starting selection and requested
% direction. No automatic population or ancestry averaging is performed.
