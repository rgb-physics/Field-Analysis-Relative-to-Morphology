# Active Foam E5: individual workflow stages

These teaching functions contain the same calculations as the corresponding
blocks in [setupActiveFoamE5.m](../setupActiveFoamE5.m). They are examples for
comparison with the combined script, rather than new general package APIs.
They call public FARM functions and ordinary MATLAB operations directly.

Every stage has one input and one output: `c`. The existing settings stay in
their configuration fields. Intermediate data is stored in `c.Results`.
`c.Frame` selects the current acquisition frame; `c.Frames` lists all requested
frames. `c.RunDirectory` identifies a new local destination for saving results.
These additional fields are specific to this example, not mandatory fields for
every FARM configuration.

Each function's help lists the configuration fields it uses, the preceding
results it reads, and the results it adds. Its body shows how those fields are
read and passed to package functions. Settings are never inferred from the data.

`c.FillMethod` selects how object segmentation assigns locations left unclassified
after opening: `'none'` (default), `'nearest'`, or highest-precedence `'fill'`.
To use nearest filling, change that setting in `farmActiveFoamE5Config` before
running this example. This changes the segmented regions and subsequent boundary
distances; existing saved observations are not changed automatically.

| Stage | Function | Main result in `c.Results` | Corresponding combined-script block |
| --- | --- | --- | --- |
| 1 | `farmE5LoadData` | `Raw`, `Probabilities`, image metadata | Data Loading |
| 2 | `farmE5SegmentObjects` | `Regions`, category masks | Object Segmentation |
| 3 | `farmE5MeasureFilaments` | `FilamentMask`, `Properties`, `Objects` | Filament Detection and Measurement |
| 4 | `farmE5DefineGeometry` | `Distance`, `DistanceValid`, working-grid data | Geometry Definition |
| 5 | `farmE5CalculateNormals` | `DistanceGradient`, `DirectionValid` | Surface-Normal Directions |
| 6 | `farmE5SampleFields` | extended `Properties`, `CentroidSupport`, `SamplingDiagnostics` | Field Sampling |
| 7 | `farmE5MeasureAlignment` | completed `Properties`, alignment results | Alignment Measurement |
| 8 | `farmE5SaveMeasurements` | `SavedFrameFile` | Save Measurements |

## Inspect one stage at a time

The first stage reads real frame 25 from the configured E5 sources. All
`O:\Session 88` inputs remain read only. The first seven stages do not save
results. Run from the repository folder after reviewing the configuration.
Execute each call separately to inspect `c.Results` before continuing.

```matlab
farmSetup('IncludeExamples', true);
c = farmActiveFoamE5Config;
c.Frame = c.Frames(1);
c = farmE5LoadData(c);
```

If `c.Results.MissingInput` is true, correct the source locations before
continuing. Otherwise run the remaining calculations individually:

```matlab
c = farmE5SegmentObjects(c);
c = farmE5MeasureFilaments(c);
c = farmE5DefineGeometry(c);
c = farmE5CalculateNormals(c);
c = farmE5SampleFields(c);
c = farmE5MeasureAlignment(c);
```

For example, inspect the sampling function and its required configuration:

```matlab
help farmE5SampleFields
edit farmE5SampleFields
c.Results.Properties
c.Results.SamplingDiagnostics
```

Loading a frame clears previous per-frame results. Changing a setting or an
intermediate result does not automatically rerun later stages: call each
affected stage again. Large arrays are retained only for the current frame.
No previews or analysis/visualization functions run automatically.

## Save the inspected frame

This creates a new local directory under the configured output root. The save
stage writes tables and calculation metadata, rather than the entire `c` with
its large arrays. It refuses to overwrite an existing frame file.

```matlab
if ~isfolder(c.OutputRoot)
    mkdir(c.OutputRoot);
end
c.RunDirectory = tempname(c.OutputRoot);
mkdir(c.RunDirectory);
c = farmE5SaveMeasurements(c);
c.Results.SavedFrameFile
```

## Run the stages across all configured frames

The accompanying script reads frames 25:30 by default and saves a new local run,
including per-frame tables, combined Workflow 2 observations, and a progress log.
Missing source files are reported and skipped. It contains no `try/catch`.

```matlab
farmSetup('IncludeExamples', true);
setupActiveFoamE5Stages
```

The output directory is printed and stored in `c.RunDirectory`. Combined data
is available as `c.Results.Workflow2.Filaments` and in `workflow2-output.mat`.
If execution is stopped manually, enter `diary off` to close the progress log.
Analysis, plotting, and general visualization interfaces remain separate work.

## Frames without a measurable boundary

The boundary calculation needs contact between the wall/on region and the
outside region. If that contact is absent, distances can be infinite even
though filament detection succeeds. An object filling the field of view is
one possible cause; an absent wall or outside segmentation can also cause it.

The staged workflow retains the filament measurements for these frames.
`DistanceValid` and `DirectionValid` are false; sampled boundary distances,
normals, and alignment values are `NaN`. It reports the unavailable distances
in the processing log. It does not treat image edges as object boundaries or
change segmentation thresholds automatically. Alignment plots therefore have
no finite alignment values for that frame.

Inspect `c.Results.GeometryInfo` for constructed boundary counts and
`c.Results.GradientInfo.Status` for `no-finite-distance`. These diagnostics
are included in the saved per-frame measurement file. Set `c.DistanceFillMethod='nearest'` to assign each undefined distance the
value of its nearest finite voxel (array-coordinate Euclidean distance).
Finite original values are retained. Assigned values can be measured and are
flagged in `c.Results.DistanceFilled` and the filament-table column
`BoundaryDistanceFilled`; counts are in `GradientInfo.FilledVoxelCount`.
These values are estimates, not newly computed exact boundary distances.
The default `'none'` keeps undefined values missing and invalidates affected
normal directions while retaining usable measurements elsewhere. A field
without any finite source values cannot be filled.

## Time taken by each stage

The accompanying script records `c.StageTimings`, with one row for every requested
frame. Columns are ordered as follows:

| Column | Meaning |
| --- | --- |
| `TotalSeconds` | Sum of the eight stage times in this row |
| `Frame` | Acquisition frame number |
| `LoadDataSeconds` | Input-file checks and data loading |
| `SegmentObjectsSeconds` | Probability segmentation and category resampling |
| `MeasureFilamentsSeconds` | Filament detection and measurements |
| `DefineGeometrySeconds` | Working-grid resampling and boundary distance |
| `CalculateNormalsSeconds` | Distance-gradient calculation |
| `SampleFieldsSeconds` | Centroid support preparation and field queries |
| `MeasureAlignmentSeconds` | Direction comparisons and selection flag |
| `SaveMeasurementsSeconds` | Saving the per-frame measurement file |
| `Completed` | True when all eight stages ran for the frame |

Times are elapsed seconds measured around each stage call. Configuration,
combined-output saving, and writing the timing files are outside these stages
and are excluded from `TotalSeconds`. Individual function calls made manually
are not timed automatically; the timing code is visible in the script.

For a skipped frame, unrun stages are `NaN`, `Completed` is false, and the total
is the sum of the stages that ran. The script updates `stage-timings.csv` and
`stage-timings.mat` in the run directory after each completed or skipped frame.
The MAT variable is `stageTimings`. The same table is included in
`c.Results.Workflow2.StageTimings` and the saved `workflow2-output.mat`.

The combined setup records the same columns in its workspace variable
`stageTimings` and `workflow2.StageTimings`, allowing comparisons between the two
implementations. Timing includes the work performed within each stage, including
its status messages; the totals need not equal the entire script's elapsed time.
