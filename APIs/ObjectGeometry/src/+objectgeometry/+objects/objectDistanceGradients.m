function [gradients, distanceField, metadata, valid] = objectDistanceGradients(mask, options)
%OBJECTDISTANCEGRADIENTS Build a distance field and use distanceGradients.
% OPTIONS.DistanceType='signed'|'interior'|'exterior'. Signed uses the user's
% signedBWDist convention: object boundary zero, deeper interior negative.
% Interior=bwdist(~mask); exterior=bwdist(mask). Distance values remain in
% voxel units (anisotropic distance correction deferred). Remaining options
% are those of distanceGradients. Empty/full masks have no finite opposite
% phase: return their distance field, NaN gradients and false validity.
if nargin<2, options=struct(); end
type='signed';
if isfield(options,'DistanceType'), type=options.DistanceType; options=rmfield(options,'DistanceType'); end
type=validatestring(type,{'signed','interior','exterior'});
validateattributes(mask,{'numeric','logical'},{'real','finite','nonsparse','nonempty'});
if ndims(mask)>3||any(mask(:)~=0&mask(:)~=1)
    error('objectgeometry:InvalidMask','Use one binary spatial mask.');
end
mask=logical(mask);
switch type
    case 'signed', distanceField=sharedutilities.numerics.signedBWDist(mask);
    case 'interior', distanceField=bwdist(~mask);
    case 'exterior', distanceField=bwdist(mask);
end
if all(isfinite(distanceField(:)))
    [gradients,metadata,valid]=objectgeometry.objects.distanceGradients(distanceField,options);
else
    [gradients,metadata,valid]=objectgeometry.objects.distanceGradients(zeros(size(mask)),options);
    gradients(:)=NaN; valid(:)=false;
end
metadata.DistanceType=type; metadata.DistanceUnit='voxel';
metadata.FiniteDistanceField=all(isfinite(distanceField(:)));
end
