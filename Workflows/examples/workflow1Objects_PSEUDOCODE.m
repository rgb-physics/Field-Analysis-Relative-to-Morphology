%% WORKFLOW 1: measure objects and sample fields on chosen geometry
% FOR VISUAL REVIEW ONLY. This script does not run.
% BUILD_* = proposed builders; LOAD_*/ALIGN_*/SAVE_* = workflow placeholders.
% Lowercase package-qualified calls refer to existing APIs.
% Builder names and signatures below are proposals, not implemented contracts.

%% 1. USER INPUT: describe the dataset (reuse this for other analyses)
datasetID = 'MyExperiment';
frames = 10:2:30;
secondsPerFrame = 30;

% Each source owns its calibration: probability data may be on another grid.
intensitySource = BUILD_DATA_SOURCE( ...
    Folder='<quantitative intensity folder>', ...
    NamePattern='t%03i_intensity.tif', ...
    Format='tiff', SourceAxes='YXZ', ...
    SpacingYXZ=[0.55 0.55 0.7], SpacingUnit='um');

probabilitySource = BUILD_DATA_SOURCE( ...
    Folder='<probability folder>', ...
    NamePattern='t%03i_probabilities.h5', ...
    Format='hdf5', DatasetPath='/exported_data', SourceAxes='CXYZ', ...
    SpacingYXZ=[1.5 1.5 1.5], SpacingUnit='um');

% Alternative to probabilities: a named source of prepared masks or ID labels.
% objectSource = BUILD_DATA_SOURCE(..., Representation='labels');
% Supplied IDs remain distinct, including disconnected pieces with one ID.

experiment = BUILD_EXPERIMENT( ...
    DatasetID=datasetID, Frames=frames, TimeStep=secondsPerFrame, TimeUnit='s', ...
    Sources=struct('Intensity',intensitySource, ...
                   'Probabilities',probabilitySource));

%% 2. USER INPUT: choose what this analysis should do
% These configurations describe tasks; they do not load images.
% This example uses an object foreground made by summing probability channels.
segmentation = BUILD_OBJECT_SEGMENTATION( ...
    Source='Probabilities', ForegroundChannels=[3 2], ...
    ForegroundThreshold=0.6, SmoothSigmaVoxels=2);

objectPreparation = BUILD_OBJECT_PREPARATION(InputType='mask');
% With supplied IDs, choose InputType='labels' and bypass segmentation.
% DatasetID, Frame and current-grid calibration will be supplied at execution.

measurements = BUILD_OBJECT_MEASUREMENTS( ...
    NativeProperties={'Volume','Centroid'}, PhysicalVolume=true);
% Native Volume remains a voxel count; PhysicalVolume is a separate column.

geometry = BUILD_GEOMETRY_REQUESTS( ...
    Supports={'objects','boundary','skeleton'}, SigmaVoxels=1);
% 'objects' uses all object indices. Other supports are generated on request.
% Skeletons are sampling geometry, not filament objects.
% Empty skeletons retain their flags; centroid fallback remains identifiable.

queries = BUILD_SAMPLING_QUERIES( ...
    QUERY(Field='Intensity', ...
          Supports={'objects','boundary','skeleton'}, ...
          Statistics={'Mean','Sum','Std'}, ...
          OutputPrefixes={'IntensityOnObjects','IntensityOnBoundary', ...
                          'IntensityOnSkeleton'}), ...
    QUERY(Field='InteriorDistanceVoxels', ...
          Supports={'objects','boundary','skeleton'}, ...
          Statistics={'Mean','Max'}, ...
          OutputPrefixes={'InteriorDistanceOnObjects', ...
                          'InteriorDistanceOnBoundary', ...
                          'InteriorDistanceOnSkeleton'}));
% QUERY is also a placeholder. The builder expands requests into queryFrame's
% Name/Field/Support/Statistics structs; user names become column prefixes.

localInertia = BUILD_LOCAL_INERTIA_REQUEST( ...
    Enabled=false, Locations='skeleton', ...
    RadiusVoxels=18, SigmaVoxels=3, SampleLimit=10000);

output = BUILD_OUTPUT_OPTIONS( ...
    Root='<package>/test-data/workflow-results', ...
    FreshRunDirectory=true, SaveFrameTables=true, RetainGeometry=false);
% Source files are read-only. Output choices govern saved results.

%% 3. OPTIONAL: collect choices into a thin run specification
% Direct API calls can also use the individual configurations above.
run = BUILD_RUN(experiment, Frames=frames, ...
    Segmentation=segmentation, ObjectPreparation=objectPreparation, ...
    Measurements=measurements, Geometry=geometry, Queries=queries, ...
    LocalInertia=localInertia, Output=output);
CHECK_RUN_CONFIGURATION(run);  % names/required choices, before large loads

%% 4. EXECUTION OUTLINE: one frame at a time
outputFolder = CREATE_FRESH_OUTPUT_DIRECTORY(output);
frameTables = cell(numel(frames),1);  % small tables, not image stacks

for frameIndex = 1:numel(frames)
    frame = frames(frameIndex);

    % Load quantitative intensity without per-frame stretching/thresholding.
    intensityImage = LOAD_SOURCE(experiment, 'Intensity', frame);
    probabilityImage = LOAD_SOURCE(experiment, 'Probabilities', frame);

    % Apply segmentation on its own grid, then map the mask to intensity grid.
    mask = SEGMENT_OBJECTS(probabilityImage, segmentation);
    mask = ALIGN_MASK_TO_GRID(mask, probabilityImage, intensityImage);
    % Verify shared physical crop/registration; equal sizes are insufficient.
    % Mask resampling uses nearest-neighbor. Record mapping/grid provenance.
    % Supplied same-grid masks/labels skip these probability steps entirely.

    identityOptions = PREPARATION_OPTIONS_FOR_FRAME( ...
        objectPreparation, experiment.DatasetID, frame, intensityImage);
    objects = objectgeometry.objects.prepareObjects(mask, identityOptions);

    % One keyed row per object, with native properties requested by the user.
    properties = objectgeometry.objects.measureObjects( ...
        objects, measurements.NativeProperties);
    properties = ADD_REQUESTED_PHYSICAL_MEASUREMENTS( ...
        properties, objects.Grid, measurements);

    % Generate each requested support once; reuse across all field queries.
    supports.objects = objects;
    supports = GENERATE_REQUESTED_SUPPORTS(objects, supports, geometry);
    % This adapter calls objectgeometry.objects.generateGeometry as needed.

    fields.Intensity = FIELD_WITH_GRID(intensityImage.Data, objects.Grid);
    distance = bwdist(~logical(mask));  % interior distance magnitude in voxels
    fields.InteriorDistanceVoxels = FIELD_WITH_GRID(distance, objects.Grid);
    % This illustrative distance uses the union foreground mask. An ID-specific
    % reference or physical-distance calculation would be an explicit choice.

    results = objectrelativeprofiles.fieldSampling.queryFrame( ...
        fields, supports, queries);
    properties = objectrelativeprofiles.fieldSampling.attachResults( ...
        properties, results);
    % Attach by DatasetID/Frame/ObjectID (and sampling ComponentID as needed),
    % not row order. Keep empty/fallback/nonfinite counts and metadata.

    % Optional independent geometric analysis; not a scalar field query.
    inertiaResults = CALCULATE_LOCAL_INERTIA_IF_REQUESTED( ...
        mask, supports, objects.Grid, localInertia);

    SAVE_FRAME_RESULTS(outputFolder, frame, properties, ...
                       supports, inertiaResults, output);
    frameTables{frameIndex} = properties;

    % Release large arrays before the next time point. No XYZT preload.
    clear intensityImage probabilityImage mask distance fields supports objects
end

%% 5. Collect small results for plotting/filtering and later field additions
allMeasurements = objectgeometry.objects.concatenateMeasurements(frameTables);
SAVE_RUN_RESULTS(outputFolder, allMeasurements, run);

% Later: reload a frame and its identified objects/supports, query another
% field, then attach new columns by keys. Saved configurations describe how
% to reconstruct supports when RetainGeometry=false; source data must remain
% available. Do not align independently generated objects by table row order.
