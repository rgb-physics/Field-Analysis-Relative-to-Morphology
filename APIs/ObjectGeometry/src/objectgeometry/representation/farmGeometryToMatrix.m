function [matrix, grid, info] = farmGeometryToMatrix(input, varargin)
%FARMGEOMETRYTOMATRIX Render prepared objects or generated voxel-index geometry.
% Inputs:
%   input           Prepared objects or generated index-based geometry.
%   varargin        Rendering options as a struct or name/value pairs.
% Outputs:
%   matrix          Mask or label rendering of the selected geometry.
%   grid            Current output grid metadata.
%   info            Rendering settings, selection counts and provenance.

options = farmParseOptions(struct('ObjectIDs', [], ...
                                  'OutputType', 'mask', 'OverlapPolicy', 'error', 'IncludeFallback', false), varargin{:});
options.OutputType = validatestring(options.OutputType, {'mask', 'labels'});
options.OverlapPolicy = validatestring(options.OverlapPolicy, {'error', 'first', 'last'});
validateattributes(options.IncludeFallback, {'logical'}, {'scalar'});
if ~isempty(options.ObjectIDs)
    validateattributes(options.ObjectIDs, {'numeric'}, {'vector', 'integer', 'finite', 'positive', '<=', flintmax});
end
if ~isstruct(input) || ~isscalar(input) || ~isfield(input, 'Grid')
    error('objectgeometry:RepresentationInput', 'Provide prepared objects or generated geometry with Grid.');
end
grid = farmOGRepresentationGrid(input.Grid);
if isfield(input, 'ObjectGeometryVersion')
    ids = input.ObjectIDs(:);
    lists = input.Components.PixelIdxList(:);
    fallbacks = cell(numel(ids), 1);
elseif isfield(input, 'Records') && isfield(input, 'Type')
    records = input.Records;
    ids = reshape([records.ObjectID], [], 1);
    lists = reshape({records.Indices}, [], 1);
    fallbacks = cell(numel(ids), 1);
    if isfield(records, 'Fallback')
        fallbacks = reshape({records.Fallback}, [], 1);
    end
else
    error('objectgeometry:RepresentationInput', 'Unsupported geometry representation.');
end
if numel(ids) ~= numel(lists)
    error('objectgeometry:RepresentationInput', 'IDs and index groups must agree.');
end
validateattributes(ids, {'numeric'}, {'integer', 'finite', 'real', 'positive', '<=', flintmax});
selected = true(numel(ids), 1);
if ~isempty(options.ObjectIDs)
    selected = ismember(ids, options.ObjectIDs);
end
if strcmp(options.OutputType, 'mask')
    matrix = false(grid.Size);
else
    matrix = zeros(grid.Size);
end
fallbackCount = 0;
for k = find(selected).'
    indices = lists{k};
    if isempty(indices) && options.IncludeFallback && isstruct(fallbacks{k}) && isfield(fallbacks{k}, 'Centroid')
        ro = farmOGRasterOptions;
        [indices, ~] = farmOGRasterIndices(fallbacks{k}.Centroid, grid, ro);
        fallbackCount = fallbackCount + double(~isempty(indices));
    end
    if isempty(indices)
        continue
    end
    validateattributes(indices, {'numeric'}, {'vector', 'integer', 'finite', 'real', 'positive', '<=', prod(grid.Size)});
    indices = unique(indices(:));
    if strcmp(options.OutputType, 'mask')
        matrix(indices) = true;
        continue
    end
    conflict = matrix(indices) ~= 0 & matrix(indices) ~= ids(k);
    if any(conflict) && strcmp(options.OverlapPolicy, 'error')
        error('objectgeometry:GeometryOverlap', 'Different object IDs overlap. Choose an explicit OverlapPolicy.');
    end
    if strcmp(options.OverlapPolicy, 'first')
        indices = indices(matrix(indices) == 0);
    end
    matrix(indices) = ids(k);
end
info = struct('Options', options, 'RenderedObjectIDs', unique(ids(selected), 'stable'), ...
              'IncludedFallbackCount', fallbackCount, 'RasterVoxelCount', nnz(matrix));
if isfield(input, 'SourceGrid')
    info.SourceGrid = input.SourceGrid;
end
if isfield(input, 'Transform')
    info.Transform = input.Transform;
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGEOMETRYTOMATRIX Render prepared objects or generated voxel-index geometry.
% Options: ObjectIDs=[] selects all; OutputType='mask'|'labels' (double IDs);
% OverlapPolicy='error'|'first'|'last' for different IDs sharing voxels;
% IncludeFallback=false. Mask output is logical union, not filled boundaries.
% Disconnected components keep their parent ID. Stored grid/calibration retained.
% IncludeFallback renders rounded XYZ Centroid only for empty geometry records.
% No coordinate rescaling, Gaussian broadening, interpolation or hole filling.
