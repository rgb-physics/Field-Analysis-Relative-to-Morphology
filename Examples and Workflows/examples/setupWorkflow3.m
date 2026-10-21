% READING GUIDE: edit SETUP / DATA / ANALYSIS first, inspect PREVIEW, then run RUN.
% The local functions below WORKFLOW IMPLEMENTATION execute those choices.
% Source descriptions/options are structs; loaded images are matrices; measurements are tables.


%% WORKFLOW 3 -- editable setup and execution (run sections in order)
% Standalone script. Original sources remain read-only; outputs use fresh tests/data folders.
% Compatibility entry: public workflow wrappers supply workflowInput and skip setup.
if exist('workflowInput','var') && isstruct(workflowInput)
    result = farmWorkflow3Lineage(workflowInput);
    return
end


%% SETUP -- explicit package location (works when running editor sections)
% Change this if you move the package. Source data folders are defined below.
repo = 'C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo';
addpath(repo);
farmSetup('IncludeExamples', true);
here = fullfile(repo,'Examples and Workflows','examples');
apis = {'ImageStackIO','SegmentationTools','ObjectGeometry',...
    'ObjectRelativeProfiles','SharedUtilities','ObjectTracking','FieldAnalysis','VisualizationTools'};
sourceFolders = cellfun(@(api)fullfile(repo,'APIs',api,'src'),apis,'UniformOutput',false);
folders = [sourceFolders,{fullfile(repo,'APIs','Workflows','src'),here}];

% Check all paths before modifying MATLAB's path; fail with a useful message.
for k = 1:numel(folders)
    if ~isfolder(folders{k})
        error('memoworkflow:RepositoryPath', ...
            'Package folder not found: %s. Set repo in the SETUP section to your MeMo root.',folders{k});
    end
end
for k = 1:numel(folders)
    addpath(folders{k});
end



%% DATA -- edit files, axes, calibration and acquisition frames

% ---- Choose acquisition frames; these are file frame numbers, not positions in a list. ----
frames = 10:2:30;
datasetID = 'S88E4';
spacing = [.55 .55 .7]; spacingUnit = 'um'; % YXZ current intensity grid
intDir = 'O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit';
segDir = 'O:\Session 88\all ilastik prep files';
segName = 't%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5';
segSpacing = [1.5 1.5 1.5]; segAxes = 'CXYZ';

% DatasetPath is the array name INSIDE the HDF5 file, not its disk folder.
trackingFrames = 10:30; % successive supplied frames are compared; no gap bridging
timeStep = 30; timeUnit = 's'; % between original acquisition frame numbers
density = farmMakeSource('Folder',intDir, ...
    'NamePattern','t%03i_illBleachCorr16bit_560.tif','Format','tiff', ...
    'SourceAxes','YXZ','Spacing',spacing,'SpacingUnit',spacingUnit);
probabilities = farmMakeSource('Folder',segDir,'NamePattern',segName, ...
    'Format','hdf5','DatasetPath','/exported_data','SourceAxes',segAxes, ...
    'Spacing',segSpacing,'SpacingUnit',spacingUnit);

% ---- EXPERIMENT: collect source descriptions and dataset identity; images are not loaded here. ----
experiment = struct('DatasetID',datasetID,'Frames',unique([frames trackingFrames],'stable'), ...
    'Sources',struct('Intensity560',density,'Probabilities',probabilities));
experiment = farmMakeExperiment(experiment);

% ---- WORKFLOW OPTIONS: c carries the experiment and the analysis choices used below. ----
c = struct('Experiment',experiment,'DatasetID',experiment.DatasetID, ...
    'Frames',unique(double(frames(:).'),'stable'),'RepositoryRoot',repo,'Spacing',spacing,'SpacingUnit',spacingUnit);

% ---- OUTPUT LOCATION: each run creates a new subfolder here. ----
c.OutputRoot = fullfile(repo,'tests', 'data','workflow-results');

% Numbered intensity source names match current workflow roles, not filenames:
% Intensity560 is the primary/density field; Intensity647 is the filament/secondary field.

% Acquisition timing needed by the time plot.
experiment.TimeStep = timeStep; experiment.TimeUnit = timeUnit;
experiment = farmMakeExperiment(experiment); c.Experiment = experiment;
c.TimeStep = timeStep; c.TimeUnit = timeUnit;


%% ANALYSIS -- segmentation, overlap lineage and seed selection
c.TrackingFrames = trackingFrames;
c.ForegroundChannels = [3 2]; c.ForegroundThreshold = .6; c.ObjectSmoothSigma = 2;
c.ObjectLoader = []; c.ObjectInputType = 'auto'; % optional supplied masks/labels
c.SeedFrame = 20; c.SeedObjectID = []; % [] explicitly chooses largest at seed frame

% Ancestors follow parent edges without adding siblings; descendants are separate.
% Trajectory inheritance is distinct from full ancestry. Overlap assumes small displacement.
% This example measures mean/summed intensity and volume on selected detections.
c.ExportTrackingTiffs = false; c.TrackingLabelMode = 'trajectory'; % or 'object'
c.ExportMaskedIntensity = false; c.RetainMasks = false; % dense matrices are opt-in

% OUTPUT CHOICES: numerical tracking/selection data and tables saved by default.
% Inspect manifest/export assignments in the helper below for further selection.


%% PREVIEW -- seed-frame detections and object IDs
if ~ismember(c.SeedFrame,c.TrackingFrames)
    error('memoworkflow:Seed','Choose SeedFrame from TrackingFrames before previewing/running.');
end
raw = farmWorkflowIntensity(c,c.SeedFrame,'560');
[objects,~] = farmWorkflowObjects(c,c.SeedFrame,size(raw));
labels = farmGeometryToMatrix(objects,'OutputType','labels');
z = round(size(raw,3)/2);
figure; subplot(1,2,1); imagesc(raw(:,:,z)); axis image; title('Seed-frame intensity');
subplot(1,2,2); imagesc(labels(:,:,z)); axis image; colorbar; title('Object IDs');
detections = farmMeasureObjects(objects,{'Volume','Centroid'});
disp(detections); % choose c.SeedObjectID using this table

% To change the seed after inspecting, assign c.SeedObjectID before RUN.


%% RUN -- compact links/events, ancestry, descendants, trajectory and measurements
result = farmWorkflow3Lineage(c);
disp(result.Seed); disp(result.Measurements);


%% WORKFLOW IMPLEMENTATION -- helper function, called by RUN above
function manifest = farmWorkflow3Lineage(c)

%WORKFLOW3LINEAGE Light ancestry plus optional per-frame TIFF/heavy matrices.

% ---- START RUN: create the output folder and keep small result tables/file paths in memory. ----
out = farmWorkflowNewRun(c,'workflow3');
firstImage = farmWorkflowIntensity(c,c.TrackingFrames(1),'560'); gridSize = size(firstImage); clear firstImage

% Link immediate supplied frames; preserve splits/merges as parent-child edges.

% ---- TRACK: link overlapping detections between successive supplied frames, retaining split/merge edges. ----
tracking = farmTrackOverlaps(c.TrackingFrames,@loadObjects,struct('DatasetID',c.DatasetID));

% ---- CHOOSE SEED: use the requested object ID, or the largest detection in the seed frame. ----
frameRows = tracking.Detections(tracking.Detections.Frame==c.SeedFrame,:);
if isempty(frameRows), error('memoworkflow:Seed','No detection in seed frame.'); end
if isempty(c.SeedObjectID), [~,largest] = max(frameRows.VoxelCount); seedID = frameRows.ObjectID(largest);
else, seedID = c.SeedObjectID; end
seed = struct('Frame',c.SeedFrame,'ObjectIDs',seedID);

% ---- TRAVERSE LINEAGE: collect parents backward and children forward as separate selections. ----
ancestors = farmSelectLineage(tracking,seed,struct('Direction','ancestors'));
descendants = farmSelectLineage(tracking,seed,struct('Direction','descendants'));
seedRow = frameRows(frameRows.ObjectID==seedID,:);
trajectory = tracking.Detections(ismember(tracking.Detections.TrajectoryID,seedRow.TrajectoryID),:);

% ---- MEASUREMENT MEMBERSHIP: combine the selected ancestors and descendants by detection identity. ----
selected = union(ancestors.Detections.DetectionID,descendants.Detections.DetectionID);
membership = tracking.Detections(ismember(tracking.Detections.DetectionID,selected),:);
tables = {}; heavy = {};

% ---- MEASURE SELECTED FRAMES: load one intensity volume and sample its object supports. ----
for frame = unique(membership.Frame)'
    a = farmWorkflowIntensity(c,frame,'560'); objects = loadObjects(frame);
    properties = farmMeasureObjects(objects,{'Volume'});
    stats = farmQueryField(a,objects,{'Mean','Sum'},struct('FieldName','Intensity'));
    properties = farmAttachResults(properties,stats);
    properties = farmAttachMembership(properties,tracking.Detections);
    properties = properties(ismember(properties.DetectionID,selected),:);
    properties.PhysicalVolume = properties.Volume*prod(c.Spacing);
    properties = farmWorkflowSetColumnUnit(properties,'PhysicalVolume',[c.SpacingUnit '^3']);
    tables{end+1} = properties; %#ok<AGROW>

    % ---- OPTIONAL DENSE OUTPUTS: render labels/masks only when one of these exports is requested. ----
    if c.ExportTrackingTiffs||c.RetainMasks||c.ExportMaskedIntensity
        rows = tracking.Detections(tracking.Detections.Frame==frame,:);
        mode = validatestring(c.TrackingLabelMode,{'trajectory','object'});
        if strcmp(mode,'object'), rows.TrajectoryID = rows.ObjectID; end
        labels = farmRenderTrackingFrame(objects,rows);
        if strcmp(mode,'object'), selectedIDs = membership.ObjectID(membership.Frame==frame);
        else, selectedIDs = membership.TrajectoryID(membership.Frame==frame); end
        selectionMask = ismember(labels,selectedIDs);
        labels(~selectionMask) = 0;
        if c.ExportTrackingTiffs
            if max(labels(:))>65535, error('memoworkflow:IDs','TIFF IDs exceed uint16; use compact export explicitly.'); end
            farmWriteTiff(uint16(labels),fullfile(out,sprintf('selected_%sIDs_t%03i.tif',mode,frame)), ...
                struct('Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit));
        end
        if c.ExportMaskedIntensity
            masked = a; masked(~selectionMask) = 0;
            farmWriteTiff(masked,fullfile(out,sprintf('selectedIntensity_t%03i.tif',frame)), ...
                struct('Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit));
        end
        if c.RetainMasks, heavy{end+1} = struct('Frame',frame,'Mask',selectionMask,'Labels',labels,'LabelMode',mode); end %#ok<AGROW>
    end
end

% OUTPUT CHOICES: compact lineage and measurement data; heavy masks are opt-in.

% ---- COMBINED OUTPUT: return the run directory and the retained tables or per-frame file paths. ----
manifest = struct('Directory',out,'Tracking',tracking,'Seed',seed,'Ancestors',ancestors, ...
    'Descendants',descendants,'Trajectory',trajectory,'Measurements',farmConcatenateMeasurements(tables));
if c.RetainMasks, manifest.HeavyMasks = heavy; end
farmWorkflowSaveNew(fullfile(out,'manifest.mat'),manifest);

% ---- SUMMARY FIGURE: show the selected lineage graph and intensity histories. ----
f = figure('Visible','off'); cleanup = onCleanup(@()close(f));
subplot(1,2,1);
g = farmLineageGraph(tracking);
g = subgraph(g,find(ismember(g.Nodes.DetectionID,selected)));
plot(g,'Layout','layered'); title('Selected ancestry and descendants');
subplot(1,2,2); hold on;
t = manifest.Measurements;
if isfield(c,'TimeStep')
    timeStep = c.TimeStep; timeUnit = c.TimeUnit;
else
    timeStep = c.TimeStepSeconds; timeUnit = 's'; % legacy configuration
end
for trajectoryID = unique(t.TrajectoryID)'
    rows = t(t.TrajectoryID==trajectoryID,:); rows = sortrows(rows,'Frame');
    plot((rows.Frame-1)*timeStep,rows.Intensity_Mean,'-o');
end
xlabel(['Time from frame 1 (' char(timeUnit) ')']); ylabel('Mean corrected intensity');
farmFigSaves(f,out,'lineage-and-measurements','png',true); clear cleanup
fprintf('Workflow 3 outputs: %s\n',out);

    % ---- LOADER CALLBACK: the tracker requests objects for one frame at a time. ----
    function objects = loadObjects(frame)
        objects = farmWorkflowObjects(c,frame,gridSize);
    end
end
