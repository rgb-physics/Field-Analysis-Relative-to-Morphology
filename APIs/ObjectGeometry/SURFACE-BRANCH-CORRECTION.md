# Branch-cut correction of surface flaps

`farmCorrectSurfaceBranches(points, sourceMask, options)` provides three
application-specific heuristics: `Method='extent'`, `'support'`, or `'both'`.
It returns an original-row subset and a table of all patch measurements and
decisions. This is not a published ET/SAT method or a topology-preserving
surface-pruning algorithm.

## Function inventory and status

| Function | Visibility | Responsibility | Verification |
| --- | --- | --- | --- |
| `farmCorrectSurfaceBranches` | Experimental public entry point | Patch/seam queries and extent/support branch-cut decisions | `testSurfaceBranchCorrection.m` |
| `farmSurfaceVoxelComplex` | Internal, shared with ET | Voxel-center lattice faces and tetrahedron/free-face collapses | Automatic-conversion and no-seam cases; ET adapter tests |
| `farmSurfacePriorityQueue` | Internal, shared with ET | Mutable min-heap for collapse/burning events | Exercised through automatic conversion and ET tests |

The public function is in `src/objectgeometry/surfaceSkeletons/`; shared helpers
are in `src/objectgeometry/internal/`. Path visibility does not make helpers
public APIs. `localCoverage` inside the public file rasterizes patch-ball unions.
`localCollapseTetrahedra` inside the lattice adapter performs sequential
collapses; `push`, `pop`, and `isEmpty` are queue closures, not separate APIs.
The historical namespace-to-function migration map does not list invented old
names for these new operations.

The editable glossary and data dictionary are
[GLOSSARY-CAPABILITIES.md](../../GLOSSARY-CAPABILITIES.md). Generated entries
appear on the [geometry reference page](../../docs/reference/geometry.md).
In MATLAB, use `farmGlossary("Branch correction result")` for the returned
structure, or `farmGlossary("UniqueSupportFraction")` for that measurement.

## Surface representation and candidates

The function accepts physical XYZ voxel centers on an isotropic YXZ source
grid. `Faces` can supply reviewed triangle connectivity. The automatic option
reuses the approximate Freudenthal lattice adapter used by ET, including
tetrahedron/free-face collapses for locally thick voxel supports.

An edge with more than two incident faces is a branch seam. Faces connected
across edges with exactly two incident faces form a patch. Connected seam
edges form one attachment seam. Candidate flaps must have a free border and
touch exactly one seam. Protected patches and patches attached to several
seams are retained. Original seam/shared points and points with no incident
surface faces are also retained.

This operates in full 3-D without an XY height field or global plane. However,
mesh conversion can create or miss seams. Inspect the colored patches before
interpreting removal. The mesh adapter's homotopy-preserving tetrahedron
collapses do not establish equivalence to the original voxel connectivity.

## Patch extent

`Extent` is the maximum shortest-path distance from any attachment-seam vertex
to a free-border vertex, measured along the patch's weighted triangle edges.
`MaxExtent` is in the same physical unit as `Spacing`. It measures the depth of
the patch away from attachment, not area, height, curvature, or straight-line
distance. The graph-edge approximation depends on triangulation.

## Source-volume support

Each support point has a ball with radius equal to its padded Euclidean
distance to a background voxel center. Open balls are rasterized on the source
grid and intersected with the segmented object. Shared point coverage stays
fixed; each patch contributes the coverage of its exclusive point rows.

`UniqueSupportVoxels` counts source voxels that would become uncovered when
that patch is removed from the initial collection. `UniqueSupportFraction`
divides this by the number of source voxels covered by that patch. It is a
representation test, not a direct measurement of biological validity or image
intensity. A genuine small flap can be redundant by this measure too.

Removals are sequential. Marginal loss is recomputed against the remaining
coverage, preventing two mutually redundant patches from both being discarded
without accounting for the combined loss. `MaxTotalLossFraction` limits new
coverage loss relative to the entire source-object voxel count, for every
method. Existing missing coverage is reported separately as
`InitialCoverageFraction`. No interpretation of "zero new loss" as complete
object reconstruction is implied.

## Selection, protection and preview

Candidates are ranked by extent for `extent`/`both`, and by unique-support
fraction for `support`. At least two patches remain incident to each seam.
This does not guarantee global topology, manifoldness, preservation of the
main ribbon, or that the correct two branches survive. A large flap can still
be retained; normal-continuation scoring is not implemented.

`ProtectedPointIndices` protects an entire patch containing those original
point rows. `Apply=false` returns the input unchanged while reporting
`Patches.WouldRemove` and `ProposedLossFraction`. `Apply=true` returns the cut
cloud and marks `Patches.Removed`. The returned `InputKept` and `OutputIndices`
preserve original-row and source-grid correspondence.

Patch IDs belong to a single call, not an acquisition or object identity.
`InputFaces` and `SeamEdges` always index original point rows. `PointPatch=0`
marks fixed/shared/unmeshed points. `DecisionLossVoxels=NaN` means the sequential
support check was not reached, not zero loss. `Reason="selected"` can describe
a proposed cut in preview mode; use `Removed` to determine actual application.

```matlab
% Preview only; pointGrid must describe the supplied sourceMask grid.
options = struct('Spacing', pointGrid.Spacing, 'Origin', pointGrid.Origin, ...
    'Method', 'both', 'MaxExtent', 12, 'Apply', false);
[unchanged, preview] = farmCorrectSurfaceBranches(points, sourceMask, options);
disp(preview.Patches(:, {'PatchID', 'Extent', 'UniqueSupportFraction', 'WouldRemove'}));

% Apply the same decisions after inspecting the candidate patches.
options.Apply = true;
[corrected, result] = farmCorrectSurfaceBranches(points, sourceMask, options);
```

## Calibration, inputs, and calculation cost

`Spacing` is YXZ physical units per voxel. `Origin` is physical XYZ of voxel
center (1,1,1), not its lower edge. Inputs must be unique voxel centers inside
the binary source object. `Area` uses squared physical units; `Extent` uses
physical units; voxel coverage counts convert to physical volume by multiplying
by `prod(Spacing)`. Fraction thresholds are dimensionless. Default `MaxExtent`
is 10; the frame-35 script explicitly selects 12 um as an initial test setting.

Empty/curve-only supports return unchanged points and a zero-row patch table.
An unattached surface is retained rather than being uniformly eroded.
Image Processing Toolbox is required; graph operations are native MATLAB.
No extra meshing or statistics toolbox is required.

Source-sized distance, coverage, and lattice-map arrays are allocated.
Overlapping patch footprints can collectively store more indices than the
source object's voxel count. Per-patch geodesic graphs and cropped dilations
can dominate cost when many patches are detected. Coverage is calculated even
for extent-only selection because the total loss guard applies to every method.
`Verbose=true` reports mesh preparation, patch counts, and every 100 coverage
queries; `ElapsedSeconds` measures wall time, not peak memory.

## Validation boundary

The branch section of `Examples and Workflows/analyzeSheetFrame35.m` runs
independently of ET/SAT. It provides separate figures for patch/seam labels,
proposed cuts, and corrected geometry. Its thresholds are starting values for
inspection, not calibrated scientific settings. Run the calculation section
again when changing the method or thresholds; rerun only display for plot edits.

`tests/testSurfaceBranchCorrection.m` checks removal of an attached third arm,
retention of the two ribbon sides, independent ball-reconstruction loss,
unique-support protection, loss budgets, preview, protected rows, physical
units, coordinate permutations, and no-seam behavior.
Empty and curve-only supports and MATLAB dictionary lookup for every returned
field/table column are covered too. Eight branch checks and fifteen existing
surface-workflow checks passed together in MATLAB R2023a. These are
synthetic contract/geometry checks, not scientific validation of the flap rule.
The 105714-point frame-35 preview was interrupted before completion because of
runtime; full-frame performance and acceptance remain unverified. The separate
experimental ET adapter has its own validation limits in
[surface pruning](SURFACE-PRUNING.md); passing branch tests does not certify ET.

Validation recorded on 2026-10-27: the combined branch, surface-workflow, and
experimental pruning run passed 32 of 33 checks. The separate ET check
`testETLocallyThickSheetAndSeparateFolds` still fails its finite-score assertion:
the collapsed thick-sheet complex retains some infinite ET values. That test
remains enabled and unchanged. All three branch-cut function files passed
MATLAB Code Analyzer without findings. Generated reference checks verify entry
locations, links, anchors, and expandable sections.
