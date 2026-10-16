function result = farmLocalInertia(occupancy, indices, options)
%FARMLOCALINERTIA Historical neighborhood inertia at any user-selected indices.
% Inputs:
%   occupancy       Foreground occupancy array used for neighborhood calculations.
%   indices         Linear voxel locations at which descriptors are requested.
%   options         Operation settings struct.
% Outputs:
%   result          Requested-index neighborhood-inertia descriptors and calculation metadata.

if nargin < 3
    options = struct();
end
o = farmOGOptions(options, struct('Radius', 18, 'Sigma', 3, ...
                                 'Spacing', [1 1 1], 'SpacingUnit', 'voxel', 'SampleLimit', Inf, 'ReturnTensors', false, 'BatchSize', 32));
validateattributes(occupancy, {'numeric', 'logical'}, {'real', 'finite', 'nonempty'});
if ndims(occupancy) ~= 3
    error('objectgeometry:Dimensions', 'Use a 3D occupancy mask.');
end
validateattributes(o.Radius, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'});
validateattributes(o.Sigma, {'numeric'}, {'scalar', 'nonnegative', 'finite'});
validateattributes(o.Spacing, {'numeric'}, {'vector', 'numel', 3, 'positive', 'finite'});
validateattributes(o.SampleLimit, {'numeric'}, {'scalar', 'positive'});
if ~isinf(o.SampleLimit) && o.SampleLimit ~= fix(o.SampleLimit)
    error('objectgeometry:SampleLimit', 'Use an integer or Inf.');
end
validateattributes(o.ReturnTensors, {'logical'}, {'scalar'});
validateattributes(o.BatchSize, {'numeric'}, {'scalar', 'integer', 'positive', 'finite'});
indices = indices(:);
if ~isempty(indices)
    validateattributes(indices, {'numeric'}, {'integer', 'positive', 'finite', '<=', numel(occupancy)});
end
indices = unique(double(indices), 'stable');
n = numel(indices);
chosen = (1:n)';
if n > o.SampleLimit
    chosen = sort(randperm(n, o.SampleLimit))';
end
r = o.Radius;
padded = padarray(double(logical(occupancy)), [r r r], 'symmetric');
if o.Sigma > 0
    padded = imgaussfilt3(padded, o.Sigma);
end
[y, x, z] = ndgrid((-r:r) * o.Spacing(1), (-r:r) * o.Spacing(2), (-r:r) * o.Spacing(3));
kernels = {x.^2 + z.^2, y.^2 + z.^2, x.^2 + y.^2, -y .* x, -y .* z, -x .* z};
[dy, dx, dz] = ndgrid(-r:r);
offsets = dy(:) + size(padded, 1) * dx(:) + size(padded, 1) * size(padded, 2) * dz(:);
[y0, x0, z0] = ind2sub(size(occupancy), indices);
centers = sub2ind(size(padded), y0 + r, x0 + r, z0 + r);
eigvals = NaN(n, 3);
fa = NaN(n, 1);
ratio = NaN(n, 1);
if o.ReturnTensors
    tensors = NaN(3, 3, n);
end
kernelMatrix = zeros(numel(offsets), 6);
for k = 1:6
    kernelMatrix(:, k) = kernels{k}(:);
end
% Bounded matrix batches exploit MATLAB multiplication without N-by-window storage.
for first = 1:o.BatchSize:numel(chosen)
    rows = chosen(first:min(first + o.BatchSize - 1, numel(chosen)));
    values = padded(offsets + centers(rows)');
    momentsBatch = values' * kernelMatrix;
    for j = 1:numel(rows)
        row = rows(j);
        moments = momentsBatch(j, :);
        tensor = [moments(1) moments(4) moments(5); moments(4) moments(2) moments(6); moments(5) moments(6) moments(3)];
        ev = eig(tensor);
        eigvals(row, :) = ev';
        denom = sqrt(sum(ev.^2));
        if denom > 0
            fa(row) = sqrt(3 / 2) * sqrt(sum((ev - mean(ev)).^2)) / denom;
        end
        if max(abs(ev)) > 0
            ratio(row) = min(abs(ev)) / max(abs(ev));
        end
        if o.ReturnTensors
            tensors(:, :, row) = tensor;
        end
    end
end
computed = false(n, 1);
computed(chosen) = true;
result = struct('Indices', indices, 'Computed', computed, 'Eigenvalues', eigvals, ...
                'FractionalAnisotropy', fa, 'EigenvalueRatio', ratio, 'Options', o, ...
                'Grid', struct('Size', size(occupancy), 'Axes', 'YXZ', 'Spacing', o.Spacing, 'SpacingUnit', o.SpacingUnit));
if o.ReturnTensors
    result.Tensors = tensors;
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMLOCALINERTIA Historical neighborhood inertia at any user-selected indices.
% Uses smoothed total occupancy (neighbors included), mirrored padding,
% and [Y X Z] coordinate kernels from blobPropsFromTrajs_R_Inertia.
% Inertia is not vector covariance or global regionprops principal axes.
% All requested indices retained; optional SampleLimit selects calculation
% locations. Uncalculated descriptors are NaN. No fallback is inferred.
