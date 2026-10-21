function c = farmActiveFoamE5Config(selFrames)
%FARMACTIVEFOAME5CONFIG Configure data loading, processing, analysis, and plotting.
% Return settings for loading images, segmenting objects, detecting filaments,
% preparing boundary distances and surface normals, and plotting alignment.
% Inputs:
%   None. Edit the settings below for the data being analyzed.
% Outputs:
%   c   Configuration [scalar struct]: named settings containing data locations,
%       metadata, frame selections, segmentation and geometry parameters,
%       analysis and plotting options, and the destination for saved results.
%
% Search the Glossary for Configuration, Experiment, Data source, and Boundary.
% Use the Data Dictionary for documented measured quantities and diagnostics.
% Enter help farmMakeSource or help farmMakeExperiment for creation inputs.
% The paths and values below describe the E5 example; replace them as needed.

% Package Setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Locate the package. Run farmSetup before calling this configuration.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
c = struct();
c.RepositoryRoot = repo;

% Data Loading %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify the folders and filename patterns used to read each source.
% For this experiment, O:\Session 88 and its subfolders must remain read only.
filsDataDirectory = 'O:\Session 88\Exp 5\3 Illumination Bleach Corrected 16bit';
probsDirectory = 'O:\Session 88\all ilastik prep files';
filamentNamePattern = 't%03i_illBleachCorr16bit_647.tif';
probabilityNamePattern = 't%03i_illCorr8bit_560_E5_Probabilities Stage 2.h5';
probabilityDatasetPath = '/exported_data';

% Select the acquisition frames to process.
c.Frames = selFrames;

% Describe dataset identity, spatial sampling, stored dimensions, and timing.
% Supply calibration from acquisition/export metadata; it is not inferred.
c.DatasetID = 'S88E5';               % Identifier stored with measurements.
c.Spacing = [0.55 0.55 0.7];         % Image sample spacing in [Y X Z] order.
probabilitySpacing = [1.5 1.5 1.5];  % Probability sample spacing in [Y X Z] order.
c.SpacingUnit = 'um';               % Spatial unit for both sources.
filamentAxes = 'YXZ';               % Stored image dimensions: Y, X, Z.
probabilityAxes = 'CXYZ';            % Stored probability dimensions: channel, X, Y, Z.
c.TimeStep = 30;                    % Time between acquisition frames.
c.TimeUnit = 's';                   % Unit of TimeStep.
c.TimeReferenceFrame = c.Frames(1);          % Frame assigned elapsed time zero.

% Define how to load corrected filament images.
% farmMakeSource describes a source; it does not load images here.
% In NamePattern, %03i represents a three-digit frame number, such as 025.
filaments = farmMakeSource( ...
    'Format', 'tiff', ...
    'Folder', filsDataDirectory, ...
    'NamePattern', filamentNamePattern, ...
    'SourceAxes', filamentAxes, ...
    'Spacing', c.Spacing, ...
    'SpacingUnit', c.SpacingUnit);

% Define how to load object-segmentation probabilities.
probabilities = farmMakeSource( ...
    'Format', 'hdf5', ...
    'Folder', probsDirectory, ...
    'NamePattern', probabilityNamePattern, ...
    'DatasetPath', probabilityDatasetPath, ...
    'SourceAxes', probabilityAxes, ...
    'Spacing', probabilitySpacing, ...
    'SpacingUnit', c.SpacingUnit);

% Combine the named sources and acquisition metadata into an experiment.
c.Experiment = farmMakeExperiment( ...
    'DatasetID', c.DatasetID, ...
    'Frames', c.Frames, ...
    'TimeStep', c.TimeStep, ...
    'TimeUnit', c.TimeUnit, ...
    'Sources', struct('Intensity647', filaments, 'Probabilities', probabilities));

% Object Segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Segment objects from probabilities for inside, boundary/on, and outside.
c.SemanticChannels = [3 2 1]; % Source channels for [inside, boundary/on, outside].
c.Thresholds = [0.6 0.6 0.6];
c.OpeningRadius = 1;         % Probability-grid voxels.
c.FillMethod = 'nearest';      % 'none', 'nearest', or highest-precedence 'fill', after opening.

% Filament Detection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detect filaments using a Laplacian-of-Gaussian (LoG) filter and threshold.
% Leave FilamentLoader empty to use this process. Alternatively, supply a
% function handle @(frame) returning a same-grid binary filament mask.
c.FilamentLoader = [];
c.FilamentSigma = 1;      % LoG smoothing, in intensity-grid voxels.
c.FilamentThreshold = 20; % Threshold applied to negative LoG intensity.
c.FilamentSegmentationMethod = 'fixed';

% Filament Measurement %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Request the quantities to retain in the measurement table. Centroid,
% ScaledDirectors, ProjectedExtent, and ScaledAspectRatios are used below;
% retain those entries when adding or removing other measurements.
c.FilamentProperties = {'Volume', 'Centroid', 'Directors', 'ExtentInVoxels', 'AspectRatios', ...
    'ScaledDirectors', 'ProjectedExtent', 'ScaledAspectRatios'};
c.ExtentWidthFloor = eps; % Positive lower limit used in extent/aspect calculations.

% Select detections by measured extent and aspect ratio; retain all table rows.
c.MinFilamentLength = 0; % Minimum ProjectedExtent accepted by the selection.
c.MinAspectRatio = 0;    % Minimum ScaledAspectRatios accepted by the selection.

% Boundary Geometry %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the isotropic grid and morphological radius for boundary distances.
c.BoundaryWorkingSpacing = min(c.Spacing); % Same physical unit as image spacing.
c.BoundaryDilationRadius = 1;              % Isotropic working-grid voxels.
c.RegionInterpolation = 'nearest';        % Preserve discrete category/validity labels.
c.DistanceInterpolation = 'nearest';      % Return distances to the intensity grid.

% Surface-Normal Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set smoothing for the distance gradient. The processing stage below defines
% the boundary geometry and distance field explicitly.
c.ProfileSigma = 2; % Distance-gradient smoothing, in intensity-grid voxels.
c.GradientDerivativeUnits = 'physical'; % Differentiate using supplied spatial spacing.

% Field Sampling %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Request statistics at each single-voxel centroid selection. Mean and
% MeanVector supply the measurement columns used below; retain them when
% adding other statistics. See help farmQueryField and farmQueryVectorField.
c.ScalarSamplingStatistics = {'Mean'};
c.VectorSamplingStatistics = {'MeanVector'};

% Alignment Measurement %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compare filament directions with the sampled surface-normal directions.
% Optionally filter directions for projected XY alignment by their Z component.
% Leave the limit empty to omit this filter; it does not filter Order3D plots.
c.MaxZComponent = []; % Optional limit from 0 to 1.
c.AlignmentPlane = [1 2]; % X and Y components for projected alignment.

% Alignment Analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Group measured Order3D values by signed distance and acquisition frame.
% Order3D = (3*cos(theta)^2 - 1)/2, where theta is the angle to the normal.
% Its isotropic reference is 0; parallel and opposite directions both give 1.
% AlignmentPlot holds settings for this example, not a general plotting API.
c.AlignmentPlot = struct();
c.AlignmentPlot.Frames = c.Frames;
c.AlignmentPlot.TimeStep = c.TimeStep;
c.AlignmentPlot.TimeReferenceFrame = c.TimeReferenceFrame;
c.AlignmentPlot.DistanceEdges = -20:1:30; % Distance-bin edges, in micrometers.

% Choose the elapsed-time window used to find a fixed peak distance r*.
% Elapsed time = (Frame - TimeReferenceFrame) * TimeStep.
% Compare bins with sufficient observations at every time in the window.
c.AlignmentPlot.AverageTimeWindow = [0 150]; % Elapsed seconds, inclusive.

% Set criteria for locating peaks and flagging flat or broad profiles.
% These are exploratory example settings; choose values for the data analyzed.
c.AlignmentPlot.MinPeakCount = 20;       % Minimum observations in an eligible bin.
c.AlignmentPlot.FlatTolerance = 0.05;    % Maximum peak-to-minimum difference called flat.
c.AlignmentPlot.BroadPeakFraction = 0.9; % Used to identify bins close to the peak value.

% Select fixed distance bands for alignment time traces.
% Bands include the left edge and exclude the right; distances are micrometers.
% The r* band may overlap InteriorBand, so traces can share observations.
c.AlignmentPlot.InteriorBand = [-10 -5];
c.AlignmentPlot.ExteriorBand = [5 10];
c.AlignmentPlot.FixedBandHalfWidth = 1; % Sample from r* - 1 to r* + 1.

% Data Plotting %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose frames for spatial profiles and create the three example figures.
% Standard deviation describes observation spread, not a confidence interval.
c.AlignmentPlot.SelectedFrames = [25 27 30];
c.AlignmentPlot.MakeFigures = true;

% Output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose where to save results and print processing progress.
% Processing creates a new run folder beneath OutputRoot.
outputDirectory = fullfile(repo, 'tests', 'data', 'workflow-results');
outputName = 'active-foam-E5-frames025-030';
c.OutputRoot = fullfile(outputDirectory, outputName);
c.Verbose = true;

end
