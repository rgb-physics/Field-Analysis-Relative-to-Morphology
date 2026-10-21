function geometry = farmGenerateGeometry(input, type, options)
%FARMGENERATEGEOMETRY Optional index-based geometry independent of measurements.
% Inputs:
%   input           Object input accepted by farmPrepareObjects.
%   type            Requested geometry type: 'boundary' or 'skeleton'.
%   options         Optional scalar struct with the fields:
%                   Identity = scalar struct;
%                   Method = character vector or string scalar;
%                   Sigma = positive numeric scalar;
%                   GradientCutoff = numeric scalar;
%                   Hessian = logical scalar;
%                   SheetCombination = character vector or string scalar;
%                   SampleFraction = numeric scalar;
%                   DistanceCutoff = numeric scalar;
%                   LayerMean = numeric scalar;
%                   LayerWidth = numeric scalar;
% Outputs:
%   geometry        Geometry construct containing component records, indices and grid metadata.

if nargin < 3
    options = struct();
end
options = farmOGOptions(options, struct('Identity', struct(), 'Method', '', ...
                                       'Sigma', 1, 'GradientCutoff', 0.2, 'Hessian', false, 'SheetCombination', 'intersection', ...
                                       'SampleFraction', 0.5, 'DistanceCutoff', 2, 'LayerMean', 0, 'LayerWidth', 1));
type = validatestring(type, {'skeleton', 'boundary'});
objects = farmPrepareObjects(input, options.Identity);
dims = numel(objects.Grid.Size);
method = char(string(options.Method));
if isempty(method)
    if strcmp(type, 'skeleton')
        method = 'blob';
    else
        method = 'shell';
    end
end
if strcmp(type, 'skeleton')
    method = validatestring(method, {'blob', 'sheet', 'sheet-sampled'});
    if dims ~= 3
        error('objectgeometry:SkeletonDimensions', 'Historical skeleton methods require 3-D input.');
    end
else
    method = validatestring(method, {'shell'});
end
validateattributes(options.Sigma, {'numeric'}, {'real', 'finite', 'scalar', 'nonnegative'});
validateattributes(options.GradientCutoff, {'numeric'}, {'real', 'finite', 'scalar', 'nonnegative'});
validateattributes(options.Hessian, {'logical'}, {'scalar'});
validateattributes(options.SampleFraction, {'numeric'}, {'real', 'finite', 'scalar', 'nonnegative'});
validateattributes(options.DistanceCutoff, {'numeric'}, {'real', 'finite', 'scalar', 'nonnegative'});
validateattributes(options.LayerMean, {'numeric'}, {'real', 'finite', 'scalar'});
validateattributes(options.LayerWidth, {'numeric'}, {'real', 'finite', 'scalar', 'nonnegative'});
if strcmp(type, 'skeleton') && strcmp(method, 'blob')
    validateattributes(options.Sigma, {'numeric'}, {'integer', 'positive'});
end
combination = validatestring(options.SheetCombination, {'intersection', 'union'});
prototype = struct('DatasetID', objects.DatasetID, 'Frame', objects.Frame, 'ObjectID', 0, ...
                   'ComponentID', 0, 'Indices', [], 'Status', 'computed', 'Fallback', []);
records = repmat(prototype, 0, 1);
for objectIndex = 1:numel(objects.ObjectIDs)
    mask = false(objects.Grid.Size);
    mask(objects.Components.PixelIdxList{objectIndex}) = true;
    cc = bwconncomp(mask, objects.Components.Connectivity);
    for componentIndex = 1:cc.NumObjects
        indices = cc.PixelIdxList{componentIndex};
        coordinates = cell(1, dims);
        [coordinates{:}] = ind2sub(objects.Grid.Size, indices);
        points = cat(2, coordinates{:});
        low = min(points, [], 1);
        high = max(points, [], 1);
        halo = max(3, ceil(abs(options.LayerMean) + options.LayerWidth + 4 * options.Sigma));
        localSize = high - low + 1 + 2 * halo;
        local = false(localSize);
        shifted = points - low + 1 + halo;
        subs = num2cell(shifted, 1);
        local(sub2ind(localSize, subs{:})) = true;
        if strcmp(type, 'boundary')
            output = farmReturnSmoothBoundsBW(local, ...
                                              options.LayerMean, options.LayerWidth, options.Sigma);
        else
            switch method
                case 'blob'
                    [~, output] = farmSkel3DBlobs(local, ...
                                                 options.GradientCutoff, options.Sigma, double(options.Hessian));
                case 'sheet'
                    [unionMask, intersectionMask] = farmSkel3Dfrom2D(local);
                    if strcmp(combination, 'union')
                        output = unionMask;
                    else
                        output = intersectionMask;
                    end
                case 'sheet-sampled'
                    output = farmSkel3DPop(local, options.SampleFraction, options.DistanceCutoff);
            end
        end
        localIndices = find(output);
        sub = cell(1, dims);
        [sub{:}] = ind2sub(localSize, localIndices);
        original = cat(2, sub{:}) + low - 1 - halo;
        inside = all(original >= 1 & original <= objects.Grid.Size, 2);
        original = original(inside, :);
        sub = num2cell(original, 1);
        globalIndices = sub2ind(objects.Grid.Size, sub{:});
        record = prototype;
        record.ObjectID = objects.ObjectIDs(objectIndex);
        record.ComponentID = componentIndex;
        record.Indices = unique(globalIndices(:));
        if isempty(record.Indices)
            record.Status = 'empty';
            if strcmp(type, 'skeleton')
                single = struct('Connectivity', cc.Connectivity, 'ImageSize', cc.ImageSize, ...
                                'NumObjects', 1, 'PixelIdxList', {{indices}});
                props = regionprops3(single, {'Centroid', 'PrincipalAxisLength', 'EigenVectors'});
                record.Fallback = table2struct(props);
            end
        end
        records(end + 1, 1) = record; %#ok<AGROW>
    end
end
geometry = struct('Type', type, 'Method', method, 'Records', records, ...
                  'Grid', objects.Grid, 'SourceGrid', objects.SourceGrid, 'Transform', objects.Transform, ...
                  'Options', options, 'DatasetID', objects.DatasetID, 'Frame', objects.Frame);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGENERATEGEOMETRY Optional index-based geometry independent of measurements.
% TYPE='skeleton' or 'boundary'. Each parent ID retains all disconnected
% entities; representations are generated per connected component. OUTPUT
% has Records keyed by DatasetID/Frame/ObjectID/ComponentID, Grid, SourceGrid,
% Transform and Options. Indices refer to CURRENT grid; never rounded XYZ.
%
% OPTIONS.Identity=struct(); Method='' -> skeleton:'blob', boundary:'shell';
% skeleton methods: 'blob' (skel3DBlobs), 'sheet' (skel3Dfrom2D union/intersection),
% 'sheet-sampled' (skel3DPop). Sigma=1, GradientCutoff=0.2, Hessian=false,
% SheetCombination='intersection'|'union', SampleFraction=0.5, DistanceCutoff=2.
% Boundary: LayerMean=0, LayerWidth=1, Sigma=1; uses returnSmoothBoundsBW.
% Empty skeletons retain Status='empty' and centroid/principal-axis fallback.
% Non-requested geometry is never created. Blob/sheet skeletons require 3-D.
% Each operation runs in a component bounding box with a background halo,
% isolating components even when the parent ID represents a disconnected lineage.
%
% RELEASE STATUS
% -------------------------------------------------------------------------
% Boundary and blob-skeleton operations remain supported. Sheet and
% sheet-sampled modes are preserved but deferred pending scientific review.
