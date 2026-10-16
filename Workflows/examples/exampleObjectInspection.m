%% SETUP -- run from the FARM repository root after farmSetup
% Run the sections in order. Results remain in the workspace for inspection.
% This synthetic example needs Image Processing Toolbox, but no image files.
% Changing an earlier section requires rerunning the dependent sections.
% No files are saved or overwritten by this example.

farmSetup('IncludeExamples', true);

objOpts = farmMakeObjectOptions( ...
    'DatasetID', 'synthetic-sphere', ...
    'Frame', 1, ...
    'Spacing', [1 1 1], ...
    'SpacingUnit', 'voxel');

geomOpts = struct('Sigma', 0, 'LayerMean', 0, 'LayerWidth', 1);
profOpts = struct('Edges', -12:2:20, 'Statistics', {{'Mean', 'Std'}});
show3D = true;
maxPoints = 1000;


%% DATA -- replace this section with an image loader for your own data
% Array dimensions are YXZ; coordinate names identify X, Y and Z explicitly.
% The field is constructed from distance so the resulting means are checkable.

[y, x, z] = ndgrid(1:32, 1:32, 1:32);
mask = (x - 16).^2 + (y - 16).^2 + (z - 16).^2 <= 8^2;
distance = farmSignedBWDist(mask);
intensity = 100 + 2 * double(distance);

% STOP: inspect mask, distance and intensity before defining geometry.
% Distances here are in voxel units on an isotropic grid.


%% OBJECTS AND GEOMETRY -- retain each result for independent inspection
objects = farmPrepareObjects(mask, objOpts);
properties = farmMeasureObjects(objects, {'Volume', 'Centroid'});
boundary = farmGenerateGeometry(objects, 'boundary', geomOpts);
boundMask = farmGeometryToMatrix(boundary);

% STOP: inspect properties and boundary.Records before querying fields.
% Changing query settings below does not require rebuilding the geometry.


%% QUERIES -- request quantities and retain the returned tables
fields = struct('Intensity', intensity);
supports = struct('boundary', boundary);

query = farmMakeQuery( ...
    'Name', 'BoundaryIntensity', ...
    'Support', 'boundary', ...
    'Field', 'Intensity', ...
    'Statistics', {'Mean', 'Std'});

results = farmQueryFrame(fields, supports, query);
profile = farmConditionalStatistics(intensity, distance, profOpts);

% STOP: access results.BoundaryIntensity_Mean or profile.Statistics.Mean.
% profile pools voxels by distance; it does not average per-object summaries.
% This single-object example makes no tracking or ancestry choices.


%% DISPLAY -- uses existing results; does not recalculate measurements
zInd = 16;
figure('Name', 'Object boundary and intensity profile');

subplot(1, 2, 1);
imagesc(intensity(:, :, zInd));
axis image;
hold on;
contour(double(boundMask(:, :, zInd)), [0.5 0.5], 'w');
hold off;
title('Intensity and boundary selection');
xlabel('X (voxel)');
ylabel('Y (voxel)');

subplot(1, 2, 2);
bins = profile.Statistics;
centers = (bins.LeftEdge + bins.RightEdge) / 2;
plot(centers, bins.Mean, 'o-');
xlabel('Signed distance (voxel)');
ylabel('Mean intensity');
title('Intensity by distance interval');

if show3D
    % Subsample display locations only; measurements use the full selections.
    indices = find(boundMask);
    stride = max(1, ceil(numel(indices) / maxPoints));
    indices = indices(1:stride:end);
    [viewY, viewX, viewZ] = ind2sub(size(mask), indices);

    figure('Name', 'Subsampled boundary intensity');
    scatter3(viewX, viewY, viewZ, 12, intensity(indices), 'filled');
    axis equal;
    colorbar;
    xlabel('X (voxel)');
    ylabel('Y (voxel)');
    zlabel('Z (voxel)');
end

% STOPPING LIMITATIONS:
% These sections inspect one frame held in memory. They do not save a restart
% file or detect stale results after upstream edits. Rerun affected sections.
% farmRunFieldBatch saves completed frames, but cannot resume inside a running
% Loader or query. Stateful/random loaders may not reproduce an earlier frame.
