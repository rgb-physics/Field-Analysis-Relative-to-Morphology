function [gradients, distanceField, metadata, valid] = farmObjectDistanceGradients(mask, options)
%FARMOBJECTDISTANCEGRADIENTS Build a distance field and use distanceGradients.
% Inputs:
%   mask            Binary foreground matrix or volume.
%   options         Operation settings struct.
% Outputs:
%   gradients       XYZ gradient components on the current grid.
%   distanceField   Requested signed/interior/exterior voxel-distance field.
%   metadata        Distance and derivative metadata.
%   valid           Gradient validity selection.

if nargin < 2
    options = struct();
end
type = 'signed';
if isfield(options, 'DistanceType')
    type = options.DistanceType;
    options = rmfield(options, 'DistanceType');
end
type = validatestring(type, {'signed', 'interior', 'exterior'});
validateattributes(mask, {'numeric', 'logical'}, {'real', 'finite', 'nonsparse', 'nonempty'});
if ndims(mask) > 3 || any(mask(:) ~= 0 & mask(:) ~= 1)
    error('objectgeometry:InvalidMask', 'Use one binary spatial mask.');
end
mask = logical(mask);
switch type
    case 'signed'
        distanceField = farmSignedBWDist(mask);
    case 'interior'
        distanceField = bwdist(~mask);
    case 'exterior'
        distanceField = bwdist(mask);
end
if all(isfinite(distanceField(:)))
    [gradients, metadata, valid] = farmDistanceGradients(distanceField, options);
else
    [gradients, metadata, valid] = farmDistanceGradients(zeros(size(mask)), options);
    gradients(:) = NaN;
    valid(:) = false;
end
metadata.DistanceType = type;
metadata.DistanceUnit = 'voxel';
metadata.FiniteDistanceField = all(isfinite(distanceField(:)));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMOBJECTDISTANCEGRADIENTS Build a distance field and use distanceGradients.
% OPTIONS.DistanceType='signed'|'interior'|'exterior'. Signed uses the user's
% signedBWDist convention: object boundary zero, deeper interior negative.
% Interior=bwdist(~mask); exterior=bwdist(mask). Distance values remain in
% voxel units (anisotropic distance correction deferred). Remaining options
% are those of distanceGradients. Empty/full masks have no finite opposite
% phase: return their distance field, NaN gradients and false validity.
