# ObjectGeometry

Reusable measurements and index-based geometry for 2-D masks and 3-D volumes.
The [representation helpers](REPRESENTATION.md) convert index geometry, points
and line segments to masks/labels, with optional Gaussian point/segment width.

For the anisotropic filament-length check, add this API's examples folder and
run `report = farmValidateFilamentProjectedExtent;`. It compares a known 40 um
centerline against ProjectedExtent over elevations 0:15:90, azimuths 0/45/90,
XY spacing 1 um and Z spacing 0.25 or 2 um. CSV/MAT/PNG reports go to a fresh
tests/data/workflow-results folder. Native ExtentInVoxels is listed separately in
voxel units. Two angle-sweep regression tests are included in testObjectGeometry.
Oblique lines allow voxel-rounding error; these thin synthetic fixtures do
not establish robustness to noise, finite thickness, curvature or branching.
Target: MATLAB R2023a with Image Processing Toolbox. Run `farmSetup` from the
repository root to add API source folders and dependencies. Historical
`farmGetDistGrads` also uses SegmentationTools. Archived implementations live
outside the release in the sibling MeMo-Archive and should stay off the path.

## Identity and selected measurements

```matlab
opts = struct('DatasetID','experiment-1','Frame',12, ...
    'Spacing',[0.4 0.4 0.4],'SpacingUnit','um');
[properties,objects] = farmMeasureObjects(mask, ...
    {'Volume','Centroid','BoundingBox','PrincipalAxisLength'},opts);
```

`farmMeasureObjects` passes requested property names (including `'all'`) to native
`regionprops` for 2-D or `regionprops3` for 3-D. Property availability follows
the installed MATLAB release. All native properties are supported; potentially
large lists/images are returned only when requested. Native measurements remain
in pixel/voxel units. For native 2-D intensity properties, supply `Intensity`
with matching spatial dimensions. Native `regionprops3` has no grayscale input
argument; general 3-D field statistics belong in the later field-query API.

Inputs may be a binary mask, object labels, TIFF path, normalized ImageStackIO
image struct, `bwconncomp` structure, or a cell array of index groups. Numeric
zeros/ones default to a binary mask; use `InputType='labels'` to explicitly
preserve label 1 across disconnected pieces. Otherwise nonzero numeric IDs
are retained as one object per unique ID, whether connected or not. Classes
such as inside/wall/outside are NOT individual object IDs: select a class mask
before component measurement when individual entities are intended.

Index groups avoid constructing a full label volume:

```matlab
objects = farmPrepareObjects(indexGroups, ...
    struct('ImageSize',[100 120 40],'ObjectIDs',[7 42],'Frame',12));
properties = farmMeasureObjects(objects,{'Volume','Centroid'});
```

Prepared objects store membership indices, IDs and grid metadata. TIFF/image
inputs use `Channel=1`, `TimeIndex=1` by default; set them explicitly as needed.
ImageStackIO calibration is inherited unless overridden. Frame is an explicit
identity key and is not inferred from file names or TimeIndex.

Tables contain `DatasetID`, `Frame`, `ObjectID` plus selected properties.
Empty foreground produces a zero-row table. Tiny objects remain measurable;
no filtering is implicit. DatasetID defaults to `'default'`, so assign unique
dataset names before combining independent experiments. IDs are positive
integers through `flintmax`, preventing silent precision loss in joins.

## Filaments are image objects, not skeletons

```matlab
filaments = farmMeasureFilaments(objects, ...
    {'Volume','Centroid','Directors','ExtentInVoxels','AspectRatios'});
scaled = farmMeasureFilaments(objects, ...
    {'ScaledDirectors','ProjectedExtent','ScaledAspectRatios'});
```

The historical `farmStoreFilCCs` principal-axis calculation is reused. Directors
use XYZ (XY in 2-D), with Y increasing along image rows. Raw native 3-D
EigenVectors are retained unmodified; Directors apply the historical `[2 1 3]`
row conversion confirmed by the known-X-axis audit. Eigenvector sign is
arbitrary. Two-dimensional Orientation retains MATLAB's native degrees;
Directors convert it into image-coordinate vectors.

`ExtentInVoxels` preserves the historical voxel-unit major principal-axis length.
`AspectRatios` is major/second principal-axis length, not skeleton-sampled width.
Scaled properties reuse the coordinate-scaled covariance/eigenvector method
from `COMBINED_Fils2Aligns_InOnOut_TIFS.m`, WITHOUT resampling the matrix.
`ProjectedExtent` is max-minus-min projection of voxel centers onto the new
principal direction, in SpacingUnit. It is not equivalent-ellipsoid length.
`ExtentWidthFloor` defaults to positive `eps` in those units; set it explicitly
for a meaningful experimental width floor. Degenerate scaled principal axes
have NaN directors. Geometry never triggers skeletonization here.

## Local occupancy inertia at supplied locations

objects.localInertia(mask,indices,options) extracts the neighborhood tensor
calculation from blobPropsFromTrajs_R_Inertia.m. Users supply arbitrary current
grid indices, Radius, Sigma, optional Spacing/SpacingUnit, SampleLimit, and
BatchSize. Mirrored padding and smoothed total occupancy preserve neighboring
objects' contributions. Kernels/tensor axes are YXZ; optional spacing scales
their coordinates. Results retain indices, Computed flags, eigenvalues,
fractional anisotropy, eigenvalue ratios, grid metadata and optional tensors.
This is separate from vector-field covariance and global principal axes.
Skeleton generation/fallback is caller-owned. No geometry is generated here.
Bounded matrix batches compute neighborhood moments; each small tensor then
uses native eig. See Examples and Workflows/examples and runWorkflowExampleTests.

## Independent optional geometry

```matlab
shells = farmGenerateGeometry(objects,'boundary', ...
    struct('LayerMean',0,'LayerWidth',1,'Sigma',1));
cores = farmGenerateGeometry(objects,'skeleton', ...
    struct('Method','blob','GradientCutoff',0.2,'Sigma',1,'Hessian',false));
```

Output `Records` contain DatasetID/Frame/ObjectID/ComponentID, current-grid
Indices, Status and optional Fallback. Objects with a disconnected lineage ID
get separate component geometries while keeping their parent ID. Each method
runs on an isolated component bounding box with a background halo; resulting
indices are mapped back and clipped to the current image grid. Component IDs
are local to that representation and are not tracking identities.

An empty skeleton has Status=`empty`, no indices, and centroid/principal-axis
fallback metadata. An unrequested representation is absent. Geometry output
stores Grid.Size, Axes, Spacing in YXZ order and SpacingUnit, plus optional
SourceGrid and Transform. Linear indices are meaningful only on this grid;
if membership/grid changes, regenerate geometry. The API never silently rescales
the input or updates source metadata by guessing a transform.

Historical methods retained:
- `blob`: `farmSkel3DBlobs` interrogation cores; requires gaussdiff's external
  `gfilter`. Missing dependency raises an informative error. Sigma is an
  integer voxel radius because the historical method uses spherical erosion.
- `sheet`: `farmSkel3Dfrom2D` union/intersection; retains the historical flattened
  reslice construction and is NOT claimed to generalize arbitrary sheet shapes.
- `sheet-sampled`: `farmSkel3DPop` random subpopulation. Set `rng` for reproducibility.
  `randperm` replaces `randsample`, removing the Statistics Toolbox dependency.
- `boundary`: two-sided signed-distance shell from `farmReturnSmoothBoundsBW`.
  `farmReturnSmoothBoundsIDed` remains available for historical fast/slow ID assignment.

Shell/core scientific validation and general sheet-midplane design remain
pending. BoundsBW/BoundsIDed are geometric shells; the BlobsBW/BlobsIDed
compatibility functions remain SegmentationTools mask-cleanup operations.

## Reusable distance gradients

```matlab
[gradients,meta,valid] = farmDistanceGradients(distanceField, ...
    struct('Sigma',1,'SmoothingOrder','gradient-first','Normalize',false));
[gradients,distanceField,meta,valid] = farmObjectDistanceGradients( ...
    mask,struct('DistanceType','signed','Sigma',1));
```

DistanceType is signed/interior/exterior. Signed reuses your `farmSignedBWDist`
convention: object boundary zero, deeper interior negative. Gradients are
`[Y X Z D]` with XY or XYZ components; no Y flip unless `FlipY=true`.
Sigma is a scalar or spatial vector in voxel units, all positive or all zero.
Gradient-first preserves historical gradient-then-Gaussian-smoothing behavior;
distance-first is selectable. Normalize optionally returns unit vectors and a
validity mask; zero vectors stay zero and invalid. Empty/full masks with an
infinite distance field return NaN gradients and false validity.

Spacing is recorded; `DerivativeUnits='physical'` divides derivatives by grid
spacing, but DOES NOT correct an anisotropic voxel-distance transform. Its
distance values are still in voxel units. Physical distance transforms remain
deferred. Smoothing sigma is always in current voxel units.

## Nematic alignment

```matlab
alignment = farmNematicAlignment(directors,normals);
projected = farmNematicAlignment(directors,normals, ...
    struct('Plane',[1 2],'MaxNormalComponent',0.5));
```

Uses the Display_AvgAlign_FromRBins ordering: normalize, optionally select by
ABSOLUTE normal component, project, renormalize, dot, calculate order.
2-D order is `2*dot^2-1`; 3-D order is `(3*dot^2-1)/2`. Unsigned separation is
`acos(abs(dot))`. SignedAngle is defined only in an ordered 2-D plane, as the
director angle minus reference angle modulo pi in `[-pi/2,pi/2)`. Invalid zero
vectors/projections return NaNs with Valid=false. Plane/component ordering must
be the same for both fields. No polar orientation or head-tail differentiation.
Aggregation and arbitrary field sampling are separate future API work.

## Safe concatenation and late-added fields

```matlab
combined = farmConcatenateMeasurements({frame1,frame2});
combined = farmAttachMeasurements(combined,newQueries);
```

Frame tables require matching schemas; metadata from EVERY frame is retained
in Properties.UserData.FrameMetadata. Keys must be unique. NewQueries contains
DatasetID/Frame/ObjectID plus new columns; attachment matches KEYS, preserves
destination order, and rejects duplicates and missing matches by default.
Extra query rows are allowed for filtered destination tables. MissingPolicy=
`'missing'` explicitly allows absent results (numeric NaNs, missing strings,
empty cells); integer/logical missing columns become double to retain NaNs.
Overwrite=true explicitly allows replacement. No positional column assignments.
Query results must be generated for the same object membership/grid revision;
keys alone do not establish spatial compatibility. Grid matching is checked
where fields are sampled, not guessed during table joins.

## Tests, examples and compatibility

From `tests`, run `results=runObjectGeometryTests(); table(results)`.
The suite covers new measurement/storage/gradient/alignment operations, known
axis conventions, disconnected labels, empty masks and shell smoothing. It does
not claim coverage of every historical prototype or the external gfilter
algorithm. `examples/exploreObjectGeometry.m` produces real-data shell and
gradient previews for visual assessment. Runtime verification is required in
your licensed MATLAB session; initial verification used MATLAB's code analyzer.

Original implementations updated in this pass are retained under
`archive/2026-10-12` with original names. Active entry points remain compatible:
`farmBlobMat2CCProps`, `farmStoreFilCCs`, `farmGetDistGrads`, `farmDistTransFromBoundary`,
`farmReturnSmoothBoundsBW`, `farmReturnSmoothBoundsIDed`, `farmSkel3DBlobs`, `farmSkel3DPop`.
Their repairs address 2-D property storage, empty outputs, package-qualified
dependencies, shell Gaussian dispatch and Hessian candidate indexing. Other
historical functions/workflows remain active; no scientific method was retired
solely because a newer interface exists.

Deferred: general sheets/midplanes, field-query reductions, filtering,
anisotropy/PSF corrections, head-tail polarity and final direct-intensity
filament-segmentation validation in SegmentationTools.

Filament property naming: `ExtentInVoxels` replaces the derived `Lengths`
request/output in the current API. It remains the native equivalent-ellipsoid
major-axis length, in voxel units; it is not a voxel-center projected span.
Update requests and saved-table consumers to the new name. Historical workflow
scripts and their stored fields retain their original names.
`ProjectedExtent` instead measures the voxel-center span along the principal
axis fitted after scaling coordinates by voxel spacing, in `SpacingUnit`.
It is useful for straight-filament length estimation, but is not a contour
length or a correction for optical blur or segmentation error.
For a single voxel only, it uses `ExtentInVoxels` multiplied by spacing along
the arbitrary native director. This finite fallback is recorded in table
`Properties.UserData.PointExtentFallbackObjectIDs`; `ScaledDirectors` stays NaN.