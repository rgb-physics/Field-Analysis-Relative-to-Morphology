function manifest = farmWorkflow1Objects(c)

%FARMWORKFLOW1OBJECTS Measure objects and sample geometry one frame at a time.
% Inputs:
%   c          Editable workflow choices; see setupWorkflow1.m.
% Outputs:
%   manifest   New output Directory, Measurements and Diagnostics tables.
%
% Optional ProfileEdges requests a pooled signed-distance profile per frame.
% SaveGeometry/SaveSupports default false; Verbose defaults false.
% Frame MAT files contain a variable named result. No source files are changed.

% Locate the repository and add its ordinary source folders.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(repo);
farmSetup('IncludeExamples', true);

if nargin < 1
    c = farmExperiment4Config;
end

if ~isfield(c, 'Verbose')
    c.Verbose = false;
end
if ~isfield(c, 'SaveGeometry')
    c.SaveGeometry = false;
end
if ~isfield(c, 'SaveSupports')
    c.SaveSupports = false;
end
if ~isfield(c, 'ProfileEdges')
    c.ProfileEdges = [];
end
validateattributes(c.Verbose, {'logical'}, {'scalar'});
validateattributes(c.SaveGeometry, {'logical'}, {'scalar'});
validateattributes(c.SaveSupports, {'logical'}, {'scalar'});

% User-selected supports and same-frame fields.
% Measure objects and sample fields within them and on requested geometry.
% ObjectIDs are frame-local: this workflow does not track trajectories/ancestry.
% IncludeDiagnostics=false keeps measurement tables compact. Diagnostics are
% always saved separately, keyed by object identity, for later inspection.
if ~isfield(c,'IncludeDiagnostics')
    c.IncludeDiagnostics = false;
end
validateattributes(c.IncludeDiagnostics,{'logical'},{'scalar'});

% Compatibility defaults for older configurations; setup supplies these explicitly.
if ~isfield(c,'ObjectProperties')
    c.ObjectProperties = {'Volume','Centroid'};
end
if ~isfield(c,'PhysicalVolume')
    c.PhysicalVolume = true;
end
if ~isfield(c,'MeasurementOptions')
    c.MeasurementOptions = struct();
end
validateattributes(c.PhysicalVolume,{'logical'},{'scalar'});
if ~isfield(c,'GeometryOptions')
    c.GeometryOptions = struct();
    for s = 1:numel(c.Supports)
        name = c.Supports{s};
        if ~strcmp(name,'objects')
            c.GeometryOptions.(name) = struct('Sigma',c.GeometrySigma);
        end
    end
end
if ~isfield(c,'Queries')
    c.Queries = [];
    for s = 1:numel(c.Supports)
        name = c.Supports{s};
        pair = [farmMakeQuery('Name',['IntensityOn' name], ...
            'Support',name,'Statistics',{'Mean','Sum','Std'},'Field','Intensity'), ...
            farmMakeQuery('Name',['InteriorDistanceOn' name], ...
            'Support',name,'Statistics',{'Mean','Max'},'Field','InteriorDistanceVoxels')];
        if isempty(c.Queries)
            c.Queries = pair;
        else
            c.Queries = [c.Queries,pair];
        end
    end
end
queries = c.Queries;

% Create a fresh package tests/data output folder and save configuration.mat.
% Retain small per-frame tables; do not preload images/masks across all times.

% ---- START RUN: create the output folder and keep small result tables/file paths in memory. ----
out = farmWorkflowNewRun(c,'workflow1');
tables = cell(numel(c.Frames),1);
diagnosticTables = cell(numel(c.Frames),1);

% ---- PROCESS ONE FRAME AT A TIME: load, calculate, save, then continue to the next frame. ----
for k = 1:numel(c.Frames)
    frame = c.Frames(k);
    timer = tic;
    current = c;

    if c.Verbose
        fprintf('Workflow 1: frame %g (%d/%d), loading and processing.\n', frame, k, numel(c.Frames));
    end

    % Load one quantitative intensity volume and its current-grid calibration.
    % Preserve intensity values; illumination/bleaching correction is upstream.
    if isfield(c,'Experiment')
        image = farmLoadSource(c.Experiment,'Intensity',frame);
        if size(image.Data,4)~=1
            error('memoworkflow:Channels','Workflow 1 requires one selected intensity channel.');
        end
        intensity = image.Data(:,:,:,1,1);
        current.DatasetID = c.Experiment.DatasetID;
        current.Spacing = image.Spacing;
        current.SpacingUnit = image.SpacingUnit;
    else
        intensity = farmWorkflowIntensity(c,frame,'560');
    end

    % Load matching probabilities; sum ForegroundChannels and threshold them,
    % smooth on the probability grid, then resize the mask to the intensity
    % grid with nearest-neighbor interpolation. prepareObjects assigns IDs
    % to connected objects and records DatasetID, Frame and grid metadata.
    % A supplied ObjectLoader bypasses probabilities and preserves supplied
    % IDs when ObjectInputType='labels'. Shared crop/registration is assumed;
    % matching volume extents alone cannot establish spatial registration.
    [objects,mask] = farmWorkflowObjects(current,frame,size(intensity));

    % Pass setup measurement requests through; native properties keep native units.

    % ---- MEASURE: requested native properties become columns, with one row per object ID. ----
    properties = farmMeasureObjects(objects,c.ObjectProperties,c.MeasurementOptions);
    if c.PhysicalVolume
        if ismember('Volume',properties.Properties.VariableNames)
            volumes = properties.Volume;
        else
            volumeTable = farmMeasureObjects(objects,{'Volume'});
            volumes = volumeTable.Volume; % internal prerequisite, not an extra output
        end
        properties.PhysicalVolume = volumes*prod(current.Spacing);
        properties = farmWorkflowSetColumnUnit(properties,'PhysicalVolume',[current.SpacingUnit '^3']);
    end

    % Interior distance magnitude to background, in voxels. This references
    % the combined foreground mask, not a separate distance field for each ID.

    % ---- FIELD: build interior distance once; reuse it across the requested sampling locations. ----
    distance = bwdist(~logical(mask));
    fields = struct('Intensity',intensity,'InteriorDistanceVoxels',distance);

    % Object support uses all object voxels. Generate requested boundary or
    % skeleton indices once, then reuse them to sample both named fields.
    % Skeletons are geometric supports, not filament objects.

    % ---- SUPPORTS: collect the voxel locations on which each field will be sampled. ----
    supports = struct('objects',objects);
    geometry = struct();
    for s = 1:numel(c.Supports)
        name = c.Supports{s};
        if ~strcmp(name,'objects')
            options = struct();
            if isfield(c.GeometryOptions,name)
                options = c.GeometryOptions.(name);
            end
            geometry.(name) = farmGenerateGeometry(objects,name,options);
            supports.(name) = geometry.(name);
        end
    end

    % Sample each field on each requested support, grouped by parent object ID.
    if ~isempty(queries)
        results = farmQueryFrame(fields,supports,queries);

        % Attach using DatasetID/Frame/ObjectID and sampling ComponentID as needed,
        % rather than trusting table row order; retain sampling validity metadata.
        properties = farmAttachResults(properties,results);
    end

    % Separate diagnostic counts/flags from the user-requested measurements.
    % Keep keys so later debugging/querying does not depend on table row order.

    % ---- DIAGNOSTICS: separate sampling counts and validity flags from the requested statistics. ----
    suffixes = {'SelectedCount','FiniteCount','NaNCount','PositiveInfCount', ...
        'NegativeInfCount','SelectionEmpty','GeometryEmpty','EmptyGeometryCount', ...
        'UsedFallback','FallbackCount'};
    diagnosticNames = {};
    for q = 1:numel(queries)
        diagnosticNames = [diagnosticNames,strcat(queries(q).Name,'_',suffixes)]; %#ok<AGROW>
    end
    keys = {'DatasetID','Frame','ObjectID'};
    if ismember('ComponentID',properties.Properties.VariableNames)
        keys{end+1} = 'ComponentID';
    end
    diagnostics = properties(:,[keys,diagnosticNames]);
    if ~c.IncludeDiagnostics
        properties = removevars(properties,diagnosticNames);
    end

    % OUTPUT CHOICES: edit these assignments to choose what each frame saves.
    % Measurements contain statistics even when geometry indices are omitted.
    payload = struct('Measurements',properties,'Seconds',toc(timer));
    payload.Diagnostics = diagnostics; % comment out to omit per-frame diagnostics

    if c.SaveGeometry
        payload.Geometry = geometry;
    end
    if c.SaveSupports
        payload.Supports = supports;
    end
    if ~isempty(c.ProfileEdges)
        % Pool all voxel samples against distance to the combined foreground.
        % Signed distances use voxel units, without anisotropic correction.
        signedDistance = farmSignedBWDist(logical(mask));
        payload.DistanceProfile = farmConditionalStatistics(intensity, signedDistance, ...
            struct('Edges', c.ProfileEdges, 'Statistics', {{'Mean', 'Std'}}));
    end

    % Optional independent local-inertia analysis at skeleton indices, or at
    % rounded centroids when no skeleton was requested. Disabled in setup.

    % ---- OPTIONAL ANALYSIS: calculate local shape information only when enabled in setup. ----
    if c.LocalInertia
        if isfield(geometry,'skeleton')
            indices = unique(vertcat(geometry.skeleton.Records.Indices));
        else
            centers = farmMeasureObjects(objects,{'Centroid'});
            xyz = round(centers.Centroid); % works even when Centroid was not requested
            indices = sub2ind(size(mask),xyz(:,2),xyz(:,1),xyz(:,3));
        end
        opts = c.InertiaOptions;
        opts.Spacing = current.Spacing;
        opts.SpacingUnit = current.SpacingUnit;
        localInertia = farmLocalInertia(logical(mask),indices,opts);
        payload.LocalInertia = localInertia; % comment out to calculate without saving
    end

    % Save only the fields assigned above. MAT files contain a variable result.
    % Full intensity/probability stacks are not retained in these outputs.

    % ---- SAVE FRAME: write the selected payload before moving on; source files are not modified. ----
    farmWorkflowSaveNew(fullfile(out,sprintf('frame%03i.mat',frame)),payload);
    tables{k} = properties;
    diagnosticTables{k} = diagnostics;
    if c.Verbose
        fprintf('Workflow 1: frame %g saved, %d object rows, %.2f s.\n', ...
            frame, height(properties), toc(timer));
    end
end

% Concatenate the small keyed tables across frames. Return/save manifest.mat
% with the combined Measurements table and output Directory; inputs unchanged.

% ---- COMBINED OUTPUT: return the run directory and the retained tables or per-frame file paths. ----
manifest = struct('Directory',out,'Measurements',farmConcatenateMeasurements(tables));

% OUTPUT CHOICE: comment out this line too if no combined diagnostics are wanted.
manifest.Diagnostics = farmConcatenateMeasurements(diagnosticTables);

% Geometry/support indices are never added to the combined manifest implicitly.
farmWorkflowSaveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 1 outputs: %s\n',out);
end
