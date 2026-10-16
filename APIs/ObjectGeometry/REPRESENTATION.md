# Geometry representation as matrices

These helpers render geometry; they do not redefine the source geometry or measurements. Run farmSetup from the repository root. Matrix grids use YX/YXZ. Coordinate rows use one-based XY/XYZ voxel positions by default, not physical coordinates.

## Existing index geometry

`farmFieldOnObjs(values, matrixSize, indices, selected)` assigns one scalar per
object to an existing voxel-index list. `selected` is a logical array with one
row per object; `indices` must follow the column-major order of its true entries.
The output is double, zero outside those indices, and retains the last value
assigned at an overlapping index. The indices and selection array are also
returned unchanged. This preserves the author's supplied `fieldOnObjs.m` method
and is used by the historical endpoint rasterizer `farmCoords2Mat_2DFils`.

```matlab
selected = logical([1 1; 1 0]);
values = farmFieldOnObjs([10; 20], [2 3], [1; 2; 4], selected);
% values = [10 0 0; 20 10 0]
```

```matlab
[mask, grid, info] = farmGeometryToMatrix(supports.boundary);
labels = farmGeometryToMatrix(supports.objects, ...
    'ObjectIDs',[2 7], 'OutputType','labels');
```

Accepted inputs: farmPrepareObjects output or farmGenerateGeometry output, including boundaries, blob skeletons, sheet midplanes and sampled sheet points. The helper selects indices regardless of their original storage path. It allocates using Grid.Size and returns current grid calibration. SourceGrid/Transform provenance is retained in info when present.

Options: ObjectIDs=[] selects all; OutputType='mask' returns logical union or 'labels' returns double object IDs. Component pieces retain the parent ID. OverlapPolicy='error' is the default for conflicting labelled voxels; 'first'/'last' follow stored group order. Shared indices from the same ID are not conflicts. Mask union does not require an overlap rule.

IncludeFallback=false shows actual geometry. true adds a rounded centroid only for an empty geometry record with a stored fallback. info.IncludedFallbackCount distinguishes those additions. Boundary/skeleton masks are not filled interiors. Unknown selected IDs simply contribute no voxels.

## Coordinate points and segments

```matlab
grid = struct('Size',[100 120 40], ...
    'Axes','YXZ','Spacing',[.5 .5 1], 'SpacingUnit','um');
points = [60 50 20; 65 55 22]; % rows: X Y Z
[pointMask, grid, info] = farmPointsToMatrix(points,grid);
segmentMask = farmSegmentsToMatrix( ...
    points(1,:),points(2,:),grid);
```

farmSegmentsToMatrix takes N-by-D starts and matching ends; farmPointsToMatrix takes N-by-D points. Empty inputs are zeros(0,D). This endpoint interface can display idealized filament backbones after their coordinates are explicitly arranged into rows; it does not infer or fit filaments.

CoordinateOrder='XYZ' is default (XY in 2-D); 'YXZ' uses matrix-coordinate order (YX in 2-D). Rounding='nearest' is default, with 'floor'/'ceil' available. BoundsPolicy='error' checks rounded raster positions; 'omit' discards them outside the grid. No automatic rescaling, shifting or clamping is performed.

Segments interpolate at no more than half a voxel per coordinate, round and deduplicate samples, and include endpoints. Zero-length segments render as points. This is a visualization raster, not exact voxel-intersection geometry or a length measurement. Diagonal segments are not guaranteed face-connected. With omit, the rendered segment is clipped by discarding exterior raster samples.

## Gaussian width and optional threshold

```matlab
field = farmPointsToMatrix(points,grid,'Sigma',2);
mask = farmSegmentsToMatrix( ...
    points(1,:),points(2,:),grid,'Sigma',2,'Threshold',.05);
```

Both coordinate converters accept Sigma=0 (default), giving logical single-voxel occupancy. Positive sigma produces a double Gaussian occupancy field. Sigma is standard deviation in voxels, scalar or YX/YXZ vector. Zero vector entries disable smoothing along those axes. This does not make physical widths equal on an anisotropic grid.

The separable Gaussian is normalized and truncated at +/-ceil(2*sigma) along each smoothed axis, with zero exterior padding. Near grid edges, cropped field mass can decrease. Coordinates and source geometry remain unchanged. Duplicate points and overlapping segments are a union, not additive density.

Threshold=[] retains the field; a finite nonnegative threshold returns logical field>Threshold. Threshold choice controls apparent feature thickness as well as Sigma. Smoothed output is occupancy, not a calibrated probability and not smoothed object IDs.

The second output preserves grid metadata; the third records options, initial occupied voxel count and omitted point/sample counts. Keep info alongside broadened fields to record Sigma/Threshold. Omitted segment samples are not a count of omitted segments.

## Workflow inspection

Inside farmWorkflow1Objects after supports are constructed:

```matlab
boundaryMask = farmGeometryToMatrix(supports.boundary);
objectLabels = farmGeometryToMatrix( ...
    supports.objects,'OutputType','labels');
imagesc(boundaryMask(:,:,round(size(boundaryMask,3)/2))); axis image;
```

These functions do not write files. Save generated matrices only when requested, since dense arrays can be much larger than index geometry. Mesh rasterization remains in the separate SurfaceFieldMapping API.

Eight focused representation tests are included in testObjectGeometry, so runObjectGeometryTests and runAllTests include them. MATLAB execution requires confirmation in a licensed user session.

