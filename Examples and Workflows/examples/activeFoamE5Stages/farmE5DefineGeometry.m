function c = farmE5DefineGeometry(c)
%FARME5DEFINEGEOMETRY Calculate boundary-relative distance on an explicit working grid.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.Spacing: intensity-grid spacing in YXZ order.
%   c.BoundaryWorkingSpacing: isotropic spacing in the same physical unit.
%   c.BoundaryDilationRadius: morphological radius in working-grid voxels.
%   c.RegionInterpolation: interpolation for labels and validity masks.
%   c.DistanceInterpolation: interpolation returning distance to the intensity grid.
% Earlier results read:
%   c.Results.Regions: semantic labels from farmE5SegmentObjects.
%   c.Results.TargetSize: intensity-grid dimensions from farmE5LoadData.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.WorkingSpacing, WorkingSize, WorkingRegions: isotropic working grid.
%   c.Results.WorkingDistance, WorkingValid: boundary-distance calculation on that grid.
%   c.Results.Distance, DistanceValid: physical signed distance and validity on the image grid.
%   c.Results.GeometryInfo: constructed boundary counts and finite working-distance count.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
regions = c.Results.Regions;
targetSize = c.Results.TargetSize;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
workingSpacing = c.BoundaryWorkingSpacing;
workingSize = max(2, round(targetSize .* c.Spacing / workingSpacing));
workingRegions = imresize3(regions, workingSize, c.RegionInterpolation);
[workingDistance, ~, ~, primaryBoundary, secondaryBoundary, workingValid] = ...
    farmDistTransFromBoundary(workingRegions == 2, workingRegions == 3, workingRegions == 1, c.BoundaryDilationRadius);
% Proximity comparisons alone can return true when both distances are Inf.
% A usable distance must also be finite; keep undefined distances unchanged.
finiteWorkingDistance = isfinite(workingDistance);
workingValid = workingValid & finiteWorkingDistance;
geometryInfo = struct('PrimaryBoundaryVoxelCount', nnz(primaryBoundary), ...
    'SecondaryBoundaryVoxelCount', nnz(secondaryBoundary), ...
    'FiniteDistanceVoxelCount', nnz(finiteWorkingDistance));
% Signed distance is negative inside and positive outside.
% Keep the calculated zero boundary; do not move it to an alignment peak.
distance = imresize3(workingDistance * workingSpacing, targetSize, c.DistanceInterpolation);
distanceValid = imresize3(workingValid, targetSize, c.RegionInterpolation) & isfinite(distance);

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.WorkingSpacing = workingSpacing;
c.Results.WorkingSize = workingSize;
c.Results.WorkingRegions = workingRegions;
c.Results.WorkingDistance = workingDistance;
c.Results.WorkingValid = workingValid;
c.Results.Distance = distance;
c.Results.DistanceValid = distanceValid;
c.Results.GeometryInfo = geometryInfo;
end
