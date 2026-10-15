# SharedUtilities

General-purpose helpers and explicit keyed table operations.
Run `farmSetup` from the repository root to add ordinary source folders
and API dependencies. Do not add the sibling MeMo-Archive to MATLAB's path.

## MATLAB glossary

From the repository root, use `farmGlossary("Experiment")` to display an entry,
`farmGlossary("search", "distance")` to search, or `catalog = farmGlossary` to browse
all entries as a table. Explicit getters include `farmGetGlossaryDataType`,
`farmGetGlossaryInputs` and `farmGetGlossaryInputOptions`.
See [MATLAB glossary usage](../../docs/MATLAB-GLOSSARY.md).
The same document contains a Data Dictionary beginning with sampling diagnostics.
Optional `Section` and `SearchIn` filters accept a name or a string array;
the default searches all sections and all columns.

## Keyed attachment and concatenation

```matlab
keys = {'DatasetID','Frame','ObjectID'};
joined = farmAttachByKeys(base,additional,keys);
joined = farmAttachByKeys(base,additional,keys, ...
    struct('MissingPolicy','missing','Overwrite',false));
combined = farmConcatenateByKeys(frameTables,keys);
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
- farmAttachMeasurements / farmConcatenateMeasurements
- farmAttachResults / farmConcatenateResults
- farmAttachMembership

Geometry keys are DatasetID/Frame/ObjectID. Sampling additionally uses
ComponentID, with absent ComponentID interpreted as parent level (zero).
Tracking membership intentionally replicates parent identities across
component rows and attaches only DetectionID/TrajectoryID.
The established public error identifiers and metadata envelopes are retained.
The internal options helpers farmFAOptions, farmOGOptions and farmSUOptions
all accept user options first and defaults second.

## Repairs and intentional behavior

Originals are preserved in the sibling MeMo-Archive under the original API
archive paths, including APIs/SharedUtilities/archive/2026-10-13-shared-repair.
- Cross-file helper calls use unique farm-prefixed names.
- farmAddFieldsStruct forwards custom indices; farmAddFieldStruct now honors them for
  both cell and numeric inputs. Source values are indexed by absolute struct
  index: fieldVals(i) belongs to structObj(i). A compact subset is not inferred.
- farmRescaleCoords maps XY/XYZ points between YX/YXZ grids using pixel centers:
  round((index-.5)*newSize/oldSize+.5), clamped to valid destination centers.
  Inputs must be inside the source grid. RescaleCoords_Inds preserves row/column
  vector shape and allows empty supports. Forward downsampling can map multiple
  source indices to one destination index; this is not label-preserving
  resampling. The caller owns updated spacing and source-transform metadata.
- farmFastLinIntNDScale2 now supports 2D and 3D, preserving its historical
  odd-index samples, halfway interpolation and final-edge extension.
  It is not equivalent to MATLAB imresize pixel-center conventions.
- farmLogAB(A,B) now returns log(B)/log(A), as documented. Check legacy external
  callers if they intentionally used the reversed formula.
- farmLoglogBin returns paired log-domain means from occupied bins. It requires
  positive finite values and retains pairing when dropping empty bins.
- farmGetUnitVecs returns NaN for zero or nonfinite rows (undefined direction).
- farmNoNan directly replaces NaN, preserves class, and does not replace Inf.
- farmConsMatLnB preserves class in numeric-index construction. It still zero-pads
  outside the selection; it is not equivalent to collecting selected samples.
- farmGetCCVectors accepts row/column index cells and returns local component
  positions, not persistent object IDs.
- myconvn retains mirrored padding; its misleading periodic comment is fixed
  and flip replaces flipdim without changing the boundary algorithm.
  LOG/GaussD/myconvn retain their original third-party attribution.

farmConcatTablesOverT remains a legacy file-loading adapter; it does not establish
DatasetID/ObjectID. New keyed functions do not guess those identities.
Five helpers now have canonical owners:
- farmFigSaves
- farmManVlnPlot / farmPlotVlns
- farmLoglogBin
- farmLogAB

Their former sharedutilities.plotting paths remain compatibility wrappers.
Add VisualizationTools/src or FieldAnalysis/src when using the corresponding
legacy wrapper. General SharedUtilities numerical/table helpers do not need
those APIs. farmProgressBar stays in SharedUtilities. Originals are preserved in
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
