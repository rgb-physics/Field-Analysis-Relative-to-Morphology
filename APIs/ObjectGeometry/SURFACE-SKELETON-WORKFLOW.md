# Surface skeletons and oriented point export

This workflow extracts two-dimensional skeletal supports from segmented
volumetric layers, prepares physical XYZ points, and optionally estimates and
orients normals for point-cloud export. It does not reconstruct meshes, patch
holes, prune sheets, calculate curvature, or implement DEC. Reconstruction is
performed in MeshLab. Scientific real-data validation and retirement of the
historical two-sheet functions remain separate work.

## Functions and processing order

| Stage | Function | Result |
| --- | --- | --- |
| Fast historical extraction | `farmSkel3Dfrom2D(mask, preferredAxis)` | Union and intersection voxel supports |
| Optional historical population | `farmSkel3DPop(mask, fraction, cutoff, union, intersection, preferredAxis)` | Double-valued voxel support |
| Medial-surface extraction | `farmMedialSurface(mask, ...)` | Logical surface skeleton and convergence information |
| Coordinate preparation | `farmMaskToPoints(mask, ...)` | Physical XYZ points, source indices, coordinate metadata |
| Optional normal estimation | `farmEstimateSurfaceNormals(points, queryIndices, ...)` | Unsigned normals at selected queries |
| Optional spatial orientation | `farmOrientSurfaceNormals(queryPoints, normals, ...)` | Spatially oriented normals and group IDs |
| Optional reference directions | `farmSurfaceBoundaryDirections(mask, indices, ...)` | Center-to-background seed references |
| Optional cross-frame matching | `farmMatchSurfaceFrames(current, previous, ...)` | Correspondence indices and supplied rigid transform |
| Optional temporal sign alignment | `farmAlignSurfaceNormalSigns(normals, previousNormals, groups, matches, ...)` | Whole-group sign choices |
| Point export | `farmWritePointPly(filename, points, 'Normals', normals)` | Vertex-only ASCII PLY, with optional normal properties |
| Historical mask export | `farmLogic2Ply(mask, filename, scaleXYZ)` | Vertex-only PLY with historical one-based XYZ scaling |

`farmGenerateGeometry` also accepts `Method='medial-surface'`. Historical
`sheet` and `sheet-sampled` modes accept `PreferredAxis`. Identity, current-grid
indices, and component records retain the existing geometry contract.

## Extraction methods and provenance

The fast method retains the original flattened-reslice `bwskel` calculation,
including adjacency between flattened sections. It is not independent thinning
of each XZ/YZ section. `preferredAxis='Z'` reproduces the original calculation;
`'X'` and `'Y'` permute the input to use another approximate thin axis. Outputs
are returned in the original YXZ grid. The population function preserves the
historical random sampling, including the possibility of choosing union points
already in the intersection. Set `rng` to reproduce a selection. The distance
cutoff is in voxel units and applies only to supplemental union candidates.
Zero cutoff selects only union voxels, rather than accidentally sampling
background voxels.

The new medial method implements **P-6-SI-2** from:

K. Palagyi, G. Nemeth, P. Kardos (2015), *Equivalent Sequential and Parallel
Subiteration-Based Surface-Thinning Algorithms*, IWCIA, LNCS 9448, pp. 31-45.
[DOI](https://doi.org/10.1007/978-3-319-26145-4_3).

The transcription was checked against the author's accessible account:
K. Palagyi (2019), *Topology Preservation and Thinning*, section 3.3,
Definition 3.3.2 (type-2 protected points), Algorithm 11, Figure 3.9.
[Author's dissertation](https://www.inf.u-szeged.hu/~palagyi/PK_MTAdissertation.pdf).
The directional deletion templates originate with Gong and Bertrand; the cited
2015 work establishes the equivalent schemes and protected-point variants.

This is **not** the initially proposed 2002 three-subiteration algorithm: its
full templates could not be verified from accessible sources in this session.
No routine is attributed to that paper. The six-direction implementation uses
vectorized candidate tests and simultaneous deletion within each subiteration.
It requires Image Processing Toolbox, not Parallel Computing Toolbox.

One complete cycle uses U,D,N,E,S,W deletion directions. A voxel with an
opposite pair of background face-neighbors is protected. Each template requires
a background neighbor in the deletion direction, a foreground neighbor in the
opposite direction, and the face/corner implications from Figure 3.9. The
opposite neighbor is in the constraint set because its neighbor toward the
deletion direction is the still-foreground candidate. Evaluations use the
unchanged subiteration snapshot. Full six-direction cycles repeat to stability.

The exterior of the image is background. The method can thin material touching
the image edge; it does not assume that the cropped object is complete.
`MaxIterations` optionally limits work and `info.Converged` reports whether
stability was reached. `farmGenerateGeometry` refuses unconverged results.

This is a topology-preserving digital thinning scheme, not an exact Euclidean
medial-axis calculation or a guaranteed smooth manifold. Geometry remains grid
dependent. The implementation explicitly rejects anisotropic `Spacing`.
Resampling must be an explicit upstream decision with the corresponding
coordinate transform retained. Scaling extracted coordinates does not correct
anisotropic thinning. Local normal fits can use anisotropic calibration because
their input coordinates are physical XYZ values.

## Coordinates, sampling, and normals

Arrays and spacing use **YXZ**. Point rows and normals use **XYZ**.
`farmMaskToPoints` returns `indices=find(mask)` in corresponding row order:

```matlab
[points, indices, grid] = farmMaskToPoints(surface, ...
    'Spacing', [dy dx dz], 'Origin', [x0 y0 z0]);
% Origin is the physical position of voxel center (1,1,1).
% points = Origin + (voxelXYZ - 1).*Spacing([2 1 3]);
values = intensity(indices); % Intensity must be on this same grid.

% Reuse the existing rasterizer if a point selection must return to voxels:
voxelXYZ = (points-grid.Origin)./grid.Spacing([2 1 3]) + 1;
support = farmPointsToMatrix(voxelXYZ, struct('Size', grid.Size));
```

Point selection is ordinary row indexing. Preserve those row indices for fields
and source correspondence. No second point-selection framework is introduced.
`farmLogic2Ply` retains its different historical convention `voxelXYZ.*scaleXYZ`:
the first voxel is scaled too. For calibrated coordinates use the point writer.
Two-dimensional mask export uses z=0. No vertices are connected or filled.

Normal estimation is optional. Query indices select the points receiving fits;
the complete input cloud remains available as neighborhood support. An explicit
physical `Radius` and `MaxNeighbors` (default 32, including the query) bound each
fit. A KD tree returns at most K candidates, then the radius is applied: no
potentially unbounded radius-neighbor list or all-pairs distance matrix is built.
The implementation requires Statistics and Machine Learning Toolbox. A tree is
built once per operation; separate fitting, orientation, and matching calls
currently build their own trees. Queries/neighborhood arrays scale with Q*K;
normal fitting is performed only for Q selected query rows.

Local PCA follows the plane-fitting approach of Hoppe et al. (1992),
*Surface Reconstruction from Unorganized Points*, SIGGRAPH, pp. 71-78.
[DOI](https://doi.org/10.1145/133994.134011).
The smallest-eigenvalue eigenvector is an unsigned unit normal. The default
minimum support is six points. Insufficient or numerically degenerate fits
return NaN; neighbor counts, eigenvalues and validity are returned. There is no
automatic radius expansion and no hidden interpolation. A larger radius reduces
noise but averages bends and can include nearby folds; a smaller radius exposes
voxel noise. The routine does not certify that a neighborhood is on one sheet.

Spatial orientation constructs a capped KNN graph at an explicit physical radius.
`MaxNeighbors=12`, `MinAbsDot=0.25`, and `MaxNormalOffset=0.65` are initial
configurable settings, not scientifically calibrated constants. Edges are
rejected for weak normal-axis agreement or excessive displacement across either
tangent plane. A minimum spanning forest prefers aligned, tangential edges;
signs propagate locally, allowing a curved sheet to turn through more than 180
degrees. These guards are FARM additions to graph-based normal orientation and
do not guarantee correct connectivity across unresolved folds or contacts.

Supply `SourceMask` and corresponding `SourceIndices` to choose initial signs
from center-to-background references by default. The helper computes one nearest
background map, with exterior padding, rather than three gradient volumes.
Nearest background is selected in voxel distance; with anisotropy the scaled
vector is only an approximate sign reference. References seed each group once;
they do not force every point toward its nearest side. Alternatively supply
`ReferenceDirections` and optional preferred `SeedIndices`. Without a usable
reference the largest component of the seed normal is made positive, and
`info.Referenced` reports false. Open sheets have no intrinsic outward side.

Temporal matching and sign alignment are independent functions. Matching accepts
an optional proper rotation and translation from previous to current coordinates,
uses a maximum distance, and defaults to mutual nearest matches. It does not
infer material identity. Sign alignment rotates previous normals consistently,
then flips whole spatial groups only when enough matched evidence agrees.
Unresolved groups keep their spatial signs. No temporal processing is implicit
in estimation or spatial orientation.

## Example

```matlab
farmSetup('IncludeExamples', true);
result = exampleSurfaceSkeleton; % Synthetic cylindrical layer; writes nothing.
result = exampleSurfaceSkeleton(fullfile(tempdir,'sheet-points.ply'));
```

The example keeps the full skeleton internally and exports only selected query
points with valid normals. Every exported oriented point has a fitted normal;
there is no direction interpolation onto unsampled points.

For temporal alignment, after independently processing the next frame:

```matlab
matches = farmMatchSurfaceFrames(currentPoints, previousPoints, ...
    'MaxDistance', matchingRadius);
[currentNormals, temporalInfo] = farmAlignSurfaceNormalSigns( ...
    currentNormals, previousNormals, spatialInfo.Group, matches);
```

## Validation

`testSurfaceSkeletonWorkflow` covers historical equivalence and axis selection,
random population, coordinate/raster round trips, centered slabs, variable
thickness, cylindrical overlap, topology checks, convergence, anisotropy
rejection, oblique-plane fits, curved orientation past a half-turn, parallel-fold
separation, seed references, temporal transforms and conflicts, and PLY contents.
It is included in `runObjectGeometryTests` and `runAllTests`. These are synthetic
implementation checks; they do not establish scientific real-data accuracy or
authorize retirement of historical source files.

Local MATLAB R2023a checks on October 27, 2026 passed all 15 new tests, the 42
existing ObjectGeometry tests, and six layout tests. The synthetic example ran
end to end, including PLY export. In one warm-session run, a 128-by-128-by-64
variable-thickness layer containing 115,200 material voxels thinned to 13,246
skeletal voxels in six cycles, taking 0.074 seconds. This is one synthetic timing,
not a general performance guarantee or a peak-memory measurement.
