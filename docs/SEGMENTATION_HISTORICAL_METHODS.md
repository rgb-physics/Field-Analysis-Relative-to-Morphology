# SegmentationTools historical methods and implementation decisions

Recorded 2026-10-10 from the FARM workflow review. This document identifies
historical algorithms to preserve for comparison, the first public
implementations, and work intentionally deferred.

## Current data contract

- Spatial arrays are `[Y X Z]` (row, column, depth).
- Probability arrays are `[Y X Z C]`, with one probability field per channel.
- ImageStackIO normalizes complete images to `[Y X Z C T]`.
- A TIFF probability wrapper returns one `[Y X Z C]` time point. ImageJ
  metadata is honored. YXZT data is reinterpreted as YXZC only when the caller
  explicitly sets `TimeAsChannels=true`; time and class channels are not
  silently interchanged.
- HDF5 inputs are normalized by ImageStackIO before segmentation. HDF5 files
  without the supported axis attribute require an explicit `SourceAxes` value.
- Threshold comparisons are strict (`probability > threshold`). Probability
  arrays are assumed to be normalized upstream and are not renormalized.
- The default classifier is disjoint but not necessarily exhaustive. Voxels
  passing no threshold retain label zero. `AssignUnclassified=true` assigns
  them to their greatest selected class score.
- Exact score ties are resolved by the order of the supplied class definitions.

For the closed-wall semantic convention:

| Full name | Historical shorthand | Default ID |
|---|---:|---:|
| inside | in | 1 |
| wall | on | 2 |
| outside | out | 3 |

`wall` is segmented wall material. A boundary/periphery is an interface
between regions, such as the inside-wall interface. A skeleton is a centerline.
A midplane is a center-plane representation defined relative to an explicit
Cartesian axis; later homeotropic thinning supports less axis-dependent sheet
representations.

## Distinct representations

FARM does not use all nonzero image arrays as the same kind of mask:

- A binary mask is a logical membership field for one region.
- A class-label volume stores one semantic class ID per voxel, with a class
  lookup table.
- An object-label volume stores one connected-object ID per voxel.
- A lineage-label volume stores trajectory IDs; merge and split relationships
  remain in an associated lineage table because one voxel value cannot encode
  the full history.
- A probability volume is floating-point `[Y X Z C]` data.

Optional full-size representations are constructed only when requested.
`farmRemapClassLabels` maps class IDs to user-selected stored values. Historical
85/170/255 encodings can therefore remain interchange formats rather than the
authoritative definition of class meaning. `farmWriteMaskTiff` performs file output
only when called and supports `[Y X Z]` masks/labels or `[Y X Z C]` ImageJ
hyperstacks through ImageStackIO.

## Implemented first-pass functions

| Function | Responsibility |
|---|---|
| `farmMakeClasses` | Distribute channel/threshold arrays into semantic class definitions; grouped channels use cells. |
| `farmThresholdProbabilityGroup` | Strict summed-channel or independent-threshold/union classification for one class. |
| `farmClassifyProbabilities` | Resolve arbitrary class candidates, using maximum aggregate probability and definition order for ties. |
| `farmClassifyProbabilityChannels` | Treat selected channels as distinct classes; an empty channel selection means all channels. |
| `farmSegmentInOnOutProbabilities` | Semantic `[inside wall outside]` convenience wrapper. |
| `farmSmoothInOnOutProbabilities` | Clearly named historical three-class opening workflow. |
| `farmRemapClassLabels` | Map default class IDs to requested integer storage values. |
| `farmReadProbabilityTiff` | Read one probability time point as `[Y X Z C]`; optionally reinterpret T as C. |
| `farmWriteMaskTiff` | Optional TIFF output for logical/categorical masks. |
| `farmFlatFill3D` | Historical independent planar fills along selected axes. |
| `farmReturnSmoothBlobsBW`, `farmReturnSmoothBlobsIDed` | Historical signed-distance cleanup, moved into SegmentationTools. |

Compatibility wrappers remain at:

- `APIs/SegmentationTools/src/segmentationtools/binarization/farmH5toSmooth3Chans.m`
- `APIs/SegmentationTools/src/segmentationtools/cleanup/farmFlatFill3D.m`
- `APIs/SegmentationTools/src/segmentationtools/cleanup/farmReturnSmoothBlobsBW.m`
- `APIs/SegmentationTools/src/segmentationtools/cleanup/farmReturnSmoothBlobsIDed.m`

The old `farmH5toSmooth3Chans` signature retains channel order
`[outside inside wall]` and output order `[inside outside wall]`. New functions
use semantic order `[inside wall outside]`.

## Historical thresholding and classification methods

### Independent channel thresholds

Each probability channel is compared with its configured threshold. This occurs
in `farmImbinarize3_4D.m`, `BatchConvertH5toTif.m`, `h5toTif.m`, filament HDF5
workflows, and several in/on/out workflows. It naturally permits overlaps and
unclassified voxels.

### Independent threshold followed by union

Selected channels are thresholded separately and their logical masks are
unioned. This expresses “any of these probability classes,” and is distinct
from thresholding their sum. `farmThresholdProbabilityGroup` exposes this as
`CombineMethod="union"`, with either one shared threshold or one threshold per
channel.

### Sum selected probabilities before thresholding

`A_blobsFromH5s.m`, `blob-pipeline/B_blobsFromH5s.m`, and related workflows sum
selected probability fields before thresholding. This allows several moderate
probabilities to jointly exceed one threshold. The new implementation does not
renormalize the sum.

### Maximum probability classification

`BatchConvertH5toTif.m`, `h5toTif.m`, and `sampleFilsInH5.m` contain variants
that select the maximum channel. The generalized classifier first determines
eligible class candidates, then chooses the greatest class score. Exact ties
select the first class definition. When exhaustive assignment is requested,
the same rule is applied to voxels below every threshold.

For a summed class, its score is the sum of its selected channels. For an
independent-union class, its score is the maximum selected-channel probability.

### Historical in/on/out opening

`farmH5toSmooth3Chans.m` thresholds inside and outside channels, performs erosion
followed by dilation with a spherical structuring element, and removes cleaned
inside voxels from outside. Wall is either independently thresholded/opened or,
when `spanBool` is true, defined as the complement of inside and outside. The
independent-wall result can overlap inside/outside. This is preserved by
`farmSmoothInOnOutProbabilities` for comparison.

### Encoded categorical TIFFs

Some later workflows read already classified TIFFs and use fixed values or
histogram bins to recover inside/wall/outside classes. This is class decoding,
not probability thresholding. New code should use explicit value-to-class maps
instead of deriving meaning from the sorted values observed in one image.

### LoG followed by a fixed threshold

`A_extractFilsFromTifs.m` and `prepareTifsForFilProps.m` calculate `-farmLOG` on
bright-on-dark microscopy intensities and apply a fixed response threshold.
This is direct filament segmentation and does not require external pixel
classification. It is retained as the initial direct-image filament method.

### LoG followed by automatic/fixed lower bound

`blob-pipeline/B_blobsFromH5s.m` and `generateBlobsFromH5Segs.m` use variants of
`max(graythresh(response), fixedThreshold)`. These are recorded for historical
comparison. Automatic threshold selection is not included in the first public
API; a graphical threshold-testing aid may be added later.

### Sheet-specific normalization and thresholding

`A_identifyFromH5_2DSheets.m` and `splitSurfaces_Threshold.m` patch or select a
sheet support, normalize probability values by column, and rethreshold. These
methods depend on a dominant Cartesian sheet axis and remain separate from the
general channel classifier.

### Experimental class-interface repair

`batch_3SegtoPerims.m` detects close inside/outside distance gradients with
opposing components and changes the intervening class. Its intended correction
is removal of erroneous background layers between interiors and walls. Preserve
the method for later comparison; ambiguous interface assignment will use a
watershed-based policy when it is made configurable.

## Cleanup timing

Independent cleanup operates on each thresholded class before conflict
resolution. It permits class-specific operations and can create new overlaps.
Final categorical cleanup operates after resolution and must state which class
owns voxels created by dilation/filling. Both stages are legitimate and remain
explicit rather than being silently combined.

Native MATLAB opening, closing, erosion, and dilation remain available to
workflows. FARM-specific planar filling, connected-component behavior, and
label-aware operations are implemented explicitly. The first planar-fill
implementation follows `farmFlatFill3D`: each requested directional fill is
computed from the original mask and the results are unioned.
For YXZ arrays, the existing kernel permutations select 0=XY, 1=XZ and
2=YZ. Earlier help reversed the plane names for 1 and 2; the calculation is
unchanged. Known planar-hole tests now cover all three selections.

Masks normally mark/select voxels rather than destructively changing the source
intensity field. Historical exceptions or apparent exceptions include:

- `batch_RemoveEdgeObjs.m` replaces/removes labeled components at image edges.
- `generateFirstGuess_morphsnakes.m` sets selected mask slices to zero.
- `C_corrBlobBndsPost.m` changes masks through filling/smoothing and may change
  label ownership.
- `cleanSegsAndFindSheets.m`, `A_identifyFromH5_2DSheets.m`, and
  `splitSurfaces_Threshold.m` alter segmentation support through morphology,
  component selection, interpolation, or rethresholding.
- `blobVolFractFromTifs.m` and many `farmConsMatLnB` calls do not alter the source
  data on disk; they construct masked samples or rendered outputs.

## Signed-distance cleanup definition and open issue

The intended quantities are:

- `layerMean`: signed distance of the target layer from the object boundary;
  negative is inside and positive is outside.
- `layerWidth`: half-width around the mean isosurface.
- `gKern`: Gaussian sigma used to smooth the signed-distance field before
  selecting the result.

The historical `farmReturnSmoothBlobsBW` implementation applies Gaussian smoothing
but selects only `smoothedDistance < layerMean + abs(layerWidth)`. It does not
apply the expected lower bound `layerMean - layerWidth`. Existing workflows
also use `layerWidth=0`, which would produce an empty result under a strict
two-sided interval. The first moved implementation preserves the historical
one-sided result while correcting the apparent 2-D/3-D Gaussian function swap.
The desired filled-region versus shell behavior must be compared on historical
and synthetic data before redefining it.

## Anisotropic voxel handling found in the workflows

### Resampling volumes toward isotropic spacing

- `alignment-pipeline/AppendDensePropsToFilCCs.m` and its thesis-timeline copy
  resize dense segmentation data by `denseVoxSize/min(denseVoxSize)` before
  distance transforms.
- Both `DisplayGradPerim.m` variants perform the same dense-volume resampling.
- `C_fil2ObjAlignment.m`, both Q-tensor variants,
  `COMBINED_Fils2Aligns_InOnOut.m`, `prepareTifsForFilProps.m`, and the TIFF
  final-analysis workflow compute a segmentation voxel size from image and
  segmentation dimensions, then resize toward a cubic grid.
- `batch_densityDistributionAlongDeltaR_TIFS.m` resizes a spheroid mask so its
  grid spacing approaches the requested radial-bin scale before calculating a
  distance transform.
- `C_corrBlobBndsPost.m` exposes pre/post resize factors around smoothing, but
  does not itself derive them from voxel metadata.

Nearest-neighbor interpolation is used in several categorical-mask paths and is
the correct starting choice for IDs/classes. Some other categorical resizes omit
an interpolation method and are ambiguous because linear interpolation can
create invalid class values.

### Correcting geometry after segmentation

- `h5Seg_FilamentPosOr.m` multiplies eigenvectors by voxel dimensions and uses
  scaled eigenvectors/eigenvalues to estimate aspect ratios and lengths. The
  implementation also calculates `scaleLens` but filters the unscaled
  `allLens`, so its intended cutoff units need historical comparison.
- `COMBINED_Fils2Aligns_InOnOut_TIFS.m` rescales every filament voxel coordinate
  by physical voxel size, constructs a covariance matrix, and recalculates
  eigenvectors, projected length, and aspect ratio. It stores these as
  `AniDirectors`, `AniLengths`, and `AniAspectRatios`. This is the clearest
  coordinate-based anisotropic filament correction found.
- Both `Display_Filaments2DCuts.m` variants rescale direction vectors using
  `min(voxelSize)./voxelSize`, then renormalize them.
- Alignment workflows also form 2-D directions from the first two components to
  reduce sensitivity to Z-axis PSF elongation. Examples include
  `alignStatsOverTime.m`, both `Display_AvgAlign_FromRBins.m` variants, and the
  2-D Q-tensor workflow.
- Sheet mesh workflows store `segVoxSize` and rescale mesh vertices before
  curvature and field calculations; this changes coordinate geometry rather
  than resampling the mask.

### Places where anisotropy remains ambiguous

- `farmStoreFilCCs.m`, `A_extractFilsFromTifs.m`, and several combined filament
  scripts use `regionprops3` principal axes directly in voxel coordinates even
  when voxel spacing is stored separately.
- Spherical structuring elements, `bwdist`, Gaussian filters, and LoG filters in
  multiple workflows operate in voxel coordinates without first demonstrating
  isotropic spacing.
- `rough_homeotropicThinning.m` resizes a logical segmentation to an image size
  without explicitly choosing nearest-neighbor interpolation.
- Several scripts scale a distance-transform result by one scalar or resize it
  after calculation; this is only physically faithful under specific spacing
  assumptions.
- Thin filaments can be close to the lateral or axial PSF width. Resampling them
  before connected-component analysis can merge, erase, or thicken structures;
  the coordinate-based correction used for `Ani*` properties is safer when the
  native segmentation contains only a few voxels across.

A literature-backed PSF/resampling limit has not been asserted here. It depends
on microscope NA, wavelength, refractive index, sampling, deconvolution, and the
feature scale. The implementation should therefore accept measured `[Y X Z]`
spacing and PSF information rather than bake in one universal cutoff.

## TIFF code that treats a fourth dimension as channels

The project convention is that general processing works on `[Y X Z]`, while
probability channels are `[Y X Z C]`. Historical functions that explicitly
operate on a fourth dimension include `farmImbinarize3_4D.m`, `farmImresize3_4mat.m`,
`farmH5toSmooth3Chans.m`, and HDF5-loading workflows. Their fourth dimension is a
probability/vector component dimension, not TIFF time.

ImageStackIO's `farmReadTiff` and `farmWriteImageJHyperstack` are the supported paths
for genuine multidimensional TIFFs. Ad-hoc `tiffreadVolume` workflows generally
assume spatial `[Y X Z]` data. The explicit legacy TIFF exceptions found are:

- `Workflows/SHG/combine_2chanSegs.m` reads a per-time TIFF whose fourth
  dimension is treated as channel, assembles `[Y X Z C]`, then writes one 3-D
  TIFF per channel.
- `Workflows/SHG/SHG_prelimAnalysis.m` reads probability TIFFs, selects time in
  dimension three and channel in dimension four, and passes a cropped 4-D TIFF
  probability array to `farmH5toSmooth3Chans` despite that function's HDF5 name.
- `Workflows/imagePreparation/illuminationCorrection/generate4DLayerStore_ZandT.m`
  creates a fourth dimension representing time, rather than channel.

Other fourth-dimensional arrays found near TIFF workflows are usually newly
constructed vector fields, RGB/display channels, or gradients; they are not
four-dimensional TIFF inputs. The exceptions above should be migrated to
ImageStackIO and declare C versus T explicitly. `farmReadProbabilityTiff` records
the explicit T-to-C exception.

## Filament data stored and used downstream

Historical filament workflows store two principal forms:

1. Binary filament TIFFs, such as `Time%06i_threshFils.tif`, used to reconstruct
   components, display selected filaments, and resample filament support against
   dense region segmentations.
2. Per-frame `rp3D` tables and `rp2D` structures. `rp3D` includes centroids,
   volume, principal-axis lengths, eigenvectors, derived directors, lengths,
   aspect ratios, and sometimes center indices, distance-to-boundary values,
   region IDs, gradients, and alignment metrics. `rp2D` stores slice-wise
   centroids, area, major/minor axes, orientation, and slice index.

Downstream scripts concatenate those records over time, filter measurements,
assign region/distance fields at filament centers, calculate filament-boundary
alignment, construct backbone displays, and plot length/orientation statistics.
Direct LoG and probability-based filament segmentation should return the same
segmentation-result structure. Component characterization remains separate and
must not alter the returned binary mask. A caller may elect to skip writing the
TIFF and immediately calculate/store connected components and properties to
reduce I/O and peak duplicate storage.

## 2-D mask extrusion

`BatchConvertH5toTif_DirtSub.m` calls `farmExtend2DTiffAlongZ` to repeat a 2-D dirt
classification through a hard-coded Z depth. The helper is located under
`APIs/ImageStackIO/legacy-or-stack-transforms/farmExtend2DTiffAlongZ.m`. The active
conversion loop does not apply the resulting dirt volume, so this path may be
deprecated. No new public extrusion function is introduced yet.

## Deferred or excluded work

- Error/warning/skip behavior for all batch failure classes remains unresolved.
- Visual comparison criteria remain user-directed; automated scientific
  acceptance thresholds are not yet selected.
- Real-data fixtures and whether to commit them remain deferred. Synthetic tests
  are sufficient for retirement, while retired replacements remain prepared for
  real-data confirmation.
- `filterBorderComponents` and generalized property-filter architecture are
  deferred.
- Watershed-based splitting of ambiguous label additions is agreed but not yet
  implemented.
- Exclusion-mask resampling/removal semantics remain deferred; masks normally
  mark voxels rather than mutate source intensity data.
- General seed-point label selection belongs more naturally in ObjectTracking;
  background-point behavior is unresolved.
- The first two-sheet workflow keeps automatic center-minimum selection plus
  `SplitSlice` and `GapHalfWidth` overrides. Removed material is returned and
  historical fragment reassignment is preserved pending review.
- Scattered-interpolation sheet patching is retained only as a historical method.
- General sheets need not be single-valued. Homeotropic thinning is the intended
  general method for arbitrary sheet geometry/object count. Axis-dependent
  top/bottom partitioning remains a two-sheet workflow.
- Active-contour scripts remain untouched.
- The class-interface repair algorithm remains historical; watershed handling is
  deferred.
- Functions remain separate and public during evaluation. Consolidation into
  private strategies will be considered after validation exposes degeneracy.
- A project-wide `retired` directory will record original paths. Files move there
  only after synthetic comparison; real-data confirmation remains prepared.
