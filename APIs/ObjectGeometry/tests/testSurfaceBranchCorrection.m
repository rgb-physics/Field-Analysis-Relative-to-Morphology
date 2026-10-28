function tests = testSurfaceBranchCorrection
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(root);
farmSetup;
end

function testExtentRemovesFlapAndKeepsRibbon(t)
[points, faces, mask] = ribbonFixture();
options = struct('Faces', faces, 'Method', 'extent', 'MaxExtent', 2.1, ...
    'MaxTotalLossFraction', 1);
[corrected, info] = farmCorrectSurfaceBranches(points, mask, options);
verifyEqual(t, height(info.Patches), 3);
verifyEqual(t, nnz(info.Patches.Removed), 1);
verifyEqual(t, nnz(info.Patches.Removed & info.Patches.Extent <= 2.1), 1);
verifyTrue(t, all(corrected(:, 3) == 5));
verifyTrue(t, all(info.InputKept(info.SeamPointIndices)));
verifyTrue(t, all(info.InputKept(points(:, 3) == 5)));
end

function testSupportProtectsUniquelyRepresentedVolume(t)
[points, faces, mask] = ribbonFixture();
[corrected, info] = farmCorrectSurfaceBranches(points, mask, ...
    struct('Faces', faces, 'Method', 'support', 'MaxUniqueSupportFraction', 0.2));
verifyEqual(t, corrected, points);
verifyEqual(t, info.Patches.UniqueSupportFraction, ones(3, 1));
verifyEqual(t, info.AppliedLostVoxels, 0);
end

function testSupportLossAgainstIndependentBallUnion(t)
[points, faces, mask] = ribbonFixture();
mask(2:12, 2:12, 2:10) = true;
options = struct('Faces', faces, 'Method', 'support', ...
    'MaxUniqueSupportFraction', 1, 'MaxTotalLossFraction', 1);
[corrected, info] = farmCorrectSurfaceBranches(points, mask, options);
before = bruteCoverage(points, mask);
after = bruteCoverage(corrected, mask);
verifyEqual(t, info.InitiallyCoveredVoxels, nnz(before));
verifyEqual(t, info.AppliedLostVoxels, nnz(before & ~after));
verifyEqual(t, nnz(info.Patches.Removed), 1);
verifyTrue(t, any(info.Patches.UniqueSupportFraction < 1));
end

function testPreviewProtectionAndLossBudget(t)
[points, faces, mask] = ribbonFixture();
options = struct('Faces', faces, 'Method', 'extent', 'MaxExtent', 2.1, ...
    'MaxTotalLossFraction', 1, 'Apply', false);
[preview, info] = farmCorrectSurfaceBranches(points, mask, options);
verifyEqual(t, preview, points);
verifyEqual(t, nnz(info.Patches.WouldRemove), 1);
verifyEqual(t, nnz(info.Patches.Removed), 0);
options.Apply = true;
options.MaxTotalLossFraction = 0;
[protected, ~] = farmCorrectSurfaceBranches(points, mask, options);
verifyEqual(t, protected, points);
options.MaxTotalLossFraction = 1;
options.ProtectedPointIndices = find(points(:, 3) == 7, 1);
[protected, info] = farmCorrectSurfaceBranches(points, mask, options);
verifyEqual(t, protected, points);
verifyEqual(t, nnz(info.Patches.Protected), 1);
end

function testCoordinatePermutationAndUnits(t)
[points, faces, mask] = ribbonFixture();
options = struct('Faces', faces, 'Method', 'extent', 'MaxExtent', 2.1, ...
    'MaxTotalLossFraction', 1);
[~, first] = farmCorrectSurfaceBranches(points, mask, options);
[~, rotated] = farmCorrectSurfaceBranches(points(:, [3 2 1]), permute(mask, [1 3 2]), options);
verifyEqual(t, first.Patches.Extent, rotated.Patches.Extent, 'AbsTol', 1e-12);
verifyEqual(t, first.InputKept, rotated.InputKept);
options.Spacing = [2 2 2];
options.Origin = [-3 4 7];
options.MaxExtent = 4.2;
physical = (points - 1) * 2 + options.Origin;
[~, scaled] = farmCorrectSurfaceBranches(physical, mask, options);
verifyEqual(t, scaled.Patches.Extent, 2 * first.Patches.Extent, 'AbsTol', 1e-12);
verifyEqual(t, scaled.Patches.Area, 4 * first.Patches.Area, 'AbsTol', 1e-12);
verifyEqual(t, first.InputKept, scaled.InputKept);
end

function testNoSeamDoesNotErodeSheet(t)
mask = false(9, 9, 9);
mask(3:7, 3:7, 5) = true;
points = farmMaskToPoints(mask);
[corrected, info] = farmCorrectSurfaceBranches(points, mask, struct('MaxExtent', 100));
verifyEqual(t, corrected, points);
verifyEmpty(t, info.SeamEdges);
verifyFalse(t, any(info.Patches.Candidate));
end

function testEmptyAndCurveOnlySupport(t)
mask = false(9, 9, 9);
mask(5, 3:7, 5) = true;
points = farmMaskToPoints(mask);
[corrected, info] = farmCorrectSurfaceBranches(points, mask);
verifyEqual(t, corrected, points);
verifyEqual(t, height(info.Patches), 0);
[empty, info] = farmCorrectSurfaceBranches(zeros(0, 3), mask);
verifySize(t, empty, [0 3]);
verifyEqual(t, info.InitiallyCoveredVoxels, 0);
end

function testReturnedFieldsHaveDictionaryEntries(t)
% Verify the actual result schema stays discoverable through MATLAB lookup.
[points, faces, mask] = ribbonFixture();
[~, info] = farmCorrectSurfaceBranches(points, mask, struct('Faces', faces, 'Apply', false));
entry = farmGlossary('Branch correction result');
verifyEqual(t, string(entry.Section), "Glossary");
names = setdiff(fieldnames(info), {'Options'});
names = [names; info.Patches.Properties.VariableNames.'];
for nameInd = 1:numel(names)
    entry = farmGlossary(names{nameInd}, 'Section', 'DataDictionary');
    verifyEqual(t, string(entry.Group), "Surface branch correction");
    verifyGreaterThan(t, strlength(string(entry.Definition)), 0);
end
end

function [points, faces, mask] = ribbonFixture()
% A horizontal ribbon with a two-voxel-deep third arm along an interior seam.
mask = false(15, 15, 15);
mask(3:9, 3:11, 5) = true;
mask(3:9, 7, 6:7) = true;
points = farmMaskToPoints(mask);
map = zeros(size(mask));
map(find(mask)) = 1:size(points, 1);
faces = zeros(0, 3);
for y = 3:8
    for x = 3:10
        ids = [map(y, x, 5), map(y, x + 1, 5), map(y + 1, x, 5), map(y + 1, x + 1, 5)];
        faces = [faces; ids([1 2 3]); ids([2 4 3])]; %#ok<AGROW>
    end
    for z = 5:6
        ids = [map(y, 7, z), map(y, 7, z + 1), map(y + 1, 7, z), map(y + 1, 7, z + 1)];
        faces = [faces; ids([1 2 3]); ids([2 4 3])]; %#ok<AGROW>
    end
end
end

function covered = bruteCoverage(points, mask)
padded = padarray(mask, [1 1 1], false, 'both');
radius = bwdist(~padded);
radius = radius(2:end - 1, 2:end - 1, 2:end - 1);
[y, x, z] = ndgrid(1:size(mask, 1), 1:size(mask, 2), 1:size(mask, 3));
covered = false(size(mask));
for pointInd = 1:size(points, 1)
    p = points(pointInd, :);
    r = double(radius(p(2), p(1), p(3)));
    covered = covered | (x - p(1)).^2 + (y - p(2)).^2 + (z - p(3)).^2 < r^2;
end
covered = covered & mask;
end
