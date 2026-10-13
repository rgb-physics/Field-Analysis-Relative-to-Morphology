# SegmentationTools

## N-channel probability smoothing

```matlab
[masks,info] = segmentationtools.binarization.smoothNChannelProbabilities( ...
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

The historical `smoothInOnOutProbabilities` and `h5toSmooth3Chans` remain
available with their existing overlap and complement-wall behavior for
comparison. Use the N-channel function for disjoint, precedence-based masks.

## Direct intensity segmentation

`segmentationtools.binarization.segmentIntensity` accepts one 2-D intensity
image or 3-D `[Y X Z]` volume, without Ilastik or probability fields. Select
channel and time before calling. Default Otsu thresholding estimates one
threshold over the entire input volume. Thresholds are reported and applied
in original intensity units; input intensities are preserved.

```matlab
image = imagestackio.readTiff('C:\path\intensity.tif');
volume = image.Data(:,:,:,1,1);
result = segmentationtools.binarization.segmentIntensity(volume);

opts = struct('Method','fixed','Threshold',1200, ...
    'FillHoles',true,'MinObjectSize',100,'KeepLargest',3,'ReturnLabels',true);
result = segmentationtools.binarization.segmentIntensity(volume,opts);
segmentationtools.io.writeMaskTiff(result.Mask,'C:\path\foreground.tif');
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

Probability arrays use `[Y X Z C]`; complete image structs use the project-wide `[Y X Z C T]` convention. The public in/on/out semantic order is `[inside wall outside]`. See `docs/SEGMENTATION_HISTORICAL_METHODS.md` for current behavior, historical alternatives, anisotropy notes, compatibility wrappers, and deferred work.
