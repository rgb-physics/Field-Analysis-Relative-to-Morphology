function tests = testActiveFoamAlignment
%TESTACTIVEFOAMALIGNMENT Known means, missing bins, peaks and time weighting.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(repo);
farmSetup('IncludeExamples', true);
tests = functiontests(localfunctions);
end

function testKnownBinsAndMissingValues(t)
input = localInput([25;25;25;25;26;26], [-.5;-.5;.5;.5;.5;.5], [0;.2;.6;.8;.5;.9]);
o = localOptions;
r = farmPlotActiveFoamAlignment(input, o);
verifyEqual(t, r.Count, [2 0; 2 2; 0 0]);
verifyEqual(t, r.Mean(1,1), .1, 'AbsTol', 1e-12);
verifyEqual(t, r.Variance(1,1), .02, 'AbsTol', 1e-12);
verifyTrue(t, isnan(r.Mean(1,2)));
verifyTrue(t, isnan(r.Variance(3,1)));
verifyEqual(t, r.MovingPeak.Distance(1), .5);
verifyTrue(t, r.MovingPeak.Flat(2));
verifyTrue(t, isnan(r.MovingPeak.Distance(2)));
verifyEqual(t, r.TimeSeconds, [0;30]);
end

function testTiedAndFlatPeaksHaveNoLocation(t)
input = localInput([25;25;25;25;26;26;26;26], ...
    [-.5;-.5;.5;.5;-.5;-.5;.5;.5], [.2;.4;.2;.4;0;0;0;0]);
r = farmPlotActiveFoamAlignment(input, localOptions);
verifyTrue(t, all(r.MovingPeak.Tied));
verifyTrue(t, all(r.MovingPeak.Flat));
verifyTrue(t, all(isnan(r.MovingPeak.Distance)));
verifyTrue(t, isnan(r.FixedPeak.Distance));
end

function testFixedPeakUsesEqualTimeMeansNotPooledRods(t)
% Bin -.5 has many rods at t=0 but a smaller equal-time mean than bin +.5.
frames = [25*ones(20,1);26*ones(2,1);25*ones(2,1);26*ones(2,1)];
distance = [-.5*ones(22,1); .5*ones(4,1)];
values = [.6*ones(20,1);zeros(2,1);.4*ones(4,1)];
r = farmPlotActiveFoamAlignment(localInput(frames,distance,values), localOptions);
verifyEqual(t, r.TimeAveragedProfile(1:2), [.3;.4], 'AbsTol', 1e-12);
verifyEqual(t, r.FixedPeak.Distance, .5);
verifyEqual(t, r.FixedPeak.Weights, [.5;.5]);
verifyEqual(t, r.FixedPeak.Window, [0 30]);
end

function testInvalidSelectionsAndSparsePeaks(t)
input = localInput([25;25;26;26], [-.5;.5;-.5;.5], [NaN;.2;.3;.4]);
input.Filaments.Selected(2) = false;
input.Filaments.ReferenceDirectionValid(3) = false;
r = farmPlotActiveFoamAlignment(input, localOptions);
verifyEqual(t, height(r.Observations), 1);
verifyTrue(t, all(r.MovingPeak.Sparse));
verifyTrue(t, all(isnan(r.MovingPeak.Distance)));
verifyTrue(t, all(isnan(r.TimeAveragedProfile)));
end

function testPublicAPIStagesMatchWorkflow2(t)
% Run the actual processing section on small synthetic files, including a
% missing frame. Compare measurements with the unchanged Workflow 2 path.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
outputRoot = fullfile(repo, 'tests', 'data', 'workflow-results');
if ~isfolder(outputRoot), mkdir(outputRoot); end
fixture = tempname(outputRoot);
mkdir(fixture);
c = farmActiveFoamE5Config;
c.OutputRoot = fixture;
c.DatasetID = 'synthetic-E5-stages';
c.Frames = [25 26];
c.Spacing = [0.55 0.55 0.7];
c.ProfileSigma = 1;
sz = [24 26 14];
[y, x, z] = ndgrid(1:sz(1), 1:sz(2), 1:sz(3));
radius = sqrt((y - 12).^2 + (x - 13).^2 + (z - 7).^2);
p = cat(4, double(radius >= 7), double(radius >= 4 & radius < 7), double(radius < 4));
p = p(1:2:end, 1:2:end, 1:2:end, :);
mask = false(sz);
mask(12, 8:15, 7) = true;
mask(8:15, 20, 7) = true;
c.FilamentLoader = @(~) mask;
farmWriteTiff(uint16(100 * ones(sz)), fullfile(fixture, 'image025.tif'));
h5create(fullfile(fixture, 'probability025.h5'), '/data', size(p));
h5write(fullfile(fixture, 'probability025.h5'), '/data', p);
intensitySource = farmMakeSource('Folder', fixture, 'NamePattern', 'image%03i.tif', ...
    'SourceAxes', 'YXZ', 'Spacing', c.Spacing, 'SpacingUnit', c.SpacingUnit);
probabilitySource = farmMakeSource('Format', 'hdf5', 'Folder', fixture, ...
    'NamePattern', 'probability%03i.h5', 'DatasetPath', '/data', ...
    'SourceAxes', 'YXZC', 'Spacing', 2 * c.Spacing, 'SpacingUnit', c.SpacingUnit);
c.Experiment = farmMakeExperiment('DatasetID', c.DatasetID, 'Frames', c.Frames, ...
    'Sources', struct('Intensity647', intensitySource, 'Probabilities', probabilitySource));
previousConfig = c;
previousConfig.Frames = 25;
previous = farmWorkflow2Filaments(previousConfig);

script = fileread(fullfile(repo, 'Examples and Workflows', 'examples', 'setupActiveFoamE5.m'));
first = strfind(script, '%% Process selected frames using public APIs');
last = strfind(script, '%% Pass measured observations to analysis');
processing = script(first:last - 1);
savedWorkflow2File = ''; %#ok<NASGU>
distance = []; %#ok<NASGU> % Name the script variable explicitly in this function workspace.
output = evalc('eval(processing);');
verifyTrue(t, contains(output, 'Skipping frame 26'));
verifyEqual(t, workflow2.Frames, 25);
verifyEqual(t, height(workflow2.Filaments), 2);
verifyEqual(t, workflow2.Filaments.Properties.VariableNames, previous.Filaments.Properties.VariableNames);
verifyEqual(t, table2cell(workflow2.Filaments), table2cell(previous.Filaments));
verifyEqual(t, properties.BoundaryDistance, distance(properties.CoMIndices));
verifyEqual(t, samplingDiagnostics.BoundaryDistance_SelectedCount, ones(2, 1));
verifyEqual(t, centroidSupport.Records(1).Indices, properties.CoMIndices(1));
saved = load(fullfile(workflow2.Directory, 'workflow2-output.mat'), 'result');
verifyEqual(t, saved.result.Filaments, workflow2.Filaments);
verifyTrue(t, isfile(fullfile(workflow2.Directory, 'processing.log')));

% The separate teaching functions must produce the same data using only c.
c.Frame = 25;
c.RunDirectory = tempname(fixture);
mkdir(c.RunDirectory);
stageFunctions = {'farmE5LoadData', 'farmE5SegmentObjects', 'farmE5MeasureFilaments', ...
    'farmE5DefineGeometry', 'farmE5CalculateNormals', 'farmE5SampleFields', ...
    'farmE5MeasureAlignment', 'farmE5SaveMeasurements'};
for stageIndex = 1:numel(stageFunctions)
    stageFunction = stageFunctions{stageIndex};
    verifyEqual(t, nargin(stageFunction), 1);
    c = feval(stageFunction, c);
end
verifyEqual(t, table2cell(c.Results.Properties), table2cell(properties));
verifyEqual(t, c.Results.Distance, distance);
verifyEqual(t, c.Results.SamplingDiagnostics, samplingDiagnostics);
verifyEqual(t, c.Results.CentroidSupport, centroidSupport);
stageFile = load(c.Results.SavedFrameFile, 'result');
verifyEqual(t, stageFile.result.Filaments, c.Results.Properties);
verifyError(t, @() farmE5SaveMeasurements(c), 'farm:E5StageOutputExists');

% Loading a missing/new frame must clear the preceding frame's dense results.
c.Frame = 26;
c = farmE5LoadData(c);
verifyTrue(t, c.Results.MissingInput);
verifyFalse(t, isfield(c.Results, 'Properties'));

% Exercise the accompanying multi-frame script with the same synthetic config.
stageScript = fileread(fullfile(repo, 'Examples and Workflows', 'examples', ...
    'activeFoamE5Stages', 'setupActiveFoamE5Stages.m'));
driverStart = strfind(stageScript, '%% Prepare a new local output directory');
driverBody = stageScript(driverStart:end);
driverOutput = evalc('eval(driverBody);');
verifyTrue(t, contains(driverOutput, 'Skipping frame 26'));
verifyEqual(t, table2cell(c.Results.Workflow2.Filaments), table2cell(workflow2.Filaments));
verifyEqual(t, c.CompletedFrames, 25);
verifyTrue(t, isfile(fullfile(c.RunDirectory, 'processing.log')));

% Timing has one row per requested frame and preserves partial/skipped frames.
for timingReport = {workflow2, c.Results.Workflow2}
    report = timingReport{1};
    times = report.StageTimings;
    verifyEqual(t, times.Properties.VariableNames{1}, 'TotalSeconds');
    verifyEqual(t, times.Frame, [25; 26]);
    verifyEqual(t, times.Completed, [true; false]);
    verifyTrue(t, all(isfinite(times{1, 3:10}) & times{1, 3:10} >= 0));
    verifyTrue(t, all(isnan(times{2, 4:10})));
    verifyGreaterThanOrEqual(t, times.LoadDataSeconds(2), 0);
    verifyEqual(t, times.TotalSeconds, sum(times{:, 3:10}, 2, 'omitnan'));
    savedTimes = load(fullfile(report.Directory, 'stage-timings.mat'), 'stageTimings');
    verifyEqual(t, savedTimes.stageTimings, times);
    verifyTrue(t, isfile(fullfile(report.Directory, 'stage-timings.csv')));
end
verifyEqual(t, c.StageTimings, c.Results.Workflow2.StageTimings);
end

function input = localInput(frames, distances, values)
n = numel(frames);
input = struct('Filaments', table(repmat("synthetic",n,1), frames, (1:n)', distances, values, ...
    true(n,1),true(n,1),true(n,1), 'VariableNames', ...
    {'DatasetID','Frame','ObjectID','BoundaryDistance','Order3D','Selected','ReferenceValid','ReferenceDirectionValid'}));
end

function o = localOptions
o = struct('Frames',[25 26], 'TimeStep',30, 'TimeReferenceFrame',25, ...
    'DistanceEdges',[-1 0 1 2], 'SelectedFrames',[25 26], 'AverageTimeWindow',[0 30], ...
    'MinPeakCount',2, 'FlatTolerance',.01, 'MakeFigures',false);
end
