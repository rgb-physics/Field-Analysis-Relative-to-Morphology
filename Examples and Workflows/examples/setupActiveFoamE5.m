%% Configure data sources and settings
% Assemble the E5 measurements with public FARM functions and MATLAB commands.
% No workflow-specific processing helper is needed. All settings are below;
% alternatively replace this configuration section with c = farmActiveFoamE5Config.
% O:\Session 88 and everything below it is read only. Results are saved locally.
% Run one frame while inspecting stages, or place breakpoints before API calls.
% Variables from the last processed frame remain in the workspace.
% Compare each block with the functions in examples/activeFoamE5Stages.
% Package Setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Locate the package. Run farmSetup before calling this configuration.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
c = struct();
c.RepositoryRoot = repo;

% Data Loading %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Specify the folders and filename patterns used to read each source.
% For this experiment, O:\Session 88 and its subfolders must remain read only.
filsDataDirectory = 'O:\Session 88\Exp 5\3 Illumination Bleach Corrected 16bit';
probsDirectory = 'O:\Session 88\all ilastik prep files';
filamentNamePattern = 't%03i_illBleachCorr16bit_647.tif';
probabilityNamePattern = 't%03i_illCorr8bit_560_E5_Probabilities Stage 2.h5';
probabilityDatasetPath = '/exported_data';

% Select the acquisition frames to process.
c.Frames = 25:30;

% Describe dataset identity, spatial sampling, stored dimensions, and timing.
% Supply calibration from acquisition/export metadata; it is not inferred.
c.DatasetID = 'S88E5';               % Identifier stored with measurements.
c.Spacing = [0.55 0.55 0.7];         % Image sample spacing in [Y X Z] order.
probabilitySpacing = [1.5 1.5 1.5];  % Probability sample spacing in [Y X Z] order.
c.SpacingUnit = 'um';               % Spatial unit for both sources.
filamentAxes = 'YXZ';               % Stored image dimensions: Y, X, Z.
probabilityAxes = 'CXYZ';            % Stored probability dimensions: channel, X, Y, Z.
c.TimeStep = 30;                    % Time between acquisition frames.
c.TimeUnit = 's';                   % Unit of TimeStep.
c.TimeReferenceFrame = c.Frames(1);          % Frame assigned elapsed time zero.

% Define how to load corrected filament images.
% farmMakeSource describes a source; it does not load images here.
% In NamePattern, %03i represents a three-digit frame number, such as 025.
filaments = farmMakeSource( ...
    'Format', 'tiff', ...
    'Folder', filsDataDirectory, ...
    'NamePattern', filamentNamePattern, ...
    'SourceAxes', filamentAxes, ...
    'Spacing', c.Spacing, ...
    'SpacingUnit', c.SpacingUnit);

% Define how to load object-segmentation probabilities.
probabilities = farmMakeSource( ...
    'Format', 'hdf5', ...
    'Folder', probsDirectory, ...
    'NamePattern', probabilityNamePattern, ...
    'DatasetPath', probabilityDatasetPath, ...
    'SourceAxes', probabilityAxes, ...
    'Spacing', probabilitySpacing, ...
    'SpacingUnit', c.SpacingUnit);

% Combine the named sources and acquisition metadata into an experiment.
c.Experiment = farmMakeExperiment( ...
    'DatasetID', c.DatasetID, ...
    'Frames', c.Frames, ...
    'TimeStep', c.TimeStep, ...
    'TimeUnit', c.TimeUnit, ...
    'Sources', struct('Intensity647', filaments, 'Probabilities', probabilities));

% Object Segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Segment objects from probabilities for inside, boundary/on, and outside.
c.SemanticChannels = [3 2 1]; % Source channels for [inside, boundary/on, outside].
c.Thresholds = [0.33 0.33 0.33];
c.OpeningRadius = 1;         % Probability-grid voxels.
c.FillMethod = 'none';      % 'none', 'nearest', or highest-precedence 'fill', after opening.

% Filament Detection %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detect filaments using a Laplacian-of-Gaussian (LoG) filter and threshold.
% Leave FilamentLoader empty to use this process. Alternatively, supply a
% function handle @(frame) returning a same-grid binary filament mask.
c.FilamentLoader = [];
c.FilamentSigma = 1;      % LoG smoothing, in intensity-grid voxels.
c.FilamentThreshold = 20; % Threshold applied to negative LoG intensity.
c.FilamentSegmentationMethod = 'fixed';

% Filament Measurement %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Request the quantities to retain in the measurement table. Centroid,
% ScaledDirectors, ProjectedExtent, and ScaledAspectRatios are used below;
% retain those entries when adding or removing other measurements.
c.FilamentProperties = {'Volume', 'Centroid', 'Directors', 'ExtentInVoxels', 'AspectRatios', ...
    'ScaledDirectors', 'ProjectedExtent', 'ScaledAspectRatios'};
c.ExtentWidthFloor = eps; % Positive lower limit used in extent/aspect calculations.

% Select detections by measured extent and aspect ratio; retain all table rows.
c.MinFilamentLength = 0; % Minimum ProjectedExtent accepted by the selection.
c.MinAspectRatio = 0;    % Minimum ScaledAspectRatios accepted by the selection.

% Boundary Geometry %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the isotropic grid and morphological radius for boundary distances.
c.BoundaryWorkingSpacing = min(c.Spacing); % Same physical unit as image spacing.
c.BoundaryDilationRadius = 1;              % Isotropic working-grid voxels.
c.RegionInterpolation = 'nearest';        % Preserve discrete category/validity labels.
c.DistanceInterpolation = 'nearest';      % Return distances to the intensity grid.

% Surface-Normal Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set smoothing for the distance gradient. The processing stage below defines
% the boundary geometry and distance field explicitly.
c.ProfileSigma = 2; % Distance-gradient smoothing, in intensity-grid voxels.
c.GradientDerivativeUnits = 'physical'; % Differentiate using supplied spatial spacing.

% Field Sampling %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Request statistics at each single-voxel centroid selection. Mean and
% MeanVector supply the measurement columns used below; retain them when
% adding other statistics. See help farmQueryField and farmQueryVectorField.
c.ScalarSamplingStatistics = {'Mean'};
c.VectorSamplingStatistics = {'MeanVector'};

% Alignment Measurement %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compare filament directions with the sampled surface-normal directions.
% Optionally filter directions for projected XY alignment by their Z component.
% Leave the limit empty to omit this filter; it does not filter Order3D plots.
c.MaxZComponent = []; % Optional limit from 0 to 1.
c.AlignmentPlane = [1 2]; % X and Y components for projected alignment.

% Alignment Analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Group measured Order3D values by signed distance and acquisition frame.
% Order3D = (3*cos(theta)^2 - 1)/2, where theta is the angle to the normal.
% Its isotropic reference is 0; parallel and opposite directions both give 1.
% AlignmentPlot holds settings for this example, not a general plotting API.
c.AlignmentPlot = struct();
c.AlignmentPlot.Frames = c.Frames;
c.AlignmentPlot.TimeStep = c.TimeStep;
c.AlignmentPlot.TimeReferenceFrame = c.TimeReferenceFrame;
c.AlignmentPlot.DistanceEdges = -20:1:30; % Distance-bin edges, in micrometers.

% Choose the elapsed-time window used to find a fixed peak distance r*.
% Elapsed time = (Frame - TimeReferenceFrame) * TimeStep.
% Compare bins with sufficient observations at every time in the window.
c.AlignmentPlot.AverageTimeWindow = [0 150]; % Elapsed seconds, inclusive.

% Set criteria for locating peaks and flagging flat or broad profiles.
% These are exploratory example settings; choose values for the data analyzed.
c.AlignmentPlot.MinPeakCount = 20;       % Minimum observations in an eligible bin.
c.AlignmentPlot.FlatTolerance = 0.05;    % Maximum peak-to-minimum difference called flat.
c.AlignmentPlot.BroadPeakFraction = 0.9; % Used to identify bins close to the peak value.

% Select fixed distance bands for alignment time traces.
% Bands include the left edge and exclude the right; distances are micrometers.
% The r* band may overlap InteriorBand, so traces can share observations.
c.AlignmentPlot.InteriorBand = [-10 -5];
c.AlignmentPlot.ExteriorBand = [5 10];
c.AlignmentPlot.FixedBandHalfWidth = 1; % Sample from r* - 1 to r* + 1.

% Data Plotting %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose frames for spatial profiles and create the three example figures.
% Standard deviation describes observation spread, not a confidence interval.
c.AlignmentPlot.SelectedFrames = [25 27 30];
c.AlignmentPlot.MakeFigures = true;

% Output %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose where to save results and print processing progress.
% Processing creates a new run folder beneath OutputRoot.
outputDirectory = fullfile(repo, 'tests', 'data', 'workflow-results');
outputName = 'active-foam-E5-frames025-030';
c.OutputRoot = fullfile(outputDirectory, outputName);
c.Verbose = true;

%% Choose whether to process images or load saved measurements
% Leave this empty to process c.Frames. Otherwise supply workflow2-output.mat.
% Loading saved measurements does not read the microscopy images.
savedWorkflow2File = '';
runAlignmentAnalysis = false; % Optional existing analysis; discuss its design separately.

%% Process selected frames using public APIs
if isempty(savedWorkflow2File)
    % Save only to a new local directory. This does not change source data.
    if ~isfolder(c.OutputRoot)
        mkdir(c.OutputRoot);
    end
    out = tempname(c.OutputRoot);
    mkdir(out);
    save(fullfile(out, 'configuration.mat'), 'c');
    diary(fullfile(out, 'processing.log'));
    fprintf('Processed data will be saved to: %s\n', out);
    frameTables = cell(numel(c.Frames), 1);
    completedFrames = [];
    inputRows = cell(0, 3);
    % Record seconds per stage. TotalSeconds excludes work outside these stages.
    stageNames = {'LoadDataSeconds', 'SegmentObjectsSeconds', 'MeasureFilamentsSeconds', ...
        'DefineGeometrySeconds', 'CalculateNormalsSeconds', 'SampleFieldsSeconds', ...
        'MeasureAlignmentSeconds', 'SaveMeasurementsSeconds'};
    stageTimings = array2table([nan(numel(c.Frames), 1), double(c.Frames(:)), nan(numel(c.Frames), 8)], ...
        'VariableNames', [{'TotalSeconds', 'Frame'}, stageNames]);
    stageTimings.Completed = false(numel(c.Frames), 1);

    try
        for frameIndex = 1:numel(c.Frames)
            frame = c.Frames(frameIndex);
            started = tic;
            fprintf('\n%s: frame %g (%d/%d).\n', char(datetime('now')), frame, frameIndex, numel(c.Frames));

            % Data Loading %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Check that both input files exist; report missing files and continue.
            stageStarted = tic;
            sources = c.Experiment.Sources;
            intensityFile = fullfile(sources.Intensity647.Folder, sprintf(sources.Intensity647.NamePattern, frame));
            probabilityFile = fullfile(sources.Probabilities.Folder, sprintf(sources.Probabilities.NamePattern, frame));
            if ~isfile(intensityFile) || ~isfile(probabilityFile)
                fprintf(2, 'Skipping frame %g. Missing inputs:\n', frame);
                if ~isfile(intensityFile)
                    fprintf(2, '%s\n', intensityFile);
                end
                if ~isfile(probabilityFile)
                    fprintf(2, '%s\n', probabilityFile);
                end
                stageTimings.LoadDataSeconds(frameIndex) = toc(stageStarted);
                stageTimings.TotalSeconds(frameIndex) = sum(stageTimings{frameIndex, 3:10}, 'omitnan');
                writetable(stageTimings, fullfile(out, 'stage-timings.csv'));
                save(fullfile(out, 'stage-timings.mat'), 'stageTimings');
                continue
            end
            intensityImage = farmLoadSource(c.Experiment, 'Intensity647', frame);
            probabilityImage = farmLoadSource(c.Experiment, 'Probabilities', frame);
            raw = intensityImage.Data(:, :, :, 1, 1);
            probabilities = probabilityImage.Data(:, :, :, :, 1);
            targetSize = [size(raw, 1) size(raw, 2) size(raw, 3)];
            inputRows(end + 1:end + 2, :) = {frame, 'Intensity647', intensityFile; frame, 'Probabilities', probabilityFile};
            fprintf('Loaded image %s and probabilities %s.\n', mat2str(targetSize), mat2str(size(probabilities)));
            stageTimings.LoadDataSeconds(frameIndex) = toc(stageStarted);

            % Object Segmentation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Convert [inside, boundary/on, outside] probability channels into masks.
            stageStarted = tic;
            [regionMasks, segmentationInfo] = farmSmoothNChannelProbabilities( ...
                probabilities, c.SemanticChannels, c.Thresholds, ...
                struct('OpeningRadius', c.OpeningRadius, 'FillMethod', c.FillMethod));
            regions = zeros(size(probabilities, 1), size(probabilities, 2), size(probabilities, 3), 'uint8');
            for category = 1:3
                categoryMask = regionMasks(:, :, :, category);
                regions(categoryMask) = category;
            end
            % Place the categories on the intensity grid. This assumes the
            % supplied sources describe the same physical field of view.
            % Resampling uses user-supplied metadata; calibration is not estimated.
            regions = imresize3(regions, targetSize, c.RegionInterpolation);
            insideMask = regions == 1;
            boundaryRegionMask = regions == 2;
            outsideMask = regions == 3;
            stageTimings.SegmentObjectsSeconds(frameIndex) = toc(stageStarted);

            % Filament Detection and Measurement %%%%%%%%%%%%%%%%%%%%%%%%%%%
            stageStarted = tic;
            if isempty(c.FilamentLoader)
                response = -farmLOG(double(raw), c.FilamentSigma);
                filamentSegmentation = farmSegmentIntensity(response, ...
                    struct('Method', c.FilamentSegmentationMethod, 'Threshold', c.FilamentThreshold));
                filamentMask = filamentSegmentation.Mask;
            else
                filamentMask = c.FilamentLoader(frame);
            end
            identity = struct('DatasetID', c.DatasetID, 'Frame', frame, 'Spacing', c.Spacing, 'SpacingUnit', c.SpacingUnit);
            [properties, objects] = farmMeasureFilaments(filamentMask, c.FilamentProperties, ...
                struct('Identity', identity, 'ExtentWidthFloor', c.ExtentWidthFloor));
            fprintf('Measured %d filament detections.\n', height(properties));
            stageTimings.MeasureFilamentsSeconds(frameIndex) = toc(stageStarted);

            % Geometry Definition %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Use an isotropic working grid for the existing boundary method.
            % The boundary/on category is a region, not the final boundary surface.
            stageStarted = tic;
            workingSpacing = c.BoundaryWorkingSpacing;
            workingSize = max(2, round(targetSize .* c.Spacing / workingSpacing));
            workingRegions = imresize3(regions, workingSize, c.RegionInterpolation);
            [workingDistance, ~, ~, ~, ~, workingValid] = ...
                farmDistTransFromBoundary(workingRegions == 2, workingRegions == 3, workingRegions == 1, c.BoundaryDilationRadius);
            % Signed distance is negative inside and positive outside.
            % Keep the calculated zero boundary; do not move it to an alignment peak.
            distance = imresize3(workingDistance * workingSpacing, targetSize, c.DistanceInterpolation);
            distanceValid = imresize3(workingValid, targetSize, c.RegionInterpolation);
            stageTimings.DefineGeometrySeconds(frameIndex) = toc(stageStarted);

            % Surface-Normal Directions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Calculate gradient components in physical coordinates; smoothing
            % uses intensity-grid voxels. Components are ordered X, Y, Z.
            stageStarted = tic;
            gradientOptions = struct('Sigma', c.ProfileSigma, 'Spacing', c.Spacing, ...
                'SpacingUnit', c.SpacingUnit, 'DerivativeUnits', c.GradientDerivativeUnits, 'DistanceUnit', c.SpacingUnit);
            [distanceGradient, gradientInfo, directionValid] = farmDistanceGradients(distance, gradientOptions);
            fprintf('Boundary distance and surface-normal directions prepared.\n');
            stageTimings.CalculateNormalsSeconds(frameIndex) = toc(stageStarted);

            % Field Sampling %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Select one rounded centroid voxel per filament. Centroid columns
            % are XYZ; MATLAB array dimensions and spatial spacing use YXZ.
            stageStarted = tic;
            centroidXYZ = round(properties.Centroid);
            centroidIndices = sub2ind(targetSize, centroidXYZ(:, 2), centroidXYZ(:, 1), centroidXYZ(:, 3));
            supportOptions = struct('Type', 'indices', 'ObjectIDs', properties.ObjectID, ...
                'DatasetID', c.DatasetID, 'Frame', frame, 'Name', 'FilamentCentroids');
            centroidSupport = farmPrepareSupport(num2cell(centroidIndices), targetSize, supportOptions);
            % Mean at a single selected voxel is that voxel's value. Keep the
            % complete query results as diagnostics, separately from measurements.
            distanceSamples = farmQueryField(distance, centroidSupport, c.ScalarSamplingStatistics, struct('FieldName', 'BoundaryDistance'));
            regionSamples = farmQueryField(regions, centroidSupport, c.ScalarSamplingStatistics, struct('FieldName', 'RegionClass'));
            referenceSamples = farmQueryField(distanceValid, centroidSupport, c.ScalarSamplingStatistics, struct('FieldName', 'ReferenceValid'));
            directionSamples = farmQueryField(directionValid, centroidSupport, c.ScalarSamplingStatistics, struct('FieldName', 'DirectionValid'));
            gradientFields = struct('X', distanceGradient(:, :, :, 1), ...
                'Y', distanceGradient(:, :, :, 2), 'Z', distanceGradient(:, :, :, 3));
            gradientSamples = farmQueryVectorField(gradientFields, centroidSupport, c.VectorSamplingStatistics, ...
                struct('FieldName', 'Gradient', 'ComponentNames', {{'X', 'Y', 'Z'}}));
            samplingDiagnostics = farmAttachResults(distanceSamples, regionSamples);
            samplingDiagnostics = farmAttachResults(samplingDiagnostics, referenceSamples);
            samplingDiagnostics = farmAttachResults(samplingDiagnostics, directionSamples);
            samplingDiagnostics = farmAttachResults(samplingDiagnostics, gradientSamples);
            properties.CoMIndices = centroidIndices;
            % Queries return double statistics; preserve the distance field's
            % numeric type in the Workflow 2 observation column.
            properties.BoundaryDistance = cast(distanceSamples.BoundaryDistance_Mean, 'like', distance);
            properties.RegionClass = uint8(regionSamples.RegionClass_Mean);
            properties.ReferenceValid = logical(referenceSamples.ReferenceValid_Mean);
            properties.ReferenceDirectionValid = logical(directionSamples.DirectionValid_Mean);
            properties.DistanceGradient = gradientSamples.Gradient_MeanVector;
            stageTimings.SampleFieldsSeconds(frameIndex) = toc(stageStarted);

            % Alignment Measurement %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Compare physical-space filament directions with sampled normals.
            % Order3D = (3*cos(theta)^2 - 1)/2; isotropic mean = 0.
            stageStarted = tic;
            directors = properties.ScaledDirectors;
            reference = properties.DistanceGradient;
            finiteDirections = all(isfinite(directors), 2) & all(isfinite(reference), 2);
            alignment3D = farmNematicAlignment(directors(finiteDirections, :), reference(finiteDirections, :));
            alignment2D = farmNematicAlignment(directors(finiteDirections, :), reference(finiteDirections, :), ...
                struct('Plane', c.AlignmentPlane, 'MaxNormalComponent', c.MaxZComponent));
            properties.Order3D = nan(height(properties), 1);
            properties.Order2D = nan(height(properties), 1);
            properties.SignedAngle2D = nan(height(properties), 1);
            properties.Order3D(finiteDirections) = alignment3D.Order;
            properties.Order2D(finiteDirections) = alignment2D.Order;
            properties.SignedAngle2D(finiteDirections) = alignment2D.SignedAngle;
            properties.Selected = properties.ReferenceValid & properties.ReferenceDirectionValid & ...
                properties.ProjectedExtent >= c.MinFilamentLength & properties.ScaledAspectRatios >= c.MinAspectRatio;
            stageTimings.MeasureAlignmentSeconds(frameIndex) = toc(stageStarted);

            % Save Measurements %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Save tables by default. Dense geometry fields remain available
            % for the current frame; add them to result explicitly if needed.
            stageStarted = tic;
            frameTables{frameIndex} = properties;
            completedFrames(end + 1) = frame; %#ok<SAGROW>
            result = struct('Filaments', properties, 'SamplingDiagnostics', samplingDiagnostics, ...
                'SegmentationInfo', segmentationInfo, 'GradientInfo', gradientInfo, 'Seconds', toc(started));
            save(fullfile(out, sprintf('frame%03i.mat', frame)), 'result', '-v7.3');
            stageTimings.SaveMeasurementsSeconds(frameIndex) = toc(stageStarted);
            stageTimings.TotalSeconds(frameIndex) = sum(stageTimings{frameIndex, 3:10});
            stageTimings.Completed(frameIndex) = true;
            writetable(stageTimings, fullfile(out, 'stage-timings.csv'));
            save(fullfile(out, 'stage-timings.mat'), 'stageTimings');
            fprintf('Frame %g saved: %d detections, %d selected, %.1f seconds.\n', ...
                frame, height(properties), nnz(properties.Selected), toc(started));
        end
        % Combine only completed frames; preserve dataset/frame/object identity.
        if isempty(completedFrames)
            error('farm:E5NoFrames', 'No frames were processed. See the missing-file messages.');
        end
        inputFiles = cell2table(inputRows, 'VariableNames', {'Frame', 'Source', 'Path'});
        workflow2 = struct('Directory', out, 'Filaments', farmConcatenateMeasurements(frameTables(cellfun(@istable, frameTables))), ...
            'Frames', completedFrames, 'RequestedFrames', c.Frames, 'InputFiles', inputFiles, ...
            'SpacingYXZ', c.Spacing, 'ProbabilitySpacingYXZ', sources.Probabilities.Spacing, ...
            'SpacingUnit', c.SpacingUnit, 'TimeStepSeconds', c.TimeStep, 'TimeReferenceFrame', c.TimeReferenceFrame, ...
            'StageTimings', stageTimings);
        result = workflow2;
        save(fullfile(out, 'workflow2-output.mat'), 'result', '-v7.3');
        writetable(workflow2.Filaments, fullfile(out, 'workflow2-filaments.csv'));
        writetable(inputFiles, fullfile(out, 'input-files.csv'));
        fprintf('Completed frames: %s. Output directory: %s\n', mat2str(completedFrames), out);
        diary off
    catch processingError
        fprintf(2, '%s\n', getReport(processingError, 'extended', 'hyperlinks', 'off'));
        diary off
        rethrow(processingError)
    end
else
    saved = load(savedWorkflow2File, 'result');
    workflow2 = saved.result;
    workflow2.OriginalDirectory = workflow2.Directory;
    workflow2.Directory = fileparts(savedWorkflow2File);
    if isfield(workflow2, 'StageTimings')
        stageTimings = workflow2.StageTimings;
    else
        stageTimings = table(); % Earlier saved runs did not record stage times.
    end
end

%% Pass measured observations to analysis
% Workflow 2's output is passed explicitly. Subsequent analysis needs only
% this table and timing/distance settings; it does not reload microscopy images.
filaments = workflow2.Filaments;

%% Calculate optional peak locations and distance-band summaries
% Analysis and visualization design will be discussed separately.
% Enable the existing example only if these summaries and figures are wanted.
if runAlignmentAnalysis
    plotOptions = c.AlignmentPlot; %#ok<UNRCH> % Enabled by changing runAlignmentAnalysis above.
    plotOptions.OutputDirectory = fullfile(workflow2.Directory, 'alignment-plots');
    alignmentReport = farmPlotActiveFoamAlignment(workflow2, plotOptions);
end
