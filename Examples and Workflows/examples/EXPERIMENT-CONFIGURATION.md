# Experiment configuration and inter-API fields

New configuration builders and the named-source workflow 1 path are described
in [Configuration builders](../../CONFIGURATION-BUILDERS.md). The fields below
remain the reference for the existing flat Experiment 4 example configuration.

An experiment configuration is currently a scalar MATLAB struct, not a class or a centrally validated schema. `farmExperiment4Config` supplies the complete example configuration. Properties below are case-sensitive. Adding an arbitrary property does not make an API consume it: workflows explicitly translate configuration into API options.

Start with `c = farmExperiment4Config;` and override the relevant fields. The defaults are specific to Session 88 Experiment 4; paths, channels, thresholds and crop metadata must be reviewed for another experiment. The configuration can retain unused settings; this guide covers the released object and filament workflows.

## Configuration reference

| Fields | Expected value and purpose |
|---|---|
| DatasetID | Text identifying an independent dataset; keep stable across geometry, sampling and tracking. |
| RepositoryRoot | Explicit MeMo package root used to validate the allowed tests/data output location; standalone setup records the SETUP repo path here. |
| Frames | Numeric frame vector for object/filament/profile workflows; default 10:2:30. |
| TrackingFrames | Numeric frame vector in desired processing order; default 10:30. Overlap tracking links successive supplied frames without filling omitted times. Duplicate frames are omitted, preserving first occurrence. |
| Spacing, SpacingUnit | Current intensity-grid spacing in **YXZ** order and unit text; defaults [.55 .55 .7], 'um'. |
| TimeStep, TimeUnit | Interval between original acquisition frames and its unit; defaults 30 and 's'. Frame numbers are not elapsed time. |
| RawDirectory, IntensityDirectory, ProbabilityDirectory | Source directories; inputs remain read-only. |
| CropMetadata | Historical crop metadata MAT path used by preparation. Historical XYZ crop coordinates are translated to YXZ by that example. |
| RawPattern | sprintf filename pattern receiving frame; default Time%06i_raw560.tif. |
| IntensityPattern | sprintf pattern receiving frame and channel text; default t%03i_illBleachCorr16bit_%s.tif. |
| ProbabilityPattern | sprintf pattern receiving frame; default t%03i_illCorr8bit_560_E4_Probabilities Stage 2.h5. |
| H5Dataset, H5SourceAxes | HDF5 dataset path and source axis order; defaults /exported_data and CXYZ. Source order differs from normalized output order. |
| ProbabilitySpacing | Probability-grid spacing in YXZ order; default [1.5 1.5 1.5]. |
| SemanticChannels | Input probability channel indices ordered inside, wall, outside; default [3 2 1]. |
| Thresholds, OpeningRadius | Semantic segmentation thresholds and cleanup radius; defaults [.33 .33 .33], 1. |
| ForegroundChannels, ForegroundThreshold, ObjectSmoothSigma | Channels summed for object foreground, threshold on that sum, and object smoothing; defaults [3 2], .6, 2. |
| ObjectLoader, ObjectInputType | Optional @(frame) supplying a mask or labels on the intensity grid; empty uses probability segmentation. InputType defaults 'auto'; use 'labels' to preserve supplied binary-valued IDs. |
| Supports, GeometrySigma | Requested sampling geometry names and geometry smoothing; defaults {'objects','boundary'}, 1. Skeleton support requires its dependencies. |
| IncludeDiagnostics | Workflow 1: false by default keeps counts/flags out of Measurements; true includes them. Diagnostics are always retained in a separate keyed Diagnostics table in frame files and the returned manifest. |
| LocalInertia, InertiaOptions | Optional local inertia calculation; default false. Options default Radius=18, Sigma=3, SampleLimit=10000; see farmLocalInertia help for additional options. |
| FilamentLoader | Optional @(frame) binary filament mask; empty uses intensity segmentation. |
| FilamentSigma, FilamentThreshold | Filament preprocessing parameters; defaults 1, 20. Threshold is in native intensity units for this example. |
| MinFilamentLength, MinAspectRatio, MaxZComponent | Filament selection controls; defaults 0, 0, [] (no Z-component restriction). |
| OutputRoot | Generated output directory under package tests/data; default tests/data/workflow-results. Each run creates a fresh directory. |

## Fields passed between APIs

The configuration itself is not an API interchange object. Pass the appropriate subset or use the workflow adapters.

| Interface | Names expected and meaning |
|---|---|
| ImageStackIO reading | Options SourceAxes, Spacing, SpacingUnit; farmReadH5 also takes the dataset path separately. Returned image Data uses YXZCT with Axes='YXZCT'. Metadata-free grayscale multipage TIFFs default to YXZ; use SourceAxes='YXT' for time pages. |
| ObjectGeometry farmPrepareObjects | Options DatasetID, Frame, Spacing, SpacingUnit, InputType; optional ImageSize, ObjectIDs, Connectivity, SourceGrid, Transform, Channel, TimeIndex. SourceGrid/Transform record previous representations; spacing describes current indices. |
| ObjectRelativeProfiles farmPrepareSupport | Options DatasetID, Frame, Name, Grid, Type, ObjectIDs, ComponentResults, CentroidFallback. Here Type is the input selection kind; it is not the ObjectGeometry option name InputType. |
| ObjectRelativeProfiles farmQueryFrame | Named fields and supports; each query uses Name, Support, Statistics and either Field or Operation. Optional Options, Fields, Mode and Kind configure custom operations/vector queries. Name supplies the output column prefix. |
| ObjectTracking | DatasetID accompanies tracking options. Frame and ObjectID identify detections; tracking attaches TrajectoryID and records links/events. A trajectory is not the complete ancestry of an object. |
| FieldAnalysis | Pass arrays and function-specific options; it does not automatically read experiment directories or infer channels from configuration. |
| Visualization | Supply the measured arrays/tables and plotting options. The configuration is not a universal plotting object. |

## Identity, coordinates and measurement naming

Table identity is **DatasetID + Frame + ObjectID**. Sampling additionally uses ComponentID where needed. TrajectoryID is an attached tracking property, not a substitute for detection identity. Join tables by explicit keys, never row position. Different object classes are not automatically associated merely because their ObjectIDs coincide.

Spatial matrix order and spacing are **YXZ**; ImageStackIO adds channel/time as YXZCT. MATLAB native Centroid/PixelList coordinates and vector outputs may use XYZ: follow the producing function's documentation rather than swapping every coordinate array. Linear indices refer to the current matrix grid, so retain grid size and calibration with them. Same dimensions alone do not establish spatial registration.

Sampled scalar columns follow **FieldName_Statistic**, using the requested FieldName/query Name. Choose descriptive prefixes such as BoundaryDistance and SkeletonDistance instead of reusing Distance for distinct references. User-chosen names are supported; they are not inferred from array values. Native regionprops property names remain native names.

Region membership (for example inside/wall/outside) differs from distance and from ObjectID. ReferenceValid and direction validity are separate from the measured alignment/distance: retain flags rather than interpreting zero as invalid. Empty geometry and centroid fallback must retain their support flags.

Units belong with the relevant grid metadata and table VariableUnits. Configuration Spacing does not automatically rescale every native regionprops measurement; explicit physical measurements must use the appropriate geometry function and calibration.

## Scope and extension

No central validator currently checks every experiment property before a run. Individual operations perform their own checks. Channel labels '560' and '647', some semantic reference choices, and parts of the examples remain Experiment-4-specific; editing directory paths alone does not generalize those assumptions.

For a new named field, load one spatial frame, add it to the named fields struct, and supply a query with a distinct Name. Attach later measurements by keys and concatenate time tables using the API helpers. Do not load all time stacks merely to add another field.

This document describes the current implementation, not a newly enforced experiment schema. Function help remains authoritative for complete API-specific option lists.

