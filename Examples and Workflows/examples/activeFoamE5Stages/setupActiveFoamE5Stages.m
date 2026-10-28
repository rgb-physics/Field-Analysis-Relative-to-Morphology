%% Configure the experiment
% Run farmSetup('IncludeExamples', true) from the repository folder first.
% This example reads E5 frames 25:30 from O: and writes new local results.
% It does not plot data or calculate peak/band summaries.
c = farmActiveFoamE5Config(10:60);

%% Prepare a new local output directory and progress log
% RunDirectory is this example's selected output folder, not a source folder.
if ~isfolder(c.OutputRoot)
    mkdir(c.OutputRoot);
end
c.RunDirectory = 'O:\Session 88\FARM Output';
% c.RunDirectory = tempname(c.OutputRoot);
mkdir(c.RunDirectory);
save(fullfile(c.RunDirectory, 'configuration.mat'), 'c');
diary(fullfile(c.RunDirectory, 'processing.log'));
fprintf('Stage-example results will be saved to: %s\n', c.RunDirectory);

%% Run the eight stages for each requested frame
% Each function accepts and returns c. Settings stay in the existing fields;
% data from the current frame is stored in c.Results. No try/catch is used.
% To inspect individual stages, use the one-frame commands in README.md.
measurementTables = cell(numel(c.Frames), 1);
inputTables = cell(numel(c.Frames), 1);
c.CompletedFrames = [];
% Record seconds per stage. TotalSeconds is their sum, excluding driver overhead.
stageNames = {'LoadDataSeconds', 'SegmentObjectsSeconds', 'MeasureFilamentsSeconds', ...
    'DefineGeometrySeconds', 'CalculateNormalsSeconds', 'SampleFieldsSeconds', ...
    'MeasureAlignmentSeconds', 'SaveMeasurementsSeconds'};
stageTimings = array2table([nan(numel(c.Frames), 1), double(c.Frames(:)), nan(numel(c.Frames), 8)], ...
    'VariableNames', [{'TotalSeconds', 'Frame'}, stageNames]);
stageTimings.Completed = false(numel(c.Frames), 1);
for frameIndex = 1:numel(c.Frames)
    tic
    c.Frame = c.Frames(frameIndex);
    fprintf('\n%s: frame %g (%d/%d).\n', char(datetime('now')), c.Frame, frameIndex, numel(c.Frames));

    % Stage 1: Load data. A new load clears earlier per-frame results.
    c = farmE5LoadData(c);
    if c.Results.MissingInput
        continue
    end

    % Stage 2: Segment the inside, boundary/on, and outside regions.
    c = farmE5SegmentObjects(c);

    % Stage 3: Detect filaments and measure their properties.
    c = farmE5MeasureFilaments(c);

    % Stage 4: Define boundary geometry and calculate signed distance.
    c = farmE5DefineGeometry(c);

    % Stage 5: Calculate surface-normal directions from distance gradients.
    c = farmE5CalculateNormals(c);

    % Stage 6: Sample fields at individual filament centroids.
    c = farmE5SampleFields(c);

    % Stage 7: Measure alignment and retain the selection flag.
    c = farmE5MeasureAlignment(c);

    % Stage 8: Save this frame's measurements and diagnostics.
    c = farmE5SaveMeasurements(c);

    measurementTables{frameIndex} = c.Results.Properties;
    inputTables{frameIndex} = c.Results.InputFiles;
    c.CompletedFrames(end + 1) = c.Frame;
    fprintf('Frame %g complete: %d detections, %.1f seconds.\n', ...
        c.Frame, height(c.Results.Properties), toc(started));
end

%% Combine the saved observations for later analysis
% Keep one table across frames, rather than retaining every dense image array.
c.StageTimings = stageTimings;
completed = cellfun(@istable, measurementTables);
if any(completed)
    observations = farmConcatenateMeasurements(measurementTables(completed));
    inputFiles = vertcat(inputTables{completed});
    c.Results.Workflow2 = struct('Directory', c.RunDirectory, 'Filaments', observations, ...
        'Frames', c.CompletedFrames, 'RequestedFrames', c.Frames, 'InputFiles', inputFiles, ...
        'SpacingYXZ', c.Spacing, 'ProbabilitySpacingYXZ', c.Experiment.Sources.Probabilities.Spacing, ...
        'SpacingUnit', c.SpacingUnit, 'TimeStepSeconds', c.TimeStep, 'TimeReferenceFrame', c.TimeReferenceFrame, ...
        'StageTimings', stageTimings);
    result = c.Results.Workflow2;
    save(fullfile(c.RunDirectory, 'workflow2-output.mat'), 'result', '-v7.3');
    writetable(observations, fullfile(c.RunDirectory, 'workflow2-filaments.csv'));
    writetable(inputFiles, fullfile(c.RunDirectory, 'input-files.csv'));
    fprintf('Completed frames: %s. Results: %s\n', mat2str(c.CompletedFrames), c.RunDirectory);
else
    fprintf(2, 'No frames were processed. See the missing-file messages.\n');
end
diary off

% If execution stops before this point, enter diary off to close the log.

%% Plot data from results
% Use the combined measurement table returned above as result.Filaments.
% This section can also run after loading result from workflow2-output.mat.

% Plotting %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Choose distance bins for the mean alignment and the distance distribution.
distanceEdges = -20:1:30; % Signed-distance edges, in result.SpacingUnit.
distanceHistogramBinWidth = 1; % Include the full finite distance range.

% Read alignment, signed distance, and acquisition frame for every detection.
% Order2D is the existing planar alignment quantity; no selection is applied.
allAlign = result.Filaments.Order2D;
allRs = result.Filaments.BoundaryDistance;
allTs = result.Filaments.Frame;

% Apply filtering
zAlignCut = .5;
zAligns = result.Filaments.Directors(:,3);
zLogic = abs(zAligns) < zAlignCut;

% Calculate elapsed time and use one acquisition frame per time bin.
% Retain missing frames as empty bins rather than closing gaps in time.
frameCenters = min(allTs):max(allTs);
timeCenters = (frameCenters - result.TimeReferenceFrame) * result.TimeStepSeconds;
timeEdges = [timeCenters - result.TimeStepSeconds / 2, timeCenters(end) + result.TimeStepSeconds / 2];
allTimes = (allTs - result.TimeReferenceFrame) * result.TimeStepSeconds;
distanceCenters = (distanceEdges(1:end - 1) + distanceEdges(2:end)) / 2;
distanceBin = discretize(allRs, distanceEdges);
timeBin = discretize(allTimes, timeEdges);

% Average finite alignment values within each distance/time bin.
% Keep counts alongside the means; an empty bin has mean NaN, not zero.
validAlignment = isfinite(allAlign) & ~isnan(distanceBin) & ~isnan(timeBin) & zLogic;
binSize = [numel(distanceCenters), numel(timeCenters)];
alignmentCounts = accumarray([distanceBin(validAlignment), timeBin(validAlignment)], 1, binSize, @sum, 0);
meanAlignment = accumarray([distanceBin(validAlignment), timeBin(validAlignment)], double(allAlign(validAlignment)), binSize, @mean, NaN);

% Display mean alignment with distance vertically and elapsed time horizontally.
% Gray regions contain no finite alignment values. The line marks r = 0.
alignmentFigure = figure('Name', 'Mean Order2D over distance and time');
alignmentAxes = axes(alignmentFigure);
alignmentImage = imagesc(alignmentAxes, timeCenters/60, distanceCenters, meanAlignment);
alignmentImage.AlphaData = isfinite(meanAlignment);
set(alignmentAxes, 'YDir', 'normal', 'Color', [0.85 0.85 0.85],'FontSize',15);
ylabel(alignmentAxes, sprintf('Signed boundary distance (%s)', result.SpacingUnit));
xlabel(alignmentAxes, 'Elapsed time (min)');
title(alignmentAxes, 'Mean Order2D by distance and time');
alignmentColorbar = colorbar(alignmentAxes);
alignmentColorbar.Label.String = 'Mean Order2D';
clim(alignmentAxes, [-1 1]);
yline(alignmentAxes, 0, 'k--');

% Display all finite distances, pooled across frames, including observations
% without a finite alignment value. These are counts, not probability density.
distanceFigure = figure('Name', 'Distribution of allRs');
distanceAxes = axes(distanceFigure);
distanceHistogram = histogram(distanceAxes, allRs(isfinite(allRs)), 'BinWidth', distanceHistogramBinWidth);
xlabel(distanceAxes, sprintf('Signed boundary distance (%s)', result.SpacingUnit));
ylabel(distanceAxes, 'Filament detections');
title(distanceAxes, 'Distribution of allRs across all processed frames');
xline(distanceAxes, 0, 'k--');

%% Get alignment maxima within a band of distances
maxDisp = 3;
minDisp = -15;
cutoffLogic = distanceCenters>minDisp & distanceCenters<maxDisp;
cutoffDists = distanceCenters(cutoffLogic);
croppedAligns = meanAlignment((cutoffLogic),1:numel(timeCenters));

[~,maxInds] = max(croppedAligns);

maxDists = cutoffDists(maxInds);

% Display mean alignment with distance horizontally and elapsed time vertically.
% Gray regions contain no finite alignment values. The line marks r = 0.
alignmentFigure = figure('Name', 'Mean Order2D over distance and time');
alignmentAxes = axes(alignmentFigure);
alignmentImage = imagesc(alignmentAxes, timeCenters/60,distanceCenters, meanAlignment);
alignmentImage.AlphaData = isfinite(meanAlignment);
set(alignmentAxes, 'YDir', 'normal', 'Color', [0.85 0.85 0.85],'FontSize',15);
ylabel(alignmentAxes, sprintf('Signed boundary distance (%s)', result.SpacingUnit));
xlabel(alignmentAxes, 'Elapsed time (min)');
title(alignmentAxes, 'Mean Order2D by distance and time');
alignmentColorbar = colorbar(alignmentAxes);
alignmentColorbar.Label.String = 'Mean Order2D';
clim(alignmentAxes, [-1 1]);
yline(alignmentAxes, 0, 'k--');

hold on
scatter(timeCenters/60,maxDists)
