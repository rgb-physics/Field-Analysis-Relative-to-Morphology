function result = farmNematicAlignment(directors, reference, options)
%FARMNEMATICALIGNMENT Compare axial directors with reference directions.
% Inputs:
%   directors       N-by-2 or N-by-3 director rows.
%   reference       Reference directions in the same component convention.
%   options         Optional scalar struct with the fields:
%                   Plane = numeric two-element vector or [];
%                   MaxNormalComponent = numeric scalar or [];
% Outputs:
%   result          Axial alignment values, angles and validity selections.

if nargin < 3
    options = struct();
end
options = farmOGOptions(options, struct('Plane', [], 'MaxNormalComponent', []));
validateattributes(directors, {'numeric'}, {'real', 'finite', '2d'});
validateattributes(reference, {'numeric'}, {'real', 'finite', '2d'});
d = size(directors, 2);
n = size(directors, 1);
if ~ismember(d, [2 3]) || size(reference, 2) ~= d || ~ismember(size(reference, 1), [1 n])
    error('objectgeometry:VectorMismatch', 'Use Nx2/Nx3 directors and NxD or 1xD reference.');
end
if size(reference, 1) == 1
    reference = repmat(reference, n, 1);
end
u = double(directors);
v = double(reference);
magU = vecnorm(u, 2, 2);
magV = vecnorm(v, 2, 2);
valid = magU > 0 & magV > 0;
u = u ./ max(magU, realmin);
v = v ./ max(magV, realmin);
plane = options.Plane;
if ~isempty(plane)
    validateattributes(plane, {'numeric'}, {'vector', 'numel', 2, 'integer', 'positive', '<=', d});
    if plane(1) == plane(2)
        error('objectgeometry:InvalidPlane', 'Plane axes must be distinct.');
    end
    if ~isempty(options.MaxNormalComponent)
        validateattributes(options.MaxNormalComponent, {'numeric'}, {'scalar', 'real', 'finite', '>=', 0, '<=', 1});
        if d ~= 3
            error('objectgeometry:InvalidPlane', 'Normal selection requires a 3-D projected plane.');
        end
        normal = setdiff(1:3, plane);
        valid = valid & abs(u(:, normal)) <= options.MaxNormalComponent;
    end
    u = u(:, plane);
    v = v(:, plane);
    d = 2;
    a = vecnorm(u, 2, 2);
    b = vecnorm(v, 2, 2);
    valid = valid & a > 0 & b > 0;
    u = u ./ max(a, realmin);
    v = v ./ max(b, realmin);
elseif ~isempty(options.MaxNormalComponent)
    error('objectgeometry:InvalidPlane', 'Specify a projection plane for normal selection.');
end
dotValue = max(-1, min(1, sum(u .* v, 2)));
if d == 2
    order = 2 * dotValue.^2 - 1;
else
    order = (3 * dotValue.^2 - 1) / 2;
end
unsigned = acos(abs(dotValue));
signed = nan(n, 1);
if d == 2
    angle = atan2(v(:, 1) .* u(:, 2) - v(:, 2) .* u(:, 1), dotValue);
    signed = mod(angle + pi / 2, pi) - pi / 2;
end
order(~valid) = NaN;
unsigned(~valid) = NaN;
signed(~valid) = NaN;
dotValue(~valid) = NaN;
result = struct('Order', order, 'UnsignedAngle', unsigned, 'SignedAngle', signed, ...
                'Dot', dotValue, 'Valid', valid, 'Dimension', d, 'Plane', plane, 'Options', options);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMNEMATICALIGNMENT Normalize -> optionally project -> normalize -> dot -> order.
% Reuses Display_AvgAlign_FromRBins formulas, with sign-invariant filtering.
% INPUT Nx2 or Nx3 vectors in the SAME coordinate convention, reference NxD
% or 1xD. OPTIONS.Plane=[] for full dimension, [1 2] etc for projection;
% MaxNormalComponent=[] optionally excludes 3-D directors with abs(normal)
% exceeding this cutoff BEFORE projection. Only used with a 3-D plane.
% Zero vectors/projections are invalid and produce NaN. Signed angle is only
% defined in an ordered 2-D plane. No polar orientation/head-tail inference.
