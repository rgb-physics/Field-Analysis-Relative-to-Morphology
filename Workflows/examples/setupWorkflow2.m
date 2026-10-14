%% WORKFLOW 2 -- editable setup and execution (run sections in order)
% Standalone script. Original sources remain read-only; outputs use fresh test-data folders.
% Compatibility entry: public workflow wrappers supply workflowInput and skip setup.
if exist('workflowInput','var') && isstruct(workflowInput)
    result=workflow2Filaments(workflowInput);
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
frames=10:2:30;
datasetID='S88E4';
spacing=[.55 .55 .7]; spacingUnit='um'; % YXZ current intensity grid
intDir='O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit';
segDir='O:\Session 88\all ilastik prep files';
segName='t%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5';
segSpacing=[1.5 1.5 1.5]; segAxes='CXYZ';
% DatasetPath is the array name INSIDE the HDF5 file, not its disk folder.
filaments=imagestackio.config.makeSource('Folder',intDir, ...
    'NamePattern','t%03i_illBleachCorr16bit_647.tif','Format','tiff', ...
    'SourceAxes','YXZ','Spacing',spacing,'SpacingUnit',spacingUnit);
probabilities=imagestackio.config.makeSource('Folder',segDir,'NamePattern',segName, ...
    'Format','hdf5','DatasetPath','/exported_data','SourceAxes',segAxes, ...
    'Spacing',segSpacing,'SpacingUnit',spacingUnit);
experiment=struct('DatasetID',datasetID,'Frames',frames, ...
    'TimeStep',30,'TimeUnit','s', ...
    'Sources',struct('Intensity647',filaments,'Probabilities',probabilities));
experiment=memoworkflow.config.makeExperiment(experiment);
c=struct('Experiment',experiment,'DatasetID',experiment.DatasetID, ...
    'Frames',unique(double(frames(:).'),'stable'),'RepositoryRoot',repo,'Spacing',spacing,'SpacingUnit',spacingUnit);
c.OutputRoot=fullfile(repo,'test-data','workflow-results');
% Numbered intensity source names match current workflow roles, not filenames:
% Intensity560 is the primary/density field; Intensity647 is the filament/secondary field.

%% ANALYSIS -- filament extraction, semantic reference and orientation selection
c.FilamentLoader=[]; % optional @(frame) -> same-grid binary filament mask
c.FilamentSigma=1; c.FilamentThreshold=20; % threshold applies to -LoG response
c.MinFilamentLength=0; c.MinAspectRatio=0; % flags retain all measurements
c.MaxZComponent=[]; % optional 0..1 filter before projected XY nematic alignment
c.SemanticChannels=[3 2 1]; % input channel numbers for INSIDE, WALL, OUTSIDE
c.Thresholds=[.33 .33 .33]; c.OpeningRadius=1;
c.ProfileSigma=2; % distance-gradient smoothing sigma in intensity-grid voxels
% Filaments are image objects; no blob skeleton is generated here.
% Measurements include native and scaled-covariance directions/extents.
% The reference is sampled at filament centroids. Invalid/zero directions are flagged.
% 3-D nematic and projected XY nematic order are distinct outputs.
% OUTPUT CHOICES: inspect the payload/manifest assignments in the helper below.

%% PREVIEW -- check filament intensity, extraction and semantic registration
frame=frames(1);
raw=memoworkflow.intensity(c,frame,'647');
if isempty(c.FilamentLoader)
    response=-sharedutilities.numerics.LOG(double(raw),c.FilamentSigma);
    options=segmentationtools.config.makeIntensityOptions('Method','fixed','Threshold',c.FilamentThreshold);
    extracted=segmentationtools.binarization.segmentIntensity(response,options);
    previewMask=extracted.Mask;
else
    previewMask=c.FilamentLoader(frame);
end
[semantic,~]=memoworkflow.regions(c,frame,size(raw));
z=round(size(raw,3)/2);
figure;
subplot(1,3,1); imagesc(raw(:,:,z)); axis image; title('Filament intensity');
subplot(1,3,2); imagesc(previewMask(:,:,z)); axis image; title('Extracted filaments');
subplot(1,3,3); imagesc(semantic(:,:,z)); axis image; clim([0 3]); colorbar;
title('0 unclassified; 1 inside; 2 wall; 3 outside');
% Verify crop/origin and channel semantics by eye before interpreting alignment.

%% RUN -- frame tables, combined filament table and first-frame semantic PNG
result=workflow2Filaments(c);
disp(result.Filaments);

%% WORKFLOW IMPLEMENTATION -- helper function, called by RUN above
function manifest=workflow2Filaments(c)
%WORKFLOW2FILAMENTS Centroid association with semantic/distance vector fields.
out=memoworkflow.newRun(c,'workflow2'); tables=cell(numel(c.Frames),1);
for k=1:numel(c.Frames)
    frame=c.Frames(k); timer=tic;
    % Load one filament intensity volume; supplied masks bypass extraction.
    raw=memoworkflow.intensity(c,frame,'647');
    if isempty(c.FilamentLoader)
        response=-sharedutilities.numerics.LOG(double(raw),c.FilamentSigma);
        segmentation=segmentationtools.binarization.segmentIntensity(response, ...
            struct('Method','fixed','Threshold',c.FilamentThreshold)); mask=segmentation.Mask;
    else, mask=c.FilamentLoader(frame); end
    identity=struct('DatasetID',c.DatasetID,'Frame',frame,'Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit);
    properties=objectgeometry.centerlines.measureFilaments(mask, ...
        {'Volume','Centroid','Directors','Lengths','AspectRatios','ScaledDirectors','ProjectedExtent','ScaledAspectRatios'}, ...
        struct('Identity',identity,'ExtentWidthFloor',eps));
    % Generate semantic/distance reference; sample it at filament centroids.
    [distance,g,valid,regions,referenceInfo]=memoworkflow.reference(c,frame,size(mask));
    xyz=round(properties.Centroid);
    indices=sub2ind(size(mask),xyz(:,2),xyz(:,1),xyz(:,3));
    reference=zeros(height(properties),3);
    for d=1:3, field=g(:,:,:,d); reference(:,d)=field(indices); end
    properties.CoMIndices=indices; properties.BoundaryDistance=distance(indices);
    properties.RegionClass=regions(indices); properties.ReferenceValid=valid(indices);
    properties.ReferenceDirectionValid=referenceInfo.DirectionValid(indices);
    properties.DistanceGradient=reference;
    % Use scaled-covariance directions, without resampling the filament image.
    directors=properties.ScaledDirectors;
    finite=all(isfinite(directors),2)&all(isfinite(reference),2);
    order3=NaN(height(properties),1); order2=order3; angle2=order3;
    a=objectgeometry.orientation.nematicAlignment(directors(finite,:),reference(finite,:));
    options=struct('Plane',[1 2],'MaxNormalComponent',c.MaxZComponent);
    b=objectgeometry.orientation.nematicAlignment(directors(finite,:),reference(finite,:),options);
    order3(finite)=a.Order; order2(finite)=b.Order; angle2(finite)=b.SignedAngle;
    properties.Order3D=order3; properties.Order2D=order2; properties.SignedAngle2D=angle2;
    properties.Selected=properties.ReferenceValid&properties.ReferenceDirectionValid& ...
        properties.ProjectedExtent>=c.MinFilamentLength&properties.ScaledAspectRatios>=c.MinAspectRatio;
    % Separate selection flag; raw measurements are retained.
    tables{k}=properties;
    % OUTPUT CHOICES: explicit retained results; matrices/indices are opt-in.
    payload=struct('Filaments',properties,'Seconds',toc(timer));
    payload.ReferenceInfo=rmfield(referenceInfo,'DirectionValid');
    % payload.FilamentMask=mask;
    % payload.Distance=distance; payload.DistanceGradient=g;
    memoworkflow.saveNew(fullfile(out,sprintf('frame%03i.mat',frame)),payload);
    if k==1
        z=round(size(mask,3)/2); f=figure('Visible','off'); cleanup=onCleanup(@()close(f));
        subplot(1,2,1); imagesc(raw(:,:,z)); axis image; title('Filament intensity');
        subplot(1,2,2); imagesc(regions(:,:,z)); axis image; clim([0 3]); colorbar; title('0 unclassified; 1 inside; 2 wall; 3 outside');
        visualizationtools.export.figSaves(f,out,'semantic-preview','png',true); clear cleanup
    end
end
manifest=struct('Directory',out,'Filaments',objectgeometry.objects.concatenateMeasurements(tables));
memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 2 outputs: %s\n',out);
end
