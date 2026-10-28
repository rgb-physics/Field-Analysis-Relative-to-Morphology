% Analyze two XY sheets and display their center-facing and medial surfaces.
% Run sections in order. Requires MATLAB Image Processing Toolbox and FARM.
% Changing loading or segmentation requires rerunning all later sections.
% Changing display settings requires rerunning only the display section.
% Results remain in the workspace; no data or figures are saved automatically.

%% USER INPUT -- source files and scientific choices
dataRoot = 'O:\Session 63\Exp 4 - Sheets\Full Sheet Analysis'; % USER INPUT
frame = 35; % USER INPUT: acquisition frame, not a stored time index
threshold = 0.6; % USER INPUT: strict probability threshold
interpMethod = 'nearest'; % USER INPUT: mask resampling and geometry-plane selection
intSpacing = [1.1 1.1 1.5]; % USER INPUT: [dY dX dZ], um/voxel
probSpacing = [2.9333 2.9281 2.9634]; % USER INPUT: [dY dX dZ], um/voxel
isoVoxel = min(probSpacing); % OPTIONAL INPUT: isotropic geometry-grid voxel size, um
spacingUnit = 'um';
% OPTIONAL INPUT: common physical origin at the lower voxel edges, XYZ in um.
% This assumes aligned source orientations and no relative crop or translation.
edgeOrigin = [0 0 0];

% OPTIONAL INPUT: verify these Ilastik export assumptions for this dataset.
probChan = 2; % Assumed sheet probability channel; change if class order differs.
probAxes = 'CXYZ'; % Assumed MATLAB h5read axis order, not HDF5 viewer order.
datasetPath = '/exported_data';
probPattern = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';
intPattern = 't%03i_illBleachCorr16bit_560.tif';
probRoot = fullfile(dataRoot, '7 Ilastik Segmentation', '560 Scaled Down');
intRoot = fullfile(dataRoot, '6 Illumination Bleach Corrected 16bit');

% OPTIONAL INPUT: registration assumption. Both exports must cover the SAME
% physical field of view, with matching orientation and no relative crop/shift.
% Physical coordinates assume coincident lower voxel edges; spacing is not registration.
sameExtent = true;

%% Set up package paths
scriptRoot = fileparts(mfilename('fullpath'));
packageRoot = fileparts(scriptRoot);
addpath(packageRoot);

% Setup: make the FARM API functions available for this MATLAB session.
farmSetup;

%% Load the probability field and 560 intensity field
probFile = fullfile(probRoot, sprintf(probPattern, frame));
intFile = fullfile(intRoot, sprintf(intPattern, frame));
assert(isfile(probFile), 'Missing probability file: %s', probFile);
assert(isfile(intFile), 'Missing intensity file: %s', intFile);

% Loading: normalize the selected probability channel to YXZ array order.
probImage = farmReadH5(probFile, datasetPath, ...
    struct('SourceAxes', probAxes, 'Channels', probChan, ...
    'Spacing', probSpacing, 'SpacingUnit', spacingUnit));
probData = probImage.Data(:, :, :, 1, 1);
assert(size(probImage.Data, 5) == 1, 'Select a stored probability time explicitly.');
assert(all(isfinite(probData(:))) && all(probData(:) >= 0 & probData(:) <= 1), ...
    'Expected finite probabilities in [0, 1]. Check channel and export scaling.');

% Loading: read the intensity TIFF, preserving its source calibration metadata.
intImage = farmReadTiff(intFile, ...
    struct('Spacing', intSpacing, 'SpacingUnit', spacingUnit));
assert(size(intImage.Data, 4) == 1 && size(intImage.Data, 5) == 1, ...
    'Expected one channel and one stored time in the 560 TIFF.');
intData = intImage.Data(:, :, :, 1, 1);
gridSize = [size(intData, 1), size(intData, 2), size(intData, 3)];
assert(all(gridSize > 1), 'Expected a three-dimensional intensity stack.');
fprintf('Frame %d: probability YXZ %s; intensity YXZ %s.\n', ...
    frame, mat2str(size(probData)), mat2str(gridSize));

%% Segment and resample onto a calibrated isotropic geometry grid
% Segmentation: threshold the already selected sheet-probability channel.
[probMask, thresholdInfo] = farmThresholdProbabilityGroup(probData, 1, threshold);

assert(sameExtent, 'Register the fields before overlaying their geometries.');
intSize = gridSize;
probSize = [size(probData, 1), size(probData, 2), size(probData, 3)];
% Calibrations, rather than size ratios, define the physical registration.
probExtent = probSize .* probSpacing;
intExtent = intSize .* intSpacing;
extentDifference = abs(probExtent - intExtent);
fprintf('Physical extents YXZ (um): probability %s; intensity %s.\n', ...
    mat2str(probExtent, 7), mat2str(intExtent, 7));
if any(extentDifference > max(probSpacing, intSpacing))
    warning('sheetAnalysis:ExtentMismatch', ...
        'Physical extents differ by %s um (YXZ). Verify crop and origin.', ...
        mat2str(extentDifference));
end

% Native MATLAB resampling: world coordinates use XYZ; sizes/spacing use YXZ.
% Both references share the same lower physical edges. An identity world
% transform resamples voxel centers without stretching the source to fit sizes.
% Round down to keep every output voxel within the acquired physical extent;
% less than one isotropic voxel is trimmed at each upper edge, never padded.
interpMethod = validatestring(interpMethod, {'nearest'});
geomSpacing = repmat(isoVoxel, 1, 3);
gridSize = floor(probExtent ./ geomSpacing);
assert(all(gridSize > 1), 'Isotropic geometry grid must be three-dimensional.');
probRef = imref3d(probSize, ...
    edgeOrigin(1) + [0 probExtent(2)], ...
    edgeOrigin(2) + [0 probExtent(1)], ...
    edgeOrigin(3) + [0 probExtent(3)]);
geomExtent = gridSize .* geomSpacing;
geomRef = imref3d(gridSize, ...
    edgeOrigin(1) + [0 geomExtent(2)], ...
    edgeOrigin(2) + [0 geomExtent(1)], ...
    edgeOrigin(3) + [0 geomExtent(3)]);
sheetMask = imwarp(probMask, probRef, affine3d(eye(4)), interpMethod, ...
    'OutputView', geomRef);
sheetMask = logical(sheetMask);

%% Select the two largest connected sheet objects
% Native MATLAB: retain actual disconnected objects; do not split a joined
% object at the midplane or manufacture a second sheet if only one is found.
components = bwconncomp(sheetMask, 26);
assert(components.NumObjects >= 2, ...
    'Fewer than two objects at threshold 0.6. Inspect the class and mask.');
objSizes = cellfun(@numel, components.PixelIdxList);
[~, sizeOrder] = sort(objSizes, 'descend');
sheetInds = components.PixelIdxList(sizeOrder(1:2));
meanZ = zeros(2, 1);
for objInd = 1:2
    [~, ~, objZ] = ind2sub(gridSize, sheetInds{objInd});
    meanZ(objInd) = mean(objZ);
end
[~, zOrder] = sort(meanZ);
sheetInds = sheetInds(zOrder);
% Top means smaller array Z, as displayed with Z increasing downwards.
sheetNames = {'Top', 'Bottom'};
sheetLabels = zeros(gridSize, 'uint8');
for objInd = 1:2
    sheetLabels(sheetInds{objInd}) = objInd;
end
fprintf('Retained %d of %d foreground voxels in two objects (%d total objects).\n', ...
    nnz(sheetLabels), nnz(sheetMask), components.NumObjects);

%% Define the center background region
% Native MATLAB selection: reconstruct background connected to background
% seeds on the chamber Z midplane. No XY column is reduced to a single Z.
% A gap through a sheet can connect center and exterior; report that explicitly.
midZ = (gridSize(3) + 1) / 2;
midInd = round(midZ);
background = ~sheetMask;
centerSeed = false(gridSize);
centerSeed(:, :, midInd) = background(:, :, midInd);
assert(any(centerSeed(:)), 'No background seeds on the chamber Z midplane.');
centerMask = imreconstruct(centerSeed, background, 6);
if any(centerMask(:, :, 1), 'all') || any(centerMask(:, :, end), 'all')
    warning('sheetAnalysis:OpenCenter', ...
        ['Center background reaches a Z end face. A sheet gap or segmentation ' ...
         'error may connect center and exterior; inspect the boundary selection.']);
end
% Native MATLAB selection: one face-neighbor step identifies material touching
% center background. This selects a side of the FARM boundary, not a new surface.
centerContact = imdilate(centerMask, conndef(3, 'minimal')) & sheetMask;

%% Calculate three FARM geometries for each sheet
% OPTIONAL INPUT: boundary layer settings, in current-grid voxel units.
layerMean = 0;
layerWidth = 0.5; % Strict interval (-0.5, 0.5) selects the zero-distance layer.
boundarySigma = 0; % No signed-distance smoothing for a direct contact boundary.
preferredAxis = 'Z'; % Approximate thin axis for historical reslice skeletons.
comparisonMode = 'intersection'; % 'union' or 'intersection'; both are retained.
comparisonMode = validatestring(comparisonMode, {'union', 'intersection'});

% All three geometries share the explicitly resampled isotropic grid.
pointOrigin = edgeOrigin + geomSpacing([2 1 3]) / 2;
geom = struct([]);
for objInd = 1:2
    objMask = sheetLabels == objInd;
    fprintf('Calculating FARM geometries for %s sheet.\n', sheetNames{objInd});

    % Geometry 1: extract the volumetric medial surface using FARM thinning.
    [medialMask, medialInfo] = farmMedialSurface(objMask, 'Spacing', geomSpacing);
    assert(medialInfo.Converged, 'Medial-surface thinning did not converge.');

    % Geometry 2: extract the signed-distance boundary layer using FARM.
    boundaryMask = farmReturnSmoothBoundsBW(objMask, ...
        layerMean, layerWidth, boundarySigma);
    % Custom side selection: retain boundary voxels adjoining center background.
    boundaryMask = boundaryMask & centerContact;

    % Geometry 3: calculate the historical reslice union and intersection.
    [unionMask, intersectionMask] = farmSkel3Dfrom2D(objMask, preferredAxis);
    if strcmp(comparisonMode, 'union')
        comparisonMask = unionMask;
    else
        comparisonMask = intersectionMask;
    end

    % Point preparation: convert the FARM medial support to physical XYZ in um.
    [medialPoints, medialIndices, pointGrid] = farmMaskToPoints(medialMask, ...
        'Spacing', geomSpacing, 'Origin', pointOrigin);

    % Point preparation: convert the selected FARM boundary support to XYZ.
    [boundaryPoints, boundaryIndices] = farmMaskToPoints(boundaryMask, ...
        'Spacing', geomSpacing, 'Origin', pointOrigin);

    % Point preparation: convert the FARM comparison support to XYZ.
    [comparisonPoints, comparisonIndices] = farmMaskToPoints(comparisonMask, ...
        'Spacing', geomSpacing, 'Origin', pointOrigin);

    % Points are physical XYZ in um; indices refer to the resampled geometry grid.
    geom(objInd).Name = sheetNames{objInd};
    geom(objInd).MedialMask = medialMask;
    geom(objInd).MedialInfo = medialInfo;
    geom(objInd).MedialPoints = medialPoints;
    geom(objInd).MedialIndices = medialIndices;
    geom(objInd).BoundaryMask = boundaryMask;
    geom(objInd).BoundaryPoints = boundaryPoints;
    geom(objInd).BoundaryIndices = boundaryIndices;
    geom(objInd).UnionMask = unionMask;
    geom(objInd).IntersectionMask = intersectionMask;
    geom(objInd).ComparisonMode = comparisonMode;
    geom(objInd).ComparisonPoints = comparisonPoints;
    geom(objInd).ComparisonIndices = comparisonIndices;
    geom(objInd).PointGrid = pointGrid;
    geom(objInd).SpacingYXZ = geomSpacing;
    geom(objInd).SpacingUnit = intImage.SpacingUnit;
    geom(objInd).SourceSpacingYXZ = probSpacing;
    geom(objInd).SourceReference = probRef;
    geom(objInd).GeometryReference = geomRef;
    fprintf('%s: medial %d, center boundary %d, reslice %d points.\n', ...
        sheetNames{objInd}, size(medialPoints, 1), ...
        size(boundaryPoints, 1), size(comparisonPoints, 1));
end

%% Display all three point clouds in the middle-Y XZ section
% OPTIONAL INPUT: display only; all point clouds retain the full 3-D geometry.
yInd = round((intSize(1) + 1) / 2);
yPosition = edgeOrigin(2) + (yInd - 0.5) * intSpacing(1);
% Nearest geometry Y plane to the displayed intensity Y plane. Its full
% point cloud is retained; only plotting selects this plane (no interpolation).
interpMethod = validatestring(interpMethod, {'nearest'});
probYInd = round((yPosition - edgeOrigin(2)) / geomSpacing(1) + 0.5);
assert(probYInd >= 1 && probYInd <= gridSize(1), ...
    'Middle intensity Y plane lies outside the probability field.');
probYPosition = edgeOrigin(2) + (probYInd - 0.5) * geomSpacing(1);
xPositions = edgeOrigin(1) + ((1:intSize(2)) - 0.5) * intSpacing(2);
zPositions = edgeOrigin(3) + ((1:intSize(3)) - 0.5) * intSpacing(3);
markerSize = 10;
sheetColors = [0 0.85 1; 1 0.45 0.1];
geometryNames = {'Center-facing boundary', 'Medial surface', ...
    ['Reslice skeleton (' comparisonMode ')']};
pointFields = {'BoundaryPoints', 'MedialPoints', 'ComparisonPoints'};
xzIntensity = reshape(intData(yInd, :, :), intSize(2), intSize(3)).';
sheetFigures = gobjects(3, 1);
sheetAxes = gobjects(3, 1);
for geometryInd = 1:3
    sheetFigures(geometryInd) = figure('Name', ...
        sprintf('%s, frame %d', geometryNames{geometryInd}, frame));
    sheetAxes(geometryInd) = axes(sheetFigures(geometryInd));
    ax = sheetAxes(geometryInd);
    imagesc(ax, xPositions, zPositions, xzIntensity);
    colormap(ax, gray(256));
    hold(ax, 'on');
    plotHandles = gobjects(2, 1);
    for objInd = 1:2
        points = geom(objInd).(pointFields{geometryInd});
        % Select every point in this Y plane, including repeated X at different Z.
        slicePoints = points(abs(points(:, 2) - probYPosition) < geomSpacing(1) / 2, :);
        plotHandles(objInd) = scatter(ax, slicePoints(:, 1), ...
            slicePoints(:, 3), markerSize, sheetColors(objInd, :), 'filled');
    end
    yline(ax, edgeOrigin(3) + geomExtent(3) / 2, ...
        'w:', 'HandleVisibility', 'off');
    set(ax, 'YDir', 'reverse');
    axis(ax, 'image');
    % Keep the field of view fixed to the original intensity voxel edges.
    xlim(ax, edgeOrigin(1) + [0 intExtent(2)]);
    ylim(ax, edgeOrigin(3) + [0 intExtent(3)]);
    xlabel(ax, 'X (um)');
    ylabel(ax, 'Z (um)');
    title(ax, {geometryNames{geometryInd}, ...
        sprintf('Frame %d: intensity Y = %.2f um; geometry Y = %.2f um', ...
        frame, yPosition, probYPosition)});
    legend(ax, plotHandles, sheetNames, 'Location', 'best');
    colorbar(ax);
    hold(ax, 'off');
end
linkaxes(sheetAxes, 'xy');

%% Display selected full point clouds in 3D without an intensity image
% Run this section after calculating geom. Each scatter call is independent:
% comment out any call to hide that sheet/geometry combination. These are all
% points in each cloud, with no middle-Y selection or display subsampling.
% OPTIONAL INPUT: display settings only.
pointSize3D = 15;
topColor3D = [0 0.65 0.9];
bottomColor3D = [0.95 0.35 0.1];

pointFigure3D = figure('Name', sprintf('Full sheet point clouds, frame %d', frame));
pointAxes3D = axes(pointFigure3D);
hold(pointAxes3D, 'on');

% Top sheet: center-facing boundary, medial surface, and reslice comparison.
% scatter3(pointAxes3D, geom(1).BoundaryPoints(:, 1), geom(1).BoundaryPoints(:, 2), geom(1).BoundaryPoints(:, 3), pointSize3D, topColor3D, '.', 'DisplayName', 'Top boundary');
% scatter3(pointAxes3D, geom(1).MedialPoints(:, 1), geom(1).MedialPoints(:, 2), geom(1).MedialPoints(:, 3), pointSize3D, topColor3D, 'o', 'DisplayName', 'Top medial');
% scatter3(pointAxes3D, geom(1).ComparisonPoints(:, 1), geom(1).ComparisonPoints(:, 2), geom(1).ComparisonPoints(:, 3), pointSize3D, topColor3D, '+', 'DisplayName', ['Top reslice (' geom(1).ComparisonMode ')']);

% Bottom sheet: center-facing boundary, medial surface, and reslice comparison.
% scatter3(pointAxes3D, geom(2).BoundaryPoints(:, 1), geom(2).BoundaryPoints(:, 2), geom(2).BoundaryPoints(:, 3), pointSize3D, bottomColor3D, '.', 'DisplayName', 'Bottom boundary');
% scatter3(pointAxes3D, geom(2).MedialPoints(:, 1), geom(2).MedialPoints(:, 2), geom(2).MedialPoints(:, 3), pointSize3D, bottomColor3D*.8, 'o', 'DisplayName', 'Bottom medial');
scatter3(pointAxes3D, geom(2).ComparisonPoints(:, 1), geom(2).ComparisonPoints(:, 2), geom(2).ComparisonPoints(:, 3), pointSize3D, bottomColor3D*.5, '+', 'DisplayName', ['Bottom reslice (' geom(2).ComparisonMode ')']);

xlim([100 400])
ylim([100 400])
axis(pointAxes3D, 'equal');
grid(pointAxes3D, 'on');
view(pointAxes3D, 3);
set(pointAxes3D, 'ZDir', 'reverse');
xlabel(pointAxes3D, 'X (um)');
ylabel(pointAxes3D, 'Y (um)');
zlabel(pointAxes3D, 'Z (um)');
title(pointAxes3D, sprintf('Full point clouds, frame %d', frame));
legend(pointAxes3D, 'show', 'Location', 'bestoutside');
rotate3d(pointFigure3D, 'on');
hold(pointAxes3D, 'off');

%% Correct branching flaps by patch extent and/or source-volume support
% Run this section directly after calculating geom and sheetLabels. It does
% not depend on the ET/SAT sections below. Original geom remains unchanged.
% USER INPUT: choose the object, cloud, and correction criterion.
branchObj = 2;
branchField = 'MedialPoints'; % 'MedialPoints', 'BoundaryPoints', 'ComparisonPoints'
branchMethod = 'both'; % 'extent', 'support', or 'both'
applyBranchCut = true; % false: preview proposed cuts without removing points

% OPTIONAL INPUT: initial test settings, in um or dimensionless fractions.
branchMaxExtent = 12; % Maximum surface-edge geodesic from seam to free border
branchMaxUniqueSupport = 0.05; % Maximum newly uncovered / patch-covered voxels
branchMaxTotalLoss = 0.01; % Maximum NEW coverage loss / all source-object voxels
branchFaces = []; % Optional reviewed M-by-3 point-row connectivity
branchProtectedRows = []; % Optional protected row indices in branchInput
branchField = validatestring(branchField, ...
    {'MedialPoints', 'BoundaryPoints', 'ComparisonPoints'});
validateattributes(branchObj, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', numel(geom)});
branchInput = geom(branchObj).(branchField);
branchMask = sheetLabels == branchObj;
branchOptions = struct('Method', branchMethod, ...
    'Spacing', geom(branchObj).PointGrid.Spacing, ...
    'Origin', geom(branchObj).PointGrid.Origin, ...
    'MaxExtent', branchMaxExtent, 'MaxUniqueSupportFraction', branchMaxUniqueSupport, ...
    'MaxTotalLossFraction', branchMaxTotalLoss, 'Faces', branchFaces, ...
    'ProtectedPointIndices', branchProtectedRows, 'Apply', applyBranchCut, 'Verbose', true);

% Correction: split at branch seams, measure patch extent and source support,
% then select whole-patch cuts while retaining at least two branches per seam.
[branchPoints, branchInfo] = farmCorrectSurfaceBranches(branchInput, branchMask, branchOptions);

branchPatches = branchInfo.Patches;
disp(branchPatches);
fprintf('Branch correction: %d seams edges, %d patches, %d proposed cuts, %d applied cuts.\n', ...
    size(branchInfo.SeamEdges, 1), height(branchPatches), ...
    nnz(branchPatches.WouldRemove), nnz(branchPatches.Removed));
fprintf('Initial source coverage %.2f%%; proposed NEW source loss %.3f%%.\n', ...
    100 * branchInfo.InitialCoverageFraction, 100 * branchInfo.ProposedLossFraction);
fprintf('Points: %d original, %d corrected. No global topology guarantee.\n', ...
    size(branchInput, 1), size(branchPoints, 1));

%% Inspect branch patches, proposed cuts, and corrected geometry in 3-D
% Run after the branch-correction section. Each figure is independent; each
% scatter line can be commented out. Black points mark detected branch seams.
branchMarkerSize = 8;
branchSeams = branchInput(branchInfo.SeamPointIndices, :);
proposedRows = ismember(branchInfo.PointPatch, ...
    branchPatches.PatchID(branchPatches.WouldRemove));
branchProposed = branchInput(proposedRows, :);

patchFigure = figure('Name', 'Branch patches and attachment seams');
patchAxes = axes(patchFigure);
hold(patchAxes, 'on');
scatter3(patchAxes, branchInput(:, 1), branchInput(:, 2), branchInput(:, 3), branchMarkerSize, branchInfo.PointPatch, '.', 'DisplayName', 'Patch ID');
scatter3(patchAxes, branchSeams(:, 1), branchSeams(:, 2), branchSeams(:, 3), 15, 'k', '.', 'DisplayName', 'Seams');
colormap(patchAxes, lines(max(1, height(branchPatches))));
colorbar(patchAxes);
title(patchAxes, 'Candidate patches (colors) and branch seams (black)');

cutFigure = figure('Name', 'Proposed branch cuts');
cutAxes = axes(cutFigure);
hold(cutAxes, 'on');
scatter3(cutAxes, branchInput(:, 1), branchInput(:, 2), branchInput(:, 3), 5, [0.7 0.7 0.7], '.', 'DisplayName', 'Original');
scatter3(cutAxes, branchProposed(:, 1), branchProposed(:, 2), branchProposed(:, 3), 15, [0.9 0.2 0.05], '.', 'DisplayName', 'Proposed removal');
scatter3(cutAxes, branchSeams(:, 1), branchSeams(:, 2), branchSeams(:, 3), 10, 'k', '.', 'DisplayName', 'Retained seams');
title(cutAxes, sprintf('Proposed cuts: %s criterion', branchMethod));

correctedFigure = figure('Name', 'Branch-corrected sheet');
correctedAxes = axes(correctedFigure);
hold(correctedAxes, 'on');
scatter3(correctedAxes, branchPoints(:, 1), branchPoints(:, 2), branchPoints(:, 3), branchMarkerSize, [0 0.5 0.85], '.', 'DisplayName', 'Returned geometry');
title(correctedAxes, sprintf('Branch correction applied = %d', applyBranchCut));

branchAxes = [patchAxes, cutAxes, correctedAxes];
for axesInd = 1:numel(branchAxes)
    ax = branchAxes(axesInd);
    axis(ax, 'equal');
    grid(ax, 'on');
    view(ax, 3);
    set(ax, 'ZDir', 'reverse');
    xlabel(ax, 'X (um)');
    ylabel(ax, 'Y (um)');
    zlabel(ax, 'Z (um)');
    legend(ax, 'show', 'Location', 'bestoutside');
    hold(ax, 'off');
end
branchViewLink = linkprop(branchAxes, {'XLim', 'YLim', 'ZLim', 'View'});

%% Prune a selected full point cloud with ET, SAT, or both
% Run after geometry calculation. Original geom and its point clouds remain
% available for comparison. These experimental algorithms use the full 3-D
% support, not the Y section displayed above. See farmPruneSurface help for
% the discrete approximations and lack of a topology-preservation guarantee.
% USER INPUT: choose sheet and cloud. ET needs a triangulatable surface;
% sparse reslice intersections may require an explicit reviewed Faces array.
pruneObj = 2; % 1 = top sheet; 2 = bottom sheet
pruneField = 'MedialPoints'; % 'MedialPoints', 'BoundaryPoints', 'ComparisonPoints'
pruneMethods = {'ET', 'SAT'}; % Use {'ET'} or {'SAT'} to run only one method.

% OPTIONAL INPUT: experimental pruning strengths, not calibrated parameters.
etThreshold = 3; % um: retain original points with ET >= this value
etSubdivisions = 0; % Triangle refinements; increases ET graph size and cost
etFaces = []; % M-by-3 indices into selectedPoints; [] tries lattice connectivity
satScale = 1.8; % Dimensionless ball growth; 1 preserves the original cloud
pruneMaxVoxels = 5e7; % SAT padded-raster size limit; several arrays are allocated

pruneField = validatestring(pruneField, ...
    {'MedialPoints', 'BoundaryPoints', 'ComparisonPoints'});
validateattributes(pruneObj, {'numeric'}, {'scalar', 'integer', '>=', 1, '<=', numel(geom)});
selectedPoints = geom(pruneObj).(pruneField);
pruneSourceMask = sheetLabels == pruneObj;
pruning = struct([]);
for methodInd = 1:numel(pruneMethods)
    pruneMethod = validatestring(pruneMethods{methodInd}, {'ET', 'SAT'});
    pruneOptions = struct('Method', pruneMethod, ...
        'Spacing', geom(pruneObj).PointGrid.Spacing, ...
        'Origin', geom(pruneObj).PointGrid.Origin, 'MaxVoxels', pruneMaxVoxels);
    if strcmp(pruneMethod, 'ET')
        pruneOptions.ETThreshold = etThreshold;
        pruneOptions.ETSubdivisions = etSubdivisions;
        pruneOptions.Faces = etFaces;
    else
        pruneOptions.Scale = satScale;
    end

    % Pruning: calculate ET filtering or rasterized SAT from the selected support.
    [prunedPoints, pruneInfo] = farmPruneSurface(selectedPoints, pruneSourceMask, pruneOptions);

    pruning(methodInd).Method = pruneMethod;
    pruning(methodInd).ObjectID = pruneObj;
    pruning(methodInd).SourceField = pruneField;
    pruning(methodInd).Points = prunedPoints;
    pruning(methodInd).Info = pruneInfo;
    fprintf('%s, %s %s: %d input points -> %d output points.\n', ...
        pruneMethod, geom(pruneObj).Name, pruneField, ...
        size(selectedPoints, 1), size(prunedPoints, 1));
    % SAT recomputes centers: its output can move and need not be a subset.
    fprintf('%s\n', pruneInfo.Approximation);
end

%% Compare the pruning results in separate 3-D figures
% Each scatter call is independent; comment out the original or pruned call
% to display just one. SAT and ET point counts have different interpretations.
pruneFigures = gobjects(numel(pruning), 1);
for methodInd = 1:numel(pruning)
    prunedPoints = pruning(methodInd).Points;
    pruneFigures(methodInd) = figure('Name', [pruning(methodInd).Method ' pruning']);
    pruneAxes = axes(pruneFigures(methodInd));
    hold(pruneAxes, 'on');
    scatter3(pruneAxes, selectedPoints(:, 1), selectedPoints(:, 2), selectedPoints(:, 3), 10, [0.7 0.7 0.7], '.', 'DisplayName', 'Original');
    scatter3(pruneAxes, prunedPoints(:, 1), prunedPoints(:, 2), prunedPoints(:, 3), 30, [0.1 0.5 0.9], '.', 'DisplayName', pruning(methodInd).Method);
    axis(pruneAxes, 'equal');
    grid(pruneAxes, 'on');
    view(pruneAxes, 3);
    set(pruneAxes, 'ZDir', 'reverse');
    xlabel(pruneAxes, 'X (um)');
    ylabel(pruneAxes, 'Y (um)');
    zlabel(pruneAxes, 'Z (um)');
    title(pruneAxes, sprintf('%s: %s %s', ...
        pruning(methodInd).Method, geom(pruneObj).Name, pruneField));
    legend(pruneAxes, 'show', 'Location', 'bestoutside');
    rotate3d(pruneFigures(methodInd), 'on');
    hold(pruneAxes, 'off');
xlim([100 400])
ylim([100 400])
end
