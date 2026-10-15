% READING GUIDE: edit SETUP / DATA / ANALYSIS first, inspect PREVIEW, then run RUN.
% The local functions below WORKFLOW IMPLEMENTATION execute those choices.
% Source descriptions/options are structs; loaded images are matrices; measurements are tables.


%% Guided workflow 1 setup: edit DATA and ANALYSIS, then run the final section.
% Run SETUP first, then DATA/ANALYSIS/PREVIEW/RUN in order.
% Standalone setup: no experiment4Config or prior workspace variables needed.

% Compatibility entry: public workflow wrappers supply workflowInput and skip setup.
if exist('workflowInput','var') && isstruct(workflowInput)
    result=workflow1Objects(workflowInput);
    return
end


%% SETUP -- explicit package location (works when running editor sections)
% Change this if you move the package. Source data folders are defined below.
repo='C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo';
here=fullfile(repo,'Workflows','examples');
apis={'ImageStackIO','SegmentationTools','ObjectGeometry',...
    'ObjectRelativeProfiles','SharedUtilities'};
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

%* Can setup be made into a concise function or is that problematic?

%% DATA -- 
% describe your dataset, store that info in an "experiment" object

% ---- Choose acquisition frames; these are file frame numbers, not positions in a list. ----
frames= 10:2:30;
deltaT = 30;

% intensity info
intDir = 'O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit';
intName = 't%03i_illBleachCorr16bit_560.tif';
intVoxSize = [.55 .55 .7];
intAxes = 'YXZ';

% probability info
segDir = 'O:\Session 88\all ilastik prep files';
segName = 't%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5';
segVoxSize = [1.5 1.5 1.5];
segAxes = 'CXYZ';

% Assign properties before building data-reader objects
intensity=imagestackio.config.makeSource( ...
    'Folder',intDir,'NamePattern',intName, ...
    'Format','tiff','SourceAxes',intAxes,'Spacing',intVoxSize,'SpacingUnit','um');
probabilities=imagestackio.config.makeSource( ...
    'Folder',segDir,'NamePattern',segName, ...
    'Format','hdf5','DatasetPath','/exported_data','SourceAxes',segAxes, ...
    'Spacing',segVoxSize,'SpacingUnit','um');

% Store info on identity, selected frames, timing, and names in experiment

% ---- EXPERIMENT: collect source descriptions and dataset identity; images are not loaded here. ----
experiment=struct( ...
    'DatasetID','S88E4','Frames',frames,'TimeStep',deltaT,'TimeUnit','s', ...
    'Sources',struct('Intensity',intensity,'Probabilities',probabilities));
experiment=memoworkflow.config.makeExperiment(experiment); % validate/normalize
%* For ease of construction, make a 'glossary' function for users to see input options

% Only the workflow 1 execution choices belong in c; dataset lives above.
%* what is an "execution choice?"
% ---- WORKFLOW OPTIONS: c carries the experiment and the analysis choices used below. ----
c=struct('Experiment',experiment,'Frames',experiment.Frames);
c.RepositoryRoot=repo; % same explicit package root used for paths and outputs
%* What is 'c'? Not literally in MATLAB, but functionally? Users need to
%know so they can query glossary for options. 

%% ANALYSIS -- 
% Select probability channels to segment, then support-geometries you wish
% to build for sampling

% Segmentation channel settings/parameters
c.ForegroundChannels=[3 2]; c.ForegroundThreshold=.6; c.ObjectSmoothSigma=2;
%* when constructing example workflows, keep assignments on separate lines

% Geometry selection and settings
c.Supports={'objects','boundary'};
c.GeometryOptions=struct( ...
    'boundary',struct('Sigma',1,'LayerMean',0,'LayerWidth',1), ...
    'skeleton',struct('Method','blob','Sigma',1));

% Geometry options above are passed directly to generateGeometry by name.
c.ObjectProperties={'Volume','Centroid'}; % properties to measure using regionprops(3)
c.PhysicalVolume=true; % separate physical-unit column; false omits it
c.MeasurementOptions=struct(); % options passed to measureObjects

% SAMPLING REQUESTS -- one query per field/support combination.
% Available fields: Intensity and InteriorDistanceVoxels.
% Support must name an entry in c.Supports; remove/add queries independently.
% Query Options passes bins, quantiles, custom reducers, etc. to queryField.
c.Queries=[
    objectrelativeprofiles.config.makeQuery('Name','IntensityOnobjects', ...
        'Field','Intensity','Support','objects','Statistics',{'Mean','Sum','Std'}, ...
        'Options',struct('VarianceNormalization',0))
    objectrelativeprofiles.config.makeQuery('Name','IntensityOnboundary', ...
        'Field','Intensity','Support','boundary','Statistics',{'Mean','Sum','Std'})
    objectrelativeprofiles.config.makeQuery('Name','InteriorDistanceOnobjects', ...
        'Field','InteriorDistanceVoxels','Support','objects','Statistics',{'Mean','Max'})
    objectrelativeprofiles.config.makeQuery('Name','InteriorDistanceOnboundary', ...
        'Field','InteriorDistanceVoxels','Support','boundary','Statistics',{'Mean','Max'})
    ];
%* is there a short-hand to call nested functions? Writing out 
%"objectrelativeprofiles.config.makeQuery" four times is clunky;

% For a properties-only run: c.Queries=[]; c.Supports={'objects'};
c.ObjectLoader=[]; c.ObjectInputType='auto';
c.LocalInertia=false; % no inertia settings needed while disabled
c.IncludeDiagnostics=false; % true also includes counts/flags in Measurements

% Diagnostics remain available as result.Diagnostics and in each frame MAT.

% ---- OUTPUT LOCATION: each run creates a new subfolder here. ----
c.OutputRoot=fullfile(repo,'test-data','workflow-results');

% To bypass probability segmentation, provide same-intensity-grid objects:
% c.ObjectLoader=@(frame) ...; c.ObjectInputType='labels'; % or 'mask'
% ObjectProperties and Queries above determine measured columns.
% InteriorDistanceVoxels is in voxels. Geometry and fields are reused
% within one frame; neither all images nor all masks are preloaded.


%% PREVIEW -- one quantitative field, without changing source files
preview=memoworkflow.loadSource(c.Experiment,'Intensity',frames(10));
imagesc(preview.Data(:,:,round(size(preview.Data,3)/2))); axis image; colorbar;
title('Quantitative intensity: middle Z slice');

% Verify probability/intensity registration before interpreting results.
% Similar physical extents do not establish a shared origin/crop.


%% RUN -- creates a fresh directory under package test-data
result=workflow1Objects(c);
disp(result.Measurements);


%% WORKFLOW IMPLEMENTATION -- helper function, called by RUN above
function manifest=workflow1Objects(c)

%WORKFLOW1OBJECTS User-selected supports and same-frame fields.
% Measure objects and sample fields within them and on requested geometry.
% ObjectIDs are frame-local: this workflow does not track trajectories/ancestry.
% IncludeDiagnostics=false keeps measurement tables compact. Diagnostics are
% always saved separately, keyed by object identity, for later inspection.
if ~isfield(c,'IncludeDiagnostics'), c.IncludeDiagnostics=false; end
validateattributes(c.IncludeDiagnostics,{'logical'},{'scalar'});

% Compatibility defaults for older configurations; setup supplies these explicitly.
if ~isfield(c,'ObjectProperties'), c.ObjectProperties={'Volume','Centroid'}; end
if ~isfield(c,'PhysicalVolume'), c.PhysicalVolume=true; end
if ~isfield(c,'MeasurementOptions'), c.MeasurementOptions=struct(); end
%* is this necessary to include in a one off example workflow?

validateattributes(c.PhysicalVolume,{'logical'},{'scalar'});
if ~isfield(c,'GeometryOptions')
    c.GeometryOptions=struct();
    for s=1:numel(c.Supports)
        name=c.Supports{s};
        if ~strcmp(name,'objects'), c.GeometryOptions.(name)=struct('Sigma',c.GeometrySigma); end
    end
end
if ~isfield(c,'Queries')
    c.Queries=[];
    for s=1:numel(c.Supports)
        name=c.Supports{s};
        pair=[objectrelativeprofiles.config.makeQuery('Name',['IntensityOn' name], ...
            'Support',name,'Statistics',{'Mean','Sum','Std'},'Field','Intensity'), ...
            objectrelativeprofiles.config.makeQuery('Name',['InteriorDistanceOn' name], ...
            'Support',name,'Statistics',{'Mean','Max'},'Field','InteriorDistanceVoxels')];
        if isempty(c.Queries), c.Queries=pair; else, c.Queries=[c.Queries,pair]; end
    end
end
queries=c.Queries;

% Create a fresh package test-data output folder and save configuration.mat.
% Retain small per-frame tables; do not preload images/masks across all times.

% ---- START RUN: create the output folder and keep small result tables/file paths in memory. ----
out=memoworkflow.newRun(c,'workflow1'); tables=cell(numel(c.Frames),1);
diagnosticTables=cell(numel(c.Frames),1);

% ---- PROCESS ONE FRAME AT A TIME: load, calculate, save, then continue to the next frame. ----
for k=1:numel(c.Frames)
    frame=c.Frames(k); timer=tic;
    current=c;

    % Load one quantitative intensity volume and its current-grid calibration.
    % Preserve intensity values; illumination/bleaching correction is upstream.
    if isfield(c,'Experiment')
        image=memoworkflow.loadSource(c.Experiment,'Intensity',frame);
        if size(image.Data,4)~=1, error('memoworkflow:Channels','Workflow 1 requires one selected intensity channel.'); end
        intensity=image.Data(:,:,:,1,1);
        current.DatasetID=c.Experiment.DatasetID;
        current.Spacing=image.Spacing; current.SpacingUnit=image.SpacingUnit;
    else
        intensity=memoworkflow.intensity(c,frame,'560');
    end

    % Load matching probabilities; sum ForegroundChannels and threshold them,
    % smooth on the probability grid, then resize the mask to the intensity
    % grid with nearest-neighbor interpolation. prepareObjects assigns IDs
    % to connected objects and records DatasetID, Frame and grid metadata.
    % A supplied ObjectLoader bypasses probabilities and preserves supplied
    % IDs when ObjectInputType='labels'. Shared crop/registration is assumed;
    % matching volume extents alone cannot establish spatial registration.
    [objects,mask]=memoworkflow.objects(current,frame,size(intensity));

    % Pass setup measurement requests through; native properties keep native units.

    % ---- MEASURE: requested native properties become columns, with one row per object ID. ----
    properties=objectgeometry.objects.measureObjects(objects,c.ObjectProperties,c.MeasurementOptions);
    if c.PhysicalVolume
        if ismember('Volume',properties.Properties.VariableNames), volumes=properties.Volume;
        else
            volumeTable=objectgeometry.objects.measureObjects(objects,{'Volume'});
            volumes=volumeTable.Volume; % internal prerequisite, not an extra output
        end
        properties.PhysicalVolume=volumes*prod(current.Spacing);
        properties=memoworkflow.setColumnUnit(properties,'PhysicalVolume',[current.SpacingUnit '^3']);
    end

    % Interior distance magnitude to background, in voxels. This references
    % the combined foreground mask, not a separate distance field for each ID.

    % ---- FIELD: build interior distance once; reuse it across the requested sampling locations. ----
    distance=bwdist(~logical(mask));
    fields=struct('Intensity',intensity,'InteriorDistanceVoxels',distance);

    % Object support uses all object voxels. Generate requested boundary or
    % skeleton indices once, then reuse them to sample both named fields.
    % Skeletons are geometric supports, not filament objects.

    % ---- SUPPORTS: collect the voxel locations on which each field will be sampled. ----
    supports=struct('objects',objects); geometry=struct;
    for s=1:numel(c.Supports)
        name=c.Supports{s};
        if ~strcmp(name,'objects')
            options=struct();
            if isfield(c.GeometryOptions,name), options=c.GeometryOptions.(name); end
            geometry.(name)=objectgeometry.objects.generateGeometry(objects,name,options);
            supports.(name)=geometry.(name);
        end
    end

    % Sample each field on each requested support, grouped by parent object ID.
    if ~isempty(queries)
        results=objectrelativeprofiles.fieldSampling.queryFrame(fields,supports,queries);

        % Attach using DatasetID/Frame/ObjectID and sampling ComponentID as needed,
        % rather than trusting table row order; retain sampling validity metadata.
        properties=objectrelativeprofiles.fieldSampling.attachResults(properties,results);
    end

    % Separate diagnostic counts/flags from the user-requested measurements.
    % Keep keys so later debugging/querying does not depend on table row order.

    % ---- DIAGNOSTICS: separate sampling counts and validity flags from the requested statistics. ----
    suffixes={'SelectedCount','FiniteCount','NaNCount','PositiveInfCount', ...
        'NegativeInfCount','SelectionEmpty','GeometryEmpty','EmptyGeometryCount', ...
        'UsedFallback','FallbackCount'};
    diagnosticNames={};
    for q=1:numel(queries)
        diagnosticNames=[diagnosticNames,strcat(queries(q).Name,'_',suffixes)]; %#ok<AGROW>
    end
    keys={'DatasetID','Frame','ObjectID'};
    if ismember('ComponentID',properties.Properties.VariableNames), keys{end+1}='ComponentID'; end
    diagnostics=properties(:,[keys,diagnosticNames]);
    if ~c.IncludeDiagnostics, properties=removevars(properties,diagnosticNames); end

    % OUTPUT CHOICES: edit these assignments to choose what each frame saves.
    % Measurements contain statistics even when geometry indices are omitted.
    payload=struct('Measurements',properties,'Seconds',toc(timer));
    payload.Diagnostics=diagnostics; % comment out to omit per-frame diagnostics

    % payload.Geometry=geometry;     % uncomment to retain generated indices
    % payload.Supports=supports;     % uncomment to retain whole-object support too
    % Optional independent local-inertia analysis at skeleton indices, or at
    % rounded centroids when no skeleton was requested. Disabled in setup.

    % ---- OPTIONAL ANALYSIS: calculate local shape information only when enabled in setup. ----
    if c.LocalInertia
        if isfield(geometry,'skeleton')
            indices=unique(vertcat(geometry.skeleton.Records.Indices));
        else
            centers=objectgeometry.objects.measureObjects(objects,{'Centroid'});
            xyz=round(centers.Centroid); % works even when Centroid was not requested
            indices=sub2ind(size(mask),xyz(:,2),xyz(:,1),xyz(:,3));
        end
        opts=c.InertiaOptions; opts.Spacing=current.Spacing; opts.SpacingUnit=current.SpacingUnit;
        localInertia=objectgeometry.objects.localInertia(logical(mask),indices,opts);
        payload.LocalInertia=localInertia; % comment out to calculate without saving
    end

    % Save only the fields assigned above. MAT files contain a variable result.
    % Full intensity/probability stacks are not retained in these outputs.

    % ---- SAVE FRAME: write the selected payload before moving on; source files are not modified. ----
    memoworkflow.saveNew(fullfile(out,sprintf('frame%03i.mat',frame)),payload);
    tables{k}=properties;
    diagnosticTables{k}=diagnostics;
end

% Concatenate the small keyed tables across frames. Return/save manifest.mat
% with the combined Measurements table and output Directory; inputs unchanged.

% ---- COMBINED OUTPUT: return the run directory and the retained tables or per-frame file paths. ----
manifest=struct('Directory',out,'Measurements',objectgeometry.objects.concatenateMeasurements(tables));

% OUTPUT CHOICE: comment out this line too if no combined diagnostics are wanted.
manifest.Diagnostics=objectgeometry.objects.concatenateMeasurements(diagnosticTables);

% Geometry/support indices are never added to the combined manifest implicitly.
memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 1 outputs: %s\n',out);
end
