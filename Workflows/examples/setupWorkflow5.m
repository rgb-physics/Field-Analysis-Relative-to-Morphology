% READING GUIDE: edit SETUP / DATA / ANALYSIS first, inspect PREVIEW, then run RUN.
% The local functions below WORKFLOW IMPLEMENTATION execute those choices.
% Source descriptions/options are structs; loaded images are matrices; measurements are tables.


%% WORKFLOW 5 -- editable setup and execution (run sections in order)
% Standalone script. Original sources remain read-only; outputs use fresh test-data folders.
% Compatibility entry: public workflow wrappers supply workflowInput and skip setup.
if exist('workflowInput','var') && isstruct(workflowInput)
    result=workflow5Profiles(workflowInput,workflowExtra{:});
    return
end


%% SETUP -- explicit package location (works when running editor sections)
% Change this if you move the package. Source data folders are defined below.
repo='C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo';
here=fullfile(repo,'Workflows','examples');
apis={'ImageStackIO','SegmentationTools','ObjectGeometry',...
    'ObjectRelativeProfiles','SharedUtilities','ObjectTracking','FieldAnalysis','VisualizationTools'};
sourceFolders=cellfun(@(api)fullfile(repo,'APIs',api,'src'),apis,'UniformOutput',false);
folders=[sourceFolders,{fullfile(repo,'Workflows','src'),here}];

% Check all paths before modifying MATLAB's path; fail with a useful message.
for k=1:numel(folders)
    if ~isfolder(folders{k})
        error('memoworkflow:RepositoryPath', ...
            'Package folder not found: %s. Set repo in the SETUP section to your MeMo root.',folders{k});
    end
end
for k=1:numel(folders)
    addpath(folders{k});
end



%% DATA -- edit files, axes, calibration and acquisition frames

% ---- Choose acquisition frames; these are file frame numbers, not positions in a list. ----
frames=10:2:30;
datasetID='S88E4';
spacing=[.55 .55 .7]; spacingUnit='um'; % YXZ current intensity grid
intDir='O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit';
segDir='O:\Session 88\all ilastik prep files';
segName='t%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5';
segSpacing=[1.5 1.5 1.5]; segAxes='CXYZ';

% DatasetPath is the array name INSIDE the HDF5 file, not its disk folder.
density=imagestackio.config.makeSource('Folder',intDir, ...
    'NamePattern','t%03i_illBleachCorr16bit_560.tif','Format','tiff', ...
    'SourceAxes','YXZ','Spacing',spacing,'SpacingUnit',spacingUnit);
filaments=imagestackio.config.makeSource('Folder',intDir, ...
    'NamePattern','t%03i_illBleachCorr16bit_647.tif','Format','tiff', ...
    'SourceAxes','YXZ','Spacing',spacing,'SpacingUnit',spacingUnit);
probabilities=imagestackio.config.makeSource('Folder',segDir,'NamePattern',segName, ...
    'Format','hdf5','DatasetPath','/exported_data','SourceAxes',segAxes, ...
    'Spacing',segSpacing,'SpacingUnit',spacingUnit);

% ---- EXPERIMENT: collect source descriptions and dataset identity; images are not loaded here. ----
experiment=struct('DatasetID',datasetID,'Frames',frames, ...
    'TimeStep',30,'TimeUnit','s', ...
    'Sources',struct('Intensity560',density,'Intensity647',filaments,'Probabilities',probabilities));
experiment=memoworkflow.config.makeExperiment(experiment);

% ---- WORKFLOW OPTIONS: c carries the experiment and the analysis choices used below. ----
c=struct('Experiment',experiment,'DatasetID',experiment.DatasetID, ...
    'Frames',unique(double(frames(:).'),'stable'),'RepositoryRoot',repo,'Spacing',spacing,'SpacingUnit',spacingUnit);

% ---- OUTPUT LOCATION: each run creates a new subfolder here. ----
c.OutputRoot=fullfile(repo,'test-data','workflow-results');

% Numbered intensity source names match current workflow roles, not filenames:
% Intensity560 is the primary/density field; Intensity647 is the filament/secondary field.


%% ANALYSIS -- conditioning field and measured intensity fields
c.ForegroundChannels=[3 2]; c.ForegroundThreshold=.6; c.ObjectSmoothSigma=2;
c.ObjectLoader=[]; c.ObjectInputType='auto';

% ---- CONDITIONING FIELD: choose which geometry defines distance, and choose distance-bin edges. ----
c.ProfileReference='boundary'; % or 'skeleton' (requires skeleton dependencies)
c.ProfileEdges=-30:.5:30; % distances in spacingUnit; user-supplied bins
c.ProfileChannels={'560','647'}; % remove a channel to avoid loading it
c.ProfileSigma=2; c.GeometrySigma=1;

% Boundary reference: signed smoothed-mask distance (negative inside).
% Skeleton reference: nonnegative distance to stored skeleton voxels.
% Intensity Mean/Sum/Std are pooled over the full XYZ, not per object ID.
% Distances are built on an isotropic working grid and returned to intensity grid.
filamentManifestPath=''; % optional workflow 2 manifest.mat; leave empty for intensity only

% Alignment option uses stored Order2D/BoundaryDistance and groups by RegionClass.
% It does NOT recompute alignments or redefine their distance reference.
% OUTPUT CHOICES: inspect per-channel/alignment result assignments in helper below.


%% PREVIEW -- check measured intensity and object foreground
raw=memoworkflow.intensity(c,frames(1),'560');
[objects,mask]=memoworkflow.objects(c,frames(1),size(raw));
z=round(size(raw,3)/2);
figure; subplot(1,2,1); imagesc(raw(:,:,z)); axis image; title('Primary intensity');
subplot(1,2,2); imagesc(mask(:,:,z)); axis image; title('Object foreground');


%% RUN -- separate binned profiles per frame, without preloading all times
if isempty(filamentManifestPath)
    result=workflow5Profiles(c);
else
    loaded=load(filamentManifestPath,'result');
    filamentManifest=loaded.result;
    if any(string(filamentManifest.Filaments.DatasetID)~=string(experiment.DatasetID))
        error('memoworkflow:Dataset','The filament manifest must come from the same dataset.');
    end

    % Also verify reference definition, units and frame correspondence.
    result=workflow5Profiles(c,filamentManifest);
end
disp(result.Files);


%% WORKFLOW IMPLEMENTATION -- helper function, called by RUN above
function manifest=workflow5Profiles(c,filamentManifest)

%WORKFLOW5PROFILES Intensity/support profiles and optional stored alignment profiles.
% A workflow2 manifest is optional; no hidden recomputation of filament geometry.

% ---- START RUN: create the output folder and keep small result tables/file paths in memory. ----
out=memoworkflow.newRun(c,'workflow5'); files=cell(numel(c.Frames),1);

% ---- PROCESS ONE FRAME AT A TIME: load, calculate, save, then continue to the next frame. ----
for k=1:numel(c.Frames)
    frame=c.Frames(k); a=memoworkflow.intensity(c,frame,'560');
    [objects,mask]=memoworkflow.objects(c,frame,size(a));

    % ---- WORKING GRID: use isotropic voxels to calculate distance, then return it to the intensity grid. ----
    iso=min(c.Spacing); workingSize=max(2,round(size(mask).*c.Spacing/iso));
    work=imresize3(logical(mask),workingSize,'nearest');

    % ---- DISTANCE DEFINITION: signed boundary distance or nonnegative distance to skeleton voxels. ----
    if strcmp(c.ProfileReference,'boundary')
        work=segmentationtools.cleanup.returnSmoothBlobsBW(work,0,1,c.ProfileSigma);
        distance=sharedutilities.numerics.signedBWDist(work)*iso;
    elseif strcmp(c.ProfileReference,'skeleton')
        geometry=objectgeometry.objects.generateGeometry(objects,'skeleton',struct('Sigma',c.GeometrySigma));
        skeleton=false(size(mask)); skeleton(vertcat(geometry.Records.Indices))=true;
        work=imresize3(skeleton,workingSize,'nearest');

        % Nonnegative exterior distance: explicit definition rather than global-min shifting.
        distance=bwdist(work)*iso;
    else, error('memoworkflow:Reference','Choose boundary or skeleton.'); end
    distance=imresize3(distance,size(a),'nearest');

    % OUTPUT CHOICES: binned results; dense reference fields are not retained.

    % ---- FRAME OUTPUT: record the reference definition, units and bins alongside the statistics. ----
    result=struct('Frame',frame,'Reference',c.ProfileReference,'DistanceUnit',c.SpacingUnit,'Edges',c.ProfileEdges);

    % ---- INTENSITY PROFILES: pool voxel intensities into distance bins, one requested channel at a time. ----
    for channel=c.ProfileChannels
        if strcmp(channel{1},'560'), image=a;
        else, image=memoworkflow.intensity(c,frame,channel{1}); end
        result.(['Channel' channel{1}])=fieldanalysis.conditional.conditionalStatistics(image,distance, ...
            struct('Edges',c.ProfileEdges,'Statistics',{{'Mean','Sum','Std'}}));
    end

    % ---- OPTIONAL ALIGNMENT PROFILES: use already measured workflow 2 rows for the current frame. ----
    if nargin>=2
        t=filamentManifest.Filaments; t=t(t.Frame==frame&t.Selected&isfinite(t.Order2D),:);
        result.Alignment=fieldanalysis.conditional.conditionalStatistics(t.Order2D,t.BoundaryDistance, ...
            struct('Edges',c.ProfileEdges,'GroupIDs',double(t.RegionClass),'Statistics',{{'Mean','Std'}}));
    end

    % OUTPUT CHOICE: choose saved fields independently of plotting.

    % ---- SAVE SELECTION: payload controls what goes to disk; result remains available for plotting. ----
    payload=result;

    % payload.DistanceField=distance; % uncomment to retain dense reference field
    files{k}=fullfile(out,sprintf('frame%03i.mat',frame)); memoworkflow.saveNew(files{k},payload);

    % ---- DIAGNOSTIC FIGURE: visualize this frame and export a PNG into the run folder. ----
    f=figure('Visible','off'); cleanup=onCleanup(@()close(f)); hold on;

    % ---- PLOT PROFILES: display the saved mean intensity in each distance bin for each channel. ----
    for channel=c.ProfileChannels
        t=result.(['Channel' channel{1}]).Statistics;
        plot((t.LeftEdge+t.RightEdge)/2,t.Mean);
    end
    xlabel(['Distance to ' c.ProfileReference ' (' c.SpacingUnit ')']); ylabel('Mean corrected intensity'); legend(c.ProfileChannels);
    visualizationtools.export.figSaves(f,out,sprintf('profiles_t%03i',frame),'png',true); clear cleanup
end

% ---- COMBINED OUTPUT: return the run directory and the retained tables or per-frame file paths. ----
manifest=struct('Directory',out,'Files',{files}); memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 5 outputs: %s\n',out);
end
