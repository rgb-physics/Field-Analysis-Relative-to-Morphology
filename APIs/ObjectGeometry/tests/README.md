# ObjectGeometry tests

In MATLAB R2023a with Image Processing Toolbox:

```matlab
cd('C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo\APIs\ObjectGeometry\tests')
results=runObjectGeometryTests();
table(results)
```

The runner adds the required source paths and stores a diagnostic log at
`fullfile(tempdir,'ObjectGeometryTestDiagnostics.log')`. It errors after running
the suite if any test fails or is incomplete. These focused tests do not claim
scientific acceptance of real data or coverage of all historical prototypes.
They emphasize preserved identity under sorting/filtering/concatenation,
disconnected labels, selectable native properties, filament-axis conventions,
scaled PCA, gradient smoothing and sign-invariant nematic alignment.

Run `../examples/exploreObjectGeometry.m` for a real-data visual experiment.
The external gaussdiff dependency of farmSkel3DBlobs is documented separately;
its Hessian behavior requires the later dedicated tests/examples agreed in
the design discussion.

`testSurfacePruning.m`, included in the runner, checks experimental ET sector
burning and rasterized SAT: planar known answers, a nonmanifold junction,
folded-sheet coordinate invariance, physical units, closed cores, scale-one
identity, halo coordinates, and validation. See
[surface pruning](../SURFACE-PRUNING.md) for the implementation limits.

`testSurfaceBranchCorrection.m`, also included in the runner, has eight tests
for seam-based flap removal, retention of the main ribbon, independent source
ball-coverage accounting, unique-support protection, preview/protected rows,
loss budgets, calibrated units, coordinate permutations, and no-seam/empty/
curve-only behavior, and dictionary entries for every returned field/table
column. Run just the branch and existing surface-workflow checks:

```matlab
results = runtests({'testSurfaceBranchCorrection.m', 'testSurfaceSkeletonWorkflow.m'});
assertSuccess(results);
```

These 23 tests passed in MATLAB R2023a. They do not establish full-frame
performance or validate automatic patch boundaries on experimental data; see
[branch correction](../SURFACE-BRANCH-CORRECTION.md).

The combined branch/surface/pruning check on 2026-10-27 passed 32/33 tests. The
separate experimental ET test `testETLocallyThickSheetAndSeparateFolds` remains
failing because some thick-sheet scores are infinite after lattice collapse.
It is not skipped or weakened; the full runner therefore still reports this
failure. MATLAB Code Analyzer reported no findings in the three branch-cut
function files during the documentation/style review.
