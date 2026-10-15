# SegmentationTools: extraction candidates from workflows

Reviewed 2026-10-10 in the FARM checkout named `MeMo`.

## Scope and conclusion

Read the implementation bodies of all **73 MATLAB files** recursively under `Workflows/filaments` (39), `Workflows/objects` (16), `Workflows/segmentationAndImport` (8), and `Workflows/sheets` (10). These folders contain only `.m` files. This is a static code review, not MATLAB validation. No workflow or API code was changed by this review.

There are useful extraction candidates in all four folders. The best approach is to extract small array-to-mask or mask-to-mask operations and compose them in the existing workflows. Several operations are already functions in SegmentationTools or another API: those need consolidation or a clearer home, rather than another implementation.

The strongest initial candidates are:

1. Class probability thresholding and explicit resolution of overlapping/unassigned classes.
2. Connected-component selection, including size, border contact, and filament shape filters.
3. Binary and labeled-mask refinement, with explicit rules for label collisions.
4. Sheet refinement and separation into upper, lower, and intervening regions.

Names and signatures below are proposals, not implemented functions. Paths and line ranges refer to the local files at review time. `objects` remains the literal directory name; the morphology is called **spheroids** in this report.

## Where the API boundary belongs

| Operation | Recommended home |
|---|---|
| Probabilities/classes to masks; connected-component selection; correcting masks | SegmentationTools |
| File discovery, loading, saving, experiment/time loops, schedules | Workflows using ImageStackIO |
| Filament axes, lengths, orientations, skeletons, sheet point clouds, distance coordinates | ObjectGeometry |
| Assigning existing objects to sampled field values, distances, or regions | ObjectRelativeProfiles / FieldAnalysis |
| Maintaining object identities and heritage across frames | ObjectTracking |
| Meshing, remeshing, mesh curvature, field interpolation onto meshes | SurfaceFieldMapping and relevant geometry/field APIs |
| Colormaps, overlays, display-only dilation, rendered object values | VisualizationTools |

A mask can represent a segmentation, a sampled region, or a visualization. Its logical data type alone does not determine its API. In particular, filament property filters used only to select measurements should remain available to analysis without forcing a new segmentation.

## Proposed extraction groups

### S1. Threshold probabilities and resolve class assignments — first priority

**Sources**

- `Workflows/segmentationAndImport/BatchConvertH5toTif.m`: 55–85.
- `Workflows/segmentationAndImport/h5toTif.m`: 16–18, 33–48.
- `Workflows/objects/A_blobsFromH5s.m`: 64–86, especially summing selected probabilities at 66 and thresholding at 77.
- `Workflows/objects/blob-pipeline/B_blobsFromH5s.m`: 47–49, 59–67.
- `Workflows/filaments/sampleFilsInH5.m`: 43, 48–49 (filament threshold and maximum-probability class assignment).

**What can be isolated**

- Threshold each selected probability channel separately.
- Alternatively sum selected probabilities before applying a threshold.
- Return a logical mask per class and, optionally, one class-label volume.
- Resolve overlapping thresholded classes with an explicit priority or maximum-probability rule.
- Decide what to do when no class passes its threshold.

Suggested interfaces:

```matlab
mask = farmThresholdProbabilityGroup(probabilities, channels, thresholds, options)
[classMasks, classLabels, info] = farmClassifyProbabilities(probabilities, options)
```

Configurable inputs: `Channels`, `Thresholds`, aggregation (`sum` or independent), `ClassIDs`, `PriorityOrder`, overlap policy, unassigned/background label, optional ROI. A maximum-probability mode should explicitly define minimum confidence and tie handling. These policies are not interchangeable: summing probabilities before thresholding differs from taking the union of separately thresholded classes.

**Existing API overlap:** `farmImbinarize3_4D` already provides channel-wise thresholding. `farmH5toSmooth3Chans` already combines thresholding, cleanup, and the inside/outside/on convention. Build on those responsibilities rather than introducing parallel copies.

**Corrections needed before reuse**

- `h5toTif` line 26 loops over `1:numel(size(inData,4))`, which is only one iteration. The intended channel count is `size(inData,4)`.
- `BatchConvertH5toTif` resolves binary-mask ties through `max` and its first-index behavior, not through probability confidence. Its zero replacement at 85 derives a label from the observed unique values, so absent classes change the result or make indexing fail. Use an explicit class ID.
- Both converters combine segmentation with resizing and 8-bit display encoding. The extracted segmentation operation should return masks/class IDs; TIFF encoding belongs to the caller.
- A scale product of one does not imply that every scale factor is one; the current resize guards can miss anisotropic transformations.

### S2. Decode class labels and restrict masks to an ROI — small shared primitives

**Sources**

- `Workflows/objects/BC_tifs2CC.m`: 31 (`ismember` on selected stored class values).
- `Workflows/segmentationAndImport/batch_3SegSubsample.m`: 38–40 (existing three-class cleanup followed by ROI restriction and encoding).
- `Workflows/filaments/final-analysis/COMBINED_Fils2Aligns_InOnOut_TIFS.m`: 141–145.
- `Workflows/filaments/COMBINED_Fils2Aligns_InOnOut.m`: 240–246.
- `Workflows/filaments/final-analysis/prepareTifsForFilProps.m`: 90–95 (existing cleanup followed by output encoding).

Potential interfaces: `selectClassMask(classLabels, classIDs)` and `decodeClassImage(encodedImage, options)`, with explicit value-to-class mapping or bin edges, unknown-value policy, background value, and ROI. A direct `mask & roi` often needs no standalone wrapper.

Do not infer biological class meaning from sorted observed intensities. Keep categorical resampling nearest-neighbor. Preserve the distinction between class labels and individual object IDs. The many display/analysis scripts that decode 85/170/255 values can consume the same mapping without becoming segmentation functions.

### S3. LoG response thresholding — useful, but partly an optional scope extension

**Sources**

- `Workflows/filaments/A_extractFilsFromTifs.m`: 59–61.
- `Workflows/filaments/final-analysis/prepareTifsForFilProps.m`: 55–57.
- `Workflows/objects/blob-pipeline/B_blobsFromH5s.m`: 62–67.
- `Workflows/segmentationAndImport/generateBlobsFromH5Segs.m`: 37–44.

The filament scripts actually compute `-farmLOG(...)` despite comments calling the filter a top-hat. The spheroid variants apply LoG to probability fields, then threshold and fill/refine masks.

Suggested interface:

```matlab
[mask, response, info] = segmentLoG(inputVolume, options)
```

Options: Gaussian scale, response polarity, fixed versus automatic threshold, automatic-threshold lower bound, response scaling/normalization, erosion radius, hole-fill mode. Keep basic LoG thresholding separate from the more speculative multi-stage refinement in `generateBlobsFromH5Segs`.

**Existing dependency:** `farmLOG.m` is present under SharedUtilities/numerics, together with `farmGaussD.m` and `farmMyconvn.m`. Its source identifies it as third-party ImSAnE code; preserve its attribution when reusing it.

**Readiness:** the threshold-20 raw-intensity response and the probability/Otsu paths need separate, explicit threshold conventions. Do not assume a signed LoG response is a normalized probability. `generateBlobsFromH5Segs` later passes undefined `logicMat` and `reqFields` at 47, and its union of `moreBlobs | blobMat` needs review for whether it adds meaningful material.

**Scope decision resolved 2026-10-10:** filament segmentation supports both direct bright-on-dark intensity detection using the historical LoG route and segmentation from external probability fields. Ilastik is a common upstream source, not a SegmentationTools requirement.

### S4. Select components by size and shape — first priority

**Primary source:** `Workflows/filaments/h5Seg_FilamentPosOr.m`: 34–69.

This block thresholds a filament probability field, calculates connected-object properties, filters by aspect ratio and length, and returns a reduced connected-component structure and property table. It contains a real object-selection operation beyond the numerous scripts that merely plot filtered measurements.

Suggested separation:

```matlab
[selectedMask, selectedCC, keptIDs, info] = filterComponents(cc, properties, options)
```

Options: component size range, major-axis/length range, minimum aspect ratio, optional orientation limits, selection mode, and explicit units. The component structure and property rows must refer to the same component IDs. Compute the connectivity once and use that structure for both measurement and selection.

Keep detailed filament geometry in ObjectGeometry. A SegmentationTools convenience function may compute the few properties required for filtering, but should return the IDs/rejection reasons and should not require the entire downstream geometry pipeline.

**Other useful inline sources**

- `Workflows/sheets/splitSurfaces_Threshold.m`: 149–157 — keep components larger than a fraction of the largest.
- `Workflows/filaments/alignment-pipeline/display/Display_FilamentsAndBoundaries.m`: 51–57, 72–76, 91–98; the thesis-timeline variant has corresponding blocks.
- Both `Display3Channel_InOnOutFils3D.m` variants: 41–44, 59–63, 82–91 — reconstruct selected component voxels for rendering.
- `DisplayInOnOut_SparseOnDense2DSlice.m`: 60–63, 78–83, 101–110 — similar selection, then a display projection.

Those display scripts should consume a shared component selector; coloring, projection, region sampling, and rendering stay outside SegmentationTools. MATLAB's existing component-to-label operations may replace the manual `PixelIdxList`/index-vector reconstruction.

**Existing API overlap:** repair/generalize `farmRemoveConObjs` before creating a second size/rank selector. Its current 2-D branch uses `Area` but later accesses `Volume`; its index-selection branch also needs correction.

**Readiness:** `h5Seg_FilamentPosOr` calculates a scaled length at 55 but filters `allLens` at 57, and its aspect-ratio calculation has a bespoke eigenvalue/spacing formula. Choose one documented geometric definition and unit system. An anisotropic correction should operate on coordinates/covariance consistently, not simply apply an unexplained scale to lengths. The anisotropic PCA block at 96–119 of `COMBINED_Fils2Aligns_InOnOut_TIFS` is a geometry candidate, not a segmentation implementation to move wholesale.

### S5. Remove objects contacting the image border — first priority, compact

**Source:** `Workflows/objects/batch_RemoveEdgeObjs.m`: 24–29.

The script labels connected objects, identifies those intersecting a border band, and changes their output values.

```matlab
[kept, rejectedMask, rejectedIDs] = filterBorderComponents(maskOrLabels, options)
```

Options: input type (binary or object labels), border margin in Y/X/Z, selected faces, connectivity for binary input, retain or renumber IDs. Reject margins that exceed the image dimensions.

**Important behavior:** its `ghostObjVal` can leave rejected objects nonzero. A generic removal function should return rejected objects separately; ghost rendering should be an explicit caller choice. Do not run connected-component labeling on a labeled volume as though all nonzero labels were the same foreground: touching distinct IDs can merge.

### S6. Fill and smooth masks, with label preservation — high value, requires care

**Sources**

- `Workflows/objects/A_blobsFromH5s.m`: 77–96.
- `Workflows/objects/C_corrBlobBndsPost.m`: 39–73.
- `Workflows/sheets/cleanSegsAndFindSheets.m`: 17–20, 27–37.
- `Workflows/sheets/A_identifyFromH5_2DSheets.m`: 81–86.

Potential interfaces: `fillMaskHoles(mask, options)`, `refineMask(mask, options)`, and a separate label-preserving form of refinement. Options should expose operation order, fill planes versus full-volume fill, connectivity, structuring element, radii, smoothing scale/offset, and collision policy for labels. A sequence of explicit operations is preferable to one function with many unrelated booleans.

**Already extracted elsewhere**

- `farmFlatFill3D` in SharedUtilities/arrays performs planar hole filling; it is a plausible relocation/consolidation candidate.
- `farmSidesHoleFill` is already in SegmentationTools and handles boundary-open cavities using padding. This is a different policy from ordinary enclosed-hole filling.
- `farmReturnSmoothBlobsBW` and `farmReturnSmoothBlobsIDed` are in ObjectGeometry/objects. Their mask-refinement use should be reconciled with SegmentationTools without duplicating their implementation.

**Corrections/decisions**

- `C_corrBlobBndsPost` assigns each filled component the maximum overlapping original ID. If filling joins objects, that silently chooses one identity. Require an explicit collision rule (for example, error, preserve originals and assign only unambiguous additions, or an agreed overlap-based rule).
- `farmReturnSmoothBlobsBW` currently chooses `imgaussfilt` when the third dimension is greater than one and `imgaussfilt3` otherwise; inspect that branch before reuse. Its output uses only an upper distance threshold, despite shell terminology in its comments. Specify whether the output is a filled object or a shell.
- `cleanSegsAndFindSheets` computes `outData` from grayscale dilation/erosion, then thresholds the original `currData`. Extraction must decide which data the cleanup is intended to affect. Its cutoff of 100 on a double array also needs an explicit intensity scale.
- Unequal dilation/erosion radii are not an ordinary closing operation. Preserve the distinction in configuration.
- `farmFlatFill3D` unions fills computed from the original input across planes. A sequential fill using each intermediate result would be a different algorithm.

### S7. Exclusion-mask preparation — secondary utility

**Source:** `Workflows/objects/blobVolFractFromTifs.m`: 48–68, particularly dilation and alignment of the exclusion mask before the in/out intersections.

Potential operation: expand a supplied exclusion mask and apply it to segmentation masks. Inputs should include the exclusion mask, expansion radius/structuring element, and already aligned spatial arrays. Return excluded/retained masks; keep intensity and volume fractions in field analysis.

`BatchConvertH5toTif_DirtSub.m` is not a complete implementation of dirt subtraction: lines 20–22 select and extrude a dirt mask, but the active conversion loop does not use it. Its cutoff variable is also unused. Do not infer a working subtraction algorithm from its name. General 2-D-to-3-D mask extrusion, if needed, can be a shared array helper with explicit axis/depth.

### S8. Select object labels using seed points — small optional utility

**Source:** `Workflows/objects/IsolateBlobs.m`: 42–57 for the initial label lookup and mask selection.

```matlab
[selectedLabels, selectedIDs] = selectLabelsAtPoints(labels, points, options)
```

Options: point coordinate convention, rounding, out-of-bounds handling, and whether background is ignored. Specify XYZ point coordinates separately from YXZ array indices.

Only the static seed-to-label selection belongs here. The subsequent propagation of selection through time belongs in ObjectTracking, consistent with the README's isolation responsibility. If that is the only consumer, this can remain a private helper rather than becoming a public SegmentationTools function.

### S9. Repair and normalize sheet masks — valuable, staged extraction

**Sources**

- `Workflows/sheets/A_identifyFromH5_2DSheets.m`: 42–86.
- `Workflows/sheets/h5ToMesh_homeoAndSplit.m`: 68–105 and 120–130.
- `Workflows/sheets/splitSurfaces_Threshold.m`: 33–103 and 106–138.

Separate these responsibilities:

1. Split an initial binary mask using the existing configurable sheet-split function.
2. Fill missing sheet columns using a height-map representation.
3. Optionally normalize probabilities per spatial column against the selected sheet support, then rethreshold.
4. Reassign fragments and retain intended sheet components.

Potential interfaces: `patchSheetMask(mask, options)`, `normalizeSheetProbabilities(probabilities, support, options)`, and `reassignSheetFragments(topMask, bottomMask, options)`.

Options: sheet axis (initially Z only is acceptable if documented), inside/outside height convention, interpolation/extrapolation method, maximum hole extent, invalid-column policy, normalization floor/zero handling, rethreshold value/method, connectivity, expected component count, and fragment-assignment policy.

**Existing helpers:** `farmReturnCorrectedBinarizedSurfaceIndices` already lives in SegmentationTools. `farmConsPatchedSheetSurface_Flat` in SurfaceFieldMapping repeats the patched-height/probability interpolation used here; `farmConsScalerMat` in SharedUtilities provides a column-normalization denominator; `farmRescalePatch` in ObjectGeometry/sheets supplies an approximate resizing-based patch. These are candidates for consolidation, not three interchangeable patch algorithms.

**Limitations and observed issues**

- Height-map patching assumes a sheet can be represented along a chosen axis. Folds, multiple crossings, and large gaps need an explicit unsupported/ambiguous result.
- `A_identifyFromH5_2DSheets` lines 76–77 uses `botDiscInds` in both reassignment expressions; the intended top/bottom exchange must be resolved.
- Its paired smoothing expressions use morphological dual operations; establish whether they provide distinct results before preserving two configurable branches.
- `h5ToMesh_homeoAndSplit` 68–75 removes dilated remnants of eroded components smaller than the mean. This is a specific heuristic, not a general small-object removal rule. Expose erosion radius, size statistic/cutoff, and restoration radius if retained.
- In that script, cumulative arrays at 120–128 are calculated before `farmRescalePatch` may alter the masks; recompute them before region classification.
- Normalization can divide by zero in empty columns. Interpolation can produce invalid/out-of-range heights or values. Return a patch/uncertainty mask rather than silently treating interpolated voxels as directly classified evidence.
- The later hole-patching experiment in `splitSurfaces_Threshold` 200–266 initializes both perimeter and area masks to true, then removes all perimeter support; it also uses vector subscripts as though they were paired point indices. This section is not ready to move.

### S10. Build regions above, between, and below sheets — strong sheet candidate

**Sources**

- `Workflows/sheets/A_identifyFromH5_2DSheets.m`: 90–111.
- `Workflows/sheets/h5ToMesh_homeoAndSplit.m`: 120–145.

These blocks construct spatial regions from paired sheet masks using directional cumulative occupancy, select a central component, and assign residual material.

```matlab
[regions, info] = partitionSheetRegions(topMask, bottomMask, options)
```

Inputs/options: axis and top/bottom convention, center-component policy, connectivity, how to handle missing columns, crossed/overlapping sheets, and whether sheet voxels are excluded from adjoining regions. Return named masks or a labeled volume plus a documented lookup table. Require disjoint regions and explicitly identify unclassified/ambiguous voxels.

This belongs in morphology-specific sheet segmentation when its purpose is assigning image regions. Subsequent distance coordinates, skeletonization, sampling, and meshing remain separate. It should operate independently of file paths, MeshLab, and intensity-field sampling.

### S11. Seeded active-contour refinement — prototype candidate

**Source:** `Workflows/sheets/splitSurfaces_Threshold.m`: 160–175.

The script evolves an interior mask from a center-plane seed, then evolves another mask from a dilated shell seed. A small callable wrapper could accept `imageOrResponse`, `initialMask`, and options for method, iteration count, smoothing/bias controls, and optional ROI. Constructing a central-plane or shell seed can remain explicit in the sheet workflow.

Keep the two stages separate until their intended relationship is clear. The script later references undefined `test` at 178. Coordinate conversion to a point cloud at 167–168 is geometry. Compare this wrapper with the existing SegmentationTools active-contour scripts before choosing a single implementation.

### S12. Class-interface correction — later experimental candidate

**Source:** `Workflows/segmentationAndImport/batch_3SegtoPerims.m`: 48–65.

This block decodes/resizes a class image, computes distance transforms and gradients of inside/outside classes, finds nearby opposing gradients, and relabels the detected voxels as inside. Its subsequent distance-based perimeter extraction at 67–75 belongs with geometry/profiles.

Potential interface: `repairClassInterfaces(labels, options)` with inside/outside/target IDs, proximity cutoff, metric/spacing, and a diagnostic changed-voxel mask. Preserve the gradient rule as a named experimental policy rather than presenting it as generic mask cleanup. The current interpolated class image is re-binned using data-dependent histogram edges; replace that with a fixed class mapping and categorical resampling before evaluating the repair.

## Useful code that should be extracted elsewhere

- `rough_homeotropicThinning.m` 62–90 builds skeleton-derived points and filters their neighborhoods. This fits ObjectGeometry's explicitly stated homeotropic-thinning responsibility. `farmSkel3DPop` already implements part of this pattern. A general component-size selector can be shared, but the flattening/skeletonization and random sampling should not move into SegmentationTools.
- `B_generatePointClouds_SplitSheets.m` 33–37 and 50–54 selects sheet-adjacent interface voxels before point-cloud export/capping. Keep this with geometric surface construction. Similarly, `D_PlotMeshStats.m` 229–231 constructs a dilated display/perimeter shell.
- `DisplayGradPerim.m` in both alignment folders contains a nearest-object territory construction (201–210 in alignment-pipeline/display; 210–219 in the thesis variant). That is a morphology-relative region/coordinate operation, better placed with geometry/profiles. Its separate point-based object selection can consume S8.
- Filament centroids, principal axes, backbone coordinates, and anisotropic PCA belong in ObjectGeometry. Much of the recurring `regionprops` work is already represented by `farmStoreFilCCs`.
- Table filtering for orientation/length distributions and alignment statistics belongs with measurement selection. It can share an S4 predicate, but should not change the underlying segmentation by default.
- Temporal overlap, new IDs, merges, splits, and trajectory exports in `Workflows/objects` remain ObjectTracking workflows.

## Common configurable-input contract

- API functions take arrays, masks, labels, component structures, or explicitly paired property tables. They should not discover files, load metadata implicitly, or depend on variables in a script workspace.
- Follow `[Y X Z C T]` at the project boundary. Core spatial operations take one `[Y X Z]` volume; probability operations can take `[Y X Z C]`. The workflow selects time/channel or calls a documented wrapper. Never accidentally treat C or T as a spatial dimension.
- Distinguish probability thresholds, raw/filtered intensity thresholds, class IDs, and object IDs. Avoid silently normalizing input because that changes the meaning of configured thresholds.
- Expose connectivity for every operation that creates/selects components. For 3-D data, 6/18/26 changes which touching voxels form an object. Property calculation and returned component IDs must use the same connectivity and component ordering. Slice-wise 2-D analysis has a separate 4/8 convention.
- Use explicit voxel units initially; if physical units are supported, require `[Y X Z]` spacing and define structuring elements/distances in that metric. Point-coordinate tables often use XYZ, so conversions must be deliberate.
- Specify empty-input, no-component, missing-class, and ambiguous-result behavior. Return diagnostics such as kept/rejected IDs, changed voxels, interpolated patches, thresholds, and class mappings.
- A configurable function is still an ordinary MATLAB function. None of these proposals requires classes, static methods, or a new namespace conversion.

## Complete file coverage

`Extract` identifies an inline candidate described above. `Reuse` means consume/consolidate an existing operation or proposed shared primitive. `Other` means the useful work primarily belongs elsewhere. These are placement recommendations, not deprecation decisions.

### Workflows/filaments — 39 files

| File relative to this folder | Assessment |
|---|---|
| `A_extractFilsFromTifs.m` | Extract S3 LoG thresholding; axes/properties go to geometry. |
| `A_getFilamentStats_2Dand3D_FROMH5s.m` | Reuse S1 instead of the mixed `h5toTif` helper; remaining work is geometry and I/O. |
| `batch_densityDistributionAlongDeltaR.m` | Reuse existing three-class cleanup and S1; distance profiles/statistics remain outside. |
| `C_fil2ObjAlignment.m` | Reuse three-class cleanup; property filtering, gradients, alignment, and plots are other APIs. |
| `C_fil2ObjAlignmentQTensor2D.m` | Same segmentation reuse; 2-D tensor alignment is field analysis. |
| `C_fil2ObjAlignmentQTensor3D.m` | Same segmentation reuse; 3-D tensor alignment is field analysis. |
| `COMBINED_Fils2Aligns_InOnOut.m` | Reuse S1/S2 and existing cleanup; geometry, region sampling, and alignment remain outside. |
| `COMBINED_getFilamentStats2D.m` | Reuse S1; region properties, concatenation, and alignment remain outside. |
| `COMBINED_plotFilamentStats2D.m` | Other: distributions, measurement binning, order parameters, plotting. |
| `h5Seg_FilamentPosOr.m` | Extract S4 filament-component selection; reuse S1; geometry and plots stay separate. |
| `plotFilamentStats_2Dand3D.m` | Other: property-table assembly, filtering measurements, interpolation, plots. |
| `sampleFilsInH5.m` | Extract/reuse S1 class assignment; fractions and overlays remain outside. |
| `alignment-pipeline/AppendDensePropsToFilCCs.m` | Other: existing geometry helper, distance/gradient sampling at centroids; S2 mapping reuse. |
| `alignment-pipeline/rp3DAssignRBins.m` | Other: samples a field at centroids and displays it. |
| `alignment-pipeline/display/Display_AverageAlignment_InOnOutBin.m` | Other: filtered alignment statistics and display-only centroid dilation. |
| `alignment-pipeline/display/Display_AvgAlign_FromRBins.m` | Other: table aggregation, orientation/size selection, statistics, plots. |
| `alignment-pipeline/display/Display_Filaments2DCuts.m` | Other: geometry/gradient overlays; can share property-selection predicate. |
| `alignment-pipeline/display/Display_FilamentsAndBoundaries.m` | Extract/reuse S4 component selection/reconstruction; boundaries and rendering remain outside. |
| `alignment-pipeline/display/Display3Channel_InOnOutFils3D.m` | Extract/reuse S4 selection; region sampling and RGB rendering stay outside. |
| `alignment-pipeline/display/DisplayGradPerim.m` | Reuse S4/S8 selection; nearest-object territory, gradients, streamlines, and rendering are other APIs. |
| `alignment-pipeline-thesis-timeline/AlignmentOVERVIEW.m` | Other: comments outlining a workflow, no executable segmentation implementation. |
| `alignment-pipeline-thesis-timeline/AppendDensePropsToFilCCs.m` | Other: experiment-loop variant of geometry/field sampling; S2 reuse. |
| `alignment-pipeline-thesis-timeline/Display_AverageAlignment_InOnOutBin.m` | Other: alignment statistics and centroid rendering. |
| `alignment-pipeline-thesis-timeline/Display_AvgAlign_FromRBins.m` | Other: table aggregation and measurement statistics. |
| `alignment-pipeline-thesis-timeline/Display_FilamentsAndBoundaries.m` | Extract/reuse S4 as in the corresponding display variant. |
| `alignment-pipeline-thesis-timeline/Display3Channel_InOnOutCoMs3D.m` | Other: centroid rendering and field-based coloring; unused label construction is not a new algorithm. |
| `alignment-pipeline-thesis-timeline/Display3Channel_InOnOutFils3D.m` | Extract/reuse S4 as in the corresponding display variant. |
| `alignment-pipeline-thesis-timeline/DisplayGradPerim.m` | Reuse S4/S8 selection; territory and visualization belong elsewhere. |
| `alignment-pipeline-thesis-timeline/DisplayInOnOut_SparseOnDense2DSlice.m` | Extract/reuse S4 voxel selection; projection and field-based coloring remain outside. |
| `alignment-pipeline-thesis-timeline/rp3DAssignRBins.m` | Other: field sampling at centroids, with multi-experiment orchestration. |
| `display/PLOT_overlayAlignsAndGrads.m` | Reuse S2 mapping; vector rasterization and overlays are visualization. |
| `final-analysis/alignStatsOverTime.m` | Other: table concatenation, measurement filters, order statistics, plots. |
| `final-analysis/COMBINED_Fils2Aligns_InOnOut_TIFS.m` | Reuse S2 mapping; anisotropic PCA and field sampling belong elsewhere. |
| `final-analysis/ConcatTableQuantities.m` | Other: table assembly across time. |
| `final-analysis/prepareTifsForFilProps.m` | Extract S3; reuse three-class cleanup and S2 output mapping. |
| `final-analysis/display/Display_Filaments2DCuts.m` | Other: filament/gradient overlays, with measurement-selection reuse. |
| `measurements/B_prepareFilamentStats_2D.m` | Other: property assembly and backbone geometry. |
| `measurements/getMTLengthDist_From3DCC.m` | Other: length/orientation/volume measurement filters and histograms. |
| `measurements/getMTLengthDist.m` | Reuse S1 threshold; geometry and selection of measurements remain outside. |

### Workflows/objects — 16 files

| File relative to this folder | Assessment |
|---|---|
| `A_blobsFromH5s.m` | Extract/consolidate S1 and S6; separate labeling from property measurement and exports. |
| `B_blobTracking_StoreObjectProps.m` | Reuse threshold/label preparation at 77–92; heritage and identity assignment remain tracking. |
| `batch_RemoveEdgeObjs.m` | Extract S5. |
| `BC_tifs2CC.m` | Reuse S2 class-code selection; property storage remains outside. |
| `blobVolFractFromTifs.m` | Extract small S7 exclusion-mask operation; volume/intensity statistics remain outside. |
| `C_corrBlobBndsPost.m` | Extract/consolidate S6; resolve label preservation before reuse. |
| `C_trajsFromBlobs.m` | Other: object-property cutoff and trajectory generation. |
| `D_consTrajStruct.m` | Other: trajectory structure assembly and geometry properties. |
| `E_mergeTrajs.m` | Other: trajectory overlap/merging and reconstruction of tracked masks. |
| `F_getIntHists.m` | Other: trajectory selection, intensity distributions, and rendered output. |
| `IsolateBlobs.m` | Optional S8 static selection; temporal propagation remains tracking. |
| `blob-pipeline/B_blobsFromH5s.m` | Extract S1/S3/S6; retain method differences until behavior is validated. |
| `display/plotGlobalQuantities.m` | Other: volume/intensity/density calculations and plots from stored data. |
| `profiles/batch_densityDistributionAlongDeltaR_TIFS.m` | Reuse simple threshold; signed-distance coordinates, field profiles, correlations, and plots remain outside. |
| `trajectoryExports/tifsOfTraj_TOT.m` | Other: reconstruct/export masks for selected tracked IDs. |
| `trajectoryExports/tifsOfTraj_trajs.m` | Other: trajectory-structure variant of mask export. |

### Workflows/segmentationAndImport — 8 files

| File | Assessment |
|---|---|
| `batch_3SegPerimeters.m` | Reuse existing three-class cleanup; distance/perimeter extraction belongs to geometry/profiles. |
| `batch_3SegSubsample.m` | Reuse three-class cleanup and S2 ROI restriction/encoding. |
| `batch_3SegtoPerims.m` | S12 experimental interface correction; S2 decoding; keep perimeter sampling separate. |
| `BatchConvertH5toTif_DirtSub.m` | Limited S7 class selection/extrusion; active loop does not subtract the dirt mask. |
| `BatchConvertH5toTif.m` | Strong S1 extraction; file I/O/resampling/output encoding remain separate. |
| `generateBlobsFromH5Segs.m` | S3 prototype; undefined variables and refinement semantics need correction. |
| `h5toTif.m` | Strong S1/S2 split; already array-based despite its name, but channel-loop bug needs correction. |
| `multiDir_batchH5toTif.m` | Reuse replacement for `h5toTif`; file/experiment orchestration only. |

### Workflows/sheets — 10 files

| File relative to this folder | Assessment |
|---|---|
| `A_identifyFromH5_2DSheets.m` | Strong S9/S10; S1/S6 and existing sheet splitting reused. |
| `B_generatePointClouds_SplitSheets.m` | Other: interface point-cloud extraction, capping, exports, MeshLab execution. |
| `C_DataOnMeshes.m` | Other: mesh cleanup/geometry and field sampling; no image-mask segmentation extraction. |
| `cleanSegsAndFindSheets.m` | S6 cleanup candidate plus existing split helper; disconnected cleanup/threshold stages need resolution. |
| `constructSegmentationTifs.m` | Other: exports existing region masks; select mask fields explicitly if generalized. |
| `D_PlotMeshStats.m` | Other: curvature/intensity analysis, normal-offset field sampling, perimeter rendering. |
| `h5ToMesh_homeoAndSplit.m` | Strong S9/S10; separate skeletonization/meshing into geometry/surface workflows. |
| `splitSurfaces_Threshold.m` | S9/S11 prototypes, S4 size selection; later unfinished experiments remain for review. |
| `prototypes/rough_homeotropicThinning.m` | Other: skeleton/point-cloud geometry; reuse generic component selection where appropriate. |
| `prototypes/temp_LapSmoothField.m` | Reuse S1 in optional H5 branch; mesh geometry, field sampling/smoothing, and plots stay outside. |

## Recommended next implementation sequence

1. Settle S1's probability/class contract and consolidate its existing helpers. This benefits all four workflow groups.
2. Repair/generalize component selection, then extract the compact border-contact filter (S4/S5).
3. Extract the filament component selector using a single component/geometry identity mapping.
4. Consolidate hole filling and label-aware refinement (S6), explicitly defining collisions and smoothing semantics.
5. Finish configurable paired-sheet splitting, then implement S10's region partition and selected S9 refinement steps.
6. Keep LoG scope expansion, active-contour prototypes, and class-interface repair as separate review decisions.

This review proposes no deletions, moves, commits, or changes to historical algorithm defaults. Each extraction should retain its source workflow as a reference until its configurable behavior can be checked in MATLAB.
