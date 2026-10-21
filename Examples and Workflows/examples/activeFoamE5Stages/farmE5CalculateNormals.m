function c = farmE5CalculateNormals(c)
%FARME5CALCULATENORMALS Calculate distance-gradient directions for boundary-normal comparisons.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.ProfileSigma: smoothing in intensity-grid voxels.
%   c.Spacing, SpacingUnit: YXZ sample spacing and its unit.
%   c.GradientDerivativeUnits: units used for spatial derivatives.
% Earlier results read:
%   c.Results.Distance: finite signed-distance field from farmE5DefineGeometry.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.DistanceGradient: gradient arrays with XYZ components in the last dimension.
%   c.Results.GradientInfo: calculation settings and metadata.
%   c.Results.DirectionValid: locations with usable nonzero gradient directions.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
distance = c.Results.Distance;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gradientOptions = struct('Sigma', c.ProfileSigma, 'Spacing', c.Spacing, ...
    'SpacingUnit', c.SpacingUnit, 'DerivativeUnits', c.GradientDerivativeUnits, 'DistanceUnit', c.SpacingUnit);
[distanceGradient, gradientInfo, directionValid] = farmDistanceGradients(distance, gradientOptions);
fprintf('Boundary distance and surface-normal directions prepared.\n');

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.DistanceGradient = distanceGradient;
c.Results.GradientInfo = gradientInfo;
c.Results.DirectionValid = directionValid;
end
