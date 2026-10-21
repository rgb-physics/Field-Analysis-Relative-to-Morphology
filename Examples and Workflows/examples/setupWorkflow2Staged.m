%% WORKFLOW 2, STAGED -- run sections in order for ONE frame
% Alternative to setupWorkflow2.m. The original workflow is unchanged.
% Each section introduces its inputs immediately before the relevant API call.
% There is no farmWorkflow2Filaments(c) call hiding the analysis below this setup.
%
% c.Experiment = file descriptions, frame identity and acquisition metadata.
% c.Options    = instructions, grouped by calculation.
% c.Images     = loaded/generated matrices for the CURRENT frame only.
% c.Results    = measured tables and reference metadata.
% c.Grid       = current intensity-grid calibration, in YXZ order.
%
% These group names organize this example; they are not a new API schema.
% APIs receive the individual arguments shown at each call, not the whole c.
% Changing an earlier stage requires rerunning the downstream stages.
% To inspect another frame, change frame below and rerun from STEP 1.
% Do not accumulate c.Images across frames: these are large XYZ matrices.


%% SETUP -- package location
repo = 'C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo';
addpath(repo);
farmSetup('IncludeExamples', true);
here = fullfile(repo,'Examples and Workflows','examples');
apis = {'ImageStackIO','SegmentationTools','ObjectGeometry','SharedUtilities','VisualizationTools'};

for k = 1:numel(apis)
    folder = fullfile(repo,'APIs',apis{k},'src');
    if ~isfolder(folder)
        error('memoworkflow:RepositoryPath','Set repo to your MeMo root. Missing: %s',folder);
    end
    addpath(folder);
end
addpath(fullfile(repo,'APIs','Workflows','src'));
addpath(here);


%% STEP 1 -- describe the sources and choose ONE frame
% EDIT HERE: paths, filename patterns, axes, calibration and frame number.
% makeSource describes a file source; it does not load its image yet.
frame = 28;

intensitySource = farmMakeSource( ...
    'Folder','O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit', ...
    'NamePattern','t%03i_illBleachCorr16bit_647.tif', ...
    'Format','tiff','SourceAxes','YXZ', ...
    'Spacing',[.55 .55 .7],'SpacingUnit','um');

probabilitySource = farmMakeSource( ...
    'Folder','O:\Session 88\all ilastik prep files', ...
    'NamePattern','t%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5', ...
    'Format','hdf5','DatasetPath','/exported_data','SourceAxes','CXYZ', ...
    'Spacing',[1.5 1.5 1.5],'SpacingUnit','um');

% Restart the current-frame workspace, so old results cannot survive a new frame.
c = struct();
c.Experiment = farmMakeExperiment( ...
    'DatasetID','S88E4','Frames',frame,'TimeStep',30,'TimeUnit','s', ...
    'Sources',struct('FilamentIntensity',intensitySource,'Probabilities',probabilitySource));
c.Frame = frame;
c.Options = struct();
c.Images = struct();
c.Results = struct();


%% STEP 2 -- ImageStackIO: load the filament intensity
% INPUT: the named source and current acquisition frame.
% OUTPUT: one XYZ intensity matrix plus its current-grid metadata.
image = farmLoadSource(c.Experiment,'FilamentIntensity',c.Frame);
if size(image.Data,4)~=1
    error('memoworkflow:Channels','Select one filament intensity channel.');
end
c.Images.Intensity = image.Data(:,:,:,1,1);
c.Grid = struct('Size',size(c.Images.Intensity), ...
    'Spacing',image.Spacing,'SpacingUnit',image.SpacingUnit);
clear image


%% STEP 3 -- SegmentationTools: extract filament voxels
% EDIT HERE: filtering scale and threshold; threshold acts on the -LoG response.
% A supplied binary mask can replace these calls by assigning c.Images.FilamentMask.
c.Options.Extraction = struct('Sigma',1);
c.Options.Threshold = farmMakeIntensityOptions( ...
    'Method','fixed','Threshold',20);

response = -farmLOG( ...
    double(c.Images.Intensity),c.Options.Extraction.Sigma);
segmented = farmSegmentIntensity(response,c.Options.Threshold);
c.Images.FilamentMask = segmented.Mask;
clear response segmented

% INSPECT: intensity and the resulting mask on the middle Z slice.
z = round(c.Grid.Size(3)/2);
figure('Name','Staged workflow 2: filament extraction');
subplot(1,2,1);
imagesc(c.Images.Intensity(:,:,z)); axis image; title('Filament intensity');
subplot(1,2,2);
imagesc(c.Images.FilamentMask(:,:,z)); axis image; title('Filament mask');


%% STEP 4 -- ObjectGeometry: measure each detected filament
% EDIT HERE: the table columns to calculate and the positive width floor.
% Filaments are connected image structures; this does not generate skeletons.
c.Options.Properties = {'Volume','Centroid','Directors','ExtentInVoxels', ...
    'AspectRatios','ScaledDirectors','ProjectedExtent','ScaledAspectRatios'};
c.Options.Measurement = struct('ExtentWidthFloor',eps);
c.Options.Measurement.Identity = struct( ...
    'DatasetID',c.Experiment.DatasetID,'Frame',c.Frame, ...
    'Spacing',c.Grid.Spacing,'SpacingUnit',c.Grid.SpacingUnit);

c.Results.Filaments = farmMeasureFilaments( ...
    c.Images.FilamentMask,c.Options.Properties,c.Options.Measurement);
disp(c.Results.Filaments);

% ExtentInVoxels is the native equivalent-ellipsoid major-axis length.
% ProjectedExtent is a voxel-center span fitted in physical coordinates.
% Keep Centroid and ScaledDirectors above: the next stages require them.


%% STEP 5 -- SegmentationTools: prepare the inside / wall / outside reference
% EDIT HERE: INPUT channel numbers in the desired inside, wall, outside order.
% Earlier channels win overlaps unless ChannelPrecedence is explicitly supplied.
c.Options.Categories = struct('Channels',[3 2 1],'Thresholds',[.33 .33 .33]);
c.Options.ProbabilitySmoothing = struct('OpeningRadius',1);

image = farmLoadSource(c.Experiment,'Probabilities',c.Frame);
if ~strcmp(image.SpacingUnit,c.Grid.SpacingUnit)
    error('memoworkflow:Units','Probability and intensity spacing units must match.');
end
p = image.Data(:,:,:,:,1);
extentError = abs(double(size(p,1:3)).*image.Spacing-c.Grid.Size.*c.Grid.Spacing);
if any(extentError>2*image.Spacing)
    error('memoworkflow:Registration','Check source axes, crops and spacing: physical extents disagree.');
end

[masks,info] = farmSmoothNChannelProbabilities( ...
    p,c.Options.Categories.Channels,c.Options.Categories.Thresholds, ...
    c.Options.ProbabilitySmoothing);
labels = zeros(size(p,1),size(p,2),size(p,3),'uint8');
for category = 1:3
    current = masks(:,:,:,category);
    labels(current) = category;
end
c.Images.Regions = imresize3(labels,c.Grid.Size,'nearest');

info.SourceGridSize = size(p,1:3);
if isfield(image,'SourceAxes'), info.SourceAxes = image.SourceAxes;
else, info.SourceAxes = image.Axes; end
info.PhysicalExtentError = extentError;
info.SemanticOrder = {'inside','wall','outside'};
c.Results.ReferenceInfo = info;
clear image p masks labels current info

% INSPECT: 0 = unclassified, 1 = inside, 2 = wall, 3 = outside.
% Matching physical extents does not prove the crops/origins are registered.
figure('Name','Staged workflow 2: reference categories');
imagesc(c.Images.Regions(:,:,z)); axis image; clim([0 3]); colorbar;
title('0 unclassified; 1 inside; 2 wall; 3 outside');


%% STEP 6 -- ObjectGeometry: boundary distance and its smoothed gradient
% EDIT HERE: gradient smoothing sigma, measured in current-grid voxels.
c.Options.Gradient = struct('Sigma',2, ...
    'Spacing',c.Grid.Spacing,'SpacingUnit',c.Grid.SpacingUnit, ...
    'DerivativeUnits','physical','DistanceUnit',c.Grid.SpacingUnit);

% Match workflow 2's historical reference construction on an isotropic grid.
% This is visible here instead of hidden behind farmWorkflowReference(c,...).
iso = min(c.Grid.Spacing);
workingSize = max(2,round(c.Grid.Size.*c.Grid.Spacing/iso));
work = imresize3(c.Images.Regions,workingSize,'nearest');
[d,~,~,~,~,keep] = farmDistTransFromBoundary( ...
    work==2,work==3,work==1,1);
if any(~isfinite(d(:)))
    error('memoworkflow:Reference','No usable boundary reference; inspect STEP 5.');
end
c.Images.Distance = imresize3(d*iso,c.Grid.Size,'nearest');
c.Images.ReferenceValid = imresize3(keep,c.Grid.Size,'nearest');
[c.Images.DistanceGradient,~,c.Images.DirectionValid] = ...
    farmDistanceGradients(c.Images.Distance,c.Options.Gradient);
c.Results.ReferenceInfo.WorkingSpacing = iso;
clear work d keep


%% STEP 7 -- sample reference fields at filament centroids
% Convert XYZ centroid coordinates into YXZ-volume linear indices.
% All sampled values are added to the SAME table, preserving its row identities.
xyz = round(c.Results.Filaments.Centroid);
indices = sub2ind(c.Grid.Size,xyz(:,2),xyz(:,1),xyz(:,3));
reference = zeros(height(c.Results.Filaments),3);
for component = 1:3
    field = c.Images.DistanceGradient(:,:,:,component);
    reference(:,component) = field(indices);
end

c.Results.Filaments.CoMIndices = indices;
c.Results.Filaments.BoundaryDistance = c.Images.Distance(indices);
c.Results.Filaments.RegionClass = c.Images.Regions(indices);
c.Results.Filaments.ReferenceValid = c.Images.ReferenceValid(indices);
c.Results.Filaments.ReferenceDirectionValid = c.Images.DirectionValid(indices);
c.Results.Filaments.DistanceGradient = reference;
clear field


%% STEP 8 -- ObjectGeometry: compare filament directions with reference gradients
% EDIT HERE: optional Z-component filter before projecting directions into XY.
% [] leaves this filter disabled. 3-D and projected 2-D order are separate results.
c.Options.Alignment2D = struct('Plane',[1 2],'MaxNormalComponent',[]);

filaments = c.Results.Filaments;
directors = filaments.ScaledDirectors;
reference = filaments.DistanceGradient;
finite = all(isfinite(directors),2)&all(isfinite(reference),2);
order3 = NaN(height(filaments),1);
order2 = order3;
angle2 = order3;

alignment3 = farmNematicAlignment(directors(finite,:),reference(finite,:));
alignment2 = farmNematicAlignment( ...
    directors(finite,:),reference(finite,:),c.Options.Alignment2D);
order3(finite) = alignment3.Order;
order2(finite) = alignment2.Order;
angle2(finite) = alignment2.SignedAngle;

c.Results.Filaments.Order3D = order3;
c.Results.Filaments.Order2D = order2;
c.Results.Filaments.SignedAngle2D = angle2;
clear filaments directors reference alignment3 alignment2


%% STEP 9 -- flag the detections you want to use
% EDIT HERE: thresholds use physical extent and the physically scaled aspect ratio.
% Selected is a flag; rejected rows remain available for inspection.
c.Options.Selection = struct('MinFilamentLength',0,'MinAspectRatio',0);
t = c.Results.Filaments;
c.Results.Filaments.Selected = t.ReferenceValid & t.ReferenceDirectionValid & ...
    t.ProjectedExtent>=c.Options.Selection.MinFilamentLength & ...
    t.ScaledAspectRatios>=c.Options.Selection.MinAspectRatio;
clear t

disp(c.Results.Filaments);


%% STEP 10 -- inspect physical filament directors and sampled gradients
% EDIT HERE: this display reloads one reference frame; it does not redetect filaments.
% Reuse the original workflow's view helper with a small, view-only configuration.
viewConfig = struct('Experiment',c.Experiment,'Frames',c.Frame, ...
    'Spacing',c.Grid.Spacing,'SpacingUnit',c.Grid.SpacingUnit, ...
    'SemanticChannels',c.Options.Categories.Channels, ...
    'Thresholds',c.Options.Categories.Thresholds, ...
    'OpeningRadius',c.Options.ProbabilitySmoothing.OpeningRadius, ...
    'ProfileSigma',c.Options.Gradient.Sigma);
% The view helper expects the historical source-role name Intensity647.
viewConfig.Experiment.Sources.Intensity647 = c.Experiment.Sources.FilamentIntensity;

c.Options.View = struct( ...
    'ZRange',[], ...                 % [] = middle slice; e.g. 68:72 = slab
    'Background','channels', ...     % 'channels' or 'distance'
    'Channels',[1 2 3], ...          % inside/wall/outside -> red/green/blue
    'SelectedOnly',true, ...         % false also displays rejected detections
    'GradientLength',5, ...          % length in current physical units
    'MaxFilaments',1000);            % thinning affects the display only

viewFigure = plotWorkflow2Cut(viewConfig,c.Results.Filaments,c.Frame, ...
    c.Options.View.ZRange,c.Options.View.Background,c.Options.View.Channels, ...
    c.Options.View.SelectedOnly,c.Options.View.GradientLength,c.Options.View.MaxFilaments);


%% STEP 11 -- save explicitly selected results, independently of current images
% EDIT HERE: uncomment individual assignments to keep large matrices if needed.
% Saving c itself would retain every current image; choose the payload explicitly.
outputConfig = struct('RepositoryRoot',repo, ...
    'OutputRoot',fullfile(repo,'tests', 'data','workflow-results'), ...
    'Experiment',c.Experiment,'Frame',c.Frame,'Options',c.Options);
c.OutputDirectory = farmWorkflowNewRun(outputConfig,'workflow2-staged');

payload = struct('Filaments',c.Results.Filaments,'ReferenceInfo',c.Results.ReferenceInfo);
% payload.FilamentMask=c.Images.FilamentMask;
% payload.Distance=c.Images.Distance;
% payload.DistanceGradient=c.Images.DistanceGradient;
farmWorkflowSaveNew(fullfile(c.OutputDirectory,sprintf('frame%03i.mat',c.Frame)),payload);

result = struct('Directory',c.OutputDirectory,'Filaments',c.Results.Filaments);
farmWorkflowSaveNew(fullfile(c.OutputDirectory,'manifest.mat'),result);
exportgraphics(viewFigure,fullfile(c.OutputDirectory,'filament-directors.png'));
fprintf('Staged workflow 2 outputs: %s\n',c.OutputDirectory);

% For future batching, repeat STEPS 2-11 for one frame at a time, keeping only
% small tables/file paths between frames. This prototype deliberately exposes
% the calculations as editor sections for manual inspection of one frame.


%% VIEW IMPLEMENTATION -- copied from setupWorkflow2.m for a standalone example
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