# SharedUtilities

General-purpose helpers and explicit keyed table operations.
Use only this API's src directory on the MATLAB path. Do not add archives
with genpath; dated archives preserve original package structures.

## Keyed attachment and concatenation

```matlab
keys = {'DatasetID','Frame','ObjectID'};
joined = sharedutilities.structsAndTables.attachByKeys(base,additional,keys);
joined = sharedutilities.structsAndTables.attachByKeys(base,additional,keys, ...
    struct('MissingPolicy','missing','Overwrite',false));
combined = sharedutilities.structsAndTables.concatenateByKeys(frameTables,keys);
```

DatasetID identifies an independent dataset, Frame a time point, and ObjectID
an object in that frame. TrajectoryID is attached information, not required
for identity matching. For component-specific geometry add ComponentID.
Spatial correspondence/registration is checked separately; key matching
does not validate the sampled geometry or grid.

Attachment retains destination row order and accepts extra incoming rows.
Incoming keys must be unique. Base keys must be unique unless
AllowRepeatedBase=true (e.g., parent tracking membership mapped onto component
rows). Columns optionally selects the incoming non-key columns to attach.
Missing matches default to error. MissingPolicy='missing' fills with NaN,
missing strings, NaT, undefined categories, or empty cells. Integer/logical
columns requiring missing values become double. Legitimate zero is retained.
Matched columns retain their type. Existing properties require Overwrite=true.
Both tables' UserData are retained. Variable descriptions/units for newly
attached columns are not automatically copied; preserve field units in
metadata and set VariableUnits explicitly where needed.

Concatenation requires identical column names/order and compatible MATLAB
column types, checks duplicate keys across all inputs, and retains frame
metadata. It does not renumber IDs, pool statistics, or infer datasets.

Existing public functions delegate to these helpers:
- objectgeometry.objects.attachMeasurements / concatenateMeasurements
- objectrelativeprofiles.fieldSampling.attachResults / concatenateResults
- objecttracking.attachMembership

Geometry keys are DatasetID/Frame/ObjectID. Sampling additionally uses
ComponentID, with absent ComponentID interpreted as parent level (zero).
Tracking membership intentionally replicates parent identities across
component rows and attaches only DetectionID/TrajectoryID.
The established public error identifiers and metadata envelopes are retained.
Other APIs' private option helpers are unchanged.

## Repairs and intentional behavior

Originals are preserved under archive/2026-10-13-shared-repair (and in the
corresponding archives of the affected APIs).
- Cross-file helper calls are package-qualified.
- addFieldsStruct forwards custom indices; addFieldStruct now honors them for
  both cell and numeric inputs. Source values are indexed by absolute struct
  index: fieldVals(i) belongs to structObj(i). A compact subset is not inferred.
- rescaleCoords maps XY/XYZ points between YX/YXZ grids using pixel centers:
  round((index-.5)*newSize/oldSize+.5), clamped to valid destination centers.
  Inputs must be inside the source grid. RescaleCoords_Inds preserves row/column
  vector shape and allows empty supports. Forward downsampling can map multiple
  source indices to one destination index; this is not label-preserving
  resampling. The caller owns updated spacing and source-transform metadata.
- fastLinIntNDScale2 now supports 2D and 3D, preserving its historical
  odd-index samples, halfway interpolation and final-edge extension.
  It is not equivalent to MATLAB imresize pixel-center conventions.
- logAB(A,B) now returns log(B)/log(A), as documented. Check legacy external
  callers if they intentionally used the reversed formula.
- loglogBin returns paired log-domain means from occupied bins. It requires
  positive finite values and retains pairing when dropping empty bins.
- getUnitVecs returns NaN for zero or nonfinite rows (undefined direction).
- noNan directly replaces NaN, preserves class, and does not replace Inf.
- consMatLnB preserves class in numeric-index construction. It still zero-pads
  outside the selection; it is not equivalent to collecting selected samples.
- getCCVectors accepts row/column index cells and returns local component
  positions, not persistent object IDs.
- myconvn retains mirrored padding; its misleading periodic comment is fixed
  and flip replaces flipdim without changing the boundary algorithm.
  LOG/GaussD/myconvn retain their original third-party attribution.

concatTablesOverT remains a legacy file-loading adapter; it does not establish
DatasetID/ObjectID. New keyed functions do not guess those identities.
Five helpers now have canonical owners:
- visualizationtools.export.figSaves
- visualizationtools.display.manVlnPlot / plotVlns
- fieldanalysis.statistics.loglogBin
- sharedutilities.numerics.logAB

Their former sharedutilities.plotting paths remain compatibility wrappers.
Add VisualizationTools/src or FieldAnalysis/src when using the corresponding
legacy wrapper. General SharedUtilities numerical/table helpers do not need
those APIs. progressBar stays in SharedUtilities. Originals are preserved in
archive/2026-10-13-ownership. No mesh workflows were modified.

## Tests

From the repository root:
```matlab
addpath(fullfile(pwd,'APIs','SharedUtilities','tests'));
results = runSharedUtilitiesTests;
```

The runner includes the focused SharedUtilities suite, four ownership checks
(numerical aliases, violin graphics/statistics, and figure exports), plus ObjectGeometry,
scalar/vector field sampling, ObjectTracking and FieldAnalysis regression
suites. It sets their src paths, retains archives outside the path, and writes
SharedUtilitiesTestDiagnostics.log in tempdir.
It does not require real Trackpy or run experimental mesh workflows.
