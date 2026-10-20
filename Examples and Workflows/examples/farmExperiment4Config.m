function c = farmExperiment4Config

%FARMEXPERIMENT4CONFIG Editable configuration; supplied datasets remain read-only.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', false);

here = fileparts(mfilename('fullpath')); repo = fileparts(fileparts(here));
for api = {'ImageStackIO','SegmentationTools','ObjectGeometry','ObjectTracking','ObjectRelativeProfiles','SharedUtilities','FieldAnalysis','VisualizationTools'}
    addpath(fullfile(repo,'APIs',api{1},'src'));
end
addpath(here);
addpath(fullfile(repo,'Examples and Workflows','src'));
c = struct;
c.IncludeDiagnostics = false; % workflow 1 also retains a separate Diagnostics table
c.RepositoryRoot = repo;
c.DatasetID = 'Session88_Experiment4'; c.Frames = 10:2:30; c.TrackingFrames = 10:30;
c.Spacing = [.55 .55 .7]; c.SpacingUnit = 'um'; c.TimeStep = 30; c.TimeUnit = 's';
c.RawDirectory = 'O:\Session 88\Exp 4 - Rmin Redo\0 Raw Tifs';
c.IntensityDirectory = 'O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit';
c.ProbabilityDirectory = 'O:\Session 88\all ilastik prep files';
c.CropMetadata = 'O:\Session 88\Exp 4 - Rmin Redo\1 Cropped MATLAB\metadata.mat';
c.RawPattern = 'Time%06i_raw560.tif'; c.IntensityPattern = 't%03i_illBleachCorr16bit_%s.tif';
c.ProbabilityPattern = 't%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5';
c.H5Dataset = '/exported_data'; c.H5SourceAxes = 'CXYZ'; % Historical loader convention; inspect preview.
c.ProbabilitySpacing = [1.5 1.5 1.5]; c.SemanticChannels = [3 2 1]; % inside/wall/outside
c.Thresholds = [.33 .33 .33]; c.OpeningRadius = 1;
c.ForegroundChannels = [3 2]; c.ForegroundThreshold = .6; c.ObjectSmoothSigma = 2;
c.ObjectLoader = []; % Optional @(frame) mask/labels on intensity grid skips H5 segmentation.
c.ObjectInputType = 'auto'; % Set 'labels' for binary-valued supplied IDs.
c.ReferenceFrames = 1:3; c.PreparationFrame = 22; c.BleachScale = true;
c.ExportIlastik = false; c.IlastikRange = [1 5000]; c.IlastikSpacing = [1.5 1.5 1.5];
c.Supports = {'objects','boundary'}; % Add 'skeleton' only if gfilter is installed.
c.GeometrySigma = 1; c.LocalInertia = false; c.InertiaOptions = struct('Radius',18,'Sigma',3,'SampleLimit',10000);
c.FilamentSigma = 1; c.FilamentThreshold = 20; c.MinFilamentLength = 0; c.MinAspectRatio = 0;
c.MaxZComponent = []; c.FilamentLoader = []; % Optional @(frame) binary mask.
c.SeedFrame = 20; c.SeedObjectID = []; % Empty -> largest detection at seed frame, recorded explicitly.
c.ExportTrackingTiffs = false; c.RetainMasks = false;
c.TrackingLabelMode = 'trajectory'; c.ExportMaskedIntensity = false;
c.SpectrumFrames = [10 20 30]; c.SelectedSlices = [20 40 60]; c.NumBins = 50;
c.MeanSubtract = false; c.Window = true; c.Projection = 'mean';
c.CorrelationMode = '2d'; % '3d' is opt-in; full linear volume can be very large.
c.CorrelationCrossChannel = false;
c.ProfileEdges = -30:.5:30; c.ProfileReference = 'boundary'; % Or 'skeleton'
c.ProfileChannels = {'560','647'}; c.ProfileSigma = 2;
c.OutputRoot = fullfile(repo,'tests', 'data','workflow-results');
end
