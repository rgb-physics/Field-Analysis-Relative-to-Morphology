function report = farmPlotActiveFoamAlignment(workflow2, options)
%FARMPLOTACTIVEFOAMALIGNMENT Summarize workflow 2 rod observations by distance/time.
% Inputs:
%   workflow2   Explicit output of farmWorkflow2Filaments/farmProcessActiveFoamE5.
%               Filaments supplies Frame, BoundaryDistance, Order3D and validity.
%   options         Optional plotting/binning settings struct with the fields:
%                   Frames = numeric vector;
%                   TimeStep = positive numeric scalar;
%                   TimeReferenceFrame = numeric scalar;
%                   DistanceEdges = numeric vector;
%                   SelectedFrames = numeric vector;
%                   AverageTimeWindow = numeric two-element vector;
%                   InteriorBand = numeric two-element vector;
%                   ExteriorBand = numeric two-element vector;
%                   FixedBandHalfWidth = positive numeric scalar;
%                   MinPeakCount = positive integer scalar;
%                   FlatTolerance = nonnegative numeric scalar;
%                   BroadPeakFraction = numeric scalar in (0, 1];
%                   MakeFigures = logical scalar;
%                   OutputDirectory = character vector or string scalar;
% Outputs:
%   report      Binned means/counts/sample variances, peaks, bands and figures.
% Equal weight per selected finite rod observation. Empty means are NaN.
% Shading is rod-level standard deviation, not a confidence interval.

if nargin < 2
    options = struct();
end
defaults = struct('Frames', 25:30, 'TimeStep', 30, 'TimeReferenceFrame', 25, ...
    'DistanceEdges', -20:1:30, 'SelectedFrames', [25 27 30], ...
    'AverageTimeWindow', [0 150], 'InteriorBand', [-10 -5], 'ExteriorBand', [5 10], ...
    'FixedBandHalfWidth', 1, 'MinPeakCount', 20, 'FlatTolerance', .05, ...
    'BroadPeakFraction', .9, 'MakeFigures', true, 'OutputDirectory', '');
o = farmParseOptions(defaults, options);
validateattributes(o.Frames, {'numeric'}, {'vector', 'real', 'finite', 'increasing', 'nonempty'});
validateattributes(o.TimeStep, {'numeric'}, {'scalar', 'positive', 'finite'});
validateattributes(o.TimeReferenceFrame, {'numeric'}, {'scalar', 'finite'});
validateattributes(o.DistanceEdges, {'numeric'}, {'vector', 'real', 'finite', 'increasing'});
validateattributes(o.AverageTimeWindow, {'numeric'}, {'vector', 'numel', 2, 'finite', 'nondecreasing'});
validateattributes(o.MinPeakCount, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(o.FlatTolerance, {'numeric'}, {'scalar', 'nonnegative', 'finite'});
validateattributes(o.BroadPeakFraction, {'numeric'}, {'scalar', '>', 0, '<=', 1});
validateattributes(o.FixedBandHalfWidth, {'numeric'}, {'scalar', 'positive', 'finite'});
validateattributes(o.MakeFigures, {'logical'}, {'scalar'});
validateattributes(o.InteriorBand, {'numeric'}, {'vector', 'numel', 2, 'finite', 'increasing'});
validateattributes(o.ExteriorBand, {'numeric'}, {'vector', 'numel', 2, 'finite', 'increasing'});
if numel(o.DistanceEdges) < 2
    error('memoworkflow:AlignmentEdges', 'Supply at least two distance edges.');
end
if ~isstruct(workflow2) || ~isscalar(workflow2) || ~isfield(workflow2, 'Filaments') || ~istable(workflow2.Filaments)
    error('memoworkflow:AlignmentInput', 'Pass workflow 2 output explicitly, with its Filaments table.');
end
input = workflow2.Filaments;
required = {'DatasetID', 'Frame', 'ObjectID', 'BoundaryDistance', 'Order3D', ...
    'Selected', 'ReferenceValid', 'ReferenceDirectionValid'};
if ~all(ismember(required, input.Properties.VariableNames))
    error('memoworkflow:AlignmentColumns', 'Workflow 2 must supply: %s', strjoin(required, ', '));
end
if numel(unique(input.DatasetID)) > 1
    error('memoworkflow:AlignmentDataset', 'Plot one dataset at a time.');
end

frames = double(o.Frames(:));
times = (frames - o.TimeReferenceFrame) * o.TimeStep;
edges = double(o.DistanceEdges(:).');
centers = (edges(1:end-1) + edges(2:end)) / 2;
inFrames = ismember(input.Frame, frames);
valid = inFrames & input.Selected & input.ReferenceValid & input.ReferenceDirectionValid & ...
    isfinite(input.BoundaryDistance) & isfinite(input.Order3D);
observations = input(valid, :);
observations.TimeSeconds = (observations.Frame - o.TimeReferenceFrame) * o.TimeStep;
distance = double(observations.BoundaryDistance);
alignment = double(observations.Order3D);
distanceBin = discretize(distance, edges);
[~, timeBin] = ismember(observations.Frame, frames);
nr = numel(centers);
nt = numel(times);
means = nan(nr, nt);
variances = nan(nr, nt);
counts = zeros(nr, nt);
for timeIndex = 1:nt
    for distanceIndex = 1:nr
        values = alignment(timeBin == timeIndex & distanceBin == distanceIndex);
        [means(distanceIndex, timeIndex), variances(distanceIndex, timeIndex), counts(distanceIndex, timeIndex)] = localStats(values);
    end
end

% Keep raw candidate location/value separately from whether a peak is meaningful.
peakPrototype = struct('CandidateDistance', NaN, 'Distance', NaN, 'Value', NaN, ...
    'Flat', false, 'Tied', false, 'Broad', false, 'Sparse', false, 'AtRangeEdge', false);
peaks = repmat(peakPrototype, nt, 1);
for timeIndex = 1:nt
    peaks(timeIndex) = localPeak(centers, means(:, timeIndex), counts(:, timeIndex) >= o.MinPeakCount, o);
end
peakTable = struct2table(peaks);
peakTable.Frame = frames;
peakTable.TimeSeconds = times;

% A fixed representative distance uses the SAME time coverage at every position.
window = times >= o.AverageTimeWindow(1) & times <= o.AverageTimeWindow(2);
windowTimes = times(window);
weights = localWeights(windowTimes);
timeMean = nan(nr, 1);
common = all(isfinite(means(:, window)), 2) & all(counts(:, window) >= o.MinPeakCount, 2);
if ~any(window)
    common(:) = false;
else
    timeMean(common) = means(common, window) * weights;
end
fixedPeak = localPeak(centers, timeMean, common, o);
fixedPeak.Window = o.AverageTimeWindow;
fixedPeak.TimeSeconds = windowTimes;
fixedPeak.Weights = weights;
fixedPeak.MissingPolicy = 'Require finite means and MinPeakCount at every included time; no per-distance renormalization';

% Fixed distance-band traces pool rod observations directly, not distance-bin means.
bandNames = ["Fixed peak band"; "Interior"; "Exterior"];
bandEdges = [fixedPeak.Distance + [-o.FixedBandHalfWidth o.FixedBandHalfWidth]; ...
    o.InteriorBand(:).'; o.ExteriorBand(:).'];
bandRows = cell(nt * 3, 9);
row = 0;
for bandIndex = 1:3
    for timeIndex = 1:nt
        row = row + 1;
        chosen = timeBin == timeIndex & distance >= bandEdges(bandIndex, 1) & distance < bandEdges(bandIndex, 2);
        [mu, variance, n] = localStats(alignment(chosen));
        bandRows(row, :) = {bandNames(bandIndex), bandEdges(bandIndex, 1), bandEdges(bandIndex, 2), ...
            frames(timeIndex), times(timeIndex), n, mu, variance, sqrt(variance)};
    end
end
bands = cell2table(bandRows, 'VariableNames', ...
    {'Band', 'LeftEdge', 'RightEdge', 'Frame', 'TimeSeconds', 'Count', 'Mean', 'Variance', 'Std'});
[rGrid, tGrid] = ndgrid(centers, times);
[~, frameGrid] = ndgrid(centers, frames);
binned = table(frameGrid(:), tGrid(:), rGrid(:), counts(:), means(:), variances(:), sqrt(variances(:)), ...
    'VariableNames', {'Frame', 'TimeSeconds', 'DistanceCenter', 'Count', 'Mean', 'Variance', 'Std'});
frameCounts = zeros(nt, 5);
for index = 1:nt
    frameCounts(index, :) = [frames(index), nnz(inFrames & input.Frame == frames(index)), ...
        nnz(valid & input.Frame == frames(index)), nnz(timeBin == index & ~isnan(distanceBin)), ...
        nnz(timeBin == index & isnan(distanceBin))];
end
qc = array2table(frameCounts, 'VariableNames', ...
    {'Frame', 'InputDetections', 'SelectedFinite', 'WithinDistanceEdges', 'OutsideDistanceEdges'});
report = struct('Observations', observations, 'Binned', binned, 'Mean', means, ...
    'Count', counts, 'Variance', variances, 'DistanceCenters', centers, 'DistanceEdges', edges, ...
    'TimeSeconds', times, 'MovingPeak', peakTable, 'FixedPeak', fixedPeak, ...
    'TimeAveragedProfile', timeMean, 'Bands', bands, 'QualityCounts', qc, 'Options', o, ...
    'IsotropicReference', 0, 'Aggregation', 'Equal weight per selected finite rod observation', ...
    'AlignmentDefinition', 'Order3D = (3*cos(theta)^2 - 1)/2; isotropic expectation 0', ...
    'Dispersion', 'Sample variance (n-1); Std describes rods, not uncertainty of the mean', ...
    'Figures', gobjects(0));

if o.MakeFigures
    report.Figures = localFigures(report, frames, o);
end
if strlength(string(o.OutputDirectory)) > 0
    localSave(report, o.OutputDirectory);
end
end

function [mu, variance, count] = localStats(values)
% Internal helper: empty means are missing; one observation has no sample variance.
count = numel(values);
mu = NaN;
variance = NaN;
if count > 0
    mu = mean(values);
end
if count > 1
    variance = var(values, 0);
end
end

function result = localPeak(centers, values, eligible, options)
% Internal helper: ties/flat profiles retain a candidate but no reported location.
result = struct('CandidateDistance', NaN, 'Distance', NaN, 'Value', NaN, ...
    'Flat', false, 'Tied', false, 'Broad', false, 'Sparse', false, 'AtRangeEdge', false);
eligible = eligible(:) & isfinite(values(:));
indices = find(eligible);
if isempty(indices)
    result.Sparse = true;
    return
end
[maximum, offset] = max(values(indices));
index = indices(offset);
result.CandidateDistance = centers(index);
result.Value = maximum;
result.Tied = nnz(abs(values(indices) - maximum) <= 1e-12) > 1;
result.Flat = max(values(indices)) - min(values(indices)) <= options.FlatTolerance;
nearMaximum = maximum - (1 - options.BroadPeakFraction) * max(abs(maximum), eps);
result.Broad = nnz(values(indices) >= nearMaximum) > 1;
result.AtRangeEdge = index == 1 || index == numel(centers);
if ~result.Flat && ~result.Tied
    result.Distance = centers(index);
end
end

function weights = localWeights(times)
% Internal helper: equal weights for equally spaced times; otherwise trapezoidal.
if isempty(times)
    weights = zeros(0, 1);
elseif numel(times) == 1
    weights = 1;
elseif max(abs(diff(times) - mean(diff(times)))) < 1e-10
    weights = ones(numel(times), 1) / numel(times);
else
    gaps = diff(times);
    weights = [gaps(1); gaps(1:end-1) + gaps(2:end); gaps(end)] / 2;
    weights = weights / sum(weights);
end
end

function figures = localFigures(r, frames, o)
% Internal helper: display existing tables; missing bins remain transparent.
figures = gobjects(3, 1);
timeLabel = sprintf('Elapsed time from frame %g (s)', o.TimeReferenceFrame);
figures(1) = figure('Name', 'Active Foam: alignment heatmap', 'Position', [100 100 1000 650]);
ax = axes(figures(1));
im = imagesc(ax, r.DistanceCenters, r.TimeSeconds, r.Mean.');
im.AlphaData = isfinite(r.Mean.');
ax.Color = [.88 .88 .88];
ax.YDir = 'normal';
clim(ax, [-.5 1]);
colormap(ax, parula);
cb = colorbar(ax);
cb.Label.String = 'Mean Order3D (isotropic reference = 0)';
hold(ax, 'on');
xline(ax, 0, 'w--', 'Defined boundary', 'LineWidth', 1.5, 'DisplayName', 'Boundary r = 0');
plot(ax, r.MovingPeak.Distance, r.TimeSeconds, 'ko-', 'MarkerFaceColor', 'w', 'DisplayName', 'Moving peak location');
broad = r.MovingPeak.Broad & isfinite(r.MovingPeak.Distance);
plot(ax, r.MovingPeak.Distance(broad), r.TimeSeconds(broad), 's', ...
    'Color', [1 .35 0], 'MarkerSize', 9, 'DisplayName', 'Broad peak');
if isfinite(r.FixedPeak.Distance)
    xline(ax, r.FixedPeak.Distance, 'm-', sprintf('Fixed r* = %.2f um', r.FixedPeak.Distance), ...
        'LineWidth', 1.5, 'DisplayName', 'Fixed representative r*');
end
xlabel(ax, 'Signed boundary distance (um; negative inside)');
ylabel(ax, timeLabel);
title(ax, {'Workflow 2 selected detections: rod-weighted mean alignment', ...
    'Gray = no data; flat/tied/sparse peak locations omitted; structural stages not assigned'});
legend(ax, 'Location', 'southoutside', 'Orientation', 'horizontal');

figures(2) = figure('Name', 'Active Foam: spatial profiles', 'Position', [100 100 1050 650]);
ax = axes(figures(2));
hold(ax, 'on');
selected = frames(ismember(frames, o.SelectedFrames));
colors = lines(max(1, numel(selected)));
for index = 1:numel(selected)
    column = find(frames == selected(index), 1);
    localBand(ax, r.DistanceCenters, r.Mean(:, column), sqrt(r.Variance(:, column)), colors(index, :));
    plot(ax, r.DistanceCenters, r.Mean(:, column), '-', 'Color', colors(index, :), 'LineWidth', 1.6, ...
        'DisplayName', sprintf('Frame %g, t = %g s', selected(index), r.TimeSeconds(column)));
    if isfinite(r.MovingPeak.Distance(column))
        plot(ax, r.MovingPeak.Distance(column), r.MovingPeak.Value(column), 'o', ...
            'Color', colors(index, :), 'MarkerFaceColor', colors(index, :), 'HandleVisibility', 'off');
    end
end
xline(ax, 0, 'k--', 'Defined boundary', 'HandleVisibility', 'off');
yline(ax, 0, 'k:', 'Isotropic mean', 'HandleVisibility', 'off');
if isfinite(r.FixedPeak.Distance)
    xline(ax, r.FixedPeak.Distance, 'm:', 'Fixed r*', 'HandleVisibility', 'off');
end
xlabel(ax, 'Signed boundary distance (um; negative inside)');
ylabel(ax, 'Mean Order3D');
title(ax, 'Spatial profiles: shading is rod standard deviation, not a confidence interval');
legend(ax, 'Location', 'best');
grid(ax, 'on');

figures(3) = figure('Name', 'Active Foam: fixed distance-band traces', 'Position', [100 100 1050 650]);
ax = axes(figures(3));
hold(ax, 'on');
names = unique(r.Bands.Band, 'stable');
colors = lines(numel(names));
for index = 1:numel(names)
    rows = r.Bands(r.Bands.Band == names(index), :);
    if ~any(isfinite(rows.Mean))
        continue
    end
    localBand(ax, rows.TimeSeconds, rows.Mean, rows.Std, colors(index, :));
    plot(ax, rows.TimeSeconds, rows.Mean, 'o-', 'Color', colors(index, :), 'LineWidth', 1.5, ...
        'DisplayName', sprintf('%s: [%.2f, %.2f) um', names(index), rows.LeftEdge(1), rows.RightEdge(1)));
end
yline(ax, 0, 'k:', 'Isotropic mean', 'HandleVisibility', 'off');
xlabel(ax, timeLabel);
ylabel(ax, 'Mean Order3D');
title(ax, 'Fixed bands: rod-weighted means; shading is rod standard deviation');
legend(ax, 'Location', 'best');
grid(ax, 'on');
end

function localBand(ax, x, mu, sd, color)
% Internal helper: do not draw dispersion across missing bins.
x = x(:);
mu = mu(:);
sd = sd(:);
valid = isfinite(x) & isfinite(mu) & isfinite(sd);
changes = diff([false; valid; false]);
starts = find(changes == 1);
stops = find(changes == -1) - 1;
for index = 1:numel(starts)
    rows = starts(index):stops(index);
    if numel(rows) < 2
        continue
    end
    fill(ax, [x(rows); flipud(x(rows))], [mu(rows) - sd(rows); flipud(mu(rows) + sd(rows))], ...
        color, 'FaceAlpha', .13, 'EdgeColor', 'none', 'HandleVisibility', 'off');
end
end

function localSave(report, destination)
% Internal helper: local new output directory only; source data cannot be targets.
repo = fileparts(fileparts(fileparts(mfilename('fullpath'))));
allowed = char(java.io.File(fullfile(repo, 'tests', 'data')).getCanonicalPath());
destination = char(java.io.File(char(string(destination))).getCanonicalPath());
if ~startsWith([destination filesep], [allowed filesep], 'IgnoreCase', true)
    error('memoworkflow:OutputLocation', 'Alignment outputs must be under package tests/data.');
end
if isfolder(destination) || isfile(destination)
    error('memoworkflow:Exists', 'Refusing to overwrite plot directory: %s', destination);
end
mkdir(destination);
analysis = rmfield(report, 'Figures');
farmWorkflowSaveNew(fullfile(destination, 'alignment-analysis.mat'), analysis);
writetable(report.Binned, fullfile(destination, 'distance-time-statistics.csv'));
writetable(report.MovingPeak, fullfile(destination, 'moving-peak-location-and-value.csv'));
writetable(report.Bands, fullfile(destination, 'fixed-distance-band-traces.csv'));
writetable(report.QualityCounts, fullfile(destination, 'observation-counts.csv'));
writetable(report.Observations, fullfile(destination, 'selected-workflow2-observations.csv'));
fixed = table(report.DistanceCenters(:), report.TimeAveragedProfile, ...
    'VariableNames', {'DistanceCenter', 'TimeAveragedMean'});
writetable(fixed, fullfile(destination, 'fixed-window-mean-profile.csv'));
names = {'mean-alignment-heatmap', 'selected-time-spatial-profiles', 'fixed-distance-band-time-traces'};
for index = 1:numel(report.Figures)
    exportgraphics(report.Figures(index), fullfile(destination, [names{index} '.png']), 'Resolution', 150);
    savefig(report.Figures(index), fullfile(destination, [names{index} '.fig']));
end
fprintf('Alignment tables and figures saved: %s\n', destination);
end
