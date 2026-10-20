% READING GUIDE: edit SETUP / DATA / ANALYSIS first, inspect PREVIEW, then run RUN.
% The local functions below WORKFLOW IMPLEMENTATION execute those choices.
% Source descriptions/options are structs; loaded images are matrices; measurements are tables.


%% WORKFLOW 4 -- editable setup and execution (run sections in order)
% Standalone script. Original sources remain read-only; outputs use fresh tests/data folders.
% Compatibility entry: public workflow wrappers supply workflowInput and skip setup.
if exist('workflowInput','var') && isstruct(workflowInput)
    result = farmWorkflow4Spectra(workflowInput);
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
folders = [sourceFolders,{fullfile(repo,'Examples and Workflows','src'),here}];

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



%% DATA -- edit primary/secondary intensity sources and selected frames

% ---- Choose acquisition frames; these are file frame numbers, not positions in a list. ----
frames = [10 20 30]; datasetID = 'S88E4';
spacing = [.55 .55 .7]; spacingUnit = 'um';
intDir = 'O:\Session 88\Exp 4 - Rmin Redo\3 Illumination Bleach Corrected 16bit';
density = farmMakeSource('Folder',intDir, ...
    'NamePattern','t%03i_illBleachCorr16bit_560.tif','Format','tiff', ...
    'SourceAxes','YXZ','Spacing',spacing,'SpacingUnit',spacingUnit);
filaments = farmMakeSource('Folder',intDir, ...
    'NamePattern','t%03i_illBleachCorr16bit_647.tif','Format','tiff', ...
    'SourceAxes','YXZ','Spacing',spacing,'SpacingUnit',spacingUnit);

% ---- EXPERIMENT: collect source descriptions and dataset identity; images are not loaded here. ----
experiment = struct('DatasetID',datasetID,'Frames',frames, ...
    'Sources',struct('Intensity560',density,'Intensity647',filaments));
experiment = farmMakeExperiment(experiment);

% ---- WORKFLOW OPTIONS: c carries the experiment and the analysis choices used below. ----
c = struct('Experiment',experiment,'DatasetID',experiment.DatasetID, ...
    'Frames',unique(double(frames(:).'),'stable'),'RepositoryRoot',repo,'Spacing',spacing,'SpacingUnit',spacingUnit);

% ---- OUTPUT LOCATION: each run creates a new subfolder here. ----
c.OutputRoot = fullfile(repo,'tests', 'data','workflow-results');

% Numbered intensity source names match current workflow roles, not filenames:
% Intensity560 is the primary/density field; Intensity647 is the filament/secondary field.


%% ANALYSIS -- independent slices, projection, 3-D power and correlation

% ---- FOURIER INPUTS: choose which frames and individual Z slices to analyze. ----
c.SpectrumFrames = c.Frames; c.SelectedSlices = [20 40 60];
c.NumBins = 50; c.MeanSubtract = false; c.Window = true;
c.Projection = 'mean'; % 'max' also available; projection precedes 2-D spectrum
c.CorrelationMode = '2d'; % '3d' allocates a potentially large full temporary lag map
c.CorrelationCrossChannel = false; % true also loads the secondary source

% Per-slice spectra remain separate. Power and correlation are unnormalized.
% Correlation is linear/native; only radial lag statistics are retained.
% OUTPUT CHOICES: radial results and normalization metadata are retained,
% full power/lag matrices are not. See result assignments in the helper below.


%% PREVIEW -- selected Z slice and projection of the primary field
raw = farmWorkflowIntensity(c,frames(1),'560');
z = c.SelectedSlices(1);
if z<1||z>size(raw,3), error('memoworkflow:Slices','Choose SelectedSlices within 1..%d.',size(raw,3)); end
if strcmp(c.Projection,'mean'), projected = mean(double(raw),3); else, projected = max(raw,[],3); end
figure; subplot(1,2,1); imagesc(raw(:,:,z)); axis image; title(sprintf('Z=%d',z));
subplot(1,2,2); imagesc(projected); axis image; title([c.Projection ' projection']);


%% RUN -- one results MAT and diagnostic PNG per frame, plus file manifest
result = farmWorkflow4Spectra(c);
disp(result.Files);

% Example of opening one saved result: saved=load(result.Files{1}); saved.result


%% WORKFLOW IMPLEMENTATION -- helper function, called by RUN above
function manifest = farmWorkflow4Spectra(c)

%WORKFLOW4SPECTRA Separate slices, projection, 3D spectra and linear correlation.

% ---- START RUN: create the output folder and keep small result tables/file paths in memory. ----
out = farmWorkflowNewRun(c,'workflow4'); files = cell(numel(c.SpectrumFrames),1);

% ---- PROCESS ONE FRAME AT A TIME: load, calculate, save, then continue to the next frame. ----
for k = 1:numel(c.SpectrumFrames)
    frame = c.SpectrumFrames(k); a = farmWorkflowIntensity(c,frame,'560'); timer = tic;
    slices = c.SelectedSlices(c.SelectedSlices<=size(a,3));
    if isempty(slices), error('memoworkflow:Slices','No selected Z slices exist.'); end

    % ---- SPECTRUM OPTIONS: pass spacing, radial bins, mean subtraction and windowing explicitly. ----
    opts = struct('Spacing',c.Spacing(1:2),'SpacingUnit',c.SpacingUnit,'NumBins',c.NumBins, ...
        'MeanSubtract',c.MeanSubtract,'Window',c.Window);
    result = struct('Frame',frame,'DatasetID',c.DatasetID);

    % OUTPUT CHOICES: separate slice/projection/volume radial spectra.

    % ---- INDIVIDUAL SLICES: each selected XY plane has its own 2-D spectrum. ----
    result.Slices = farmSelectSlicesAnalysis(a,slices,opts);

    % ---- PROJECTION: first collapse Z, then apply the same 2-D spectrum calculator. ----
    projection = validatestring(c.Projection,{'mean','max'});
    if strcmp(projection,'mean'), projected = mean(double(a),3); else, projected = max(a,[],3); end
    result.Projection = farmPowerSpectrum2D(projected,opts);
    result.Projection.Method = projection;

    % ---- FULL VOLUME: calculate the 3-D spectrum with all three voxel spacings. ----
    opts.Spacing = c.Spacing; result.Volume = farmPowerSpectrum3D(a,opts);

    % Store only radial correlation; discard each full temporary lag map.

    % ---- CORRELATION INPUT: use the first selected slice or the full XYZ volume. ----
    if strcmp(c.CorrelationMode,'3d'), field = a; spacing = c.Spacing;
    elseif strcmp(c.CorrelationMode,'2d'), field = a(:,:,slices(1)); spacing = c.Spacing(1:2);
    else, error('memoworkflow:Correlation','Choose 2d or 3d.'); end
    corr = farmAutoCorrelation(field,struct('Spacing',spacing,'MeanSubtract',c.MeanSubtract));
    result.AutoCorrelation = farmRadialAverage(corr.Correlation,struct('Coordinates',{corr.LagAxes},'NumBins',c.NumBins));
    clear corr

    % ---- OPTIONAL CROSS-CORRELATION: compare the same-frame primary and secondary fields. ----
    if c.CorrelationCrossChannel
        b = farmWorkflowIntensity(c,frame,'647');
        if strcmp(c.CorrelationMode,'2d'), b = b(:,:,slices(1)); end
        corr = farmCrossCorrelation(field,b,struct('Spacing',spacing,'MeanSubtract',c.MeanSubtract));
        result.CrossCorrelation = farmRadialAverage(corr.Correlation,struct('Coordinates',{corr.LagAxes},'NumBins',c.NumBins));
        clear corr b
    end
    result.CorrelationOptions = struct('Mode',c.CorrelationMode,'Spacing',spacing,'MeanSubtract',c.MeanSubtract,'Normalization','none');
    result.Seconds = toc(timer);

    % OUTPUT CHOICE: choose saved fields independently of plot/computation.

    % ---- SAVE SELECTION: payload controls what goes to disk; result remains available for plotting. ----
    payload = result;

    % payload=rmfield(payload,{'Slices','Projection'}); % example: omit 2-D spectra
    files{k} = fullfile(out,sprintf('frame%03i.mat',frame)); farmWorkflowSaveNew(files{k},payload);

    % ---- DIAGNOSTIC FIGURE: visualize this frame and export a PNG into the run folder. ----
    f = figure('Visible','off'); cleanup = onCleanup(@()close(f));
    subplot(1,2,1); hold on;
    for s = 1:numel(result.Slices), r = result.Slices{s}.Radial; plot(r.Centers,r.Mean); end
    r = result.Projection.Radial; plot(r.Centers,r.Mean,'k--');
    r = result.Volume.Radial; plot(r.Centers,r.Mean,'k','LineWidth',2);
    set(gca,'XScale','log','YScale','log'); xlabel(['Frequency (cycles/' c.SpacingUnit ')']); ylabel('Unnormalized radial power');
    subplot(1,2,2); plot(result.AutoCorrelation.Centers,result.AutoCorrelation.Mean);
    xlabel(['Lag magnitude (' c.SpacingUnit ')']); ylabel('Unnormalized correlation');
    farmFigSaves(f,out,sprintf('spectra_t%03i',frame),'png',true); clear cleanup
end

% ---- COMBINED OUTPUT: return the run directory and the retained tables or per-frame file paths. ----
manifest = struct('Directory',out,'Files',{files}); farmWorkflowSaveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 4 outputs: %s\n',out);
end
