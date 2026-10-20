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
