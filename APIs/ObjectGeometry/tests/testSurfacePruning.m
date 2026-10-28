function tests = testSurfacePruning
% Known-answer discrete geometry checks; no real-data scientific validation.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(root);
farmSetup;
end

function testETFlatSheet(t)
mask = false(9, 9, 9);
mask(3:7, 3:7, 5) = true;
points = farmMaskToPoints(mask);
[kept, info] = farmPruneSurface(points, mask, struct('Method', 'ET', 'ETThreshold', 1));
verifyEqual(t, size(kept, 1), 9);
center = all(points == [5 5 5], 2);
verifyEqual(t, info.ErosionThickness(center), 2, 'AbsTol', 1e-12);
edge = points(:, 1) == 3 | points(:, 1) == 7 | points(:, 2) == 3 | points(:, 2) == 7;
verifyEqual(t, info.ErosionThickness(edge), zeros(nnz(edge), 1));
verifyFalse(t, info.TopologyPreserved);
[identity, ~] = farmPruneSurface(points, mask, struct('Method', 'ET'));
verifyEqual(t, identity, points);
end

function testETNonmanifoldJunctionNeedsSecondSector(t)
% Three half-sheets meet along A--center--B. The three sectors reach center
% at times 2, 4 and 6. Burning must wait for the SECOND sector, not the first.
points = [0 0 0; 0 0 -10; 0 0 10; 1 0 0; 0 3 0; -5 0 0] + 12;
faces = [1 2 4; 1 4 3; 1 2 5; 1 5 3; 1 2 6; 1 6 3];
mask = false(25, 25, 25);
indices = sub2ind(size(mask), points(:, 2), points(:, 1), points(:, 3));
mask(indices) = true;
[~, info] = farmPruneSurface(points, mask, struct('Method', 'ET', 'Faces', faces));
verifyEqual(t, info.BurnTime(1), 4, 'AbsTol', 1e-12);
verifyEqual(t, info.ErosionThickness(1), 3, 'AbsTol', 1e-12);
end

function testETPhysicalUnitsAndSubdivision(t)
mask = false(9, 9, 9);
mask(3:7, 3:7, 5) = true;
points = farmMaskToPoints(mask, 'Spacing', [2 2 2], 'Origin', [-4 7 2]);
[~, info] = farmPruneSurface(points, mask, struct('Method', 'ET', ...
    'Spacing', [2 2 2], 'Origin', [-4 7 2], 'ETSubdivisions', 1));
verifyGreaterThan(t, info.SamplePointCount, size(points, 1));
verifyEqual(t, max(info.ErosionThickness), 4, 'AbsTol', 1e-12);
end

function testETClosedCore(t)
points = [3 3 3; 4 3 3; 3 4 3; 3 3 4];
faces = [1 2 3; 1 2 4; 1 3 4; 2 3 4];
mask = false(7, 7, 7);
mask(sub2ind(size(mask), points(:, 2), points(:, 1), points(:, 3))) = true;
[kept, info] = farmPruneSurface(points, mask, struct('Method', 'ET', ...
    'Faces', faces, 'ETThreshold', 100));
verifyTrue(t, all(isinf(info.ErosionThickness)));
verifyEqual(t, kept, points);
end

function testETAutomaticTetrahedronCollapse(t)
% A locally thick voxel support must not become an artificial closed ET shell.
points = [3 3 3; 4 3 3; 4 4 3; 4 4 4];
mask = false(7, 7, 7);
mask(sub2ind(size(mask), points(:, 2), points(:, 1), points(:, 3))) = true;
[kept, info] = farmPruneSurface(points, mask);
verifyEqual(t, info.MeshPreparation.InputTetrahedronCount, 1);
verifyEqual(t, info.MeshPreparation.CollapsedTetrahedronCount, 1);
verifyEqual(t, size(info.InputFaces, 1), 3);
verifyTrue(t, all(isfinite(info.ErosionThickness)));
verifyEqual(t, kept, points);
end

function testETLocallyThickSheetAndSeparateFolds(t)
mask = false(11, 11, 11);
mask(3:9, 3:9, 4:5) = true;
mask(3:9, 3:9, 8) = true;
points = farmMaskToPoints(mask);
[kept, info] = farmPruneSurface(points, mask);
verifyGreaterThan(t, info.MeshPreparation.InputTetrahedronCount, 0);
verifyEqual(t, info.MeshPreparation.CollapsedTetrahedronCount, ...
    info.MeshPreparation.InputTetrahedronCount);
verifyEqual(t, kept, points);
verifyTrue(t, all(isfinite(info.ErosionThickness)));
% The conversion cannot bridge the gap from the thick sheet to the other fold.
faceZ = reshape(points(info.InputFaces(:), 3), size(info.InputFaces));
verifyFalse(t, any(min(faceZ, [], 2) <= 5 & max(faceZ, [], 2) >= 8));
end

function testETLowerDimensionalPoints(t)
mask = false(9, 9, 9);
mask(5, 3:7, 5) = true;
points = farmMaskToPoints(mask);
[kept, info] = farmPruneSurface(points, mask, struct('ETThreshold', 0.1));
verifyEmpty(t, kept);
verifyEqual(t, info.ErosionThickness, zeros(5, 1));
verifyEqual(t, info.MeshPreparation.LowerDimensionalPointCount, 5);
end

function testETFoldedSheetAndCoordinatePermutation(t)
% Extrude a U-shaped XZ path in Y. Several XY columns contain two Z values.
path = [3 3; 4 3; 5 3; 5 4; 5 5; 4 5; 3 5];
points = zeros(35, 3);
faces = zeros(0, 3);
for yInd = 1:5
    rows = (yInd - 1) * 7 + (1:7);
    points(rows, :) = [path(:, 1), repmat(yInd + 2, 7, 1), path(:, 2)];
    if yInd < 5
        for pathInd = 1:6
            a = rows(pathInd);
            faces = [faces; a, a + 1, a + 7; a + 1, a + 8, a + 7]; %#ok<AGROW>
        end
    end
end
mask = false(9, 9, 9);
mask(sub2ind(size(mask), points(:, 2), points(:, 1), points(:, 3))) = true;
[~, info] = farmPruneSurface(points, mask, struct('Faces', faces));
swapped = points(:, [3 2 1]);
swappedMask = permute(mask, [1 3 2]);
[~, rotatedInfo] = farmPruneSurface(swapped, swappedMask, struct('Faces', faces));
verifyEqual(t, info.ErosionThickness, rotatedInfo.ErosionThickness, 'AbsTol', 1e-12);
verifyGreaterThan(t, info.ErosionThickness(18), 0);
verifyEqual(t, info.ErosionThickness(1:7), zeros(7, 1));
end

function testSATScaleOneAndHaloCoordinates(t)
mask = false(9, 9, 9);
mask(5, 5, 5) = true;
points = farmMaskToPoints(mask, 'Spacing', [2 2 2], 'Origin', [-3 4 11]);
options = struct('Method', 'SAT', 'Spacing', [2 2 2], 'Origin', [-3 4 11], 'Scale', 1);
[identity, info] = farmPruneSurface(points, mask, options);
verifyEqual(t, identity, points);
verifyTrue(t, all(info.InputKept));
options.Scale = 1.1;
options.ReturnReconstruction = true;
[result, info] = farmPruneSurface(points, mask, options);
verifyGreaterThan(t, size(result, 1), 0);
verifyEqual(t, mean(result, 1), points, 'AbsTol', 1e-12);
verifyTrue(t, info.ThinningInfo.Converged);
verifyTrue(t, any(info.Reconstruction(:)));
verifyEmpty(t, info.InputKept);
verifyTrue(t, all(info.Radii > 0));
end

function testValidationAndEmpty(t)
mask = false(9, 9, 9);
mask(3:7, 3:7, 5) = true;
points = farmMaskToPoints(mask);
verifyError(t, @() farmPruneSurface(points, mask, struct('Spacing', [1 1 2])), ...
    'objectgeometry:PruningAnisotropy');
verifyError(t, @() farmPruneSurface(points + 0.1, mask), 'objectgeometry:PruningGrid');
verifyError(t, @() farmPruneSurface(points, mask, struct('Method', 'SAT', 'MaxVoxels', 1)), ...
    'objectgeometry:PruningMemory');
[empty, info] = farmPruneSurface(zeros(0, 3), mask);
verifySize(t, empty, [0 3]);
verifyEqual(t, info.OutputPointCount, 0);
end
