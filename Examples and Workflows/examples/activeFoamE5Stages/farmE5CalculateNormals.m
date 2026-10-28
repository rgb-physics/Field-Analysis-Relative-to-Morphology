function c = farmE5CalculateNormals(c)
%FARME5CALCULATENORMALS Calculate distance-gradient directions for boundary-normal comparisons.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.ProfileSigma: smoothing in intensity-grid voxels.
%   c.Spacing, SpacingUnit: YXZ sample spacing and its unit.
%   c.GradientDerivativeUnits: units used for spatial derivatives.
%   c.DistanceFillMethod: optional none/nearest setting; missing defaults to none.
% Earlier results read:
%   c.Results.Distance: signed-distance field from farmE5DefineGeometry.
%   c.Results.DistanceValid: optional selection of valid boundary distances.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.Distance, DistanceValid: updated distances and usability after filling.
%   c.Results.DistanceFilled: logical mask of assigned distance values.
%   c.Results.DistanceGradient: gradient arrays with XYZ components in the last dimension.
%   c.Results.GradientInfo: settings, metadata, and FiniteDistanceField/Status diagnostics.
%   c.Results.DirectionValid: locations with usable nonzero gradient directions.
%   With no finite distances, gradients are NaN and all directions are invalid.
%   Filament measurements can still be retained; no image-edge boundary is inferred.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
distance = c.Results.Distance;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fillMethod = 'none';
if isfield(c, 'DistanceFillMethod'), fillMethod = c.DistanceFillMethod; end
originalFinite = isfinite(distance);
distanceValid = originalFinite;
if isfield(c.Results, 'DistanceValid')
    distanceValid = distanceValid & c.Results.DistanceValid;
end
gradientOptions = struct('Sigma', c.ProfileSigma, 'Spacing', c.Spacing, ...
    'SpacingUnit', c.SpacingUnit, 'DerivativeUnits', c.GradientDerivativeUnits, ...
    'DistanceUnit', c.SpacingUnit, 'FillMethod', fillMethod);
[distanceGradient, gradientInfo, directionValid, distance, distanceFilled] = ...
    farmDistanceGradients(distance, gradientOptions);
% Explicitly requested fills may be measured; preserve a flag for each value.
distanceValid = distanceValid | distanceFilled;
directionValid = directionValid & distanceValid;
if ~any(isfinite(distance(:)))
    gradientInfo.Status = 'no-finite-distance';
    fprintf(2, 'No finite boundary distance: retaining filament measurements with invalid normals and alignment.\n');
elseif any(distanceFilled(:))
    gradientInfo.Status = 'computed-with-filled-distance';
    fprintf('Assigned %d undefined distance voxels using nearest finite values.\n', nnz(distanceFilled));
elseif ~all(originalFinite(:))
    gradientInfo.Status = 'computed-with-undefined-distance';
    fprintf('Undefined distances retained; affected normal directions are invalid.\n');
else
    gradientInfo.Status = 'computed';
    fprintf('Boundary distance and surface-normal directions prepared.\n');
end
c.Results.Distance = distance;
c.Results.DistanceValid = distanceValid;
c.Results.DistanceFilled = distanceFilled;

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.DistanceGradient = distanceGradient;
c.Results.GradientInfo = gradientInfo;
c.Results.DirectionValid = directionValid;
end
