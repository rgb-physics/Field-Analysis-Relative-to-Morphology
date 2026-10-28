# SegmentationTools

## N-channel probability smoothing

```matlab
[masks,info] = farmSmoothNChannelProbabilities( ...
    probabilities,[1 3 2],[0.2 0.5 0.5], ...
    struct('OpeningRadius',1,'ChannelPrecedence',[3 1 2]));
```

Each selected channel is strictly thresholded and independently opened.
Overlaps are then awarded to the first eligible channel in precedence order,
regardless of score. Default precedence follows the supplied channel order;
`channels=[]` selects all input channels. `ChannelPrecedence` uses actual input
channel numbers, highest priority first, listing every selected channel once.
Thresholds and output masks remain in the supplied `channels` order.
`ReturnOpenedMasks=true` exposes the masks before conflict resolution in
`info.OpenedMasks`. Unclaimed voxels remain background; no complement class
is inferred. Radius is in voxel units. Two-dimensional images use a disk;
volumes use a sphere. `OpeningRadius=0` disables opening.

The historical `farmSmoothInOnOutProbabilities` and `farmH5toSmooth3Chans` remain
available with their existing overlap and complement-wall behavior for
comparison. Use the N-channel function for disjoint, precedence-based masks.

## Direct intensity segmentation

`farmSegmentIntensity` accepts one 2-D intensity
image or 3-D `[Y X Z]` volume, without Ilastik or probability fields. Select
channel and time before calling. Default Otsu thresholding estimates one
threshold over the entire input volume. Thresholds are reported and applied
in original intensity units; input intensities are preserved.

```matlab
image = farmReadTiff('C:\path\intensity.tif');
volume = image.Data(:,:,:,1,1);
result = farmSegmentIntensity(volume);

opts = struct('Method','fixed','Threshold',1200, ...
    'FillHoles',true,'MinObjectSize',100,'KeepLargest',3,'ReturnLabels',true);
result = farmSegmentIntensity(volume,opts);
farmWriteMaskTiff(result.Mask,'C:\path\foreground.tif');
```

`Mask` is the cleaned morphology; `CandidateMask` retains the original
threshold result. `LabelVolume`, when requested, contains connected-object IDs.
The result also reports the threshold, fitting intensity range, connectivity,
voxel and component counts, and options. `Foreground='dark'` selects intensities
below the threshold. Comparisons are strict, excluding exact threshold values.

Otsu uses min-max scaling of the reference samples internally; an explicit
`IntensityRange=[low high]` overrides that range. `EstimationMask` limits the
samples used to estimate the range and threshold, without excluding other
voxels from the output. Use a fixed threshold to reuse a chosen cutoff across
time points. Cleanup is opt-in and ordered: enclosed-hole filling, minimum
component size, then retaining the largest components. Sizes are voxel counts.

This produces rudimentary foreground masks, not calibrated probabilities or
inside/wall/outside classes. Touching cells may remain a single object.
Per-slice/adaptive thresholds and physical-spacing-based morphology are not
included. See function help for all options. The automated suite includes
fixed/dark thresholds, Otsu scaling, reference selection, constant input,
cleanup, labels, and invalid-option checks.

SegmentationTools converts pixel-classification probabilities into masks and labels through binarization and cleanup. Ilastik is a common upstream source of probability fields, but it is not required for every segmentation route. Filaments can be segmented directly from bright-on-dark microscopy intensities with the historical Laplacian-of-Gaussian (LoG) method or from external probability fields.

Reusable algorithms and example workflows are separated in the proposed structure. Implementations are preserved without refactoring in this first-pass copy.

Probability arrays use `[Y X Z C]`; complete image structs use the project-wide `[Y X Z C T]` convention. The public in/on/out semantic order is `[inside wall outside]`.

## Fill unclassified locations after opening

`farmSmoothNChannelProbabilities` accepts `FillMethod` in its options struct:

| Value | Assignment after opening and overlap resolution |
| --- | --- |
| `'none'` (default) | Leave locations unclassified, preserving the previous behavior. |
| `'nearest'` | Copy the channel of the nearest classified voxel using one Euclidean `bwdist` transform and its nearest-index output. MATLAB decides ties. |
| `'fill'` | Assign unclassified locations to the highest-precedence selected channel. |

Existing classified voxels keep their assignments. Nearest uses voxel distances
on the supplied probability grid, including the Z dimension for 3-D data; it
does not estimate calibration or account for anisotropic spacing.

With probability data already loaded:

```matlab
options = struct('OpeningRadius', 1, 'FillMethod', 'nearest');
[masks, info] = farmSmoothNChannelProbabilities(probabilities, [3 2 1], 0.6, options);
```

`info.UnclassifiedVoxelCountBeforeFill` records how many locations needed filling.
`info.FilledVoxelCount` counts assignments made by this option. `VoxelCounts` and
`UnclassifiedVoxelCount` describe the final masks. With `ReturnOpenedMasks=true`,
`info.OpenedMasks` remains the intermediate array before overlap resolution and
filling. No distance transform is calculated for `'none'` or `'fill'`, or when
there are no unclassified locations.

## Reuse intensity-segmentation components

Set `ReturnComponents=true` in `farmSegmentIntensity` to retain its final
connected components as `result.Components`. Pass that struct to
`farmPrepareObjects` or `farmMeasureFilaments` to avoid detecting components
again. Filtering preserves scan-order IDs, including after `KeepLargest`.
`ReturnLabels=true` also reuses the computed components internally.
This opt-in output defaults to false and uses the segmentation connectivity;
do not reuse it if you intend a different connectivity for object detection.
