function [gradients, metadata, valid] = distanceGradients(distanceField, options)
%DISTANCEGRADIENTS Reusable smoothed derivatives of signed/unsigned distance.
% INPUT: finite scalar 2-D or 3-D distance field. OPTIONS.Sigma=0 in voxels;
% scalar or [sigmaY sigmaX sigmaZ] (2-D uses first two). SmoothingOrder=
% 'gradient-first' (historical) or 'distance-first'; Normalize=false;
% FlipY=false (opt-in historical Cartesian conversion); Spacing=[1 1 1];
% SpacingUnit='pixel'; DerivativeUnits='voxel'|'physical'; DistanceUnit='voxel'.
% OUT components XYZ in [Y X Z D], even for 2-D output ([Y X 1 2]).
% VALID is false wherever magnitude is zero. Normalized invalid values are
% zero, not NaN. Sigma=0 bypasses smoothing; each spatial axis must have >=2
% samples except singleton Z (treated as 2-D). No implicit resizing occurs.
if nargin<2, options=struct(); end
options=objectgeometry.internal.options(options,struct('Sigma',0,'SmoothingOrder','gradient-first', ...
    'Normalize',false,'FlipY',false,'Spacing',[1 1 1],'SpacingUnit','pixel', ...
    'DerivativeUnits','voxel','DistanceUnit','voxel'));
validateattributes(distanceField,{'numeric'},{'real','finite','nonsparse','nonempty'});
if ndims(distanceField)>3||size(distanceField,1)<2||size(distanceField,2)<2
    error('objectgeometry:InvalidDistanceField','Use one scalar 2-D/3-D field with X/Y dimensions at least two.');
end
dims=ndims(distanceField); sigma=double(options.Sigma(:).');
validateattributes(sigma,{'numeric'},{'real','finite','vector','nonnegative','nonempty'});
if isscalar(sigma), sigma=repmat(sigma,1,dims); end
if dims==2&&numel(sigma)==3, sigma=sigma(1:2); end
if numel(sigma)~=dims, error('objectgeometry:InvalidSigma','Use scalar sigma or one per spatial dimension.'); end
if any(sigma==0)&&any(sigma>0)
    error('objectgeometry:InvalidSigma','Use all-zero sigma to disable smoothing, or positive sigma on every axis.');
end
validateattributes(options.Spacing,{'numeric'},{'real','finite','vector','numel',3,'positive'});
validateattributes(options.Normalize,{'logical'},{'scalar'});
validateattributes(options.FlipY,{'logical'},{'scalar'});
order=validatestring(options.SmoothingOrder,{'gradient-first','distance-first'});
units=validatestring(options.DerivativeUnits,{'voxel','physical'});
data=double(distanceField);
if strcmp(order,'distance-first'), data=localSmooth(data,sigma,dims); end
if dims==3, [gx,gy,gz]=gradient(data); fields={gx,gy,gz};
else, [gx,gy]=gradient(data); fields={gx,gy}; end
gradients=zeros(size(data,1),size(data,2),size(data,3),dims);
spacing=options.Spacing([2 1 3]);
for i=1:dims
    field=fields{i};
    if strcmp(order,'gradient-first'), field=localSmooth(field,sigma,dims); end
    if strcmp(units,'physical'), field=field/spacing(i); end
    if options.FlipY&&i==2, field=-field; end
    gradients(:,:,:,i)=field;
end
magnitude=sqrt(sum(gradients.^2,4)); valid=magnitude>0;
if options.Normalize, gradients=gradients./max(magnitude,realmin); end
metadata=struct('Size',size(data),'Axes','YXZ','ComponentAxes','XYZ', ...
    'Spacing',options.Spacing,'SpacingUnit',string(options.SpacingUnit), ...
    'Sigma',sigma,'SigmaUnit','voxel','SmoothingOrder',order,'Normalize',options.Normalize, ...
    'FlipY',options.FlipY,'DerivativeUnits',units,'DistanceUnit',string(options.DistanceUnit));
if dims==2, metadata.Axes='YX'; metadata.ComponentAxes='XY'; end
end
function out=localSmooth(in,sigma,dims)
if all(sigma==0)
    out=in;
elseif dims==3
    out=imgaussfilt3(in,sigma);
else
    out=imgaussfilt(in,sigma);
end
end
