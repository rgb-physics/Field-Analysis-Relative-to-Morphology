function support = farmPrepareSupport(input, imageSize, options)
%FARMPREPARESUPPORT Sampling groups without implicit connected-component analysis.
% Inputs:
%   input           Object input accepted by farmPrepareObjects.
%   imageSize       Spatial array dimensions in YX or YXZ order.
%   options         Operation settings struct.
% Outputs:
%   support         Support construct containing deduplicated groups and diagnostics.

if nargin < 3
    options = struct();
end
options = farmOGOptions(options, struct('Type', 'auto', 'ObjectIDs', [], ...
                                       'DatasetID', 'default', 'Frame', 1, 'Name', 'selection', 'Grid', [], ...
                                       'ComponentResults', false, 'CentroidFallback', true));
validateattributes(imageSize, {'numeric'}, {'vector', 'integer', 'positive', 'finite'});
sz = double(imageSize(:).');
if numel(sz) == 2
    sz(3) = 1;
end
if numel(sz) ~= 3
    error('objectrelativeprofiles:InvalidDimensions', 'Use one spatial XYZ grid.');
end
if isstruct(input) && isfield(input, 'SamplingVersion')
    support = input;
    localMatch(support.Grid.Size, sz);
    return
end
validateattributes(options.ComponentResults, {'logical'}, {'scalar'});
validateattributes(options.CentroidFallback, {'logical'}, {'scalar'});
grid = options.Grid;
if isempty(grid)
    grid = struct('Size', sz);
end
localMatch(grid.Size, sz);
record = struct('ObjectID', 0, 'ComponentID', 0, 'Indices', [], 'GeometryEmpty', false, ...
                'EmptyGeometryCount', 0, 'UsedFallback', false, 'FallbackCount', 0);
records = repmat(record, 0, 1);
dataset = string(options.DatasetID);
frame = options.Frame;
if isstruct(input) && isfield(input, 'Records') && isfield(input, 'Grid')
    grid = input.Grid;
    localMatch(grid.Size, sz);
    dataset = string(input.DatasetID);
    frame = input.Frame;
    for i = 1:numel(input.Records)
        source = input.Records(i);
        r = record;
        r.ObjectID = source.ObjectID;
        r.ComponentID = source.ComponentID;
        r.Indices = source.Indices(:);
        r.GeometryEmpty = isempty(r.Indices);
        r.EmptyGeometryCount = double(r.GeometryEmpty);
        if r.GeometryEmpty && strcmp(input.Type, 'skeleton') && options.CentroidFallback ...
                && isstruct(source.Fallback) && isfield(source.Fallback, 'Centroid')
            xyz = round(source.Fallback.Centroid);
            xyz = xyz(:).';
            yxz = xyz([2 1 3]);
            if any(yxz < 1 | yxz > sz)
                error('objectrelativeprofiles:FallbackOutOfBounds', 'Centroid fallback is outside the grid.');
            end
            r.Indices = sub2ind(sz, yxz(1), yxz(2), yxz(3));
            r.UsedFallback = true;
            r.FallbackCount = 1;
        end
        records(end + 1, 1) = r; %#ok<AGROW>
    end
    if ~options.ComponentResults
        ids = unique([records.ObjectID], 'stable');
        combined = repmat(record, 0, 1);
        for id = ids
            pieces = records([records.ObjectID] == id);
            r = record;
            r.ObjectID = id;
            r.Indices = vertcat(pieces.Indices);
            r.GeometryEmpty = all([pieces.GeometryEmpty]);
            r.EmptyGeometryCount = sum([pieces.EmptyGeometryCount]);
            r.UsedFallback = any([pieces.UsedFallback]);
            r.FallbackCount = sum([pieces.FallbackCount]);
            combined(end + 1, 1) = r; %#ok<AGROW>
        end
        records = combined;
    end
elseif isstruct(input) && isfield(input, 'ObjectGeometryVersion')
    grid = input.Grid;
    localMatch(grid.Size, sz);
    dataset = input.DatasetID;
    frame = input.Frame;
    for i = 1:numel(input.ObjectIDs)
        r = record;
        r.ObjectID = input.ObjectIDs(i);
        r.Indices = input.Components.PixelIdxList{i};
        records(end + 1, 1) = r; %#ok<AGROW>
    end
else
    type = validatestring(options.Type, {'auto', 'indices', 'mask', 'labels'});
    if strcmp(type, 'auto')
        if islogical(input)
            type = 'mask';
        elseif iscell(input) || isvector(input) || isempty(input)
            type = 'indices';
        else
            type = 'labels';
        end
    end
    ids = options.ObjectIDs;
    lists = {};
    switch type
        case 'mask'
            localMatch(size(input), sz);
            if ~islogical(input)
                error('objectrelativeprofiles:InvalidMask', 'Use a logical selection mask.');
            end
            lists = {find(input)};
        case 'indices'
            if iscell(input)
                lists = input;
            else
                lists = {input};
            end
        case 'labels'
            localMatch(size(input), sz);
            validateattributes(input, {'numeric'}, {'real', 'finite', 'integer', 'nonnegative', '<=', flintmax});
            if ~isempty(ids)
                error('objectrelativeprofiles:LabelIDs', 'Labels already define the IDs.');
            end
            ids = double(unique(input(input > 0)));
            for i = 1:numel(ids)
                lists{i} = find(input == ids(i));
            end %#ok<AGROW>
    end
    if isempty(ids)
        ids = 1:numel(lists);
    end
    if numel(ids) ~= numel(lists)
        error('objectrelativeprofiles:InvalidIDs', 'Provide one ID per group.');
    end
    for i = 1:numel(lists)
        r = record;
        r.ObjectID = ids(i);
        r.Indices = lists{i};
        records(end + 1, 1) = r; %#ok<AGROW>
    end
end
validateattributes(frame, {'numeric'}, {'scalar', 'finite', 'integer', 'nonnegative'});
if ~isscalar(dataset) || ismissing(dataset) || strlength(dataset) == 0
    error('objectrelativeprofiles:InvalidDataset', 'DatasetID must be nonempty scalar text.');
end
for i = 1:numel(records)
    indices = records(i).Indices;
    if ~isempty(indices)
        validateattributes(indices, {'numeric'}, {'real', 'finite', 'integer', 'positive', 'vector'});
        if any(indices(:) > prod(sz))
            error('objectrelativeprofiles:IndexOutOfBounds', 'An index exceeds the field grid.');
        end
    end
    records(i).Indices = unique(double(indices(:)));
    validateattributes(records(i).ObjectID, {'numeric'}, {'scalar', 'finite', 'integer', 'positive', '<=', flintmax});
end
keys = [[records.ObjectID].' [records.ComponentID].'];
if size(unique(keys, 'rows'), 1) ~= numel(records)
    error('objectrelativeprofiles:DuplicateSupportKeys', 'Duplicate ID/component groups.');
end
name = string(options.Name);
if ~isscalar(name) || ismissing(name) || strlength(name) == 0
    error('objectrelativeprofiles:InvalidSupportName', 'Name must be scalar text.');
end
support = struct('SamplingVersion', 1, 'DatasetID', dataset, 'Frame', double(frame), ...
                 'Name', name, 'Records', records, 'Grid', grid, 'Options', options);
end

function localMatch(actual, expected)
% Internal helper.
actual = double(actual(:).');
if numel(actual) == 2
    actual(3) = 1;
end
if ~isequal(actual, expected)
    error('objectrelativeprofiles:GridMismatch', 'Field and support spatial dimensions must match.');
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMPREPARESUPPORT Sampling groups without implicit connected-component analysis.
% INPUT: indices, logical mask, label matrix, cell index groups, prepared
% ObjectGeometry objects, generated geometry, or an already prepared support.
% OPTIONS: Type='auto'|'indices'|'mask'|'labels'; ObjectIDs=[];
% DatasetID='default'; Frame=1; Name='selection'; Grid=[];
% ComponentResults=false; CentroidFallback=true. Indices are deduplicated
% within each group; groups may overlap. Numeric vectors default to indices,
% other numeric matrices to labels. Explicit Type resolves ambiguous inputs.
% Geometry components combine by parent ID by default. Empty skeletons use
% nearest-voxel centroid fallback, flagged separately from computed geometry.
