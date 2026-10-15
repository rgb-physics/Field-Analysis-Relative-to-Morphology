% READING GUIDE: edit SETUP / DATA / ANALYSIS first, inspect PREVIEW, then run RUN.
% The local functions below WORKFLOW IMPLEMENTATION execute those choices.
% Source descriptions/options are structs; loaded images are matrices; measurements are tables.


%% WORKFLOW 2 -- editable setup and execution (run sections in order)
% Standalone script. Original sources remain read-only; outputs use fresh test-data folders.
% Compatibility entry: public workflow wrappers supply workflowInput and skip setup.
if exist('workflowInput','var') && isstruct(workflowInput)
    result = farmWorkflow2Filaments(workflowInput);
    return
end


%% SETUP -- explicit package location (works when running editor sections)
% Change this if you move the package. Source data folders are defined below.
repo = 'C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo';
addpath(repo);
farmSetup('IncludeExamples', true);
here = fullfile(repo,'Workflows','examples');
apis = {'ImageStackIO','SegmentationTools','ObjectGeometry',...
    'ObjectRelativeProfiles','SharedUtilities','ObjectTracking','FieldAnalysis','VisualizationTools'};
sourceFolders = cellfun(@(api)fullfile(repo,'APIs',api,'src'),apis,'UniformOutput',false);
folders = [sourceFolders,{fullfile(repo,'Workflows','src'),here}];

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
frames = 28:30;
datasetID = 'S88E4';
spacing = [.55 .55 .7]; spacingUnit = 'um'; % YXZ current intensity grid
intDir = 'O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit';
segDir = 'O:\Session 88\all ilastik prep files';
segName = 't%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5';
segSpacing = [1.5 1.5 1.5]; segAxes = 'CXYZ';

% DatasetPath is the array name INSIDE the HDF5 file, not its disk folder.
filaments = farmMakeSource('Folder',intDir, ...
    'NamePattern','t%03i_illBleachCorr16bit_647.tif','Format','tiff', ...
    'SourceAxes','YXZ','Spacing',spacing,'SpacingUnit',spacingUnit);
probabilities = farmMakeSource('Folder',segDir,'NamePattern',segName, ...
    'Format','hdf5','DatasetPath','/exported_data','SourceAxes',segAxes, ...
    'Spacing',segSpacing,'SpacingUnit',spacingUnit);

% ---- EXPERIMENT: collect source descriptions and dataset identity; images are not loaded here. ----
experiment = struct('DatasetID',datasetID,'Frames',frames, ...
    'TimeStep',30,'TimeUnit','s', ...
    'Sources',struct('Intensity647',filaments,'Probabilities',probabilities));
experiment = farmMakeExperiment(experiment);

% ---- WORKFLOW OPTIONS: c carries the experiment and the analysis choices used below. ----
c = struct('Experiment',experiment,'DatasetID',experiment.DatasetID, ...
    'Frames',unique(double(frames(:).'),'stable'),'RepositoryRoot',repo,'Spacing',spacing,'SpacingUnit',spacingUnit);

% ---- OUTPUT LOCATION: each run creates a new subfolder here. ----
c.OutputRoot = fullfile(repo,'test-data','workflow-results');

% Numbered intensity source names match current workflow roles, not filenames:
% Intensity560 is the primary/density field; Intensity647 is the filament/secondary field.


%% ANALYSIS -- filament extraction, semantic reference and orientation selection

% ---- FILAMENT DETECTION: use a supplied mask loader or threshold the filtered intensity. ----
c.FilamentLoader = []; % optional @(frame) -> same-grid binary filament mask
c.FilamentSigma = 1; c.FilamentThreshold = 20; % threshold applies to -LoG response
c.MinFilamentLength = 0; c.MinAspectRatio = 0; % flags retain all measurements
c.MaxZComponent = []; % optional 0..1 filter before projected XY nematic alignment

% ---- REFERENCE CATEGORIES: map probability channels to inside, wall and outside. ----
c.SemanticChannels = [3 2 1]; % input channel numbers for INSIDE, WALL, OUTSIDE
c.Thresholds = [.33 .33 .33]; c.OpeningRadius = 1;
c.ProfileSigma = 2; % distance-gradient smoothing sigma in intensity-grid voxels

% Filaments are image objects; no blob skeleton is generated here.
% Measurements include native and scaled-covariance directions/extents.
% The reference is sampled at filament centroids. Invalid/zero directions are flagged.
% 3-D nematic and projected XY nematic order are distinct outputs.
% OUTPUT CHOICES: inspect the payload/manifest assignments in the helper below.


%% PREVIEW -- check filament intensity, extraction and semantic registration
frame = frames(1);
raw = farmWorkflowIntensity(c,frame,'647');
if isempty(c.FilamentLoader)
    response = -farmLOG(double(raw),c.FilamentSigma);
    options = farmMakeIntensityOptions('Method','fixed','Threshold',c.FilamentThreshold);
    extracted = farmSegmentIntensity(response,options);
    previewMask = extracted.Mask;
else
    previewMask = c.FilamentLoader(frame);
end
[semantic,~] = farmWorkflowRegions(c,frame,size(raw));
z = round(size(raw,3)/2);
figure;
subplot(1,3,1); imagesc(raw(:,:,z)); axis image; title('Filament intensity');
subplot(1,3,2); imagesc(previewMask(:,:,z)); axis image; title('Extracted filaments');
subplot(1,3,3); imagesc(semantic(:,:,z)); axis image; clim([0 3]); colorbar;
title('0 unclassified; 1 inside; 2 wall; 3 outside');

% Verify crop/origin and channel semantics by eye before interpreting alignment.


%% RUN -- frame tables, combined filament table and first-frame semantic PNG
result = farmWorkflow2Filaments(c);
disp(result.Filaments);


%% VIEW -- scaled filament directors and distance gradients on an XY cut
% Run after RUN; change these inputs and rerun this section to explore.
viewFrame = c.Frames(1);
viewZRange = []; % [] = middle slice; e.g. 68:72 selects centroids in that slab
viewBackground = 'channels'; % 'channels' or 'distance'
viewChannels = [1 2 3]; % semantic inside/wall/outside -> red/green/blue
viewSelectedOnly = true; % false also shows filaments rejected by analysis filters
viewGradientLength = 5; % physical units; vectors normalized in 3-D, then projected
viewMaxFilaments = 1000; % display thinning only; measurements stay unchanged
viewFigure = plotWorkflow2Cut(c,result.Filaments,viewFrame,viewZRange, ...
    viewBackground,viewChannels,viewSelectedOnly,viewGradientLength,viewMaxFilaments);

% Optional export to a new filename:
% exportgraphics(viewFigure,fullfile(result.Directory,'filament-directors.png'));


%% WORKFLOW IMPLEMENTATION -- helper function, called by RUN above
function manifest = farmWorkflow2Filaments(c)

%WORKFLOW2FILAMENTS Centroid association with semantic/distance vector fields.

% ---- START RUN: create the output folder and keep small result tables/file paths in memory. ----
out = farmWorkflowNewRun(c,'workflow2'); tables = cell(numel(c.Frames),1);

% ---- PROCESS ONE FRAME AT A TIME: load, calculate, save, then continue to the next frame. ----
for k = 1:numel(c.Frames)
    frame = c.Frames(k); timer = tic;

    % Load one filament intensity volume; supplied masks bypass extraction.
    raw = farmWorkflowIntensity(c,frame,'647');
    if isempty(c.FilamentLoader)
        response = -farmLOG(double(raw),c.FilamentSigma);
        segmentation = farmSegmentIntensity(response, ...
            struct('Method','fixed','Threshold',c.FilamentThreshold)); mask = segmentation.Mask;
    else
        mask = c.FilamentLoader(frame);
    end

    % ---- MEASURE FILAMENTS: preserve frame/object identity and record current-grid voxel spacing. ----
    identity = struct('DatasetID',c.DatasetID,'Frame',frame,'Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit);
    properties = farmMeasureFilaments(mask, ...
        {'Volume','Centroid','Directors','ExtentInVoxels','AspectRatios','ScaledDirectors','ProjectedExtent','ScaledAspectRatios'}, ...
        struct('Identity',identity,'ExtentWidthFloor',eps));

    % Generate semantic/distance reference; sample it at filament centroids.

    % ---- REFERENCE FIELDS: create boundary distance, its gradient and the segmented categories. ----
    [distance,g,valid,regions,referenceInfo] = farmWorkflowReference(c,frame,size(mask));

    % ---- SAMPLE: convert centroid XYZ coordinates to MATLAB linear indices in the YXZ volume. ----
    xyz = round(properties.Centroid);
    indices = sub2ind(size(mask),xyz(:,2),xyz(:,1),xyz(:,3));
    reference = zeros(height(properties),3);
    for d = 1:3, field = g(:,:,:,d); reference(:,d) = field(indices); end
    properties.CoMIndices = indices; properties.BoundaryDistance = distance(indices);
    properties.RegionClass = regions(indices); properties.ReferenceValid = valid(indices);
    properties.ReferenceDirectionValid = referenceInfo.DirectionValid(indices);
    properties.DistanceGradient = reference;

    % Use scaled-covariance directions, without resampling the filament image.

    % ---- ALIGNMENT: compare physical-space filament directions with the sampled distance gradients. ----
    directors = properties.ScaledDirectors;
    finite = all(isfinite(directors),2)&all(isfinite(reference),2);
    order3 = NaN(height(properties),1); order2 = order3; angle2 = order3;
    a = farmNematicAlignment(directors(finite,:),reference(finite,:));
    options = struct('Plane',[1 2],'MaxNormalComponent',c.MaxZComponent);
    b = farmNematicAlignment(directors(finite,:),reference(finite,:),options);
    order3(finite) = a.Order; order2(finite) = b.Order; angle2(finite) = b.SignedAngle;
    properties.Order3D = order3; properties.Order2D = order2; properties.SignedAngle2D = angle2;

    % ---- SELECTION: flag detections passing the filters; keep rejected detections in the table. ----
    properties.Selected = properties.ReferenceValid&properties.ReferenceDirectionValid& ...
        properties.ProjectedExtent>=c.MinFilamentLength&properties.ScaledAspectRatios>=c.MinAspectRatio;

    % Separate selection flag; raw measurements are retained.

    % ---- RETAIN AND SAVE: keep the small table across frames; dense images remain optional. ----
    tables{k} = properties;

    % OUTPUT CHOICES: explicit retained results; matrices/indices are opt-in.
    payload = struct('Filaments',properties,'Seconds',toc(timer));
    payload.ReferenceInfo = rmfield(referenceInfo,'DirectionValid');

    % payload.FilamentMask=mask;
    % payload.Distance=distance; payload.DistanceGradient=g;
    farmWorkflowSaveNew(fullfile(out,sprintf('frame%03i.mat',frame)),payload);
    if k==1
        z = round(size(mask,3)/2); f = figure('Visible','off'); cleanup = onCleanup(@()close(f));
        subplot(1,2,1); imagesc(raw(:,:,z)); axis image; title('Filament intensity');
        subplot(1,2,2); imagesc(regions(:,:,z)); axis image; clim([0 3]); colorbar; title('0 unclassified; 1 inside; 2 wall; 3 outside');
        farmFigSaves(f,out,'semantic-preview','png',true); clear cleanup
    end
end

% ---- COMBINED OUTPUT: return the run directory and the retained tables or per-frame file paths. ----
manifest = struct('Directory',out,'Filaments',farmConcatenateMeasurements(tables));
farmWorkflowSaveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 2 outputs: %s\n',out);
end

% ---- VIEW HELPER: reload one frame and draw stored measurements; this does not rerun filament detection. ----
function f = plotWorkflow2Cut(c,filaments,frame,zRange,background,channels,selectedOnly,gradientLength,maxFilaments)

% Adapted from archived Display_Filaments2DCuts and filBackBonesND.
% Background: central slice. Vectors: filament centroids within the Z slab.
% Physical XY coordinates account for anisotropic image spacing.
if ~ismember(frame,c.Frames), error('memoworkflow:ViewFrame','Choose a frame from c.Frames.'); end
background = validatestring(background,{'channels','distance'});
validateattributes(channels,{'numeric'},{'vector','integer','>=',1,'<=',3,'numel',3});
validateattributes(gradientLength,{'numeric'},{'scalar','finite','positive'});
validateattributes(maxFilaments,{'numeric'},{'scalar','integer','positive','finite'});
raw = farmWorkflowIntensity(c,frame,'647');

% Regenerate the reference, so the view needs no saved full-volume payload.
% regions contains thresholded semantic channels, nearest-neighbour resampled.
[distance,~,~,regions] = farmWorkflowReference(c,frame,size(raw));
if isempty(zRange), zRange = round(size(raw,3)/2); end
validateattributes(zRange,{'numeric'},{'vector','nonempty','integer','>=',1,'<=',size(raw,3)});
z = round(mean(zRange));
x = (0:size(raw,2)-1)*c.Spacing(2); y = (0:size(raw,1)-1)*c.Spacing(1);
f = figure('Name','Workflow 2: directors and distance gradients'); ax = axes(f);
if strcmp(background,'channels')
    rgb = zeros(size(raw,1),size(raw,2),3);
    for channel = 1:3, rgb(:,:,channel) = regions(:,:,z)==channels(channel); end
    image(ax,x,y,rgb);
    backgroundLabel = sprintf('RGB semantic classes [%d %d %d]',channels);
else
    imagesc(ax,x,y,distance(:,:,z)); colormap(ax,parula); cb = colorbar(ax);
    cb.Label.String = ['Boundary distance (' c.SpacingUnit ')'];
    backgroundLabel = 'boundary distance';
end
axis(ax,'image'); set(ax,'YDir','reverse'); hold(ax,'on');

% ---- VIEW SELECTION: restrict the display to this frame, the requested Z slab and valid directions. ----
t = filaments(filaments.Frame==frame,:);
keep = ismember(round(t.Centroid(:,3)),zRange);
if selectedOnly, keep = keep&t.Selected; end
keep = keep&all(isfinite(t.Centroid),2)&all(isfinite(t.ScaledDirectors),2)& ...
    isfinite(t.ProjectedExtent)&t.ProjectedExtent>0;
rows = find(keep);
if numel(rows)>maxFilaments
    rows = rows(unique(round(linspace(1,numel(rows),maxFilaments))));
end
t = t(rows,:);

% ---- DRAW DIRECTORS: place physical-length line segments around the filament centroids. ----
centers = (t.Centroid-1).*c.Spacing([2 1 3]); % voxel centers -> physical XYZ

% ScaledDirectors are already physical unit vectors; avoid a second scaling.
bb = farmFilBackBonesND(centers',t.ProjectedExtent',t.ScaledDirectors');
xx = [bb(1).BBs;nan(1,height(t))]; yy = [bb(2).BBs;nan(1,height(t))];
hDirector = plot(ax,xx(:),yy(:),'-','Color',[1 .2 .2],'LineWidth',1.3);

% ---- DRAW REFERENCE: normalize the stored gradients in 3-D before displaying their XY components. ----
g = t.DistanceGradient; magnitude = sqrt(sum(g.^2,2));
valid = all(isfinite(g),2)&magnitude>0&t.ReferenceValid&t.ReferenceDirectionValid;
g = g(valid,:)./magnitude(valid); % normalize in 3-D before projecting into XY
hGradient = quiver(ax,centers(valid,1),centers(valid,2), ...
    gradientLength*g(:,1),gradientLength*g(:,2),0,'Color',[0 1 1],'LineWidth',1);
legend(ax,[hDirector hGradient],{'Scaled filament director','Distance gradient'},'Location','best');
xlabel(ax,['X (' c.SpacingUnit ')']); ylabel(ax,['Y (' c.SpacingUnit ')']);
title(ax,sprintf('Frame %g | Z slice %d, slab %d:%d | %s | %d filaments', ...
    frame,z,min(zRange),max(zRange),backgroundLabel,height(t)));
hold(ax,'off');
end
