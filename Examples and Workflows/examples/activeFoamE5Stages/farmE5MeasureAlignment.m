function c = farmE5MeasureAlignment(c)
%FARME5MEASUREALIGNMENT Compare filament directions with the sampled surface-normal directions.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.AlignmentPlane: components used for projected 2-D alignment.
%   c.MaxZComponent: optional normal-component limit for the projected comparison.
%   c.MinFilamentLength, MinAspectRatio: thresholds for the Selected flag.
% Earlier results read:
%   c.Results.Properties: measurements extended by farmE5SampleFields; requires
%   ScaledDirectors, DistanceGradient, validity flags, ProjectedExtent, and ScaledAspectRatios.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.Properties: table extended with Order3D, Order2D, SignedAngle2D, and Selected.
%   c.Results.Alignment3D, Alignment2D: alignment results for finite direction pairs.
%   Order3D = (3*cos(theta)^2 - 1)/2; isotropic mean is 0. All rows are retained.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
properties = c.Results.Properties;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
directors = properties.ScaledDirectors;
reference = properties.DistanceGradient;
finiteDirections = all(isfinite(directors), 2) & all(isfinite(reference), 2);
alignment3D = farmNematicAlignment(directors(finiteDirections, :), reference(finiteDirections, :));
alignment2D = farmNematicAlignment(directors(finiteDirections, :), reference(finiteDirections, :), ...
    struct('Plane', c.AlignmentPlane, 'MaxNormalComponent', c.MaxZComponent));
properties.Order3D = nan(height(properties), 1);
properties.Order2D = nan(height(properties), 1);
properties.SignedAngle2D = nan(height(properties), 1);
properties.Order3D(finiteDirections) = alignment3D.Order;
properties.Order2D(finiteDirections) = alignment2D.Order;
properties.SignedAngle2D(finiteDirections) = alignment2D.SignedAngle;
properties.Selected = properties.ReferenceValid & properties.ReferenceDirectionValid & ...
    properties.ProjectedExtent >= c.MinFilamentLength & properties.ScaledAspectRatios >= c.MinAspectRatio;

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.Properties = properties;
c.Results.Alignment3D = alignment3D;
c.Results.Alignment2D = alignment2D;
end
