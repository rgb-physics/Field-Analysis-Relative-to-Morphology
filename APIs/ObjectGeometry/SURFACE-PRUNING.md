# Experimental surface pruning

`farmPruneSurface(points, sourceMask, options)` supports `Method='ET'` and
`Method='SAT'`. Points are physical XYZ voxel centers; the source object is a
binary YXZ volume on an explicitly calibrated isotropic grid. The original
volume supplies padded interior distances. No height-field projection or
single-valued Z assumption is used.

These are **discrete experimental approximations**, not exact continuous
medial-axis algorithms. Neither option promises topology preservation.
Point clouds from an object's interface are accepted, but do not become medial
axes merely by supplying the object's mask. Prefer an actual medial support
when testing the methods' intended geometric behavior.

## ET

The implementation follows the sector-burning logic of Figure 8 in
[Yan et al. (2016), Erosion Thickness on Medial Axes of 3D Shapes](https://www.cs.wustl.edu/~taoju/research/et.pdf):
boundary vertices start at their radius, arrivals propagate along surface arcs,
and a junction burns only after sufficiently many incident sectors burn to
expose its remaining sectors. Closed sheet cores retain infinite burn time.
ET is burn time minus radius. `ETThreshold` retains original points with ET at
least that threshold, in the physical unit of `Spacing`.

This uses a triangle-edge graph, rather than the paper's full graph with
Steiner samples and cross-triangle arcs. `ETSubdivisions` refines triangles and
interpolates radii before burning. The published Steiner-graph error bound is
not claimed. The medial-curve augmentation and topology-preserving contraction
from the paper are not implemented: simple thresholding can disconnect a sheet.

Supply `Faces`, an M-by-3 array indexing input point rows, when surface
connectivity is known. Without it, a fixed Freudenthal lattice triangulation
constructs a local surface complex. It does not join points by Euclidean KNN.
The shared internal `farmSurfaceVoxelComplex` adapter reduces occupied lattice
tetrahedra with tetrahedron/free-face collapses; it does not wrap each occupied
tetrahedron in a false closed shell. Points left without incident faces receive
zero sheet ET, rather than invented faces. Remaining uncollapsible tetrahedra
still produce an actionable error. The conversion can produce nonmanifold
complexes and retained infinite-ET cores; it is not a guaranteed medial-sheet
reconstruction. Digital connectivity is not automatically equivalent to the
topology of this triangle complex. Inspect `InputFaces` and `MeshPreparation`
before interpreting ET. Supplied Faces bypass this automatic conversion.

Returned `InputKept`, `OutputIndices`, `Radii`, `BurnTime`, and
`ErosionThickness` correspond to original input rows or the documented source
grid. Refinement points are used for calculation, not added to the output cloud.

## SAT

The construction follows grow–recompute–shrink from
[Miklos et al. (2010), Discrete Scale Axis Representations for 3D Geometry](https://www.cs.jhu.edu/~misha/ReadingSeminar/Papers/Miklos10.pdf).

1. Sample object radii at the selected support, measured to background voxel
   centers. Construct the rasterized union of open balls with radii multiplied
   by `Scale`. A halo prevents clipping at the original image boundary.
2. Recompute the grown object's surface skeleton using `farmMedialSurface`.
3. Calculate radii at the new centers and divide them by `Scale`. The centers
   themselves are not shrunk or snapped back to original points.

This is SAT applied approximately to the selected support's ball representation.
The support may not reconstruct the whole original volume, its points need not
be maximal-ball centers, and FARM thinning is not an exact medial-axis solver.
Thus it is not the paper's exact union-of-balls algorithm. `Scale=1` explicitly
returns the input unchanged. At larger scales, points can move, point counts can
increase, and folds can merge. SAT is not guaranteed to produce a subset.

`Radii` contains the shrunk radii. `OutputIndices` refers to `OutputGrid` on the
padded raster; `InputKept=[]` prevents false original-row correspondence.
`ReturnReconstruction=true` also returns the shrunk-ball union on that raster.
`MaxVoxels` limits padded raster size, not peak memory. Several volume-sized
arrays and temporary dilation kernels are allocated.

## Use

```matlab
options = struct('Method', 'ET', 'Spacing', grid.Spacing, ...
    'Origin', grid.Origin, 'ETThreshold', 5);
[etPoints, etInfo] = farmPruneSurface(points, objectMask, options);

options = struct('Method', 'SAT', 'Spacing', grid.Spacing, ...
    'Origin', grid.Origin, 'Scale', 1.2);
[satPoints, satInfo] = farmPruneSurface(points, objectMask, options);
```

The editable `Examples and Workflows/analyzeSheetFrame35.m` has separate
calculation and display sections for choosing a cloud, running one or both
methods, and comparing their results to the original points in 3D.

Focused checks are in `tests/testSurfacePruning.m` and the ObjectGeometry test
runner. They cover planar ET, a nonmanifold three-sector junction, physical
units, closed cores, scale-one identity, SAT halo coordinates, and invalid grids.
Synthetic checks do not establish scientific suitability for the sheet dataset.

Known validation issue (2026-10-27): `testETLocallyThickSheetAndSeparateFolds`
still fails its assertion that every ET score is finite after lattice collapse.
Some infinite scores remain on that nonmanifold thick-sheet complex. The test
is retained unchanged; the full pruning suite is not claimed to pass. This is
separate from the passing branch-correction tests and their coverage queries.
