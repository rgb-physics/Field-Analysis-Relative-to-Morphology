function tests = testActiveFoamBoundaryStages
%TESTACTIVEFOAMBOUNDARYSTAGES Missing boundaries retain rows with invalid measurements.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(repo);
farmSetup('IncludeExamples', true);
tests = functiontests(localfunctions);
end

function testMissingBoundaryRetainsFilaments(t)
c = localConfiguration;
sz = c.Results.TargetSize;
noWall = repmat(uint8(3), sz);
noWall(:, 1:4, :) = 1;
regions = {ones(sz, 'uint8'), repmat(uint8(2), sz), repmat(uint8(3), sz), noWall};
for k = 1:numel(regions)
    c.Results.Regions = regions{k};
    c = farmE5DefineGeometry(c);
    verifyTrue(t, all(isinf(c.Results.Distance(:))));
    verifyFalse(t, any(c.Results.WorkingValid(:)));
    verifyFalse(t, any(c.Results.DistanceValid(:)));
    verifyEqual(t, c.Results.GeometryInfo.PrimaryBoundaryVoxelCount, 0);
    verifyEqual(t, c.Results.GeometryInfo.SecondaryBoundaryVoxelCount, 0);
    c = farmE5CalculateNormals(c);
    verifyTrue(t, all(isnan(c.Results.DistanceGradient(:))));
    verifyFalse(t, any(c.Results.DirectionValid(:)));
    verifyEqual(t, c.Results.GradientInfo.Size, sz);
    verifyEqual(t, c.Results.GradientInfo.Status, 'no-finite-distance');
    c = farmE5SampleFields(c);
    c = farmE5MeasureAlignment(c);
    verifyEqual(t, height(c.Results.Properties), 2);
    verifyTrue(t, all(isnan(c.Results.Properties.BoundaryDistance)));
    verifyTrue(t, all(isnan(c.Results.Properties.Order2D)));
    verifyTrue(t, all(isnan(c.Results.Properties.Order3D)));
    verifyFalse(t, any(c.Results.Properties.Selected));
end
end

function testFinitePlaneKeepsKnownDistanceAndNormals(t)
c = localConfiguration;
sz = c.Results.TargetSize;
c.Results.Regions = repmat(uint8(3), sz);
c.Results.Regions(:, 1:4, :) = 1;
c.Results.Regions(:, 5, :) = 2;
c = farmE5DefineGeometry(c);
expected = repmat(single((1:sz(2)) - 5), sz(1), 1, sz(3));
verifyEqual(t, c.Results.Distance, expected);
verifyTrue(t, all(c.Results.DistanceValid(:)));
verifyEqual(t, c.Results.GeometryInfo.PrimaryBoundaryVoxelCount, sz(1) * sz(3));
c = farmE5CalculateNormals(c);
verifyEqual(t, c.Results.DistanceGradient(:, :, :, 1), ones(sz));
verifyEqual(t, c.Results.DistanceGradient(:, :, :, 2:3), zeros([sz 2]));
verifyTrue(t, all(c.Results.DirectionValid(:)));
verifyTrue(t, c.Results.GradientInfo.FiniteDistanceField);
verifyEqual(t, c.Results.GradientInfo.Status, 'computed');
end

function testPartialNonfiniteFieldWithoutFill(t)
c = localConfiguration;
sz = c.Results.TargetSize;
c.Results.Distance = repmat(single(1:sz(2)), sz(1), 1, sz(3));
c.Results.Distance(4, 3, 3) = NaN;
c.ProfileSigma = 1;
c = farmE5CalculateNormals(c);
verifyTrue(t, isnan(c.Results.Distance(4, 3, 3)));
verifyFalse(t, c.Results.DirectionValid(4, 3, 3));
verifyTrue(t, c.Results.DirectionValid(end, end, end));
verifyFalse(t, any(c.Results.DistanceFilled(:)));
verifyEqual(t, c.Results.GradientInfo.Status, 'computed-with-undefined-distance');
end

function testNearestDistanceFillIsMeasurableAndFlagged(t)
c = localConfiguration;
sz = c.Results.TargetSize;
c.Results.Regions = ones(sz, 'uint8');
c.DistanceFillMethod = 'nearest';
c.Results.Distance = repmat(single(1:sz(2)), sz(1), 1, sz(3));
c.Results.Distance(4, 3, 3) = Inf;
c.Results.DistanceValid = isfinite(c.Results.Distance);
c = farmE5CalculateNormals(c);
verifyTrue(t, all(isfinite(c.Results.Distance(:))));
verifyClass(t, c.Results.Distance, 'single');
verifyTrue(t, c.Results.DistanceValid(4, 3, 3));
verifyEqual(t, nnz(c.Results.DistanceFilled), 1);
verifyEqual(t, c.Results.GradientInfo.FilledVoxelCount, 1);
c = farmE5SampleFields(c);
c = farmE5MeasureAlignment(c);
verifyEqual(t, c.Results.Properties.BoundaryDistanceFilled, [true; false]);
verifyEqual(t, c.Results.Properties.BoundaryDistance(1), c.Results.Distance(4, 3, 3));
verifyTrue(t, c.Results.Properties.Selected(1));
end

function testDirectionValidityHonorsDistanceSelection(t)
c = localConfiguration;
sz = c.Results.TargetSize;
c.Results.Distance = repmat(1:sz(2), sz(1), 1, sz(3));
c.Results.DistanceValid = true(sz);
c.Results.DistanceValid(4, 5, 3) = false;
c = farmE5CalculateNormals(c);
verifyEqual(t, nnz(c.Results.DirectionValid), prod(sz) - 1);
verifyFalse(t, c.Results.DirectionValid(4, 5, 3));
end

function testMissingBoundaryDiagnosticsAreSaved(t)
c = localConfiguration;
c.Results.Regions = repmat(uint8(2), c.Results.TargetSize);
c = farmE5DefineGeometry(c);
c = farmE5CalculateNormals(c);
c = farmE5SampleFields(c);
c = farmE5MeasureAlignment(c);
c.Results.SegmentationInfo = struct();
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
outputRoot = fullfile(repo, 'tests', 'data', 'workflow-results', 'refactor-validation');
if ~isfolder(outputRoot), mkdir(outputRoot); end
c.RunDirectory = tempname(outputRoot);
mkdir(c.RunDirectory);
c = farmE5SaveMeasurements(c);
saved = load(c.Results.SavedFrameFile, 'result');
verifyEqual(t, saved.result.GeometryInfo.PrimaryBoundaryVoxelCount, 0);
verifyEqual(t, saved.result.GradientInfo.Status, 'no-finite-distance');
verifyEqual(t, height(saved.result.Filaments), 2);
end

function testFilamentStageReusesSegmentedMembership(t)
c = struct('DatasetID', 'reuse-test', 'Frame', 1, 'Spacing', [.55 .55 .7], ...
    'SpacingUnit', 'um', 'FilamentLoader', [], 'FilamentSigma', 1, ...
    'FilamentSegmentationMethod', 'fixed', 'FilamentThreshold', 20, ...
    'FilamentProperties', {{'Volume','Centroid','Directors','ExtentInVoxels', ...
    'AspectRatios','ScaledDirectors','ProjectedExtent','ScaledAspectRatios'}}, 'ExtentWidthFloor', eps);
c.Results.Raw = zeros(17, 19, 15, 'uint16');
c.Results.Raw(8:10, 4:15, 7:9) = 1000;
c.Results.Raw(3:4, 4:9, 3:4) = 700;
c = farmE5MeasureFilaments(c);
identity = struct('DatasetID', c.DatasetID, 'Frame', c.Frame, 'Spacing', c.Spacing, 'SpacingUnit', c.SpacingUnit);
expected = farmMeasureFilaments(c.Results.FilamentMask, c.FilamentProperties, ...
    struct('Identity', identity, 'ExtentWidthFloor', c.ExtentWidthFloor));
verifyGreaterThan(t, height(expected), 0);
verifyEqual(t, c.Results.Properties.Properties.VariableNames, expected.Properties.VariableNames);
for name = expected.Properties.VariableNames
    verifyEqual(t, c.Results.Properties.(name{1}), expected.(name{1}));
end
verifyEqual(t, c.Results.Objects.Components.PixelIdxList, c.Results.FilamentSegmentation.Components.PixelIdxList);
end

function c = localConfiguration
c = struct('DatasetID', 'missing-boundary-test', 'Frame', 1, 'Spacing', [1 1 1], ...
    'SpacingUnit', 'um', 'BoundaryWorkingSpacing', 1, 'BoundaryDilationRadius', 1, ...
    'RegionInterpolation', 'nearest', 'DistanceInterpolation', 'nearest', ...
    'ProfileSigma', 0, 'GradientDerivativeUnits', 'physical', ...
    'ScalarSamplingStatistics', {{'Mean'}}, 'VectorSamplingStatistics', {{'MeanVector'}}, ...
    'AlignmentPlane', [1 2], 'MaxZComponent', [], 'MinFilamentLength', 0, 'MinAspectRatio', 0);
c.Results = struct('TargetSize', [9 10 7]);
c.Results.Properties = table([1;2], [3 4 3; 6 7 4], [1 0 0; 0 1 0], [2;3], [2;2], ...
    'VariableNames', {'ObjectID', 'Centroid', 'ScaledDirectors', 'ProjectedExtent', 'ScaledAspectRatios'});
end
