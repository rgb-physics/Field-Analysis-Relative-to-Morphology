# SegmentationTools tests

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
