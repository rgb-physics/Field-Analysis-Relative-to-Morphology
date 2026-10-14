# Experiment 4 modular workflow examples

All supplied O: datasets are read-only. Outputs are new, uniquely named
directories under package test-data/workflow-results. Existing files are never
overwritten by the workflows. No output is written beside source data.

## Start here

From the repository root in MATLAB R2023a:
```matlab
addpath(fullfile(pwd,'Workflows','examples'));
results = runWorkflowExampleTests; % synthetic only
c = experiment4Config;
preview = previewExperiment4(c);  % inspect class meanings and registration
```

The preview writes a PNG with density, filament intensity, and semantic
classes. Confirm 1=inside, 2=wall, 3=outside, 0=unclassified before interpreting
alignment. User supplied semantic channels are [3 2 1].
HDF5 /exported_data metadata was read without modifying the file:
on-disk [44 270 275 3], MATLAB h5read [3 275 270 44].
Thus SourceAxes=CXYZ gives YXZ=[270 275 44]. The intensity TIFF header gives
YXZ=[735 750 94]. Physical extents agree within voxel rounding. These checks
do not establish image registration or semantic correctness; inspect preview.
Crop metadata: legacy XYZ corner [5 15 1], size [750 735 94].
The example explicitly swaps X/Y to YXZ.

## Six independent examples

```matlab
prep = preparationExample(c);
objects = workflow1Objects(c);
filaments = workflow2Filaments(c);
lineage = workflow3Lineage(c);
spectra = workflow4Spectra(c);
profiles = workflow5Profiles(c,filaments); % second argument optional
```

Do not run all six blindly: inspect the preview and a short first run.
Choose a subset before extending to 10:2:30:
```matlab
c.Frames = 10;
c.SpectrumFrames = 10;
```
Workflow3 uses c.TrackingFrames (default 10:30), not c.Frames.
The seed defaults to the largest detection at frame 20 and is saved explicitly;
set SeedObjectID to select a known object instead.

1. Preparation fits the historical two-pass illumination/focal model from raw
   cropped frames 1:3 and corrects frame 22. BleachScale is explicitly true in
   this Experiment4 configuration, but the reusable application function
   defaults false. The double correction model is saved as MAT.
   Quantitative uint16 export rejects out-of-range values instead of clipping.
   Optional Ilastik export reloads that saved quantitative TIFF, uses the fixed
   c.IlastikRange, resizes, and updates spacing from actual output dimensions.
   It never uses a per-frame min/max stretch. ExportIlastik defaults false.
2. Objects: select requested c.Supports and field/statistic queries.
   H5 summed foreground channels are [3 2], threshold .6; historical distance
   smoothing follows thresholding. Optional ObjectLoader skips segmentation
   and supplies same-grid masks/IDs. Set ObjectInputType='labels' for a
   disconnected label 1. Whole-object measurements, physical volume and
   same-frame support statistics are retained in keyed tables.
   Skeleton support requires historical gfilter; default boundary support does
   not. LocalInertia is optional. With skeleton support it queries skeleton
   indices; otherwise centroids are used explicitly.
3. Filaments: optional native-mask FilamentLoader, otherwise historical -LoG
   followed by explicit fixed threshold 20. Native and scaled-covariance
   properties are retained without resampling the filament image.
   In/on/out segmentation supplies distance, validity and centroid class.
   Distance is generated on an isotropic grid and converted to um.
   Smoothed gradients are XYZ components with physical derivatives.
   ReferenceValid and ReferenceDirectionValid are separate.
   Order2D projects/renormalizes; Z selection is optional.
   No cross-object filament/blob association is implemented.
   Direct intensity filament segmentation remains subject to visual validation.
4. Lineage: light detections/links/events and ancestry/descendants/trajectory
   selections are retained. Querying intensity/volume reuses workflow1 APIs.
   ExportTrackingTiffs and RetainMasks default false; heavy retention is opt-in
   and can consume XYZT memory. TIFFs can be emitted frame by frame.
   TrackingLabelMode selects trajectory/object IDs. ExportMaskedIntensity
   optionally saves selected quantitative intensity with zeros outside support.
   Measured intensity Sum is an uncalibrated mass proxy, not physical mass.
5. Fourier: selected slices (20,40,60 by default), mean/max projection passed
   into the same 2D calculator, and full 3D radial spectra.
   Autocorrelation is 2D by default; 3D or channel cross-correlation is opt-in.
   Full linear 3D correlation has roughly eight times the input voxel count,
   plus FFT temporaries, so start with 2D or a cropped synthetic case.
   Power is unnormalized; historical normalization divides the stored radial
   mean by Normalization.VoxelCount. Mean subtraction defaults false.
   Retain only radial correlation profiles; temporary lag maps are released.
6. Conditional profiles: channel intensities versus signed boundary distance
   or nonnegative exterior skeleton distance. The latter is an explicit
   definition replacing the historical global-min shift, not an assertion of
   scientific equivalence. Optional workflow2 alignment rows are grouped by
   semantic region and distance. Whole-field intensity profiles pool objects,
   matching the historical logical-mask approach. Per-object associations
   remain deferred.

The numbering above counts preparation first; function names preserve the
agreed workflows 1–5.

## Modularity and extension points

experiment4Config is ordinary editable configuration. ObjectLoader and
FilamentLoader can supply prepared masks without H5/intensity segmentation.
Supports and named fields can be extended directly in workflow1's queryFrame
specification. Same-frame sample operations can call custom functions.
These are editable examples, not a pipeline that loads all channels/times.
Frame-wise MATs retain small measured tables; geometry indices are retained
only when requested. Workflow2/1 concatenate tables, not images.
No old workflow has been archived because these examples still need real-data
validation and explicit policy comparison.

New reusable functions:
- fieldanalysis.preprocessing.fitIlluminationCorrection
- fieldanalysis.preprocessing.applyIlluminationCorrection
- fieldanalysis.preprocessing.scaleToReferenceTotal
- objectgeometry.objects.localInertia

Local inertia retains historical all-neighbor smoothed occupancy, mirrored
padding, and inertia kernels in YXZ order. Optional physical spacing scales
coordinate kernels; metadata is retained. Eigenvalue ratio is not geometric
surface-area sphericity. Query indices are user-selected; fallback/selection
is caller-owned. Bounded BatchSize matrix products compute moments efficiently;
a small loop solves each 3-by-3 eigensystem. SampleLimit is opt-in and uses
MATLAB RNG; set rng for repeatable sampling.

## Scalability

```matlab
timings = benchmarkWorkflowScaling(c);
```
Default synthetic cases vary XYZ size, frames, channels and label-group count,
holding foreground occupancy fixed within each size. Object and filament
measurement timings are separated from field sampling.
Synthetic disconnected groups isolate ID-count cost; they do not represent
real filament packing/orientation. Treat them as an implementation baseline,
then use real frame counts/subsets for representative timing.
RetainedArrayBytes is not peak memory. Windows/MATLAB memory observations
should be recorded separately when running larger real-data cases.
Do not claim accurate peak-memory measurement from whos.
Intensity/probability reads in real examples remain sequential. Runtime/output
scaling must include disk IO, tables, masks, and neighborhood computation.

## Tests and limitations

Seven synthetic tests cover explicit reference scaling, correction without
hidden normalization, streamed reference fitting, known local inertia,
batch-size equivalence, empty/subsampled support, output protection, and a
whole-object sampling example. MATLAB cannot execute in the agent environment
because of license username mismatch; static checks are separate from tests.
No real data processing has been run by the agent. Source headers and metadata
were inspected read-only. Graphical/photometric validation is still required.
