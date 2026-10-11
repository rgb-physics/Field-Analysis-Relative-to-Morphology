# SegmentationTools tests

## Complete non-active-contour suite

`runSegmentationToolsTests.m` runs 18 synthetic tests covering every public
function currently stored under `SegmentationTools/src` except the three
functions in `+activeContours`. The coverage-manifest test fails if a new
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

`validateInOnOutImplementations.m` is a runnable comparison script. With no
arguments it generates two synthetic closed-wall volumetric structures,
compares the generalized disjoint classifier with the historical opening
workflow, asserts basic invariants, and writes inspectable TIFFs to:

```matlab
fullfile(tempdir, 'FARM-SegmentationTools-in-on-out')
```

Run it from MATLAB R2023a or newer:

```matlab
report = validateInOnOutImplementations();
```

To inspect a real TIFF probability hyperstack:

```matlab
opts = struct();
opts.InputFile = "C:\path\probabilities.tif";
opts.Channels = [1 2 3]; % [inside wall outside]
opts.Thresholds = [0.2 0.5 0.5];
report = validateInOnOutImplementations(opts);
```

TIFF metadata is used where available. Set
`opts.ReadOptions.TimeAsChannels=true` only if metadata describes YXZT but
the pages actually represent probability classes. HDF5 input additionally
accepts `DatasetPath` and ImageStackIO `SourceAxes` options.
