% Benchmark the four requested SAT scales on frame 35's bottom medial cloud.
% Mirrors analyzeSheetFrame35 calibration, threshold, and object selection.
% Records single-pass wall times, excluding file loading and input geometry.
% Results and comparison figures are written to a temporary output folder.

%% USER INPUT -- dataset and benchmark choices
dataRoot = 'O:\Session 63\Exp 4 - Sheets\Full Sheet Analysis';
frame = 35;
probChan = 2;
threshold = 0.6;
probSpacing = [2.9333 2.9281 2.9634]; % YXZ, um/voxel
scales = [1.1 1.2 1.5 2];
selectedSheet = 2; % Bottom sheet, matching analyzeSheetFrame35 pruning defaults.
outputRoot = fullfile(tempdir, 'farm-sheet-sat-frame35');

%% Setup and calibrated probability loading
packageRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(packageRoot);

% Setup: make FARM operations available.
farmSetup;

probFile = fullfile(dataRoot, '7 Ilastik Segmentation', '560 Scaled Down', ...
    sprintf('t%03i_illCorr8bit_560_Probabilities Stage 2.h5', frame));

% Loading: use the same source channel and calibration as the analysis script.
probImage = farmReadH5(probFile, '/exported_data', ...
    struct('SourceAxes', 'CXYZ', 'Channels', probChan, ...
    'Spacing', probSpacing, 'SpacingUnit', 'um'));

% Segmentation: threshold the selected probability channel.
[mask, ~] = farmThresholdProbabilityGroup(probImage.Data(:, :, :, 1, 1), 1, threshold);

%% Prepare the same isotropic grid and bottom-sheet medial support
sourceSize = size(mask);
extent = sourceSize .* probSpacing;
spacing = repmat(min(probSpacing), 1, 3);
workSize = floor(extent ./ spacing);
sourceRef = imref3d(sourceSize, [0 extent(2)], [0 extent(1)], [0 extent(3)]);
workExtent = workSize .* spacing;
workRef = imref3d(workSize, [0 workExtent(2)], [0 workExtent(1)], [0 workExtent(3)]);
mask = imwarp(mask, sourceRef, affine3d(eye(4)), 'nearest', 'OutputView', workRef);
components = bwconncomp(mask, 26);
assert(components.NumObjects >= 2, 'Expected at least two sheet objects.');
[~, order] = sort(cellfun(@numel, components.PixelIdxList), 'descend');
sheetIndices = components.PixelIdxList(order(1:2));
meanZ = zeros(2, 1);
for objInd = 1:2
    [~, ~, z] = ind2sub(workSize, sheetIndices{objInd});
    meanZ(objInd) = mean(z);
end
[~, order] = sort(meanZ);
objectMask = false(workSize);
objectMask(sheetIndices{order(selectedSheet)}) = true;
fprintf('Input object: grid %s, %d foreground voxels.\n', mat2str(workSize), nnz(objectMask));
inputTimer = tic;

% Geometry: compute the selected object's native FARM medial surface.
[surface, surfaceInfo] = farmMedialSurface(objectMask, 'Spacing', spacing);
assert(surfaceInfo.Converged, 'Input geometry did not converge.');

% Point preparation: physical XYZ, with the lower voxel edges at zero.
[inputPoints, ~, pointGrid] = farmMaskToPoints(surface, ...
    'Spacing', spacing, 'Origin', spacing([2 1 3]) / 2);
inputGeometrySeconds = toc(inputTimer);
fprintf('Input medial support: %d points, %.3f seconds.\n', size(inputPoints, 1), inputGeometrySeconds);

%% Run each requested SAT scale once and checkpoint results
if ~isfolder(outputRoot)
    mkdir(outputRoot);
end
results = table(scales(:), nan(4, 1), nan(4, 1), nan(4, 1), nan(4, 1), ...
    nan(4, 1), nan(4, 1), nan(4, 1), nan(4, 1), ...
    'VariableNames', {'Scale', 'TotalSeconds', 'SourceRadiusSeconds', ...
    'GrowthSeconds', 'ThinningSeconds', 'OutputPreparationSeconds', ...
    'GrownVoxels', 'OutputPoints', 'ThinningIterations'});
clouds = cell(4, 1);
details = cell(4, 1);
for scaleInd = 1:numel(scales)
    options = struct('Method', 'SAT', 'Scale', scales(scaleInd), ...
        'Spacing', spacing, 'Origin', pointGrid.Origin);
    fprintf('Starting SAT scale %.2f at %s.\n', scales(scaleInd), char(datetime('now')));
    started = tic;

    % Pruning: raster SAT, including growth, medial recomputation and radius shrink.
    [clouds{scaleInd}, details{scaleInd}] = farmPruneSurface(inputPoints, objectMask, options);

    results.TotalSeconds(scaleInd) = toc(started);
    info = details{scaleInd};
    results.SourceRadiusSeconds(scaleInd) = info.SourceRadiusSeconds;
    results.GrowthSeconds(scaleInd) = info.GrowthSeconds;
    results.ThinningSeconds(scaleInd) = info.ThinningSeconds;
    results.OutputPreparationSeconds(scaleInd) = info.OutputPreparationSeconds;
    results.GrownVoxels(scaleInd) = info.GrownVoxelCount;
    results.OutputPoints(scaleInd) = size(clouds{scaleInd}, 1);
    results.ThinningIterations(scaleInd) = info.ThinningInfo.Iterations;
    writetable(results, fullfile(outputRoot, 'sat-timings.csv'));
    save(fullfile(outputRoot, 'sat-benchmark.mat'), 'results', 'clouds', ...
        'details', 'inputPoints', 'pointGrid', 'inputGeometrySeconds', '-v7.3');
    disp(results(scaleInd, :));
end

%% Export separate 3-D comparisons using identical views and limits
allPoints = vertcat(inputPoints, clouds{:});
low = min(allPoints, [], 1);
high = max(allPoints, [], 1);
for scaleInd = 1:numel(scales)
    points = clouds{scaleInd};
    comparisonFigure = figure('Visible', 'off', 'Position', [100 100 1000 800]);
    comparisonAxes = axes(comparisonFigure);
    hold(comparisonAxes, 'on');
    scatter3(comparisonAxes, inputPoints(:, 1), inputPoints(:, 2), inputPoints(:, 3), 2, [0.75 0.75 0.75], '.', 'DisplayName', 'Input');
    scatter3(comparisonAxes, points(:, 1), points(:, 2), points(:, 3), 3, [0 0.4 0.9], '.', 'DisplayName', 'SAT');
    axis(comparisonAxes, 'equal');
    xlim(comparisonAxes, [low(1) high(1)]);
    ylim(comparisonAxes, [low(2) high(2)]);
    zlim(comparisonAxes, [low(3) high(3)]);
    view(comparisonAxes, [35 25]);
    set(comparisonAxes, 'ZDir', 'reverse');
    grid(comparisonAxes, 'on');
    xlabel(comparisonAxes, 'X (um)');
    ylabel(comparisonAxes, 'Y (um)');
    zlabel(comparisonAxes, 'Z (um)');
    title(comparisonAxes, sprintf('SAT scale %.1f: %.2f s, %d output points', ...
        scales(scaleInd), results.TotalSeconds(scaleInd), size(points, 1)));
    legend(comparisonAxes, 'show');
    exportgraphics(comparisonFigure, fullfile(outputRoot, ...
        sprintf('sat-scale-%.1f.png', scales(scaleInd))));
    close(comparisonFigure);
end
disp(results);
fprintf('Benchmark outputs: %s\n', outputRoot);
