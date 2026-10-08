# Proposed SegmentationTools tree

This is a first-pass organization of segmentation-related code already present in `Active Foam Archive`. It groups files by what they do before making keep/retire decisions. A file's current `Retired`, `One Off`, or `Test` location is recorded as review context, not used to exclude it from the functional inventory. This is a proposal, not a claim that files are ready to publish or runtime-validated. No archive files are moved or changed here.

```text
SegmentationTools/
├── README.md
├── src/+segmentationtools/
│   ├── +binarization/
│   │   ├── imbinarize3_4D.m
│   │   └── h5toSmooth3Chans.m              [candidate for a clearer array-oriented name]
│   ├── +cleanup/
│   │   ├── removeConObjs.m
│   │   ├── sidesHoleFill.m
│   │   └── dilateErodeSegWeights.m              [review: script-like]
│   ├── +activeContours/
│   │   ├── activeContourFrame1.m                [workflow/example candidate]
│   │   ├── activeContourFromH5.m                [workflow candidate]
│   │   └── generateFirstGuess_morphsnakes.m     [workflow/helper candidate]
│   └── +morphologySpecific/
│       ├── +sheets/
│       │   ├── getCentralSlice.m
│       │   ├── returnTopBottom2DSheets.m
│       │   ├── returnCorrectedBinarizedSurfaceIndices.m
│       │   └── splitSurfaces_Threshold.m        [workflow candidate]
│       └── +filaments/
│           └── storeFilCCs.m                    [component properties; boundary with ObjectGeometry]
├── workflows/
│   ├── batch_3SegPerimeters.m
│   ├── batch_3SegSubsample.m
│   ├── batch_3SegtoPerims.m
│   ├── constructSegmentationTifs.m
│   ├── generateBlobsFromH5Segs.m
│   ├── combine_2chanSegs.m
│   ├── A_extractFilsFromTifs.m                 [LoG filter + threshold; isolate reusable operation]
│   ├── h5Seg_FilamentPosOr.m                   [probability threshold + component filters]
│   ├── A_getFilamentStats_2Dand3D_FROMH5s.m
│   └── COMBINED_Fils2Aligns_InOnOut.m          [header reports current implementation does not work]
├── examples/
├── tests/
└── docs/
```

## Why these groups

- `+binarization` turns probability or intensity arrays into logical masks and separates multiple classes. MATLAB `+` folders make these nested package namespaces callable as part of `segmentationtools`.
- `cleanup` removes unwanted connected components and fills holes. `dilateErodeSegWeights.m` appears to be a dataset-oriented script and needs review before it can be treated as a reusable function.
- `binarization` is the broader group for binning/thresholding, whether it returns one mask or multiple class masks. `h5toSmooth3Chans.m` accepts a matrix and channel information, then returns three separate masks; despite its name, file reading belongs to ImageStackIO. Keep the existing filename in the inventory until any rename is deliberate.
- `+activeContours` groups contour evolution and initial-mask code. The current files include path setup and file I/O, so some may belong in `workflows/` after their reusable algorithm portions are separated.
- `+morphologySpecific` groups reusable algorithms that assume a shape family. The sheet helpers assume top/bottom sheet-like regions; the filament detector scripts are currently workflows, with their reusable operations to be extracted into `+filaments` only after source review. Keep these distinctions inside SegmentationTools for now, while reusable mask operations remain in the general-purpose groups.
- `workflows` holds batch or experiment-oriented orchestration. These scripts combine loading, thresholds, perimeters, saving, or object generation and should call ImageStackIO and SegmentationTools rather than duplicate their low-level behavior.

## Source mapping and review notes

| Proposed file | Current source in `Active Foam Archive` | First-pass disposition |
|---|---|---|
| `imbinarize3_4D.m` | `Manipulation - Matrices/imbinarize3_4D.m` | Candidate reusable threshold helper; its fourth-dimension meaning and threshold broadcasting need documentation. |
| `h5toSmooth3Chans.m` | `Manipulation - H5/H5 Functions/h5toSmooth3Chans.m` | Takes a matrix and channel information, returns three masks; candidate for `binarization`, not file I/O. |
| `removeConObjs.m` | `Manipulation - Matrices/removeConObjs.m` | Candidate reusable connected-component filter; likely depends on Image Processing Toolbox. |
| `sidesHoleFill.m` | `Manipulation - Matrices/sidesHoleFill.m` | Candidate specialized hole filling; source warns it is unsuitable for certain corner/connected topologies. |
| `dilateErodeSegWeights.m` | `Additional Functions/Active Contouring/dilateErodeSegWeights.m` | Review first: filename suggests a helper, but the file is script-like and contains experiment-specific setup. |
| `activeContourFrame1.m` | `Additional Functions/Active Contouring/activeContourFrame1.m` | Workflow/example; contains direct H5 and TIFF loading and a specific active-contour setup. |
| `activeContourFromH5.m` | `Additional Functions/Active Contouring/activeContourFromH5.m` | Workflow candidate; reads H5 and makes top/bottom active contours. Separate reusable contour logic from file and experiment assumptions if retained. |
| `generateFirstGuess_morphsnakes.m` | `Additional Functions/Active Contouring/generateFirstGuess_morphsnakes.m` | Candidate mask-generation helper, but currently loads and writes files; review before assigning to the public API. |
| `getCentralSlice.m` | `Additional Functions/Active Contouring/getCentralSlice.m` | Candidate sheet-specific helper; its criterion is tied to the sample geometry described in its header. |
| `returnTopBottom2DSheets.m` | `Additional Functions/Active Contouring/returnTopBottom2DSheets.m` | Candidate sheet-specific mask decomposition helper. |
| `returnCorrectedBinarizedSurfaceIndices.m` | `Additional Functions/Active Contouring/returnCorrectedBinarizedSurfaceIndices.m` | Candidate repair of missing surface-index locations; document interpolation assumptions and edge cases. |
| `splitSurfaces_Threshold.m` | `Additional Functions/Active Contouring/splitSurfaces_Threshold.m` | Workflow candidate; reads H5 and contains a particular threshold-based top/bottom surface procedure. |
| `batch_3SegPerimeters.m` | `Manipulation - H5/batch_3SegPerimeters.m` | Workflow, not a core segmentation primitive. |
| `batch_3SegSubsample.m` | `Manipulation - H5/batch_3SegSubsample.m` | Workflow combining H5 inputs, isolated-object masks, smoothing/subsampling, and output. |
| `batch_3SegtoPerims.m` | `Manipulation - Tiffs/Batch Process/batch_3SegtoPerims.m` | Workflow; its distance-transform and perimeter outputs are likely split between ObjectGeometry and workflow orchestration. |
| `constructSegmentationTifs.m` | `Analysis - Sheets/One Time Scripts/constructSegmentationTifs.m` | One-off conversion workflow; retain as an example/archive candidate, not a general API function by default. |
| `generateBlobsFromH5Segs.m` | `Analysis - Blobs/Functions/generateBlobsFromH5Segs.m` | Object-construction/import workflow candidate; likely spans image I/O, segmentation, and object labeling. |
| `combine_2chanSegs.m` | `SHG/combine_2chanSegs.m` | Experiment-specific channel-combination workflow candidate; review whether the operation is generic enough for this API. |
| `A_extractFilsFromTifs.m` | `Analysis - Filaments/A_extractFilsFromTifs.m` | Filament-detection workflow: applies a Laplacian-of-Gaussian filter, thresholds the response, then measures candidate objects. Extract its array-in/array-out detection steps into `+morphologySpecific/+filaments` after source review. |
| `h5Seg_FilamentPosOr.m` | `Analysis - Filaments/h5Seg_FilamentPosOr.m` | Filament-detection workflow: reads a probability channel, thresholds it, measures 3D components, and filters by size/aspect ratio. Keep H5 loading/saving in the workflow; assess its filtering algorithm for extraction. |
| `storeFilCCs.m` | `Analysis - Filaments/Functions/storeFilCCs.m` | Takes a binary filament image and computes 2D/3D component properties and directors. Candidate shared primitive; its boundary with ObjectGeometry should be decided after grouping. |
| `COMBINED_Fils2Aligns_InOnOut.m` | `Analysis - Filaments/COMBINED_Fils2Aligns_InOnOut.m` | Combined workflow candidate, but its header says the current implementation does not work because the prior filament detection source is no longer used. Preserve in the functional grouping for now; review separately before retaining. |
| `A_getFilamentStats_2Dand3D_FROMH5s.m` | `Analysis - Filaments/A_getFilamentStats_2Dand3D_FROMH5s.m` | H5-to-mask plus component-statistics workflow; useful source for identifying dependencies and reusable steps, not a public function as-is. |
| `getMTLengthDist_From3DCC.m` | `Analysis - Filaments/getMTLengthDist_From3DCC.m` | Downstream length-distribution analysis from existing component properties; include in the functional grouping pass, but it belongs with filament measurement/analysis rather than mask generation. |
| `getMTLengthDist_From3DBW.m` | `Analysis - Filaments/getMTLengthDist_From3DBW.m` | Header says not implemented; record with filament measurement candidates for review rather than removing it at this stage. |

## Keep in neighboring APIs

- `returnSmoothBlobsBW.m`, `returnSmoothBlobsIDed.m`, `returnSmoothBound.m`, `returnSmoothBoundsBW.m`, and `returnSmoothBoundsIDed.m` create geometric shells or boundaries from masks. They fit better in **ObjectGeometry**, which can expose distance and boundary representations consistently.
- `distTransFromBoundary.m`, `getDistGrads.m`, perimeter extraction, and measurements by distance from a boundary fit better in **ObjectGeometry** or **ObjectRelativeProfiles**, depending on whether they compute geometry or analyze sampled fields.
- H5/TIFF reading and writing belong in **ImageStackIO**. SegmentationTools should accept arrays and metadata rather than own format-specific readers.
- Mesh construction and mapping fields onto meshes belong in **SurfaceFieldMapping**.

## Related candidates in neighboring groups

- Chan-Vese vendor code and `ChenVese_Extracted.m` are absent from `Active Foam Archive` per the archive scope decision, so they are not listed here.
- 3D PIV and its velocity-processing functions remain outside this API family.
- `generateDirtMask.m` is in `Manipulation - Tiffs/Retired`, but its contents build a TIFF illumination-correction mask from corrected image intensities. It is better grouped with image correction than biological object segmentation; this is a functional distinction, not a deprecation decision.

## Scope and grouping recommendation

For now, distinguish sheets and filaments inside SegmentationTools as morphology-specific algorithm groups, while keeping generic binarization/cleanup at the top of the package. Keep droplet- or experiment-specific end-to-end pipelines in `workflows/`. If a shape family later has enough independent reusable algorithms, documentation, and users to stand on its own, it can become a separate API at the repository root; splitting it out now would mix API boundaries with an early inventory decision.

## Open design points for the next pass

1. Decide whether SegmentationTools includes only reusable array-in/array-out functions, with all current file-loading scripts kept under `workflows/`.
2. Decide whether the inside/outside/layer workflow is a core supported segmentation model or a project-specific example.
3. Review source dependencies and duplicate/variant status before selecting canonical implementations.
4. Define common input/output conventions (logical masks versus integer labels, spatial axes `[Y X Z C T]`, and voxel spacing) shared with ImageStackIO and ObjectGeometry.
