# FieldAnalysis: first pass

Reusable numerical analysis of scalar fields or corresponding samples.
ObjectRelativeProfiles owns support selection and object/frame identities.
Mesh/PLY interpolation and surface derivatives remain in SurfaceFieldMapping.
No historical experiment script is claimed to be replaced in its entirety.

## Setup and tests

Add `APIs/FieldAnalysis/src` and `APIs/SharedUtilities/src` to the MATLAB path.
For tests, add `APIs/FieldAnalysis/tests`, then run:

```matlab
results = runFieldAnalysisTests;
```

The suite tests analytic frequencies, sinusoidal peaks, Parseval's identity,
native Hann weighting, radial centering and counts, 2D/3D linear correlations,
paired sample order, empty supports, and rejected invalid data.
Signal Processing Toolbox is needed for `hann` and `xcorr2`.
The suite does not establish scientific validity for real experiments.
See `examples/exampleFieldAnalysis.m`.

## Fourier analysis

```matlab
r = fieldanalysis.fourier.powerSpectrum2D(image, struct( ...
    'Spacing',[dy dx], 'SpacingUnit','um', 'NumBins',100));
r3 = fieldanalysis.fourier.powerSpectrum3D(volume, struct( ...
    'Spacing',[dy dx dz], 'SpacingUnit','um', 'NumBins',100));
slices = fieldanalysis.fourier.selectSlicesAnalysis(volume,[3 8 15], ...
    struct('Spacing',[dy dx]));
projection = fieldanalysis.fourier.powerSpectrum2D(mean(volume,3));
maximumProjection = fieldanalysis.fourier.powerSpectrum2D(max(volume,[],3));
```

The baseline is the squared Fourier magnitude from
`Workflows/fourier/batch_FFTAnalysis_samAdapted.m` and its 3D variant.
There is no implicit division by voxel count in the new API:

```matlab
power = abs(fftshift(fftn(window .* processedField))).^2;
```

`MeanSubtract=false` by default; `Window=true` uses
`sharedutilities.numerics.generateNDHann` (symmetric MATLAB Hann).
`Window=false` disables the window.
The new consistent window replaces the direct 2D window expression in the
historical samAdapted script. A two-sample symmetric Hann is all zero:
very small dimensions can therefore remove the entire signal.

`frequencyCoordinates` calls `genScaledKVec`. Frequencies are cycles per
spacing unit, in Y X Z order; they are not angular wave numbers.
Spacing changes frequency axes without resampling the image.
A corrected frequency helper places DC at index `floor(N/2)+1` for both
odd and even grids. Its original is preserved in SharedUtilities/archive.

### Returned data and storage

`Radial` contains `Edges`, `Centers`, `Counts`, `Mean`, `Sums`,
`WeightSums`, `Sigma`, and `ExcludedCount`.
The radial mean divides by the number of frequency samples in a bin; this is
averaging, not intensity/energy normalization of the input field.
Full power arrays are temporary by default. Set `ReturnPower=true` to retain
`Power`. Radial analysis still requires a temporary full power array.
Separate 2D slices return a cell array in the requested slice order; no slice
averaging occurs. Each result records its `Slice`.

Results retain grid size, spacing/unit, frequency axes, mean-subtraction and
window choices. `Normalization.Method='none'` and `AppliedFactor=1`.
Recorded scalars are voxel count, input sum/mean/variance, and window sum and
squared sum. Keep DatasetID/Frame alongside results in your workflow.

For the historical samAdapted voxel-count normalization:

```matlab
normalized = r.Radial.Mean / r.Normalization.VoxelCount;
```

To compare window-corrected power per voxel, an explicit alternative is to
divide by `WindowSquaredSum`, provided it is nonzero. Reference-spectrum
ratios and user-selected intensity factors can be applied to stored profiles.
For a field amplitude scaling by c, power scales by c^2.
These are different conventions; record the denominator and method used.
PSD per unit frequency or a physical structure factor needs a separately
defined normalization, not merely a new label.
Changing windows, supports, projection, or resampling requires recalculation.

### Radial grouping

Hard bins are default. Specify `Edges` (frequency units) or `NumBins`;
edges take precedence. Empty bins have count zero and mean NaN, with sum zero.
MATLAB histcounts conventions apply, including the rightmost final edge.

`Sigma>0` requests historical-style Gaussian weighting. The new function
evaluates weights at each bin center:

```matlab
w = exp(-0.5 * ((radius - center) / Sigma).^2);
value = sum(power .* w) / sum(w);
```

Weights use all frequency samples, including radii outside the edge range.
Counts still describe hard-bin occupancy; they are not Gaussian effective
sample counts. Empty hard bins remain NaN even with Gaussian weighting.
Sigma has the same units as radial coordinates. No historical low-frequency
replacement or automatic cropping is applied.

`radialAverage(array,options)` also works on correlation maps.
Its default coordinates are fftshift-centered voxel coordinates.
Supply `Coordinates={axisY,axisX,axisZ}` to use explicit lag/frequency axes.
For cylindrical averaging of a 3D array, supply a zero-valued Z coordinate
vector; this pools Z rather than returning separate slices.

## Spatial correlation

```matlab
r = fieldanalysis.spatialCorrelation.crossCorrelation(a,b);
s = fieldanalysis.spatialCorrelation.autoCorrelation(a, ...
    struct('MeanSubtract',true));
profile = fieldanalysis.fourier.radialAverage(r.Correlation, ...
    struct('Coordinates',{r.LagAxes},'NumBins',50));
```

Only unnormalized linear correlation is implemented. There is no periodic
mode or normalized-template-correlation alternative in this pass.
2D uses MATLAB `xcorr2`; 3D uses zero-padded FFT convolution of A with B
reversed along all axes. Full output size is `2*size(a)-1`.
Positive lag means A is displaced toward increasing array indices relative
to B. `LagAxes` retain signed YXZ lags scaled by spacing.
`ZeroLagIndex=size(b)`. Inputs must have identical dimensions.

Mean subtraction and Hann windowing are optional and false by default.
No standard-deviation, pair-count, or zero-lag division is applied.
For mean-subtracted fields, a user may divide the correlation by an explicitly
chosen overlap count and standard-deviation product. Those choices define the
estimator and should be documented in the workflow. Zero-lag normalization is
another different convention. Opposite boundaries do not wrap.
Full correlation maps can be large: reduce to a profile and discard the map
before loading the next frame.

## Conditional and paired analysis

```matlab
r = fieldanalysis.conditional.conditionalStatistics(intensity,distance, ...
    struct('Edges',0:2:40,'Statistics',{{'Mean','Variance','Median'}}));
% Same operation on selected samples:
r = fieldanalysis.conditional.conditionalStatistics(intensity(indices), ...
    distance(indices),struct('Edges',0:2:40));
% Optional object/region grouping:
r = fieldanalysis.conditional.conditionalStatistics(values,distances, ...
    struct('Edges',edges,'GroupIDs',objectIDs));
h = fieldanalysis.conditional.jointHistogram(a,b,struct('NumBins',[20 30]));
p = fieldanalysis.statistics.pairedFieldStatistics(a,b);
```

Matching full arrays or equal-length vectors are accepted. Both inputs must
use the same selection and order; never filter or reorder them independently.
The core does not choose masks, skeletons, boundaries, or identities.
ObjectRelativeProfiles selects support and supplies the paired samples.
Group IDs are sorted in output; rows are keyed by GroupID and Bin.
No-group queries use GroupID=1. Empty selections are accepted with explicit
edges and yield zero counts, NaN summaries, and zero sums.

Conditional statistics: Count, Sum, Mean, Median, Variance, Std, Min, Max.
Variance/Std follow MATLAB's default sample convention.
Out-of-range conditioning values appear in ExcludedCounts by group.
Counts and edges are retained even when only one statistic is requested.
Joint histograms use native histcounts2 and retain excluded counts.
Paired statistics use native cov/corrcoef; these describe paired values at
the same support, not spatial displacement correlations.

## Optional quantitative preprocessing

preprocessing.fitIlluminationCorrection streams user-selected reference
frames via a loader, fitting the historical broad/focal correction model.
preprocessing.applyIlluminationCorrection returns double corrected values
without thresholding, range stretching, or implicit export. BleachScale is
explicit and defaults false. preprocessing.scaleToReferenceTotal accepts a
reference total supplied by the workflow and returns the applied factor.
See Workflows/examples/preparationExample.m for optional 16-bit quantitative
and separate fixed-range 8-bit Ilastik export, plus explicit crop conversion.

## Invalid data and batching

Nonfinite values trigger an informative error. Find and repair invalid
indices upstream with native functions and appropriate API helpers.
Legitimate zeros are retained. These functions do not fill missing data,
resample fields, or infer registration from equal matrix sizes.
Empty Fourier/correlation fields are rejected.

Load manageable same-frame XYZ fields, query/analyze all needed supports,
store small results with DatasetID/Frame/ObjectID as appropriate, and proceed
to the next frame. Do not load complete XYZT datasets. Existing
ObjectRelativeProfiles loaders and keyed attachment functions remain available;
this API does not create another batching or identity framework.

## Historical code and exclusions

loglogBin is now owned by fieldanalysis.statistics. It calculates paired
log-domain means over occupied X bins. Its old sharedutilities.plotting path
remains a compatibility wrapper; its repaired numerical behavior is unchanged.

LiangOG, LiangADAPT, percolationAnalysis, general fitting, temporal peak
association, and mesh workflows are outside this first pass.
The old Fourier/plotting scripts remain as provenance until their full
workflows are replaced. The legacy generateVanHove and
generateStaticStructureFactor are not repaired or recommended entry points:
genCorrScaleMat was not found, and their estimator requires separate review.
twoFieldsCrossCorr remains a historical experiment script. Its unpadded,
windowed FFT convention differs from the new linear correlation.

generateRadialMatrix and radiallyAverageMatrix now preserve correctly sized
grids and return one value per bin. Their originals are archived.
The legacy averaging wrapper retains Gaussian evaluation at left edges
instead of the new function's bin centers, but corrects origins and drops the
extra trailing zero. Its default edges now include radius zero.
Existing scripts that strip the last value with end-1 need review before use.
