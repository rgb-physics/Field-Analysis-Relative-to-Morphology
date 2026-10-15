# ObjectTracking

Two parallel workflows: overlap lineage tracking and Trackpy position linking.
Neither is intrinsically restricted to a specimen type. Historically overlap
was used for blob/network lineage and Trackpy for filaments. Position-based
analysis is a future possibility, not implemented here.

Add `src` for ObjectTracking, ObjectGeometry, ImageStackIO and SharedUtilities.
Do not add archived directories through genpath. MATLAB R2023a with Image
Processing Toolbox is the target. Trackpy execution additionally needs Python;
overlap tracking and the MATLAB test suite do not.

## Overlap core

```matlab
loader = @(frame) farmReadTiff(sprintf('C:\data\objects_%03d.tif',frame));
tracking = farmTrackOverlaps(1:50,loader, ...
    struct('DatasetID','experiment1','Identity',struct('InputType','labels'), ...
    'Ranking','overlap','MergePolicy','inherit','SplitPolicy','inherit', ...
    'ExportDirectory','C:\data\tracked'));
```

Input may be a binary mask (internally connected components), supplied labels
or prepared objects/index groups. Prepared objects must match dataset/frame.
Disconnected pieces with the same label remain one tracking entity. Overlap
requires registered spatial grids and modest object displacement. It cannot
recover links without shared voxels. Same dimensions are checked; no movement
or resampling correction is guessed. Use explicit label mode for binary-valued
label matrices when label 1 should remain a disconnected group.

Frames are processed as successive entries in the supplied vector, with
arbitrary intervals and order (for example 10:2:30 or [12 16 17 23 34]).
Repeated frame numbers are omitted, keeping their first occurrence. Descending
order is allowed. Source/target links and ancestry refer to processing order;
with reverse order, graph ancestors are not chronological ancestors.
Skipped acquisition frames are not loaded or searched for missing detections.
A missing file/load error stops execution. Only the current pair's spatial data is held; compact tables of
observations and relationships accumulate. `farmOverlapLinks` exposes the reusable
intersection -> label pairs -> counts primitive, preserving the historical
method without constructing full label volumes from index inputs.

Every nonzero-overlap pair is retained as ancestry evidence. ID inheritance is
separate. Default ranking is descending overlap count; Ranking='volume' uses
source+target voxel count (largest parent at simple merges, largest child at
simple splits). MergePolicy/SplitPolicy independently select 'inherit' or 'new'.
Equal scores sort by smallest source then target ObjectID. Many-to-many cases
use that deterministic ranked greedy ordering: one inherited trajectory per
source-target pair, no duplicated trajectory within a frame. This is not a
global optimal assignment and should be reviewed with dedicated examples.

## Identity, links and events

`tracking.Detections`: DatasetID, Frame, ObjectID, DetectionID, TrajectoryID,
VoxelCount. ObjectID is frame-local; DetectionID is globally unique within this
tracking run; TrajectoryID is inherited identity. Initial trajectories are
numbered in initial object order; source object IDs are never overwritten.
Always retain DatasetID when combining runs.

`tracking.Links`: SourceDetectionID, TargetDetectionID, SourceFrame, TargetFrame,
OverlapCount, source/target overlap fractions, IoU and InheritanceChosen. These
are compact edges: no overlapping voxel arrays are stored. All accepted edges
remain regardless of which trajectory ID is inherited.

`tracking.Events`: EventID, source/target frames, Type and cell-valued parent/
child detection IDs. Weak components of each bipartite frame transition classify
continuations, appearances, disappearances, splits, merges and merge-splits.
Events describe transitions; the first frame establishes observations without
an appearance transition. Isolated detections are preserved. `farmLineageGraph`
constructs a digraph on demand, including isolated nodes.

## Seed-based lineage access

```matlab
history = farmSelectLineage(tracking, ...
    struct('ObjectIDs',61,'Frame',20),struct('Direction','ancestors'));
future = farmSelectLineage(tracking,struct('TrajectoryIDs',7), ...
    struct('Direction','descendants','IncludeSeed',true));
```

DetectionIDs are also accepted. Coordinates use N-by-3 YXZ plus Frame, with
Loader supplied to resolve current labels. Background returns an empty seed
selection with a status and recorded YXZ coordinates. Out-of-bounds coordinates
error. Input coordinates are integer voxel positions, not rounded physical
coordinates. IncludeSeed defaults true pending user testing.

Ancestors follows ONLY incoming parent edges, recursively. It does not turn
around at ancestors to include their other children. Descendants is the converse.
Both takes the union of those two traversals from the original seed, not the
entire weakly connected lineage. All parents of a merge are accessible even if
only one inherited its trajectory ID. No rerun backward in time is needed.

## Optional labels and field-query integration

`farmRenderTrackingFrame(objects,membership,options)` maps current object indices
to TrajectoryID. TIFF output is optional. ImageStackIO supports uint16 label
storage; larger IDs raise an error unless CompactIDs=true. Compact exports
store a sidecar ID map. Never discard the map or interpret compact stored IDs
as the original trajectories. farmTrackOverlaps' automatic export uses native IDs;
use explicit rendering for compact exports.

`farmAttachMembership(measurements,tracking.Detections)` joins DetectionID and
TrajectoryID by DatasetID/Frame/ObjectID, preserving destination row order.
Per-component query rows receive their parent's membership. Selection tables
can produce per-frame supports for ObjectRelativeProfiles queries. Position
is not required for subsequent field-density/geometry-relative sampling.

`farmSelectTrajectories` is post-tracking selection: MinDetections counts actual
observations; MinFrameSpan counts last-first+1. It never renumbers IDs or rewrites
the original lineage result. Filtering and ancestry are distinct operations.

## Trackpy core

See PYTHON_INTEGRATION.md for all completed and pending Python work.
`farmExportDetections` carries an explicit RowID map;
`farmImportLinks` accepts one-based RowID/TrajectoryID pairs in any order;
`farmTrackPositions` invokes the adapted Python bridge or an injected Linker.
Input detection tables must contain DatasetID/Frame/ObjectID/Centroid. Link
one dataset at a time. CoordinateScale can convert coordinates into physical
units without image resampling; SearchRange uses those same units. Memory is
Trackpy's missed-frame allowance. No merge/split inference is added.

## Preservation and tests

The historical overlap and graph scripts remain intact as provenance and
method references. Their experiment loading, graph-replacement prototypes,
display offsets and measurement orchestration have NOT been declared replaced
in full. Munkres is omitted from the new core; its old helper remains historical.
The original supplied Python script remains unchanged beside the old adapters.

Repaired converters/reconstruction preserve old entry points: tot2ts defaults
minimum observations to 1 and stores explicit TrajectoryID; ts2tot respects it;
farmConsObjMatSelTrajs writes its intended output. Original versions are in
archive/2026-10-13. Legacy farmAddFieldStruct2Traj remains positional and is NOT
recommended for new code: use farmAttachMembership and keyed measurement joins.

Run `results=runObjectTrackingTests()` from tests. Twelve synthetic tests cover
split/merge ancestry, policies, many-to-many ties, sparse IDs, empty frames,
seed selection, ID round trips, rendering and Python adapter mapping using an
injected linker. Actual Trackpy execution is not claimed tested. Dedicated
scientific examples/validation and larger-network performance remain pending.
