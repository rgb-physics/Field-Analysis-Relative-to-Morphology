function c = farmE5SampleFields(c)
%FARME5SAMPLEFIELDS Sample boundary fields at one rounded centroid voxel per filament.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.DatasetID, Frame: identity assigned to each centroid selection.
%   c.ScalarSamplingStatistics: scalar statistics; retain Mean for subsequent columns.
%   c.VectorSamplingStatistics: vector statistics; retain MeanVector.
% Earlier results read:
%   c.Results.Properties: filament measurements, including XYZ Centroid, from farmE5MeasureFilaments.
%   c.Results.TargetSize: YXZ field dimensions from farmE5LoadData.
%   c.Results.Regions: semantic labels from farmE5SegmentObjects.
%   c.Results.Distance, DistanceValid: fields from geometry/normal calculation.
%   c.Results.DistanceFilled: optional logical mask identifying assigned distances.
%   c.Results.DistanceGradient, DirectionValid: fields from farmE5CalculateNormals.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.Properties: table extended with centroid indices, distance, region, validity, and gradient.
%   c.Results.Properties.BoundaryDistanceFilled: true where the centroid distance was assigned by filling.
%   c.Results.CentroidSupport: prepared single-voxel selections with object IDs.
%   c.Results.SamplingDiagnostics: keyed field-query statistics and validity counts.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
frame = c.Frame;
properties = c.Results.Properties;
targetSize = c.Results.TargetSize;
regions = c.Results.Regions;
distance = c.Results.Distance;
distanceValid = c.Results.DistanceValid;
distanceGradient = c.Results.DistanceGradient;
directionValid = c.Results.DirectionValid;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
centroidXYZ = round(properties.Centroid);
centroidIndices = sub2ind(targetSize, centroidXYZ(:, 2), centroidXYZ(:, 1), centroidXYZ(:, 3));
supportOptions = struct('Type', 'indices', 'ObjectIDs', properties.ObjectID, ...
    'DatasetID', c.DatasetID, 'Frame', frame, 'Name', 'FilamentCentroids');
centroidSupport = farmPrepareSupport(num2cell(centroidIndices), targetSize, supportOptions);
% Mean at a single selected voxel is that voxel's value. Keep the
% complete query results as diagnostics, separately from measurements.
distanceSamples = farmQueryField(distance, centroidSupport, c.ScalarSamplingStatistics, struct('FieldName', 'BoundaryDistance'));
regionSamples = farmQueryField(regions, centroidSupport, c.ScalarSamplingStatistics, struct('FieldName', 'RegionClass'));
referenceSamples = farmQueryField(distanceValid, centroidSupport, c.ScalarSamplingStatistics, struct('FieldName', 'ReferenceValid'));
directionSamples = farmQueryField(directionValid, centroidSupport, c.ScalarSamplingStatistics, struct('FieldName', 'DirectionValid'));
gradientFields = struct('X', distanceGradient(:, :, :, 1), ...
    'Y', distanceGradient(:, :, :, 2), 'Z', distanceGradient(:, :, :, 3));
gradientSamples = farmQueryVectorField(gradientFields, centroidSupport, c.VectorSamplingStatistics, ...
    struct('FieldName', 'Gradient', 'ComponentNames', {{'X', 'Y', 'Z'}}));
samplingDiagnostics = farmAttachResults(distanceSamples, regionSamples);
samplingDiagnostics = farmAttachResults(samplingDiagnostics, referenceSamples);
samplingDiagnostics = farmAttachResults(samplingDiagnostics, directionSamples);
samplingDiagnostics = farmAttachResults(samplingDiagnostics, gradientSamples);
properties.CoMIndices = centroidIndices;
% Queries return double statistics; preserve the distance field's
% numeric type in the Workflow 2 observation column.
properties.BoundaryDistance = cast(distanceSamples.BoundaryDistance_Mean, 'like', distance);
properties.RegionClass = uint8(regionSamples.RegionClass_Mean);
properties.ReferenceValid = logical(referenceSamples.ReferenceValid_Mean);
properties.ReferenceDirectionValid = logical(directionSamples.DirectionValid_Mean);
properties.DistanceGradient = gradientSamples.Gradient_MeanVector;
properties.BoundaryDistanceFilled = false(height(properties), 1);
if isfield(c.Results, 'DistanceFilled')
    properties.BoundaryDistanceFilled = c.Results.DistanceFilled(centroidIndices);
end

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.Properties = properties;
c.Results.CentroidSupport = centroidSupport;
c.Results.SamplingDiagnostics = samplingDiagnostics;
end
