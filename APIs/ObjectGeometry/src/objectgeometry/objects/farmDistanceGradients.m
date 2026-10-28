function [gradients, metadata, valid, filledDistance, filledVoxels] = farmDistanceGradients(distanceField, options)
%FARMDISTANCEGRADIENTS Reusable smoothed derivatives of signed/unsigned distance.
% Inputs:
%   distanceField   Scalar distance field; NaN/Inf mark undefined voxels.
%   options         Optional scalar struct with the fields:
%                   Sigma = nonnegative numeric scalar or vector;
%                   SmoothingOrder = character vector or string scalar;
%                   Normalize = logical scalar;
%                   FlipY = logical scalar;
%                   Spacing = positive numeric three-element vector;
%                   SpacingUnit = character vector or string scalar;
%                   DerivativeUnits = character vector or string scalar;
%                   DistanceUnit = character vector or string scalar;
%                   FillMethod = character vector or string scalar;
% Outputs:
%   gradients       XYZ components stored along the last dimension of a YXZ grid.
%   metadata        Smoothing, derivative and coordinate metadata.
%   valid           Locations with finite nonzero gradient magnitude.
%   filledDistance  Distance field after the requested fill (same numeric class).
%   filledVoxels    Logical mask identifying values assigned by nearest filling.

if nargin < 2
    options = struct();
end
options = farmOGOptions(options, struct('Sigma', 0, 'SmoothingOrder', 'gradient-first', ...
                                       'Normalize', false, 'FlipY', false, 'Spacing', [1 1 1], 'SpacingUnit', 'pixel', ...
                                       'DerivativeUnits', 'voxel', 'DistanceUnit', 'voxel', 'FillMethod', 'none'));
validateattributes(distanceField, {'numeric'}, {'real', 'nonsparse', 'nonempty'});
if ndims(distanceField) > 3 || size(distanceField, 1) < 2 || size(distanceField, 2) < 2
    error('objectgeometry:InvalidDistanceField', 'Use one scalar 2-D/3-D field with X/Y dimensions at least two.');
end
dims = ndims(distanceField);
sigma = double(options.Sigma(:).');
validateattributes(sigma, {'numeric'}, {'real', 'finite', 'vector', 'nonnegative', 'nonempty'});
if isscalar(sigma)
    sigma = repmat(sigma, 1, dims);
end
if dims == 2 && numel(sigma) == 3
    sigma = sigma(1:2);
end
if numel(sigma) ~= dims
    error('objectgeometry:InvalidSigma', 'Use scalar sigma or one per spatial dimension.');
end
if any(sigma == 0) && any(sigma > 0)
    error('objectgeometry:InvalidSigma', 'Use all-zero sigma to disable smoothing, or positive sigma on every axis.');
end
validateattributes(options.Spacing, {'numeric'}, {'real', 'finite', 'vector', 'numel', 3, 'positive'});
validateattributes(options.Normalize, {'logical'}, {'scalar'});
validateattributes(options.FlipY, {'logical'}, {'scalar'});
order = validatestring(options.SmoothingOrder, {'gradient-first', 'distance-first'});
units = validatestring(options.DerivativeUnits, {'voxel', 'physical'});
% Undefined Values %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nearest uses one voxel-coordinate Euclidean transform and MATLAB's tie choice.
% Without filling, NaNs propagate only through affected derivative/smoothing
% neighborhoods; spatial filtering prevents whole-array FFT contamination.
fillMethod = validatestring(options.FillMethod, {'none', 'nearest'});
undefined = ~isfinite(distanceField);
filledDistance = distanceField;
filledVoxels = false(size(distanceField));
if strcmp(fillMethod, 'nearest') && any(undefined(:)) && any(~undefined(:))
    [~, nearestIndices] = bwdist(~undefined);
    nearestIndices = nearestIndices(undefined);
    filledDistance(undefined) = distanceField(nearestIndices);
    filledVoxels = undefined;
    clear nearestIndices
end
data = double(filledDistance);
unfilled = ~isfinite(data);
data(unfilled) = NaN;
forceSpatial = any(unfilled(:));
if all(unfilled(:))
    gradients = nan(size(data, 1), size(data, 2), size(data, 3), dims);
    valid = false(size(data));
else
    if strcmp(order, 'distance-first')
        data = localSmooth(data, sigma, dims, forceSpatial);
    end
    if dims == 3
        [gx, gy, gz] = gradient(data);
        fields = {gx, gy, gz};
    else
        [gx, gy] = gradient(data);
        fields = {gx, gy};
    end
    gradients = zeros(size(data, 1), size(data, 2), size(data, 3), dims);
    spacing = options.Spacing([2 1 3]);
    for i = 1:dims
        field = fields{i};
        if strcmp(order, 'gradient-first')
            field = localSmooth(field, sigma, dims, forceSpatial);
        end
        if strcmp(units, 'physical')
            field = field / spacing(i);
        end
        if options.FlipY && i == 2
            field = -field;
        end
        field(unfilled) = NaN;
        gradients(:, :, :, i) = field;
    end
    magnitude = sqrt(sum(gradients.^2, 4));
    valid = isfinite(magnitude) & magnitude > 0;
    if options.Normalize
        gradients = gradients ./ max(magnitude, realmin);
    end
end

metadata = struct('Size', size(data), 'Axes', 'YXZ', 'ComponentAxes', 'XYZ', ...
                  'Spacing', options.Spacing, 'SpacingUnit', string(options.SpacingUnit), ...
                  'Sigma', sigma, 'SigmaUnit', 'voxel', 'SmoothingOrder', order, 'Normalize', options.Normalize, ...
                  'FlipY', options.FlipY, 'DerivativeUnits', units, 'DistanceUnit', string(options.DistanceUnit), ...
                  'FillMethod', fillMethod, 'UndefinedVoxelCount', nnz(undefined), 'FilledVoxelCount', nnz(filledVoxels), ...
                  'InputFiniteDistanceField', ~any(undefined(:)), 'FiniteDistanceField', ~any(unfilled(:)));
if dims == 2
    metadata.Axes = 'YX';
    metadata.ComponentAxes = 'XY';
end
end

function out = localSmooth(in, sigma, dims, forceSpatial)
% Internal helper.
if all(sigma == 0)
    out = in;
elseif dims == 3 && forceSpatial
    out = imgaussfilt3(in, sigma, 'FilterDomain', 'spatial');
elseif forceSpatial
    out = imgaussfilt(in, sigma, 'FilterDomain', 'spatial');
elseif dims == 3
    out = imgaussfilt3(in, sigma);
else
    out = imgaussfilt(in, sigma);
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMDISTANCEGRADIENTS Reusable smoothed derivatives of signed/unsigned distance.
% INPUT: scalar 2-D or 3-D distance field. OPTIONS.Sigma=0 in voxels;
% scalar or [sigmaY sigmaX sigmaZ] (2-D uses first two). SmoothingOrder=
% 'gradient-first' (historical) or 'distance-first'; Normalize=false;
% FlipY=false (opt-in historical Cartesian conversion); Spacing=[1 1 1];
% SpacingUnit='pixel'; DerivativeUnits='voxel'|'physical'; DistanceUnit='voxel'.
% OUT components XYZ in [Y X Z D], even for 2-D output ([Y X 1 2]).
% VALID is false for zero or nonfinite magnitude. Finite zero gradients stay
% zero when normalized; undefined gradients remain NaN. Sigma=0 bypasses smoothing; each spatial axis must have >=2
% samples except singleton Z (treated as 2-D). No implicit resizing occurs.

% OPTIONS.FillMethod: 'none' (default) retains undefined distances. Gradients
% touching undefined values are NaN and invalid. 'nearest' copies the value of
% the nearest finite voxel using array coordinates, retaining finite originals.
% Assigned values are estimates, not recomputed exact distances. The fourth
% output returns assigned distances; the fifth flags each assigned location.
% No finite source means no filling, NaN gradients, and false validity.
