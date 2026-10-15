# ObjectRelativeProfiles: general field sampling

## Vector fields

```matlab
fields = struct('VX',velocityX,'VY',velocityY,'VZ',velocityZ);
t = farmQueryVectorField(fields,support, ...
    {'ComponentMean','MeanVector','MagnitudeOfMean','MeanMagnitude','Covariance'}, ...
    struct('FieldName','Velocity','ComponentNames',{{'VX','VY','VZ'}}));
```

ComponentNames explicitly declares component order; inputs are separate XYZ
arrays or Data/Grid structures. Component statistics use independently finite
values, retaining separate NaN and positive/negative infinity counts. MeanVector
contains the independent component means, so its coordinates may be based on
different sample counts. MagnitudeOfMean is the norm of that vector. MeanMagnitude,
MagnitudeStd, MinMagnitude, MaxMagnitude and RMSMagnitude use locations with all
required components finite. CompleteVectorCount and IncompleteVectorCount
record that population; one invalid voxel does not discard other valid voxels.
Zero vectors remain valid.

Covariance uses pairwise-finite samples and returns CovariancePairCounts.
Pairwise sample sets may differ, so this covariance is not guaranteed positive
semidefinite. Do not use it as a PCA covariance without choosing a consistent
sample population. Sample/population normalization follows the scalar option.
Nematic directors and angle statistics are not ordinary vector statistics and
remain separate. Other supported component statistics are ComponentVariance,
ComponentStd, ComponentMin and ComponentMax. All quantities are opt-in.

Frame/batch queries use `Kind='vector'`, `Fields={'VX','VY','VZ'}` in coordinate
order, vector Statistics names, and ordinary Name/Support entries. Existing
scalar queries are unchanged. The test runner includes scalar and vector suites.

The new `fieldSampling` functions extract samples, calculate requested scalar
or component statistics, and stream frames. They reuse the direct indexing,
per-ID selection, `mean`/`sum`/`median`/`std`, and `histcounts` calculations in
the historical scripts. All 27 historical scripts remain unchanged for comparison
and specialized workflows; they have not been silently redefined as generic
functions. The old `farmConsMatLnB` zero-padded mean behavior is not reused: only
selected samples contribute, and genuine zero values remain valid.

Requires ObjectGeometry source on the MATLAB path. File loading is supplied
by user callbacks (typically ImageStackIO). Target MATLAB R2023a.

## Single XYZ field and user-supplied support

```matlab
t = farmQueryField(intensity,mask, ...
    {'Mean','Variance','Max'}, ...
    struct('FieldName','Intensity_Object', ...
    'Support',struct('DatasetID','experiment1','Frame',12)));
```

Field input is one real numeric/logical XYZ matrix (2-D is also accepted),
or `struct('Data',matrix,'Grid',metadata)`. Select one time/channel/component
before calling. VelocityX/Y/Z are independent scalar fields in this release;
orientation-specific reductions remain separate from vector sampling.

Supports may be linear indices, logical masks, integer ID matrices, cell arrays
of index groups, prepared ObjectGeometry objects, or generated geometry.
There is no implicit connected-component calculation for masks: one mask is
one sampling selection. Numeric vectors default to indices, other numeric
matrices to labels; use `Support.Type` to resolve ambiguous row-vector labels.
Index groups may overlap. Repeated indices within each group are deduplicated.
ID groups may contain disconnected regions. Indices always refer to the current
field grid, not an original image with different dimensions.

```matlab
support = farmPrepareSupport(indexGroups, ...
    size(field),struct('ObjectIDs',[7 42],'DatasetID','experiment1','Frame',12));
t = farmQueryField(field,support,'all');
```

## Requested statistics and invalid values

Supported: Count, Sum, Mean, Median, Variance, Std, Min, Max, Quantiles, Histogram.
`'all'` requests these, not raw samples. Every statistic uses finite samples.
VarianceNormalization=0 is MATLAB sample normalization; 1 selects population
normalization. Quantiles defaults to [.25 .5 .75]. Set BinEdges OR NumBins, or
leave both empty for MATLAB-selected histogram edges. Counts and actual edges
are stored together in a histogram cell, so comparisons can inspect binning.
Use common explicit edges for comparable distributions across frames.

Each row has DatasetID/Frame/ObjectID/ComponentID plus named result columns.
FieldName must be a valid MATLAB identifier and prefixes every result, e.g.
Intensity_Object_Mean. Diagnostic columns always include SelectedCount,
FiniteCount, NaNCount, PositiveInfCount, NegativeInfCount, SelectionEmpty,
GeometryEmpty, EmptyGeometryCount, UsedFallback and FallbackCount.

Empty selection: count/sum zero, other summaries NaN, SelectionEmpty=true.
Nonempty selection containing only invalid values: finite count/sum zero,
other summaries NaN, SelectionEmpty=false, with separate invalid counts.
A label matrix with no positive IDs yields zero rows because no identities
are supplied. To retain a known empty identity, supply an empty index group
with ObjectIDs, or prepared geometry records.

## Skeleton fallback and geometry

Generated geometry combines disconnected components by parent ID by default.
Set Support.ComponentResults=true to retain separate component rows. Empty
skeleton records with fallback centroid are sampled at the nearest voxel:
round XYZ centroid, convert to YXZ, then linear index. Out-of-grid centroids
are rejected, never clamped. CentroidFallback=false disables this sampling.
UsedFallback permits excluding these results later. EmptyGeometryCount records
partially empty multi-component objects; GeometryEmpty means ALL pieces were
empty. Actual and fallback indices are deduplicated after combination.

Dimensions must match. Supplied differences in spacing/units, axes, origin,
grid identity and transforms are recorded under Properties.UserData, not
rejected or automatically corrected. CorrespondenceVerified remains false:
equal dimensions or metadata do not prove real-world registration. Metadata
of named source fields is retained separately. No field is resampled implicitly.

## Custom operations and multiple fields at one time

```matlab
fields = struct('Intensity',intensity,'Distance',abs(distanceField));
t = farmQueryField(fields,support, ...
    {'Mean','Max'},struct('FieldName','WeightedIntensity', ...
    'SampleOperation',@(f) f.Intensity.*f.Distance, ...
    'CustomOperations',struct('MeanAbsolute',@(v) mean(abs(v)))));
```

SampleOperation receives a named struct of selected DOUBLE vectors, all at
corresponding indices, and returns one real value per selected location.
Nonfinite diagnostics then describe the derived values. CustomOperations is
a struct of named function handles applied to FINITE derived samples; results
are stored in cells to permit user-defined result shapes. It receives an empty
vector for empty/invalid-only selection and must define its own behavior.
Functions can compose other functions internally. Raw-value storage is deferred;
custom functions returning long vectors incur storage costs chosen by the user.

`farmQueryFrame(fields,supports,queries)` applies multiple named queries to the
same loaded frame. Each query defines Name (unique output prefix), Support
(named support), Statistics, optional Options, and either Field OR Operation.
For Operation, Mode='samples' uses the contract above; Mode='field' receives
the named full XYZ arrays and returns a matching derived XYZ field. Field
operations receive original numeric types: explicitly convert integer images
to double when arithmetic must avoid integer saturation. Optional Fields selects
the source names passed to an operation. Query names should include the support
name when one field is queried on objects, skeletons and boundaries.

## Incremental batching without stacks of stacks

```matlab
specs(1) = struct('Name','Intensity','Loader',@(frame) loadIntensityXYZ(frame));
specs(2) = struct('Name','Distance','Loader',@(frame) loadDistanceXYZ(frame));
supportLoader = @(frame,fields) loadSupportsForFrame(frame,fields);
manifest = farmRunFieldBatch( ...
    frames,specs,supportLoader,queries, ...
    struct('DatasetID','experiment1','OutputDirectory',outputFolder));
```

For EACH frame: load its required XYZ fields, load/generate its supports,
run all queries, save results as MAT, release full fields/supports, continue.
Several XYZ fields may coexist at one frame; the library never preloads all
time points. Loader callbacks must not capture entire XYZT datasets. The API
cannot detect an XYT array falsely presented as XYZ: selection and axes are
the loader's responsibility. Four-dimensional stacks are explicitly rejected.

Supports have an easy injection point: supportLoader(frame,fields) returns a
struct of named selections or prepared geometries. Raw supports receive batch
dataset/frame identity; prepared supports must already match it. Previously
saved frames survive a later failure. Overwrite=false protects existing files.
Use a separate output directory per dataset. RetainTables=true keeps only
small result tables; default false retains only paths/counts in the manifest.
Operations spanning different times or motion correspondence remain deferred.

## Concatenation across time or late-added fields

`farmConcatenateResults({frame1,frame2,...})` appends matching schemas and retains
each table's metadata. `farmAttachResults(base,newQueries)` attaches columns by
DatasetID/Frame/ObjectID/ComponentID, preserving destination order. It works
with ObjectGeometry tables (parent ComponentID defaults to zero), rejects
duplicate keys and missing matches by default, and allows extra incoming rows
for a filtered destination. MissingPolicy='missing' and Overwrite=true are
explicit alternatives. Grid/membership compatibility remains the query's
responsibility: keys alone cannot establish unchanged geometry.

Different named supports use distinct column prefixes with associated metadata;
support identity is not inferred from row position. farmQueryFrame expects its
supports to share the destination ID set. For differing sets, query separately
and use farmAttachResults with the explicit desired missing policy.

Raw sample memory: doubles cost approximately 8 bytes per sampled value;
double indices another 8 bytes, before cell/table overhead. Storing values
and indices for 10 million samples is about 160 MB per field/support/frame.
This is why raw storage is not enabled by default or included in this release.

## Tests and historical scope

Run `results=runFieldSamplingTests()` from tests. These are focused interface
checks, not broader scientific validation. `examples/exampleFieldQueries.m`
demonstrates queries, a custom combination, keyed attachment and incremental
batching. MATLAB runtime verification is pending in the user's licensed session.

Historical experiment scripts from fieldSampling, distance, objectMetrics and
sheetProfiles are preserved in the sibling MeMo-Archive at their original
relative paths. Their additional workflow functionality remains a future review
task; archiving does not imply that the general query API replaces every step.
