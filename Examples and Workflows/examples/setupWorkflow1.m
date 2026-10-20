%% WORKFLOW 1 -- inspect one frame, then optionally process the selected frames
% Run sections in order. Stop after any numbered stage to inspect its outputs.
% The default synthetic example needs Image Processing Toolbox and no files.
% Your original Experiment 4 settings remain below under the real-data option.
% No files are saved unless savePreview or runBatch is true.


%% SETUP -- package location and execution choices
% Keep this explicit path for running individual sections from the MATLAB editor.
repo = 'C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo';
addpath(repo);
farmSetup('IncludeExamples', true);

useSynthetic = true;
showFigures = true;
savePreview = false;
runBatch = false;


%% DATA SOURCES -- describe files or loaders; no acquisition frame is loaded yet
frames = 10:2:30;
deltaT = 30;

intDir = 'O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit';
intName = 't%03i_illBleachCorr16bit_560.tif';
intVoxSize = [.55 .55 .7];
intAxes = 'YXZ';

segDir = 'O:\Session 88\all ilastik prep files';
segName = 't%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5';
segVoxSize = [1.5 1.5 1.5];
segAxes = 'CXYZ';

if useSynthetic
    % Two separated objects on an isotropic YXZ grid. The signal increases
    % with interior voxel distance; category channels are 3=inside, 2=wall.
    [demoY, demoX, demoZ] = ndgrid(1:32, 1:36, 1:16);
    demoMask = (demoX - 12).^2 + (demoY - 16).^2 + (demoZ - 8).^2 <= 5^2 | ...
               (demoX - 26).^2 + (demoY - 16).^2 + (demoZ - 8).^2 <= 4^2;
    demoIntensity = 100 + 2 * double(bwdist(~demoMask));
    demoProbabilities = cat(4, .95 - .9 * double(demoMask), ...
        .025 * ones(size(demoMask)), .025 + .9 * double(demoMask));
    intSrc = farmMakeSource('Format', 'custom', ...
        'Loader', @(frame) demoIntensity + frame, ...
        'Spacing', [1 1 1], 'SpacingUnit', 'voxel');
    probSrc = farmMakeSource('Format', 'custom', ...
        'Loader', @(frame) struct('Data', demoProbabilities, 'Axes', 'YXZCT'), ...
        'Spacing', [1 1 1], 'SpacingUnit', 'voxel');
    experiment = farmMakeExperiment('DatasetID', 'workflow1-demo', ...
        'Frames', 1:3, 'Sources', struct('Intensity', intSrc, 'Probabilities', probSrc));
else
    intSrc = farmMakeSource('Folder', intDir, 'NamePattern', intName, ...
        'Format', 'tiff', 'SourceAxes', intAxes, ...
        'Spacing', intVoxSize, 'SpacingUnit', 'um');
    probSrc = farmMakeSource('Folder', segDir, 'NamePattern', segName, ...
        'Format', 'hdf5', 'DatasetPath', '/exported_data', 'SourceAxes', segAxes, ...
        'Spacing', segVoxSize, 'SpacingUnit', 'um');
    experiment = farmMakeExperiment('DatasetID', 'S88E4', 'Frames', frames, ...
        'TimeStep', deltaT, 'TimeUnit', 's', ...
        'Sources', struct('Intensity', intSrc, 'Probabilities', probSrc));
end

c = struct('Experiment', experiment, 'Frames', experiment.Frames);
c.RepositoryRoot = repo;
c.OutputRoot = fullfile(repo, 'tests', 'data', 'workflow-results');
frame = c.Frames(1); % Acquisition frame number, not a stored TimeIndex.


%% STAGE 1 -- load data for the current frame
image = farmLoadSource(experiment, 'Intensity', frame);
probabilityImage = farmLoadSource(experiment, 'Probabilities', frame);
if size(image.Data, 4) ~= 1 || size(image.Data, 5) ~= 1
    error('memoworkflow:Channels', 'Select one intensity channel and stored time point.');
end
intensity = image.Data(:, :, :, 1, 1);
probabilities = probabilityImage.Data(:, :, :, :, 1);

% STOP: inspect intensity, probabilities and both image calibration records.
% Confirm shared origin/crop/registration on real data before continuing.


%% STAGE 2 -- segment objects, then request object measurements
% Sum selected category probabilities before thresholding, as in workflow 1.
c.ForegroundChannels = [3 2];
c.ForegroundThreshold = .6;
c.ObjectSmoothSigma = 2;
if useSynthetic
    c.ObjectSmoothSigma = 0;
end
c.ObjectLoader = []; % Batch alternative: @(frame) mask or labels on intensity grid.
c.ObjectInputType = 'auto';
c.ObjectProperties = {'Volume', 'Centroid'};
c.MeasurementOptions = struct();
c.PhysicalVolume = true;
c.LocalInertia = false;

if ~strcmp(probabilityImage.SpacingUnit, image.SpacingUnit)
    error('memoworkflow:Units', 'Probability and intensity spacing units must match.');
end
extentDifference = abs(double(size(probabilities, 1:3)) .* probabilityImage.Spacing - ...
    double(size(intensity, 1:3)) .* image.Spacing);
if any(extentDifference > 2 * probabilityImage.Spacing)
    error('memoworkflow:Registration', 'Verify probability/image axes and shared crop.');
end
foregroundProbability = sum(probabilities(:, :, :, c.ForegroundChannels), 4);
segmentationMask = foregroundProbability > c.ForegroundThreshold;
if c.ObjectSmoothSigma > 0
    segmentationMask = farmReturnSmoothBlobsBW(segmentationMask, 0, 0, c.ObjectSmoothSigma);
end
mask = imresize3(segmentationMask, size(intensity), 'nearest');

identity = farmMakeObjectOptions('DatasetID', experiment.DatasetID, 'Frame', frame, ...
    'Spacing', image.Spacing, 'SpacingUnit', image.SpacingUnit, ...
    'InputType', c.ObjectInputType);
objects = farmPrepareObjects(mask, identity);
properties = farmMeasureObjects(objects, c.ObjectProperties, c.MeasurementOptions);
if c.PhysicalVolume
    volumeTable = farmMeasureObjects(objects, {'Volume'});
    properties.PhysicalVolume = volumeTable.Volume * prod(image.Spacing);
    properties = farmWorkflowSetColumnUnit(properties, 'PhysicalVolume', [image.SpacingUnit '^3']);
end

% STOP: inspect foregroundProbability, segmentationMask, mask, objects and properties.
% Nearest-neighbor resizing changes the sampling grid; it does not register images.


%% STAGE 3 -- define geometry and reusable sampling supports
c.Supports = {'objects', 'boundary'};
c.GeometryOptions = struct( ...
    'boundary', struct('Sigma', 1, 'LayerMean', 0, 'LayerWidth', 1), ...
    'skeleton', struct('Method', 'blob', 'Sigma', 1));

geometry = struct();
supports = struct('objects', objects);
for supportIndex = 1:numel(c.Supports)
    supportName = c.Supports{supportIndex};
    if ~strcmp(supportName, 'objects')
        geometry.(supportName) = farmGenerateGeometry(objects, supportName, ...
            c.GeometryOptions.(supportName));
        supports.(supportName) = geometry.(supportName);
    end
end

% Distance fields reference the combined foreground, not each object separately.
interiorDistance = bwdist(~logical(mask));
signedDistance = farmSignedBWDist(logical(mask));
fields = struct('Intensity', intensity, 'InteriorDistanceVoxels', interiorDistance);

% STOP: inspect geometry.boundary.Records and supports before requesting statistics.
% Shell width and distance values use voxels; distance transforms are isotropic.
% Adding skeleton requires the project-local GaussDiff dependency.


%% STAGE 4 -- sample fields at the selected geometry locations
c.Queries = [
    farmMakeQuery('Name', 'IntensityOnobjects', 'Field', 'Intensity', ...
        'Support', 'objects', 'Statistics', {'Mean', 'Sum', 'Std'})
    farmMakeQuery('Name', 'IntensityOnboundary', 'Field', 'Intensity', ...
        'Support', 'boundary', 'Statistics', {'Mean', 'Sum', 'Std'})
    farmMakeQuery('Name', 'InteriorDistanceOnobjects', 'Field', 'InteriorDistanceVoxels', ...
        'Support', 'objects', 'Statistics', {'Mean', 'Max'})
    farmMakeQuery('Name', 'InteriorDistanceOnboundary', 'Field', 'InteriorDistanceVoxels', ...
        'Support', 'boundary', 'Statistics', {'Mean', 'Max'})
    ];
c.IncludeDiagnostics = false;
c.ProfileEdges = -12:2:16; % Set [] to skip the additional pooled distance profile.

if isempty(c.Queries)
    sampling = table();
    measurements = properties;
else
    sampling = farmQueryFrame(fields, supports, c.Queries);
    measurements = farmAttachResults(properties, sampling);
end

% Keep diagnostic counts/flags accessible separately from requested statistics.
suffixes = {'SelectedCount', 'FiniteCount', 'NaNCount', 'PositiveInfCount', ...
    'NegativeInfCount', 'SelectionEmpty', 'GeometryEmpty', 'EmptyGeometryCount', ...
    'UsedFallback', 'FallbackCount'};
diagnosticNames = {};
for queryIndex = 1:numel(c.Queries)
    diagnosticNames = [diagnosticNames, strcat(c.Queries(queryIndex).Name, '_', suffixes)]; %#ok<AGROW>
end
keys = {'DatasetID', 'Frame', 'ObjectID'};
if ismember('ComponentID', measurements.Properties.VariableNames)
    keys{end + 1} = 'ComponentID';
end
diagnostics = measurements(:, [keys, diagnosticNames]);
if ~c.IncludeDiagnostics
    measurements = removevars(measurements, diagnosticNames);
end

distanceProfile = [];
if ~isempty(c.ProfileEdges)
    distanceProfile = farmConditionalStatistics(intensity, signedDistance, ...
        struct('Edges', c.ProfileEdges, 'Statistics', {{'Mean', 'Std'}}));
end

% STOP: inspect measurements.IntensityOnboundary_Mean and diagnostics.
% sampling keeps the full query result. distanceProfile.Statistics holds the
% pooled distance-bin results; ExcludedCounts records values outside the edges.
% Rerun only this stage after changing requests, names, statistics or bin edges.


%% DISPLAY -- existing results only; no measurements are recomputed
if showFigures
    boundaryMask = false(size(mask));
    if isfield(geometry, 'boundary')
        boundaryMask = farmGeometryToMatrix(geometry.boundary);
    end
    zIndex = max(1, round(size(intensity, 3) / 2));
    figure('Name', 'Workflow 1: intensity, objects and boundary', ...
        'Position', [100 100 1100 450]);
    subplot(1, 2, 1);
    imagesc(intensity(:, :, zIndex));
    axis image;
    colorbar;
    hold on;
    contour(double(mask(:, :, zIndex)), [.5 .5], 'm');
    contour(double(boundaryMask(:, :, zIndex)), [.5 .5], 'w');
    hold off;
    % Contours must not change the intensity image's color limits.
    sliceValues = intensity(:, :, zIndex);
    finiteValues = double(sliceValues(isfinite(sliceValues)));
    if ~isempty(finiteValues)
        displayLimits = [min(finiteValues), max(finiteValues)];
        if displayLimits(1) == displayLimits(2)
            displayLimits = displayLimits + [-.5 .5];
        end
        caxis(displayLimits);
    end
    colormap(gca, 'gray');
    title(sprintf('Frame %g: objects (magenta), boundary (white)', frame));
    xlabel('X (voxel index)');
    ylabel('Y (voxel index)');

    subplot(1, 2, 2);
    if ~isempty(distanceProfile)
        bins = distanceProfile.Statistics;
        plot((bins.LeftEdge + bins.RightEdge) / 2, bins.Mean, 'o-');
        xlabel('Signed distance (voxel; negative inside)');
        ylabel('Mean intensity');
        title('Pooled distance profile');
    end
    disp(measurements);
end


%% SAVE CURRENT FRAME -- optional; retains selected results in a new directory
c.SaveGeometry = false;
c.SaveSupports = false;
c.Verbose = true;
if savePreview
    previewDirectory = farmWorkflowNewRun(c, 'workflow1-preview');
    payload = struct('Measurements', measurements, 'Diagnostics', diagnostics);
    if ~isempty(distanceProfile)
        payload.DistanceProfile = distanceProfile;
    end
    if c.SaveGeometry
        payload.Geometry = geometry;
    end
    if c.SaveSupports
        payload.Supports = supports;
    end
    farmWorkflowSaveNew(fullfile(previewDirectory, sprintf('frame%03i.mat', frame)), payload);
    fprintf('Workflow 1 preview saved: %s\n', previewDirectory);
end


%% BATCH -- optional; repeat the choices above one frame at a time
% This starts a new run; it does not resume the current workspace frame.
% Frame MAT files hold results, not complete restart checkpoints.
if runBatch
    result = farmWorkflow1Objects(c);
end

% Changing data/frame: rerun STAGES 1-4. Changing segmentation: STAGES 2-4.
% Changing geometry: STAGES 3-4. Changing sampling: STAGE 4 only.
% Rerun DISPLAY and any selected SAVE/BATCH sections after the changed stages.
