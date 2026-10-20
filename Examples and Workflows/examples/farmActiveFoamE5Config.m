function c = farmActiveFoamE5Config
%FARMACTIVEFOAME5CONFIG Confirmed E5 inputs and explicit analysis definitions.
% Inputs:
%   None. Edit this example to change the acquisition or analysis choices.
% Outputs:
%   c   Workflow 2 configuration plus plotting/calibration definitions.

repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(repo);
farmSetup('IncludeExamples', true);

% Everything at/below this source root is READ ONLY. All writes use OutputRoot.
sourceRoot = 'O:\Session 88';
filamentDirectory = fullfile(sourceRoot, 'Exp 5', '3 Illumination Bleach Corrected 16bit');
probabilityDirectory = fullfile(sourceRoot, 'all ilastik prep files');
frames = 25:30;

% Confirmed spatial calibration: values are in Y, X, Z array-axis order.
spacing = [.55 .55 .7];
probabilitySpacing = [1.5 1.5 1.5];
spacingUnit = 'um';

filaments = farmMakeSource('Format', 'tiff', 'Folder', filamentDirectory, ...
    'NamePattern', 't%03i_illBleachCorr16bit_647.tif', ...
    'SourceAxes', 'YXZ', 'Spacing', spacing, 'SpacingUnit', spacingUnit);
probabilities = farmMakeSource('Format', 'hdf5', 'Folder', probabilityDirectory, ...
    'NamePattern', 't%03i_illCorr8bit_560_E5_Probabilities Stage 2.h5', ...
    'DatasetPath', '/exported_data', 'SourceAxes', 'CXYZ', ...
    'Spacing', probabilitySpacing, 'SpacingUnit', spacingUnit);

c = struct();
c.RepositoryRoot = repo;
c.ReadOnlySourceRoot = sourceRoot;
c.OutputRoot = fullfile(repo, 'tests', 'data', 'workflow-results', 'active-foam-E5-frames025-030');
c.DatasetID = 'S88E5';
c.Frames = frames;
c.Spacing = spacing;
c.SpacingUnit = spacingUnit;
c.TimeStep = 30; % Seconds per original acquisition frame increment.
c.TimeUnit = 's';
c.TimeReferenceFrame = 25; % Plot elapsed time = (Frame - 25) * 30 seconds.
c.Experiment = farmMakeExperiment('DatasetID', c.DatasetID, 'Frames', frames, ...
    'TimeStep', c.TimeStep, 'TimeUnit', c.TimeUnit, ...
    'Sources', struct('Intensity647', filaments, 'Probabilities', probabilities));

% Existing workflow 2 defaults, exposed here rather than silently retuned.
c.FilamentLoader = [];
c.FilamentSigma = 1; % LoG sigma, intensity-grid voxels.
c.FilamentThreshold = 20; % Threshold of -LoG(corrected 647 intensity).
c.MinFilamentLength = 0;
c.MinAspectRatio = 0;
c.MaxZComponent = [];
c.SemanticChannels = [3 2 1]; % [inside, wall/on, outside] source channel numbers.
c.Thresholds = [.33 .33 .33];
c.OpeningRadius = 1; % Probability-grid voxels.
c.ProfileSigma = 2; % Distance-gradient smoothing, intensity-grid voxels.
c.Verbose = true;

% Exploratory plotting choices, not fitted experimental acceptance thresholds.
c.AlignmentPlot = struct('Frames', frames, 'TimeStep', c.TimeStep, 'TimeReferenceFrame', c.TimeReferenceFrame, ...
    'DistanceEdges', -20:1:30, 'SelectedFrames', [25 27 30], ...
    'AverageTimeWindow', [0 150], 'InteriorBand', [-10 -5], 'ExteriorBand', [5 10], ...
    'FixedBandHalfWidth', 1, 'MinPeakCount', 20, 'FlatTolerance', .05, ...
    'BroadPeakFraction', .9, 'MakeFigures', true);
end
