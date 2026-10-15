# SegmentationTools tests

## Real-data visual experiments

Run `exploreRealSegmentationData` from this folder. Edit the settings at the
top before running, especially `semanticChannels`: `[1 3 2]` is an assumption
to confirm using the exported original-channel preview.

The script reads the shared HDF5 fixture and every TIFF under
`test-data/image-stacks/tiff`, using the first time point. It creates a fresh
temporary folder containing threshold sweeps, disjoint class labels,
historical opening comparisons, sum-versus-union masks, component filtering,
directional hole filling, a voxel-count CSV, and settings/reports in a MAT file.
Every output TIFF is read back to check that its stored values are preserved.
Intensity thresholds refer to each channel's min-max scaled intensity, not
class probabilities. Preview intensities are scaled to 16-bit for viewing.

Distance cleanup is optional and assumes verified isotropic voxels. Sheet
splitting is optional and requires a suitable two-sheet wall mask. Outputs
are exploratory comparisons, not known-correct real-data segmentations.
Inspect the same slice in each comparison channel, plus XZ and YZ views.
Inputs are never overwritten; generated outputs remain outside the repository.

## Complete non-active-contour suite

`runSegmentationToolsTests.m` runs 18 synthetic tests covering every public
function currently stored under `SegmentationTools/src` except the three
functions in `activeContours`. The coverage-manifest test fails if a new
source function is added without being listed in the suite.

```matlab
cd(fullfile(repositoryRoot,'APIs','SegmentationTools','tests'))
results = runSegmentationToolsTests();
```

The runner prints detailed results and writes
`SegmentationToolsTestDiagnostics.log` beside the test files. Temporary TIFF
round-trip fixtures are deleted after the run. MATLAB R2023a with Image
Processing Toolbox and Signal Processing Toolbox is expected.

## Focused visual comparison

`farmValidateInOnOutImplementations.m` is a runnable comparison script. With no
arguments it generates two synthetic closed-wall volumetric structures,
compares the generalized disjoint classifier with the historical opening
workflow, asserts basic invariants, and writes inspectable TIFFs to:

```matlab
fullfile(tempdir, 'FARM-SegmentationTools-in-on-out')
```

Run it from MATLAB R2023a or newer:

```matlab
report = farmValidateInOnOutImplementations();
```

To inspect a real TIFF probability hyperstack:

```matlab
opts = struct();
opts.InputFile = "C:\path\probabilities.tif";
opts.Channels = [1 2 3]; % [inside wall outside]
opts.Thresholds = [0.2 0.5 0.5];
report = farmValidateInOnOutImplementations(opts);
```

TIFF metadata is used where available. Set
`opts.ReadOptions.TimeAsChannels=true` only if metadata describes YXZT but
the pages actually represent probability classes. HDF5 input additionally
accepts `DatasetPath` and ImageStackIO `SourceAxes` options.
