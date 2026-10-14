# Package fields/options and builder audit

Subsequent implementation: see [Configuration builders](CONFIGURATION-BUILDERS.md)
for the first implemented builders. The audit below records the pre-builder
interfaces and proposals; it is retained for comparison.

Audited 2026-10-14. This document records current interfaces; no builders or API behavior were changed by this audit.

## Scope and how to read this reference

The inventory covers current public MATLAB functions under APIs/*/src with options, configuration, query specifications, or varargin in their signatures. Archived scripts, tests and workflow-local variables are not API contracts. SurfaceFieldMapping and VisualizationTools remain largely positional/legacy interfaces; their redesign is deferred. Internal parsers are included only to explain inherited defaults. Function help excerpts and literal defaults below preserve actual variable names instead of inventing a universal schema. Source links provide the complete validation and conditional behavior.

Experiment configuration is currently a plain struct. Its complete field reference is [Experiment configuration](Workflows/examples/EXPERIMENT-CONFIGURATION.md); that includes acquisition identity/timing, source paths, task settings and export choices. Those example fields are not automatically accepted by every API.

## Proposed hierarchy (not implemented)

Experiment: DatasetID, acquisition timing, available frames, named source descriptions.
Sources: loader/path/pattern, format-specific axes/channels, current calibration, optional source-grid provenance.
Task configurations: segmentation; geometry; sampling; tracking; field analysis. Build these independently and reuse them.
Run/output: selected frames and sources, task configurations, destination and retention choices.

Keep direct API calls available. A thin optional run specification connects these parts without copying all their options. Builders construct descriptions; loaders allocate data only when execution requests a frame.

## Findings requiring explicit mappings

| Names/functions | Current distinction and builder implication |
|---|---|
| prepareObjects InputType; prepareSupport Type; generateGeometry positional type | Input representation versus sampling interpretation versus generated geometry kind. Keep distinct meanings visible. |
| measureObjects options; measureFilaments Identity; generateGeometry Identity; trackOverlaps Identity | measureObjects removes Intensity then forwards preparation options directly; the others nest preparation options. Builders need consumer-specific adapters, not one interchangeable struct. |
| readH5 datasetPath; inspectImage DatasetPath; experiment H5Dataset | Same dataset selection is positional, an option, or a workflow field depending on consumer. Source builder must translate it. |
| Channel, Channels, TimeIndex, Frame | Stored channel selection, stored time position and acquisition frame identity are separate. Do not silently equate Frame with TimeIndex. |
| Spacing/SpacingUnit; Grid; SourceGrid/Transform | Current sampling grid differs from source provenance. Matching sizes alone cannot establish registration. Retain metadata after resampling. |
| Sigma in segmentIntensity, distanceGradients, localInertia, radialAverage | Spatial smoothing and frequency-bin weighting have different meanings/units. API grouping alone does not make Sigma reusable. |
| Threshold, thresholds, Thresholds, BinEdges, Edges | Intensity/probability classification thresholds differ from statistical bin boundaries. Positional and struct spellings also differ. |
| Name/Names/FieldName; Fields/Field | Semantic class names, support names, query output prefixes and selected input fields are different roles. Query Name becomes FieldName internally. |
| ChannelPrecedence; classifyProbabilities precedence | Input channel numbers versus semantic-class resolution require their own documented domains; do not reuse without translation. |
| ReturnLabels, ReturnLabelVolume, ReturnPower, ReturnScore, RetainTables, RetainMasks | Different retained outputs and memory costs. They belong to their consuming operation rather than one universal retention flag. |
| OutputRoot, OutputDirectory, ExportDirectory, FilePath | Workflow root, batch output folder, tracker export folder and single output file. A run adapter may derive them, but existing consumers use different names. |
| BleachScale | API correction default false; Experiment 4 preparation default true. Dataset example choices must not become universal defaults. |
| MeanSubtract/Window | Spectra default false/true; correlation default false/false. Shared spellings do not imply shared defaults. |
| trackOverlaps frames; runFieldBatch frames | Overlap tracking removes duplicates in supplied order; field batching rejects duplicates. Decide a common run-level policy explicitly before introducing an adapter. |
| ExtentWidthFloor; experiment MinAspectRatio | Positive width floor stabilizes scaled filament aspect ratio; MinAspectRatio filters objects afterward. Neither is a replacement for the other. |
| DatasetID/Frame/ObjectID/ComponentID; TrajectoryID/DetectionID | Detection identity, sampling component and tracking identifiers differ. Join by documented keys; do not join different object classes solely by ObjectID. |
| ReferenceValid; geometry/fallback flags; vector valid counts | Validity is operation-specific. Never replace all invalid/empty flags with a generic zero value. |

Matrices use YXZ (images YXZCT); native regionprops coordinate outputs and directors use their documented XYZ convention. Spacing follows matrix order. Measurement columns use the requested FieldName_Statistic prefix; native properties keep native names. Physical rescaling is operation-specific, not automatic merely because Spacing was supplied.

## Builder priorities and boundaries

1. Named source and experiment descriptions: highest priority for switching validation datasets. Require explicit calibration/axes when ambiguous; avoid data loading in construction.
2. Object preparation/identity and sampling support/query specifications: reduce nested-struct mistakes and preserve grid/identity information.
3. Segmentation: reuse makeClassConfig; complement it with intensity and classification options where needed.
4. Operation-specific geometry, tracking, spectrum, correlation and conditional-statistics options. Share defaults only when the consumers actually share them.
5. Output/run adapters after the above interfaces are stable; visualization/mesh builders wait for those API discussions.

Before implementing a builder, move or expose its consumer's default definitions through a shared provider where practical; test that builder output is accepted by the consumer. Validate configuration structure without reading entire datasets. Validate loaded matrix/grid compatibility at execution. Retain existing function signatures and error behavior unless a deliberate change is agreed.

## Function-by-function inventory

The option-name lists are a static index of literal accesses/default blocks, not an executable schema. Dynamic option fields and forwarded options are explained by the help/source. Empty values can have special meanings. Defaults reproduced as MATLAB code are the implemented definitions; absent definitions often indicate forwarding to another function.

## FieldAnalysis interfaces


### fieldanalysis.conditional.conditionalStatistics

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+conditional/conditionalStatistics.m)
```matlab
function result=conditionalStatistics(measured,conditioning,options)
```

Literal option/specification names: Edges, GroupIDs, Mean, NumBins, Statistics.

Implemented function help:

```matlab
%CONDITIONALSTATISTICS Bin corresponding values of one field by another.
% Matching arrays or equally sized sample vectors; selection occurs upstream.
% Edges override NumBins. Histcounts includes the last edge in the last bin.
```

Literal defaults:

```matlab
o=fieldanalysis.internal.options(struct('Edges',[],'NumBins',20,'Statistics',{{'Mean','Variance'}}, ...
    'GroupIDs',[]),options);
```

### fieldanalysis.conditional.jointHistogram

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+conditional/jointHistogram.m)
```matlab
function result=jointHistogram(a,b,options)
```

Literal option/specification names: EdgesA, EdgesB, NumBins.

Implemented function help:

```matlab
%JOINTHISTOGRAM Native histcounts2 on corresponding full fields or samples.
```

Literal defaults:

```matlab
o=fieldanalysis.internal.options(struct('EdgesA',[],'EdgesB',[],'NumBins',20),options);
```

### fieldanalysis.fourier.powerSpectrum2D

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/powerSpectrum2D.m)
```matlab
function result=powerSpectrum2D(data,options)
```

Literal option/specification names: .

Implemented function help:

```matlab
%POWERSPECTRUM2D Unnormalized power and radial spectrum of a YX image.
```

### fieldanalysis.fourier.powerSpectrum3D

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/powerSpectrum3D.m)
```matlab
function result=powerSpectrum3D(data,options)
```

Literal option/specification names: .

Implemented function help:

```matlab
%POWERSPECTRUM3D Unnormalized power and spherical spectrum of a YXZ volume.
```

### fieldanalysis.fourier.radialAverage

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/radialAverage.m)
```matlab
function result=radialAverage(values,options)
```

Literal option/specification names: Coordinates, Edges, NumBins, Sigma, Spacing.

Implemented function help:

```matlab
%RADIALAVERAGE Hard bins or historical Gaussian radial weighting.
% Coordinates are axis vectors; default is an fftshift-centered voxel grid.
% Gaussian uses all voxels at each bin center, not only voxels in that bin.
```

Literal defaults:

```matlab
o=fieldanalysis.internal.options(struct('Coordinates',{{}},'Spacing',[], ...
    'Edges',[],'NumBins',50,'Sigma',0),options);
```

### fieldanalysis.fourier.selectSlicesAnalysis

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/selectSlicesAnalysis.m)
```matlab
function results=selectSlicesAnalysis(volume,slices,options)
```

Literal option/specification names: .

Implemented function help:

```matlab
%SELECTSLICESANALYSIS Return one separate XY power spectrum per selected Z.
% Projection is external: powerSpectrum2D(mean(volume,3),options), etc.
```

### fieldanalysis.preprocessing.applyIlluminationCorrection

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+preprocessing/applyIlluminationCorrection.m)
```matlab
function [corrected,info]=applyIlluminationCorrection(field,model,options)
```

Literal option/specification names: BleachScale.

Implemented function help:

```matlab
%APPLYILLUMINATIONCORRECTION Correct a quantitative field without stretching.
% BleachScale=false by default. Returns double; export conversion is external.
```

Literal defaults:

```matlab
o=fieldanalysis.internal.options(struct('BleachScale',false),options);
```

### fieldanalysis.preprocessing.fitIlluminationCorrection

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+preprocessing/fitIlluminationCorrection.m)
```matlab
function model=fitIlluminationCorrection(frames,loader,options)
```

Literal option/specification names: FirstSigma, OutlierPercentile, PercentileScope, SecondSigma, Spacing.

Implemented function help:

```matlab
%FITILLUMINATIONCORRECTION Stream early XYZ references, following corr3DTiff.
% Historical two-pass broad illumination and Z-median focal correction.
% Reference frames are scaled to the first frame total before averaging.
% PercentileScope='columns' reproduces native prctile(A,p) in the old script;
% 'global' is explicit alternate behavior. Correction model stays double.
```

Literal defaults:

```matlab
o=fieldanalysis.internal.options(struct('Spacing',[1 1 1],'FirstSigma',24, ...
    'SecondSigma',20,'OutlierPercentile',97,'PercentileScope','columns'),options);
```

### fieldanalysis.spatialCorrelation.autoCorrelation

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+spatialCorrelation/autoCorrelation.m)
```matlab
function result=autoCorrelation(data,options)
```

Literal option/specification names: .

Implemented function help:

```matlab
%AUTOCORRELATION Unnormalized linear self-correlation.
```

### fieldanalysis.spatialCorrelation.crossCorrelation

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+spatialCorrelation/crossCorrelation.m)
```matlab
function result=crossCorrelation(a,b,options)
```

Literal option/specification names: MeanSubtract, Spacing, SpacingUnit, Window.

Implemented function help:

```matlab
%CROSSCORRELATION Unnormalized linear correlation, native xcorr2 in 2D.
% 3D uses FFT convolution of A with reversed B (equivalent lag convention).
% Positive lag means A is displaced toward increasing indices relative to B.
```

Literal defaults:

```matlab
o=fieldanalysis.internal.options(struct('MeanSubtract',false,'Window',false, ...
    'Spacing',ones(1,nD),'SpacingUnit','voxel'),options);
```

## ImageStackIO interfaces


### imagestackioinspectImage

[Source](APIs/ImageStackIO/src/+imagestackio/inspectImage.m)
```matlab
function info = inspectImage(filePath, options)
```

Literal option/specification names: DatasetPath, Spacing, SpacingUnit.

Implemented function help:

```matlab
%INSPECTIMAGE Inspect TIFF or HDF5 image metadata without loading pixels.
%   INFO = imagestackio.inspectImage(FILEPATH, OPTIONS) supports TIFF and
%   HDF5 files. For HDF5, OPTIONS.DatasetPath is required. OPTIONS.Spacing
%   is [Y X Z] and defaults to [1 1 1]. OPTIONS.SpacingUnit defaults to
%   "pixel".
```

### imagestackioreadH5

[Source](APIs/ImageStackIO/src/+imagestackio/readH5.m)
```matlab
function image = readH5(filePath, datasetPath, options)
```

Literal option/specification names: Channels, SourceAxes.

Implemented function help:

```matlab
%READH5 Read an HDF5 dataset and normalize it to [Y X Z C T] array order.
%   IMAGE = imagestackio.readH5(FILEPATH, DATASETPATH, OPTIONS) reads the
%   requested HDF5 dataset and returns a struct containing the normalized
%   array, axis labels, source-axis information, and HDF5 dataset metadata.
%
%   DATASETPATH is required. OPTIONS is an optional struct with fields:
%       SourceAxes  Axis labels for the array returned by h5read, such as
%                   "CYXZ". Use this when the file does not contain the
%                   supported MATLAB_AXIS_ORDER attribute.
%       Channels    Channel indices to retain after normalization. By
%                   default, all channels are retained.
%       Spacing     Spatial sample spacing in [Y X Z] order. The default
%                   is [1 1 1].
%       SpacingUnit Unit for Spacing, such as "um" or "nm". The default
%                   is "pixel".
%
%   The only automatically recognized axis attribute is
%   MATLAB_AXIS_ORDER. Its value must describe the order returned by
%   MATLAB's h5read function, not an assumed on-disk byte order.
```

### imagestackioreadTiff

[Source](APIs/ImageStackIO/src/+imagestackio/readTiff.m)
```matlab
function image = readTiff(filePath, options)
```

Literal option/specification names: SourceAxes.

Implemented function help:

```matlab
%READTIFF Read a TIFF file and normalize it to [Y X Z C T] array order.
%   IMAGE = imagestackio.readTiff(FILEPATH, OPTIONS) reads a TIFF image or
%   stack and returns a struct with normalized data and source metadata.
%   OPTIONS is an optional struct. SourceAxes labels the dimensions of the
%   array assembled from TIFF pages before normalization. For a grayscale
%   page stack, examples include "YXZ" and "YXT". For ImageJ hyperstacks,
%   embedded dimensions are used by default. Spacing gives spatial sample
%   spacing in [Y X Z] order. SpacingUnit gives its unit, such as "um" or
%   "nm". Explicit options override embedded TIFF/ImageJ calibration. When
%   neither is available, spacing defaults to [1 1 1] in pixels.
%   Grayscale multipage TIFFs without axis metadata default to YXZ (Z pages).
%   Explicit SourceAxes or recognized metadata take precedence; specify YXT
%   for a metadata-free time stack. Single-page/color layouts are preserved.
```

### imagestackiowriteImageJHyperstack

[Source](APIs/ImageStackIO/src/+imagestackio/writeImageJHyperstack.m)
```matlab
function writeImageJHyperstack(imageInput, filePath, options)
```

Literal option/specification names: Compression, Overwrite, Spacing, SpacingUnit.

Implemented function help:

```matlab
%WRITEIMAGEJHYPERSTACK Write a canonical [Y X Z C T] image as ImageJ TIFF.
%   Supports uint8, uint16, and logical pixel arrays. TIFF pages are stored
%   with C varying fastest, then Z, then T, with an ImageJ hyperstack
%   description to preserve the dimensions. OPTIONS supports Overwrite
%   (false by default), Compression ('LZW', 'Deflate', or 'None'), Spacing
%   in [Y X Z] order, and SpacingUnit. Spacing and SpacingUnit are taken
%   from an input image struct when present, then overridden by OPTIONS.
%   Their defaults are [1 1 1] and 'pixel'. FIJI receives X/Y calibration
%   through TIFF resolution tags and Z calibration through ImageJ metadata.
```

### imagestackiowriteTiff

[Source](APIs/ImageStackIO/src/+imagestackio/writeTiff.m)
```matlab
function writeTiff(imageInput, filePath, options)
```

Literal option/specification names: Compression, Overwrite, Spacing, SpacingUnit.

Implemented function help:

```matlab
%WRITETIFF Write a grayscale YXZ image or image struct as a TIFF stack.
%   imagestackio.writeTiff(IMAGE, FILEPATH, OPTIONS) writes one 2D image or
%   a Z stack. IMAGE can be a numeric YX/Z array, or an image struct with
%   Data in [Y X Z C T] order. C and T must be singleton dimensions.
%   Numeric input is interpreted as [Y X Z]. Supported pixel classes are
%   uint8, uint16, and logical. OPTIONS fields: Overwrite (false by default)
%   Compression ('LZW' by default; also 'Deflate' or 'None'), Spacing in
%   [Y X Z] order, and SpacingUnit. Spacing and SpacingUnit are taken from
%   an input image struct when present, then overridden by OPTIONS. Their
%   defaults are [1 1 1] and 'pixel'. FIJI receives X/Y calibration through
%   TIFF resolution tags and Z calibration through ImageJ metadata.
```

## ObjectGeometry interfaces


### objectgeometry.centerlines.measureFilaments

[Source](APIs/ObjectGeometry/src/+objectgeometry/+centerlines/measureFilaments.m)
```matlab
function [properties, objects] = measureFilaments(input, requested, options)
```

Literal option/specification names: ExtentWidthFloor, Identity.

Implemented function help:

```matlab
%MEASUREFILAMENTS Native and selected derived filament properties; no skeleton.
% REQUESTED: any native regionprops(3) name, plus Directors, AspectRatios,
% Lengths (historical voxel principal-axis length), ScaledDirectors,
% ProjectedExtent, ScaledAspectRatios. Derived values are opt-in.
% 'all' requests native properties only. OPTIONS.Identity holds prepareObjects
% options. ExtentWidthFloor=eps is positive in SpacingUnit units. Scaled values
% reuse the historical coordinate-scaled covariance/PCA method, WITHOUT
% resampling masks. Extent is max-minus-min of voxel CENTER projections, not
% equivalent-ellipsoid axis length. Metadata explicitly distinguishes units.
% Directors use [X Y Z] or [X Y] in image coordinates (Y increases downwards).
% Eigenvector sign is arbitrary; use nematic alignment, not polar direction.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('Identity',struct(),'ExtentWidthFloor',eps));
```

### objectgeometry.objects.attachMeasurements

[Source](APIs/ObjectGeometry/src/+objectgeometry/+objects/attachMeasurements.m)
```matlab
function combined=attachMeasurements(base,additional,options)
```

Literal option/specification names: ErrorNames, ErrorPrefix, MissingPolicy, Overwrite.

Implemented function help:

```matlab
%ATTACHMEASUREMENTS Attach properties by DatasetID/Frame/ObjectID, retaining order.
% MissingPolicy='error'|'missing', Overwrite=false. Grid compatibility is separate.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('MissingPolicy','error','Overwrite',false));
```

### objectgeometry.objects.distanceGradients

[Source](APIs/ObjectGeometry/src/+objectgeometry/+objects/distanceGradients.m)
```matlab
function [gradients, metadata, valid] = distanceGradients(distanceField, options)
```

Literal option/specification names: DerivativeUnits, DistanceUnit, FlipY, Normalize, Sigma, SmoothingOrder, Spacing, SpacingUnit.

Implemented function help:

```matlab
%DISTANCEGRADIENTS Reusable smoothed derivatives of signed/unsigned distance.
% INPUT: finite scalar 2-D or 3-D distance field. OPTIONS.Sigma=0 in voxels;
% scalar or [sigmaY sigmaX sigmaZ] (2-D uses first two). SmoothingOrder=
% 'gradient-first' (historical) or 'distance-first'; Normalize=false;
% FlipY=false (opt-in historical Cartesian conversion); Spacing=[1 1 1];
% SpacingUnit='pixel'; DerivativeUnits='voxel'|'physical'; DistanceUnit='voxel'.
% OUT components XYZ in [Y X Z D], even for 2-D output ([Y X 1 2]).
% VALID is false wherever magnitude is zero. Normalized invalid values are
% zero, not NaN. Sigma=0 bypasses smoothing; each spatial axis must have >=2
% samples except singleton Z (treated as 2-D). No implicit resizing occurs.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('Sigma',0,'SmoothingOrder','gradient-first', ...
    'Normalize',false,'FlipY',false,'Spacing',[1 1 1],'SpacingUnit','pixel', ...
    'DerivativeUnits','voxel','DistanceUnit','voxel'));
```

### objectgeometry.objects.generateGeometry

[Source](APIs/ObjectGeometry/src/+objectgeometry/+objects/generateGeometry.m)
```matlab
function geometry = generateGeometry(input, type, options)
```

Literal option/specification names: DistanceCutoff, GradientCutoff, Hessian, Identity, LayerMean, LayerWidth, Method, SampleFraction, SheetCombination, Sigma.

Implemented function help:

```matlab
%GENERATEGEOMETRY Optional index-based geometry independent of measurements.
% TYPE='skeleton' or 'boundary'. Each parent ID retains all disconnected
% entities; representations are generated per connected component. OUTPUT
% has Records keyed by DatasetID/Frame/ObjectID/ComponentID, Grid, SourceGrid,
% Transform and Options. Indices refer to CURRENT grid; never rounded XYZ.
%
% OPTIONS.Identity=struct(); Method='' -> skeleton:'blob', boundary:'shell';
% skeleton methods: 'blob' (skel3DBlobs), 'sheet' (skel3Dfrom2D union/intersection),
% 'sheet-sampled' (skel3DPop). Sigma=1, GradientCutoff=0.2, Hessian=false,
% SheetCombination='intersection'|'union', SampleFraction=0.5, DistanceCutoff=2.
% Boundary: LayerMean=0, LayerWidth=1, Sigma=1; uses returnSmoothBoundsBW.
% Empty skeletons retain Status='empty' and centroid/principal-axis fallback.
% Non-requested geometry is never created. Blob/sheet skeletons require 3-D.
% Each operation runs in a component bounding box with a background halo,
% isolating components even when the parent ID represents a disconnected lineage.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('Identity',struct(),'Method','', ...
    'Sigma',1,'GradientCutoff',0.2,'Hessian',false,'SheetCombination','intersection', ...
    'SampleFraction',0.5,'DistanceCutoff',2,'LayerMean',0,'LayerWidth',1));
```

### objectgeometry.objects.localInertia

[Source](APIs/ObjectGeometry/src/+objectgeometry/+objects/localInertia.m)
```matlab
function result=localInertia(occupancy,indices,options)
```

Literal option/specification names: BatchSize, Radius, ReturnTensors, SampleLimit, Sigma, Spacing, SpacingUnit.

Implemented function help:

```matlab
%LOCALINERTIA Historical neighborhood inertia at any user-selected indices.
% Uses smoothed total occupancy (neighbors included), mirrored padding,
% and [Y X Z] coordinate kernels from blobPropsFromTrajs_R_Inertia.
% Inertia is not vector covariance or global regionprops principal axes.
% All requested indices retained; optional SampleLimit selects calculation
% locations. Uncalculated descriptors are NaN. No fallback is inferred.
```

Literal defaults:

```matlab
o=objectgeometry.internal.options(options,struct('Radius',18,'Sigma',3, ...
    'Spacing',[1 1 1],'SpacingUnit','voxel','SampleLimit',Inf,'ReturnTensors',false,'BatchSize',32));
```

### objectgeometry.objects.measureObjects

[Source](APIs/ObjectGeometry/src/+objectgeometry/+objects/measureObjects.m)
```matlab
function [properties, objects] = measureObjects(input, requested, options)
```

Literal option/specification names: Intensity.

Implemented function help:

```matlab
%MEASUREOBJECTS User-selected native regionprops/regionprops3 properties.
% [TABLE,OBJECTS]=measureObjects(INPUT,PROPERTIES,OPTIONS). PROPERTIES is a
% cell/string array of native property names, or 'all'. Identity options go
% to prepareObjects; OPTIONS.Intensity=[] supplies matching grayscale data
% for native 2-D intensity properties. MATLAB determines property availability
% for the installed release. No custom properties computed silently.
% Table keys are DatasetID/Frame/ObjectID. Native geometric values are in
% pixel/voxel units. Centroid/BoundingBox/VoxelList use MATLAB XYZ ordering;
% raw 3-D EigenVectors retain MATLAB ordering (see measureFilaments).
% Optional large native properties are included only when requested.
```

### objectgeometry.objects.objectDistanceGradients

[Source](APIs/ObjectGeometry/src/+objectgeometry/+objects/objectDistanceGradients.m)
```matlab
function [gradients, distanceField, metadata, valid] = objectDistanceGradients(mask, options)
```

Literal option/specification names: DistanceType.

Implemented function help:

```matlab
%OBJECTDISTANCEGRADIENTS Build a distance field and use distanceGradients.
% OPTIONS.DistanceType='signed'|'interior'|'exterior'. Signed uses the user's
% signedBWDist convention: object boundary zero, deeper interior negative.
% Interior=bwdist(~mask); exterior=bwdist(mask). Distance values remain in
% voxel units (anisotropic distance correction deferred). Remaining options
% are those of distanceGradients. Empty/full masks have no finite opposite
% phase: return their distance field, NaN gradients and false validity.
```

### objectgeometry.objects.prepareObjects

[Source](APIs/ObjectGeometry/src/+objectgeometry/+objects/prepareObjects.m)
```matlab
function objects = prepareObjects(input, options)
```

Literal option/specification names: Channel, Connectivity, DatasetID, Frame, ImageSize, InputType, ObjectIDs, SourceGrid, Spacing, SpacingUnit, TimeIndex, Transform.

Implemented function help:

```matlab
%PREPAREOBJECTS Preserve supplied identities or compute connected components.
% INPUT: logical mask, numeric mask/labels, TIFF path/ImageStackIO image, bwconncomp structure, cell of
% index vectors, or an already prepared structure. No label volume allocated.
% Numeric binary input defaults to mask; InputType='labels' removes ambiguity.
% Nonzero labels define one object each, including disconnected regions.
% OPTIONS: InputType='auto'|'mask'|'labels'|'indices'|'components'; ImageSize=[]
% (required for index cells); ObjectIDs=[] (for masks/components/index cells);
% Connectivity=[] (8/26 default); DatasetID='default'; Frame=1;
% Channel=1 and TimeIndex=1 select TIFF/ImageStackIO data. Image calibration
% is inherited unless Spacing/SpacingUnit are explicitly overridden.
% Spacing=[1 1 1] in YXZ; SpacingUnit='pixel'; SourceGrid=[]; Transform=[].
% Grid metadata describes CURRENT indices. SourceGrid and Transform record
% previous grids/mappings; spacing is recorded, not used to resample input.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('InputType','auto', ...
    'ImageSize',[],'ObjectIDs',[],'Connectivity',[],'DatasetID','default', ...
    'Frame',1,'Spacing',[1 1 1],'SpacingUnit','pixel','SourceGrid',[], 'Transform',[], ...
    'Channel',1,'TimeIndex',1));
```

### objectgeometry.orientation.nematicAlignment

[Source](APIs/ObjectGeometry/src/+objectgeometry/+orientation/nematicAlignment.m)
```matlab
function result = nematicAlignment(directors, reference, options)
```

Literal option/specification names: MaxNormalComponent, Plane.

Implemented function help:

```matlab
%NEMATICALIGNMENT Normalize -> optionally project -> normalize -> dot -> order.
% Reuses Display_AvgAlign_FromRBins formulas, with sign-invariant filtering.
% INPUT Nx2 or Nx3 vectors in the SAME coordinate convention, reference NxD
% or 1xD. OPTIONS.Plane=[] for full dimension, [1 2] etc for projection;
% MaxNormalComponent=[] optionally excludes 3-D directors with abs(normal)
% exceeding this cutoff BEFORE projection. Only used with a 3-D plane.
% Zero vectors/projections are invalid and produce NaN. Signed angle is only
% defined in an ordered 2-D plane. No polar orientation/head-tail inference.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('Plane',[],'MaxNormalComponent',[]));
```

## ObjectRelativeProfiles interfaces


### objectrelativeprofiles.fieldSampling.attachResults

[Source](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/attachResults.m)
```matlab
function combined=attachResults(base,additional,options)
```

Literal option/specification names: ErrorNames, ErrorPrefix, MissingPolicy, Overwrite.

Implemented function help:

```matlab
%ATTACHRESULTS Component-aware keyed join; absent ComponentID means parent (0).
% MissingPolicy='error'|'missing', Overwrite=false. Spatial alignment is separate.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('MissingPolicy','error','Overwrite',false));
```

### objectrelativeprofiles.fieldSampling.prepareSupport

[Source](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/prepareSupport.m)
```matlab
function support = prepareSupport(input, imageSize, options)
```

Literal option/specification names: CentroidFallback, ComponentResults, DatasetID, Frame, Grid, Name, ObjectIDs, Type.

Implemented function help:

```matlab
%PREPARESUPPORT Sampling groups without implicit connected-component analysis.
% INPUT: indices, logical mask, label matrix, cell index groups, prepared
% ObjectGeometry objects, generated geometry, or an already prepared support.
% OPTIONS: Type='auto'|'indices'|'mask'|'labels'; ObjectIDs=[];
% DatasetID='default'; Frame=1; Name='selection'; Grid=[];
% ComponentResults=false; CentroidFallback=true. Indices are deduplicated
% within each group; groups may overlap. Numeric vectors default to indices,
% other numeric matrices to labels. Explicit Type resolves ambiguous inputs.
% Geometry components combine by parent ID by default. Empty skeletons use
% nearest-voxel centroid fallback, flagged separately from computed geometry.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('Type','auto','ObjectIDs',[], ...
    'DatasetID','default','Frame',1,'Name','selection','Grid',[], ...
    'ComponentResults',false,'CentroidFallback',true));
```

### objectrelativeprofiles.fieldSampling.queryField

[Source](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/queryField.m)
```matlab
function results = queryField(field, inputSupport, requested, options)
```

Literal option/specification names: BinEdges, CustomOperations, Field, FieldName, Grid, NumBins, Quantiles, SampleOperation, Support, VarianceNormalization.

Implemented function help:

```matlab
%QUERYFIELD Scalar/component statistics at indices, masks or ID groups.
% FIELD is one XYZ numeric array, struct(Data,Grid), or named fields for a
% SampleOperation. Named fields must each be same-frame matching XYZ arrays.
% REQUESTED: Count, Sum, Mean, Median, Variance, Std, Min, Max, Quantiles,
% Histogram, or 'all'. Statistics use FINITE samples only. Always records
% selected/finite counts, NaN/+Inf/-Inf counts and empty/fallback flags.
% OPTIONS.FieldName='Field'; Support=struct() -> prepareSupport options;
% Grid=[]; Quantiles=[.25 .5 .75]; BinEdges=[]; NumBins=[] (MATLAB automatic);
% VarianceNormalization=0 (sample) or 1 (population); SampleOperation=[];
% CustomOperations=struct() of named @(finiteSamples) reducers.
% Raw sample storage is deliberately deferred. Metadata mismatches are
% recorded, never automatically remapped. Dimensions must match.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('FieldName','Field','Support',struct(), ...
    'Grid',[],'Quantiles',[.25 .5 .75],'BinEdges',[],'NumBins',[], ...
    'VarianceNormalization',0,'SampleOperation',[],'CustomOperations',struct()));
```

### objectrelativeprofiles.fieldSampling.queryFrame

[Source](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/queryFrame.m)
```matlab
function results = queryFrame(fields, supports, queries)
```

Literal option/specification names: ComponentNames, Field, FieldName, Fields, Kind, Mode, Name, Operation, Options, SampleOperation, Statistics, Support.

Implemented function help:

```matlab
%QUERYFRAME All named queries for one frame; accepts several XYZ fields.
% FIELDS is a struct of named XYZ arrays or struct(Data,Grid).
% SUPPORTS is a struct of named raw/prepared supports. QUERIES is a struct
% array; each query has Name (unique column prefix), Support (support name),
% Statistics, optional Options, and EITHER Field (field name) OR Operation
% Vector queries use Kind='vector', Fields={component names in coordinate
% order}, and Options for queryVectorField. Operations remain scalar queries.
% (@(fields) ...) with Mode='field'|'samples' and optional Fields (names needed).
% Field operations return one matching XYZ field. Sample operations receive
% selected vectors in a named struct and return one value per location.
% Operation handles can call other functions internally. All queries are
% attached by identity. Supports with different ID sets require explicit
% querying/attachment with missing policy rather than silent row expansion.
```

### objectrelativeprofiles.fieldSampling.queryVectorField

[Source](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/queryVectorField.m)
```matlab
function results = queryVectorField(fields, inputSupport, requested, options)
```

Literal option/specification names: ComponentNames, FieldName, Grid, Support, VarianceNormalization, Vector.

Implemented function help:

```matlab
%QUERYVECTORFIELD Same-frame vectors with independent component validity.
% FIELDS: named XYZ scalar components, each array or struct(Data,Grid).
% OPTIONS.ComponentNames is REQUIRED, in explicit coordinate order (2 or 3).
% FieldName='Vector'; Support=struct(); Grid=[]; VarianceNormalization=0.
% Requested: ComponentMean/Variance/Std/Min/Max, MeanVector, MagnitudeOfMean,
% MeanMagnitude, MagnitudeStd, MinMagnitude, MaxMagnitude, RMSMagnitude,
% Covariance, or 'all'. No director/nematic or circular statistics implied.
%
% Component statistics use each component's finite values independently.
% MeanVector contains those independent means, with per-component counts.
% MagnitudeOfMean is the norm of that vector, NOT mean magnitude.
% Magnitudes require every component finite AT THAT VOXEL. Covariance uses
% pairwise-finite samples with a separate count per pair, not whole-selection
% exclusion. Pairwise covariance may not be positive semidefinite when pairs
% have different valid samples. Pair means are recomputed for each pair.
% RMSMagnitude uses complete finite vectors. Zero vectors are valid.
% NaN/+Inf/-Inf counts are preserved separately for EACH component.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('ComponentNames',[], ...
    'FieldName','Vector','Support',struct(),'Grid',[],'VarianceNormalization',0));
```

### objectrelativeprofiles.fieldSampling.runFieldBatch

[Source](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/runFieldBatch.m)
```matlab
function manifest = runFieldBatch(frames, fieldSpecs, supportLoader, queries, options)
```

Literal option/specification names: DatasetID, OutputDirectory, Overwrite, RetainTables.

Implemented function help:

```matlab
%RUNFIELDBATCH Stream frames, allowing multiple XYZ fields within ONE frame.
% FIELDSPECS: struct array with Name and Loader=@(frame) -> XYZ or Data/Grid.
% SUPPORTLOADER=@(frame,fields) -> named supports (user injection point).
% QUERIES: queryFrame specifications. OPTIONS.OutputDirectory is REQUIRED;
% DatasetID='default'; Overwrite=false; RetainTables=false. Saves each completed
% frame immediately as MAT. Manifest contains frame/path/count; optional Tables
% retains SMALL result tables only. No XYZT fields/masks are preloaded.
% Failures stop execution; previously saved frames remain available.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('OutputDirectory','', ...
    'DatasetID','default','Overwrite',false,'RetainTables',false));
```

## ObjectTracking interfaces


### objecttrackingrenderTrackingFrame

[Source](APIs/ObjectTracking/src/+objecttracking/renderTrackingFrame.m)
```matlab
function [labels, map] = renderTrackingFrame(objects, membership, options)
```

Literal option/specification names: CompactIDs, FilePath, Overwrite.

Implemented function help:

```matlab
%RENDERTRACKINGFRAME Optional trajectory labels; no scientific mask changes.
% OPTIONS.FilePath=''; Overwrite=false; CompactIDs=false. TIFF writers support
% uint16; larger trajectories error unless CompactIDs=true. Compact rendering
% returns/stores a map from StoredID to TrajectoryID; never silently truncates.
% Input membership must match dataset/frame and cover every current ObjectID.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('FilePath','','Overwrite',false,'CompactIDs',false));
```

### objecttrackingselectLineage

[Source](APIs/ObjectTracking/src/+objecttracking/selectLineage.m)
```matlab
function selection = selectLineage(tracking, seed, options)
```

Literal option/specification names: Direction, IncludeSeed, Loader.

Implemented function help:

```matlab
%SELECTLINEAGE Directed reachability, not weak connected lineage expansion.
% SEED struct: ObjectIDs+Frame, TrajectoryIDs, DetectionIDs, or CoordinatesYXZ
% +Frame. Coordinates require OPTIONS.Loader=@(frame) -> prepared objects.
% Direction='ancestors'|'descendants'|'both'|'self'; IncludeSeed=true.
% Background coordinates yield no seed and report coordinates/status. Traversal
% never switches direction at an ancestor to collect unrelated siblings.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('Direction','ancestors','IncludeSeed',true,'Loader',[]));
```

### objecttrackingselectTrajectories

[Source](APIs/ObjectTracking/src/+objecttracking/selectTrajectories.m)
```matlab
function [selected, summary] = selectTrajectories(membership, options)
```

Literal option/specification names: MinDetections, MinFrameSpan.

Implemented function help:

```matlab
%SELECTTRAJECTORIES Post-tracking selection without renumbering identities.
% MinDetections=1; MinFrameSpan=1. FrameSpan=end-start+1; ObservationCount counts
% actual rows, including gaps. Selection leaves original TrajectoryIDs intact.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('MinDetections',1,'MinFrameSpan',1));
```

### objecttrackingtrackOverlaps

[Source](APIs/ObjectTracking/src/+objecttracking/trackOverlaps.m)
```matlab
function tracking = trackOverlaps(frames, loader, options)
```

Literal option/specification names: DatasetID, ExportDirectory, Identity, MergePolicy, Overwrite, Ranking, SplitPolicy.

Implemented function help:

```matlab
%TRACKOVERLAPS Stream successive supplied frames using overlap inheritance.
% LOADER=@(frame) -> mask, label array, TIFF path or prepared objects.
% Numeric binary input defaults to components; InputType='labels' preserves
% disconnected pieces carrying label 1. Other label IDs are preserved.
% OPTIONS.DatasetID='default'; Identity=struct() prepareObjects options;
% Ranking='overlap'|'volume'; MergePolicy='inherit'|'new'; SplitPolicy likewise;
% ExportDirectory=''; Overwrite=false. Arbitrary spacing/order is accepted.
% Repeated frame numbers are omitted, retaining their first occurrence.
% No missing-detection gap recovery; load failure stops processing.
% Ancestry follows the supplied processing order, including reverse order.
% Ranking volume uses source+target voxel count: largest parent at pure merges
% and largest child at pure splits. For many-to-many events, ranked greedy
% one-to-one inheritance is deterministic (not global assignment optimization).
% Ties: smallest source then target ObjectID. ALL ancestry edges remain saved.
% Assumes modest displacement and spatially registered masks across frames.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('DatasetID','default','Identity',struct(), ...
    'Ranking','overlap','MergePolicy','inherit','SplitPolicy','inherit', ...
    'ExportDirectory','','Overwrite',false));
```

### objecttracking.trackpy.exportDetections

[Source](APIs/ObjectTracking/src/+objecttracking/+trackpy/exportDetections.m)
```matlab
function [matrix, map] = exportDetections(detections, options)
```

Literal option/specification names: CoordinateScale, MassProperty.

Implemented function help:

```matlab
%EXPORTDETECTIONS Explicit original-row identity map for position tracking.
% Input table DatasetID/Frame/ObjectID/Centroid (XYZ or XY). One dataset only.
% MassProperty='' uses ones; e.g. 'Volume' preserves historical mass column.
% CoordinateScale=[] optionally scales each coordinate WITHOUT matrix resizing.
% Numeric output is [coordinates mass frame]. RowID is one-based original row,
% explicitly carried through Python; not inferred from frame counts/order.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('MassProperty','','CoordinateScale',[]));
```

### objecttracking.trackpy.trackPositions

[Source](APIs/ObjectTracking/src/+objecttracking/+trackpy/trackPositions.m)
```matlab
function membership = trackPositions(detections, options)
```

Literal option/specification names: CoordinateScale, Linker, MassProperty, Memory, SearchRange.

Implemented function help:

```matlab
%TRACKPOSITIONS Optional Python Trackpy backend; no merge/split inference.
% SearchRange=8 (same units as scaled coordinates), Memory=3 missing frames;
% MassProperty=''; CoordinateScale=[]; Linker=[] optional injection for tests
% or external execution: @(matrix,range,memory)->[RowID TrajectoryID], one-based.
% Requires configured MATLAB pyenv, numpy, pandas, trackpy unless Linker supplied.
```

Literal defaults:

```matlab
options=objectgeometry.internal.options(options,struct('SearchRange',8,'Memory',3, ...
    'MassProperty','','CoordinateScale',[],'Linker',[]));
```

## SegmentationTools interfaces


### segmentationtools.binarization.classifyProbabilities

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/classifyProbabilities.m)
```matlab
function result = classifyProbabilities(probabilities, classes, options)
```

Literal option/specification names: AssignUnclassified, Connectivity, CountComponents, EnsureDisjoint, ReturnCandidateMasks, ReturnChangedVoxelMask, ReturnLabelVolume, ReturnMasks, ReturnOverlapMask, ReturnUnclassifiedMask.

Implemented function help:

```matlab
%CLASSIFYPROBABILITIES Convert [Y X Z C] probabilities into class masks.
%   RESULT = CLASSIFYPROBABILITIES(PROBABILITIES, CLASSES, OPTIONS) uses
%   class definitions from makeClassConfig. Threshold comparisons are
%   strict. Inputs are not normalized internally.
%
%   Default behavior is disjoint but not exhaustive: overlapping candidate
%   classes are assigned to the class with the greatest aggregate score;
%   exact ties go to the class appearing first in CLASSES. Voxels passing
%   no threshold remain zero/unclassified. Set AssignUnclassified=true to
%   assign them by maximum aggregate score.
%
%   OPTIONS fields:
%     EnsureDisjoint          true
%     AssignUnclassified      false
%     ReturnLabelVolume       true
%     ReturnMasks             false
%     ReturnCandidateMasks    false
%     ReturnOverlapMask       false
%     ReturnUnclassifiedMask  false
%     ReturnChangedVoxelMask  false
%     CountComponents         false
%     Connectivity            26 for 3-D, 8 for 2-D
%
%   Full-size representations are constructed in RESULT only when their
%   corresponding return option is true. Candidate masks and scores are
%   still used internally to resolve classes.
```

Literal defaults:

```matlab
defaults = struct('EnsureDisjoint', true, 'AssignUnclassified', false, ...
    'ReturnLabelVolume', true, 'ReturnMasks', false, ...
    'ReturnCandidateMasks', false, 'ReturnOverlapMask', false, ...
    'ReturnUnclassifiedMask', false, 'ReturnChangedVoxelMask', false, ...
    'CountComponents', false, 'Connectivity', []);
```

### segmentationtools.binarization.classifyProbabilityChannels

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/classifyProbabilityChannels.m)
```matlab
function result = classifyProbabilityChannels(probabilities, channels, thresholds, options)
```

Literal option/specification names: ClassifyOptions, IDs, Names.

Implemented function help:

```matlab
%CLASSIFYPROBABILITYCHANNELS Classify selected channels as distinct classes.
%   RESULT = CLASSIFYPROBABILITYCHANNELS(P, CHANNELS, THRESHOLDS, OPTIONS)
%   constructs one class per selected probability channel. When CHANNELS is
%   empty, every channel in P is selected. P is [Y X Z C].
%
%   OPTIONS.Names and OPTIONS.IDs customize class metadata.
%   OPTIONS.ClassifyOptions is passed to classifyProbabilities.
```

### segmentationtools.binarization.makeClassConfig

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/makeClassConfig.m)
```matlab
function classes = makeClassConfig(channels, thresholds, options)
```

Literal option/specification names: IDs.

Implemented function help:

```matlab
%MAKECLASSCONFIG Build semantic class definitions from compact arrays.
%   CLASSES = MAKECLASSCONFIG(CHANNELS, THRESHOLDS) creates one class for
%   each channel. CHANNELS may also be a cell array, where each cell lists
%   the probability channels that form one class. THRESHOLDS may be a
%   scalar, a numeric vector with one value per class, or a cell array with
%   one scalar/vector entry per class.
%
%   OPTIONS is an optional scalar struct:
%     Names          class names; defaults to class1, class2, ...
%     CombineMethods "sum" or "union" per class; default "sum"
%     IDs            positive integer output IDs; default 1:N
%
%   A class is a semantic segmentation result. A channel is one stored
%   probability field. A class may therefore use one or several channels.
```

### segmentationtools.binarization.remapClassLabels

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/remapClassLabels.m)
```matlab
function mapped = remapClassLabels(labels, sourceIDs, outputValues, options)
```

Literal option/specification names: OutputType, UnmappedValue.

Implemented function help:

```matlab
%REMAPCLASSLABELS Map categorical class IDs to user-selected values.
%   MAPPED = REMAPCLASSLABELS(LABELS, SOURCEIDS, OUTPUTVALUES) replaces
%   each SOURCEIDS value with its corresponding OUTPUTVALUES value.
%   Background/unclassified zero remains zero by default.
%
%   OPTIONS.UnmappedValue defaults to zero. OPTIONS.OutputType may be a
%   MATLAB integer class name. If omitted, the smallest unsigned integer
%   type that can represent OUTPUTVALUES and UnmappedValue is selected.
```

### segmentationtools.binarization.segmentInOnOutProbabilities

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/segmentInOnOutProbabilities.m)
```matlab
function result = segmentInOnOutProbabilities(probabilities, channels, thresholds, options)
```

Literal option/specification names: ClassifyOptions, CombineMethods.

Implemented function help:

```matlab
%SEGMENTINONOUTPROBABILITIES Segment inside, wall, and outside classes.
%   RESULT = SEGMENTINONOUTPROBABILITIES(P, CHANNELS, THRESHOLDS, OPTIONS)
%   uses the semantic order [inside, wall, outside], corresponding to the
%   historical shorthand [in, on, out]. P is [Y X Z C]. CHANNELS may be a
%   three-element numeric vector or a three-cell array of grouped channels.
%
%   OPTIONS.CombineMethods defaults to "sum" for each class.
%   OPTIONS.ClassifyOptions is passed to classifyProbabilities. The default
%   result is disjoint, is not necessarily exhaustive, and contains one
%   label volume with IDs [1 2 3] for [inside wall outside].
```

### segmentationtools.binarization.segmentIntensity

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/segmentIntensity.m)
```matlab
function result = segmentIntensity(intensity, options)
```

Literal option/specification names: Connectivity, EstimationMask, FillHoles, Foreground, IntensityRange, KeepLargest, Method, MinObjectSize, ReturnLabels, Threshold.

Implemented function help:

```matlab
%SEGMENTINTENSITY Generate a basic foreground morphology from intensity.
% Input: one finite real 2-D image or [Y X Z] volume. Select channel/time
% before calling. Requires Image Processing Toolbox. No files are written.
%
% OPTIONS (scalar struct; all optional):
%   Method          'otsu' (default) or 'fixed'. One threshold per volume.
%   Threshold       [] by default; required for fixed, in ORIGINAL units.
%   Foreground      'bright' (default) or 'dark'; strict > or < threshold.
%   IntensityRange  [] uses observed min/max for Otsu scaling; otherwise
%                   [low high] in original units, clipping only for fitting.
%   EstimationMask  [] uses all voxels to estimate range/threshold; logical
%                   mask selects reference voxels, NOT output support.
%   FillHoles       false; fill enclosed holes (2-D/3-D) before filtering.
%   MinObjectSize   0; remove components smaller than this voxel count.
%   KeepLargest     []; optionally keep this many largest components.
%   Connectivity    []; defaults to 8 (2-D), 26 (3-D).
%   ReturnLabels    false; optionally label individual connected objects.
%
% RESULT.Mask is the final logical morphology; CandidateMask is the strict
% threshold result before cleanup. Threshold is in original intensity units.
% IntensityRange records Otsu scaling. VoxelCount and ComponentCount describe
% the final mask. LabelVolume, when requested, stores object IDs, NOT classes.
% This is foreground selection, not probability estimation or touching-cell
% separation. Cleanup order: fill holes, minimum size, largest components.
%
% Example: r = segmentationtools.binarization.segmentIntensity(volume);
% Fixed: r = segmentationtools.binarization.segmentIntensity(volume, ...
%     struct('Method','fixed','Threshold',1200,'MinObjectSize',100));
```

Literal defaults:

```matlab
defaults = struct('Method','otsu','Threshold',[],'Foreground','bright', ...
    'IntensityRange',[],'EstimationMask',[],'FillHoles',false, ...
    'MinObjectSize',0,'KeepLargest',[],'Connectivity',[],'ReturnLabels',false);
```

### segmentationtools.binarization.smoothInOnOutProbabilities

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/smoothInOnOutProbabilities.m)
```matlab
function [inside, wall, outside, info] = smoothInOnOutProbabilities(probabilities, channels, thresholds, options)
```

Literal option/specification names: OpeningRadius, SpanSpace.

Implemented function help:

```matlab
%SMOOTHINONOUTPROBABILITIES Historical in/on/out opening workflow.
%   Inputs use semantic order [inside, wall, outside]. Each selected channel
%   is strictly thresholded and opened using erosion followed by dilation.
%
%   OPTIONS.OpeningRadius defaults to 2 voxels. OPTIONS.SpanSpace defaults
%   to false. When SpanSpace=true, wall is the complement of cleaned inside
%   and outside. Otherwise wall is thresholded/opened independently, which
%   can overlap the other returned masks. This preserves the historical
%   h5toSmooth3Chans behavior behind a clearly named function.
```

### segmentationtools.binarization.smoothNChannelProbabilities

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/smoothNChannelProbabilities.m)
```matlab
function [masks, info] = smoothNChannelProbabilities(probabilities, channels, thresholds, options)
```

Literal option/specification names: ChannelPrecedence, OpeningRadius, ReturnOpenedMasks.

Implemented function help:

```matlab
%SMOOTHNCHANNELPROBABILITIES Threshold, open, and resolve N channel masks.
% P is [Y X Z C]. CHANNELS=[] selects all channels in input order.
% THRESHOLDS is one shared value or one per selected channel, aligned with
% CHANNELS (not precedence). Comparisons are strict; no normalization occurs.
% MASKS is logical [Y X Z N], in CHANNELS order, and is always disjoint.
% Voxels not retained by any opened mask stay unclassified.
%
% OPTIONS.OpeningRadius: nonnegative integer, default 2 voxels; 0 disables
% opening. Each candidate is eroded then dilated independently before overlap
% resolution. A disk is used for 2-D input and sphere for 3-D input. Radius
% is in voxel units; anisotropic spacing is not corrected.
% OPTIONS.ChannelPrecedence: actual INPUT CHANNEL NUMBERS in highest-to-lowest
% priority order. Must contain each selected channel exactly once. Defaults
% to CHANNELS order. Earlier channels win regardless of probability magnitude.
% Output channel order does not change when precedence changes.
% OPTIONS.ReturnOpenedMasks: logical, default false; retain opened masks in
% INFO.OpenedMasks for comparison before conflict resolution.
%
% INFO reports channels, precedence, thresholds, radius, per-channel voxel
% counts, overlap voxel count after opening/before resolution, and unclassified
% voxel count. No complement class is inferred (unlike historical SpanSpace).
%
% [m,info] = segmentationtools.binarization.smoothNChannelProbabilities( ...
%     p,[1 3 2],[0.2 0.5 0.5], ...
%     struct('OpeningRadius',1,'ChannelPrecedence',[3 1 2]));
```

Literal defaults:

```matlab
defaults=struct('OpeningRadius',2,'ChannelPrecedence',[], 'ReturnOpenedMasks',false);
```

### segmentationtools.binarization.thresholdProbabilityGroup

[Source](APIs/SegmentationTools/src/+segmentationtools/+binarization/thresholdProbabilityGroup.m)
```matlab
function [mask, info] = thresholdProbabilityGroup(probabilities, channels, thresholds, options)
```

Literal option/specification names: CombineMethod, ReturnScore.

Implemented function help:

```matlab
%THRESHOLDPROBABILITYGROUP Threshold one semantic probability class.
%   MASK = THRESHOLDPROBABILITYGROUP(P, CHANNELS, THRESHOLDS, OPTIONS)
%   accepts P in [Y X Z C] order. A [Y X Z] array is one channel.
%
%   OPTIONS.CombineMethod is "sum" (default) or "union". Sum adds the
%   requested probability channels, then applies one strict threshold.
%   Union applies strict thresholds independently and unions the masks.
%   Union accepts one shared threshold or one threshold per channel.
%   Inputs are not normalized internally.
%
%   OPTIONS.ReturnScore controls whether INFO.Score is retained. The score
%   is the summed probability for "sum" and the maximum selected-channel
%   probability for "union". It defaults to false to avoid retaining an
%   additional full-size array when it is not needed.
```

### segmentationtools.io.readProbabilityTiff

[Source](APIs/SegmentationTools/src/+segmentationtools/+io/readProbabilityTiff.m)
```matlab
function [probabilities, image] = readProbabilityTiff(filePath, options)
```

Literal option/specification names: TimeAsChannels, TimeIndex.

Implemented function help:

```matlab
%READPROBABILITYTIFF Read a TIFF probability stack as [Y X Z C].
%   This wrapper uses imagestackio.readTiff, whose canonical representation
%   is [Y X Z C T]. ImageJ metadata is used when available. A TIFF with
%   channels and more than one time point requires OPTIONS.TimeIndex.
%
%   OPTIONS.SourceAxes is passed to imagestackio.readTiff when metadata is
%   missing or must be overridden. OPTIONS.TimeIndex selects one timepoint.
%   OPTIONS.TimeAsChannels=false by default. When true, singleton-C YXZT
%   data is explicitly reinterpreted as YXZC. This is never done silently.
```

### segmentationtools.io.writeMaskTiff

[Source](APIs/SegmentationTools/src/+segmentationtools/+io/writeMaskTiff.m)
```matlab
function writeMaskTiff(mask, filePath, options)
```

Literal option/specification names: .

Implemented function help:

```matlab
%WRITEMASKTIFF Write a requested mask representation to TIFF.
%   WRITEMASKTIFF(MASK, FILEPATH, OPTIONS) writes logical or nonnegative
%   integer-valued [Y X Z] data using imagestackio.writeTiff. [Y X Z C]
%   data is written as an ImageJ hyperstack with singleton time.
%
%   This function performs no class remapping. Use remapClassLabels first
%   when stored values such as 85/170/255 are required. Files are created
%   only when this function is called.
```

### segmentationtools.morphologySpecific.sheets.returnTopBottom2DSheetsConfigurable

[Source](APIs/SegmentationTools/src/+segmentationtools/+morphologySpecific/+sheets/returnTopBottom2DSheetsConfigurable.m)
```matlab
function [topLayer,botLayer,topLayerZs,botLayerZs,centerSlice,centerSliceZs,splitSlice] = returnTopBottom2DSheetsConfigurable(inputData,options)
```

Literal option/specification names: Connectivity, GapHalfWidth, SplitSearchRange, SplitSlice.

Implemented function help:

```matlab
%RETURNTOPBOTTOM2DSHEETSCONFIGURABLE Separate two dominant sheets in a mask.
% Configurable copy of returnTopBottom2DSheets.m; the original is retained.
%
% INPUTDATA is one binary [Y X Z] volume. Select channel and time before
% calling this function. Numeric zeros/ones and logical arrays are accepted.
%
% OPTIONS is an optional scalar struct with these fields:
%   SplitSlice       [] (default): detect a local occupancy minimum nearest
%                    the volume's central Z slice. Otherwise, supply an
%                    integer Z index to override automatic detection.
%   SplitSearchRange [] (default): consider minima throughout the volume.
%                    Otherwise, supply inclusive [firstZ lastZ] bounds.
%                    Used only for automatic detection. Minima are detected
%                    on the full occupancy profile, then filtered by range.
%   GapHalfWidth     2 (default): remove SplitSlice +/- this many slices.
%                    Zero removes only the split slice. Units are voxels.
%   Connectivity     26 (default): 6, 18, or 26 for connected components.
%                    6 joins face neighbors; 18 also joins edge neighbors;
%                    26 additionally joins corner neighbors.
%
% The two largest remaining components are selected, then ordered by mean
% Z index. TOP means smaller mean Z index, not necessarily physical top.
% TOPLAYER and BOTLAYER are logical masks. Their corresponding Z arrays
% contain Z indices at selected voxels and zero elsewhere. CENTERSLICE is
% the original material removed by the cut (the entire band, despite its
% historical name). CENTERSLICEZS contains its Z indices. SPLITSLICE is the
% selected Z index. All mask and coordinate arrays retain the input size.
%
% The removal band must fit inside the volume. No automatic clipping or
% fallback split is applied. An error is raised if no local minimum is found
% in the search range or fewer than two components remain after cutting.
% This function does not guarantee one component on each side of the gap.
%
% Requires Image Processing Toolbox (bwconncomp), and Signal Processing
% Toolbox (findpeaks) when SplitSlice is not supplied.
%
% Example, after adding APIs/SegmentationTools/src to the MATLAB path:
%   opts = struct('SplitSlice', 30, 'GapHalfWidth', 2, 'Connectivity', 26);
%   [top,bottom] = segmentationtools.morphologySpecific.sheets.returnTopBottom2DSheetsConfigurable(mask, opts);
```

Literal defaults:

```matlab
defaults = struct('SplitSlice', [], 'SplitSearchRange', [], ...
    'GapHalfWidth', 2, 'Connectivity', 26);
```

## SharedUtilities interfaces


### sharedutilities.numerics.GaussD

[Source](APIs/SharedUtilities/src/+sharedutilities/+numerics/GaussD.m)
```matlab
function dG = GaussD(sigma, n, varargin)
```

Literal option/specification names: .

### sharedutilities.structsAndTables.attachByKeys

[Source](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/attachByKeys.m)
```matlab
function combined=attachByKeys(base,additional,keys,options)
```

Literal option/specification names: AllowRepeatedBase, Columns, ErrorNames, ErrorPrefix, MissingPolicy, Overwrite.

Implemented function help:

```matlab
%ATTACHBYKEYS Attach columns by explicit keys, retaining destination row order.
% Additional keys must be unique; repeated base keys are opt-in (parent mapping).
% Columns defaults to all non-key columns. MissingPolicy='error'|'missing'.
% Integer/logical missing columns become double NaN; finite zero remains zero.
```

Literal defaults:

```matlab
o=sharedutilities.internal.options(options,struct('MissingPolicy','error','Overwrite',false, ...
    'AllowRepeatedBase',false,'Columns',{{}},'ErrorPrefix','sharedutilities','ErrorNames',struct()));
```

### sharedutilities.structsAndTables.concatenateByKeys

[Source](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/concatenateByKeys.m)
```matlab
function combined=concatenateByKeys(tables,keys,options)
```

Literal option/specification names: ErrorNames, ErrorPrefix.

Implemented function help:

```matlab
%CONCATENATEBYKEYS Append matching-schema tables; preserve keys/order/metadata.
```

Literal defaults:

```matlab
o=sharedutilities.internal.options(options,struct('ErrorPrefix','sharedutilities','ErrorNames',struct()));
```

### sharedutilities.structsAndTables.validateTableKeys

[Source](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/validateTableKeys.m)
```matlab
function validateTableKeys(t,keys,options)
```

Literal option/specification names: AllowRepeated, ErrorNames, ErrorPrefix.

Implemented function help:

```matlab
%VALIDATETABLEKEYS Validate explicit scalar keys and optional uniqueness.
% Known object keys use DatasetID string, nonnegative integer Frame/ComponentID,
% positive integer ObjectID. TrajectoryID is a property unless explicitly keyed.
```

Literal defaults:

```matlab
o=sharedutilities.internal.options(options,struct('AllowRepeated',false, ...
    'ErrorPrefix','sharedutilities','ErrorNames',struct()));
```

## FieldAnalysis interfaces


### fieldanalysis.internal.spectrum

[Source](APIs/FieldAnalysis/src/+fieldanalysis/+internal/spectrum.m)
```matlab
function result=spectrum(data,nD,options)
```

Literal option/specification names: Edges, MeanSubtract, NumBins, ReturnPower, Sigma, Spacing, SpacingUnit, Window.

Implemented function help:

```matlab
%SPECTRUM samAdapted squared FFT magnitude; scalar normalization is external.
```

Literal defaults:

```matlab
o=fieldanalysis.internal.options(struct('Spacing',ones(1,nD),'SpacingUnit','voxel', ...
    'MeanSubtract',false,'Window',true,'Edges',[],'NumBins',50,'Sigma',0, ...
    'ReturnPower',false),options);
```

## ImageStackIO interfaces


### imagestackioparseSpacingOptions

[Source](APIs/ImageStackIO/src/+imagestackio/private/parseSpacingOptions.m)
```matlab
function [spacing, spacingUnit] = parseSpacingOptions(options)
```

Literal option/specification names: Spacing, SpacingUnit.

Implemented function help:

```matlab
%PARSESPACINGOPTIONS Validate spatial calibration loader options.
%   Spacing follows the canonical spatial axis order [Y X Z].
```

### imagestackioparseTiffAxisOrder

[Source](APIs/ImageStackIO/src/+imagestackio/private/parseTiffAxisOrder.m)
```matlab
function axes = parseTiffAxisOrder(description)
```

Literal option/specification names: .

Implemented function help:

```matlab
%PARSETIFFAXISORDER Parse Image Stack I/O's axis marker from a TIFF comment.
```

## Positional/legacy interfaces

These public functions have no options/configuration/query parameter in their signature. This does not mean they need builders: many accept simple positional arguments. This index makes the audit boundary explicit, including deferred mesh and visualization functions.
- [fitToFunction](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/fitToFunction.m): `%% Fit power spectra to structure factor`
- [frequencyCoordinates](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/frequencyCoordinates.m): `function axes=frequencyCoordinates(gridSize,spacing)`
- [get_meanimg_LiangADAPT](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/get_meanimg_LiangADAPT.m): ``
- [get_meanimg_LiangOG](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/get_meanimg_LiangOG.m): `clear all`
- [get_ProfileScatterFunctions](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/get_ProfileScatterFunctions.m): `% Scattering function/power spectra of I(q) are calculated in `
- [plotSpectra_Multiple](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/plotSpectra_Multiple.m): `% Data loaded from Fourier Analysis and make plots`
- [plotSpectra](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/plotSpectra.m): `% Data loaded from Fourier Analysis and make plots`
- [samCompare](APIs/FieldAnalysis/src/+fieldanalysis/+fourier/samCompare.m): `%% Load`
- [scaleToReferenceTotal](APIs/FieldAnalysis/src/+fieldanalysis/+preprocessing/scaleToReferenceTotal.m): `function [scaled,factor]=scaleToReferenceTotal(field,referenceTotal)`
- [generateRadialMatrix](APIs/FieldAnalysis/src/+fieldanalysis/+statistics/generateRadialMatrix.m): `function ringIndMat=generateRadialMatrix(matSize,ringNum)`
- [generateStaticStructureFactor](APIs/FieldAnalysis/src/+fieldanalysis/+statistics/generateStaticStructureFactor.m): `function [structFact,scaledvanHove,vanHove] = generateStaticStructureFactor(inputField,subWin)`
- [generateVanHove](APIs/FieldAnalysis/src/+fieldanalysis/+statistics/generateVanHove.m): `function [vanHove] = generateVanHove(dataSet)`
- [loglogBin](APIs/FieldAnalysis/src/+fieldanalysis/+statistics/loglogBin.m): `function [meanLogXVals,meanLogYVals]=loglogBin(xVals,yVals,numBins)`
- [pairedFieldStatistics](APIs/FieldAnalysis/src/+fieldanalysis/+statistics/pairedFieldStatistics.m): `function result=pairedFieldStatistics(a,b)`
- [radiallyAverageMatrix](APIs/FieldAnalysis/src/+fieldanalysis/+statistics/radiallyAverageMatrix.m): `function [meanVals,r_bin,r_counts,binnedInds]=radiallyAverageMatrix(inputMat,sigma,polBool,ringSpace)`
- [twoFieldsCrossCorr](APIs/FieldAnalysis/src/+fieldanalysis/+statistics/twoFieldsCrossCorr.m): `% Takes in two directories and name formats corresponding to tifs of the`
- [fastWriteTiff](APIs/ImageStackIO/src/+imagestackio/+legacy/fastWriteTiff.m): `function fastWriteTiff(currTif,file_path,bit,compressionMethod)`
- [genTifTagRGB](APIs/ImageStackIO/src/+imagestackio/+legacy/genTifTagRGB.m): `function [tagstruct] = genTifTagRGB(inMat)`
- [loadH5](APIs/ImageStackIO/src/+imagestackio/+legacy/loadH5.m): `function [selMat] = loadH5(filePath,inString,chanNum,chanDim,dimOrder)`
- [save3DTiff](APIs/ImageStackIO/src/+imagestackio/+legacy/save3DTiff.m): `function [] = save3DTiff(tiffIn,savePath)`
- [saveNDTiffFIJI](APIs/ImageStackIO/src/+imagestackio/+legacy/saveNDTiffFIJI.m): `function [] = saveNDTiffFIJI(inMat,savePath,dimOrder)`
- [saveNDTiffFIJI](APIs/ImageStackIO/src/+imagestackio/+legacy/+variants/saveNDTiffFIJI.m): `function [] = saveNDTiffFIJI(inMat,savePath)`
- [coords2Mat_2DFils](APIs/ObjectGeometry/src/+objectgeometry/+centerlines/coords2Mat_2DFils.m): `function [filMat,filamentInds,validLogic] = coords2Mat_Fils(currFils,initBoxDims,outMatSideLen)`
- [filBackBones2D](APIs/ObjectGeometry/src/+objectgeometry/+centerlines/filBackBones2D.m): `function [outXs,outYs] = filBackBones2D(CoMs, MajAxes, Oris)`
- [filBackBonesND](APIs/ObjectGeometry/src/+objectgeometry/+centerlines/filBackBonesND.m): `function [bbStruct] = filBackBonesND(CoMs,lens,direcs)`
- [storeFilCCs](APIs/ObjectGeometry/src/+objectgeometry/+centerlines/storeFilCCs.m): `function [rp3D,rp2D] = storeFilCCs(bwObjs)`
- [blobMat2CCProps](APIs/ObjectGeometry/src/+objectgeometry/+objects/blobMat2CCProps.m): `function [ccObj,storeStruct] = blobMat2CCProps(logicMat,reqFields,storeStruct)`
- [concatenateMeasurements](APIs/ObjectGeometry/src/+objectgeometry/+objects/concatenateMeasurements.m): `function combined=concatenateMeasurements(tables)`
- [distTransFromBoundary](APIs/ObjectGeometry/src/+objectgeometry/+objects/distTransFromBoundary.m): `function [distMat,globalDistMat,regionFlip,primbgInds,secbgInds,primProximalInds] = ...`
- [getDistGrads](APIs/ObjectGeometry/src/+objectgeometry/+objects/getDistGrads.m): `function [allGrads,distMat] = getDistGrads(fullSegDir,h5Chans,outInOnChans,h5thresh,imgSize,imgScaling,inOnDist)`
- [returnSmoothBlobsBW](APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBlobsBW.m): `function [outBounds] = returnSmoothBlobsBW(ogBW,layerMean,layerWidth,gKern)`
- [returnSmoothBlobsIDed](APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBlobsIDed.m): `function [outMat] = returnSmoothBlobsIDed(inMat,layerMean,layerWidth,gKern,calcSpeed)`
- [returnSmoothBound](APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBound.m): `function [erodedBnd] = returnSmoothBound(segBW,strelRad,ogSize)`
- [returnSmoothBoundsBW](APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBoundsBW.m): `function [outBounds] = returnSmoothBoundsBW(ogBW,layerMean,layerWidth,gKern)`
- [returnSmoothBoundsIDed](APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBoundsIDed.m): `function [outMat] = returnSmoothBoundsIDed(inMat,layerMean,layerWidth,gKern,calcSpeed)`
- [skel3DBlobs](APIs/ObjectGeometry/src/+objectgeometry/+objects/skel3DBlobs.m): `function [validCores,coreMat] = skel3DBlobs(inMat,gradCut,sigma,hBool)`
- [skel3DClean](APIs/ObjectGeometry/src/+objectgeometry/+objects/skel3DClean.m): `function [trimSkel] = skel3DClean(inputMat,distCO)`
- [skel3Dfrom2D](APIs/ObjectGeometry/src/+objectgeometry/+objects/skel3Dfrom2D.m): `function [orMat,andMat] = skel3Dfrom2D(inputMat)`
- [skel3DPop](APIs/ObjectGeometry/src/+objectgeometry/+objects/skel3DPop.m): `function [ptCloud, orMat, andMat] = skel3DPop(inputMat, andOrFrac, cutOff, orMat, andMat)`
- [structCutOffThresh](APIs/ObjectGeometry/src/+objectgeometry/+objects/structCutOffThresh.m): `function [newStruct] = structCutOffThresh(inStruct, choiceField, minCut, maxCut, changeFields)`
- [rescalePatch](APIs/ObjectGeometry/src/+objectgeometry/+sheets/rescalePatch.m): `function [currentSurface] = rescalePatch(currentSurface,rescaleFactor)`
- [struct2Mat_sheets](APIs/ObjectGeometry/src/+objectgeometry/+sheets/struct2Mat_sheets.m): `function [maskMat] = struct2Mat_sheets(outputStruct,fieldNames,matSize)`
- [blobDensityDeltaR_Blobs](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/blobDensityDeltaR_Blobs.m): `%% Returns density profiles as a function of distance over time`
- [blobDensityDeltaR_Skels](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/blobDensityDeltaR_Skels.m): `%% Returns density profiles as a function of distance over time`
- [distanceBinning](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/distanceBinning.m): `% Load data structures saved to distinguish objects over time. One object`
- [dropIntensitiesDistRings](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/dropIntensitiesDistRings.m): `%% Data directory info`
- [getMTProfile_afterSeg](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/getMTProfile_afterSeg.m): `%% This script assumes sheets have already been segmented and returns the profile of MTs in segmented pixels along z`
- [concatenateResults](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/concatenateResults.m): `function combined=concatenateResults(tables)`
- [getHeightProfiles_eachLayer](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getHeightProfiles_eachLayer.m): `%% This script returns the height profile in each protein sheet from indices stored in segmentation structures`
- [getIntensityFluxes_2DSheets](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getIntensityFluxes_2DSheets.m): `%% This script gets intensity in regions separated by 2D sheets of protein`
- [getMaxInt_eachLayer](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getMaxInt_eachLayer.m): `%% This script returns the maximum intensity at each x,y pixel in each 2D sheet at indices defined in a segmentation structure over time`
- [getMeanIntensityOverTime3D](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getMeanIntensityOverTime3D.m): `%% Data info`
- [getMeanIntPerZOverT](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getMeanIntPerZOverT.m): `%% Iterate over a series of tifs (each time point) and store/plot the mean intensity for each z`
- [regionInts_Sheets](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/regionInts_Sheets.m): `% Rough: sample intensities in different regions of sheets and get`
- [rough_MeanIntProfile](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/rough_MeanIntProfile.m): `%% This script assumes sheets have already been segmented and returns the profile of MTs in segmented pixels along z`
- [blobInertiaTensorCalcs](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobInertiaTensorCalcs.m): `% Calculate local inertia tensor along skeletons of blobs, then calculate`
- [blobPropsFromTrajs_R_Inertia](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobPropsFromTrajs_R_Inertia.m): `% Takes in tifs of blob objects with pixel intensities denoting object ID.`
- [blobPropsFromTrajs](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobPropsFromTrajs.m): `% Takes in tifs of blob objects with pixel intensities denoting object ID.`
- [blobVolDistsFromCCs](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobVolDistsFromCCs.m): `%% Calculates simple quantities like fraction occupied by blobs over time`
- [blobVolFractFromh5](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobVolFractFromh5.m): `%% Calculates simple quantities like fraction occupied by blobs over time`
- [blobVolFractFromTifs](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobVolFractFromTifs.m): `%% Calculates simple quantities like fraction occupied by blobs over time`
- [dropSurfacesCenters](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/dropSurfacesCenters.m): `% Take in h5 segmentations of droplets over time and detect object centers`
- [estimateFirstInertiaMoment](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/estimateFirstInertiaMoment.m): `%% From Jakob's suggestion, plot integral of rho r dr over segmented bounds`
- [meanPropsOverTime](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/meanPropsOverTime.m): `%% Very crude, very fast, mean proeprties from structures over time`
- [percolationAnalysis](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/percolationAnalysis.m): `%% FFT analysis`
- [secondSegQuant](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/secondSegQuant.m): `% Looks at drops that have been segmented twice, once to detect drop`
- [volFractAndIntGlobal_Modular](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/volFractAndIntGlobal_Modular.m): `%Plot volumes, intensities, etc. from segmentations, then subsample`
- [correlateHeightIntensity](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+sheetProfiles/correlateHeightIntensity.m): `%% This function takes in the height and intensity profiles of layers and correlates them`
- [storeMeshProps_1_IntsCurvesVF](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+sheetProfiles/storeMeshProps_1_IntsCurvesVF.m): `% Get intensities, curvatures, clean up faces and verts from meshes.`
- [storeMeshProps_Combined](APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+sheetProfiles/storeMeshProps_Combined.m): `%% Effectively composites three scripts:`
- [addFieldStruct2Traj](APIs/ObjectTracking/src/+objecttracking/addFieldStruct2Traj.m): `function [trajStruct] = addFieldStruct2Traj(inStruct,trajStruct,desFields,desTrajs)`
- [attachMembership](APIs/ObjectTracking/src/+objecttracking/attachMembership.m): `function combined=attachMembership(measurements,membership)`
- [consObjMatSelTrajs](APIs/ObjectTracking/src/+objecttracking/consObjMatSelTrajs.m): `function outMat = consObjMatSelTrajs(selectTrajs,objIDs,totTable,matDims)`
- [generateTrajsFromObjs](APIs/ObjectTracking/src/+objecttracking/generateTrajsFromObjs.m): `%% Directory info`
- [getTimeObjTrajTableFromPyTrajs](APIs/ObjectTracking/src/+objecttracking/getTimeObjTrajTableFromPyTrajs.m): `function [totTable] = getTimeObjTrajTableFromPyTrajs(Trajectories)`
- [lineageGraph](APIs/ObjectTracking/src/+objecttracking/lineageGraph.m): `function graph = lineageGraph(tracking)`
- [mat2pyTrackMat](APIs/ObjectTracking/src/+objecttracking/mat2pyTrackMat.m): `function [pyMat] = mat2pyTrackMat(storeStruct,customFields)`
- [overlapLinks](APIs/ObjectTracking/src/+objecttracking/overlapLinks.m): `function links = overlapLinks(source, target)`
- [singleTimePointTrajGen](APIs/ObjectTracking/src/+objecttracking/singleTimePointTrajGen.m): `function [matchIndices,pointerMat,matchDists,totalCost] = singleTimePointTrajGen(sourceCenters,targetCeters,cutOffVal)`
- [tot2ts](APIs/ObjectTracking/src/+objecttracking/tot2ts.m): `function trajStruct = tot2ts(input,minTrajLength)`
- [ts2tot](APIs/ObjectTracking/src/+objecttracking/ts2tot.m): `function totTable = ts2tot(trajStruct,fieldNames)`
- [digraphOverlapTracking_UniqueIDs](APIs/ObjectTracking/src/+objecttracking/+blobLineage/digraphOverlapTracking_UniqueIDs.m): `% Takes in directory of blob objects saved tif per time point. Checks for`
- [digraphOverlapTracking](APIs/ObjectTracking/src/+objecttracking/+blobLineage/digraphOverlapTracking.m): `% Takes in directory of blob objects saved tif per time point. Checks for`
- [IsolateBlobLineage](APIs/ObjectTracking/src/+objecttracking/+blobLineage/IsolateBlobLineage.m): `%% Outline and testing to isolate blobs spatially and temporally`
- [overlapBlobTrack_fromCCs](APIs/ObjectTracking/src/+objecttracking/+blobLineage/overlapBlobTrack_fromCCs.m): `% Assumes blobs are segmented and saved as connected component objects for`
- [overlapBlobTracking_TrackObjectProps](APIs/ObjectTracking/src/+objecttracking/+blobLineage/overlapBlobTracking_TrackObjectProps.m): `% Takes in directory of blob objects saved tif per time point. Checks for`
- [overlapBlobTracking](APIs/ObjectTracking/src/+objecttracking/+blobLineage/overlapBlobTracking.m): `% Takes in directory of blob objects saved tif per time point. Checks for`
- [importLinks](APIs/ObjectTracking/src/+objecttracking/+trackpy/importLinks.m): `function membership = importLinks(linkedRows, map)`
- [activeContourFrame1](APIs/SegmentationTools/src/+segmentationtools/+activeContours/activeContourFrame1.m): `%% data info`
- [activeContourFromH5](APIs/SegmentationTools/src/+segmentationtools/+activeContours/activeContourFromH5.m): `%% This script takes in .h5 files and applies active contouring to generate`
- [generateFirstGuess_morphsnakes](APIs/SegmentationTools/src/+segmentationtools/+activeContours/generateFirstGuess_morphsnakes.m): `%% This script takes in a segmentation matrix and generates a mask tif`
- [h5toSmooth3Chans](APIs/SegmentationTools/src/+segmentationtools/+binarization/h5toSmooth3Chans.m): `function [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(currSeg,outInOnChans,threshVec,strelRad,spanBool)`
- [imbinarize3_4D](APIs/SegmentationTools/src/+segmentationtools/+binarization/imbinarize3_4D.m): `function [outData] = imbinarize3_4D(inData,threshVals)`
- [flatFill3D](APIs/SegmentationTools/src/+segmentationtools/+cleanup/flatFill3D.m): `function outMat = flatFill3D(inMat, dimFills)`
- [removeConObjs](APIs/SegmentationTools/src/+segmentationtools/+cleanup/removeConObjs.m): `function [logicMat,toRemove] = removeConObjs(logicMat,toKeep,modeStr)`
- [returnSmoothBlobsBW](APIs/SegmentationTools/src/+segmentationtools/+cleanup/returnSmoothBlobsBW.m): `function outBounds = returnSmoothBlobsBW(ogBW, layerMean, layerWidth, gKern)`
- [returnSmoothBlobsIDed](APIs/SegmentationTools/src/+segmentationtools/+cleanup/returnSmoothBlobsIDed.m): `function outMat = returnSmoothBlobsIDed(inMat, layerMean, layerWidth, gKern, calcSpeed)`
- [sidesHoleFill](APIs/SegmentationTools/src/+segmentationtools/+cleanup/sidesHoleFill.m): `function [outMat] = sidesHoleFill(inMat)`
- [getCentralSlice](APIs/SegmentationTools/src/+segmentationtools/+morphologySpecific/+sheets/getCentralSlice.m): `function [splitSlice] = getCentralSlice(inputData)`
- [returnCorrectedBinarizedSurfaceIndices](APIs/SegmentationTools/src/+segmentationtools/+morphologySpecific/+sheets/returnCorrectedBinarizedSurfaceIndices.m): `function [newInds,holeLocVec] = returnCorrectedBinarizedSurfaceIndices(surfaceInds,imgSize)`
- [returnTopBottom2DSheets](APIs/SegmentationTools/src/+segmentationtools/+morphologySpecific/+sheets/returnTopBottom2DSheets.m): `function [topLayer,botLayer,topLayerZs,botLayerZs, centerSlice,centerSliceZs,splitSlice] = returnTopBottom2DSheets(inputData)`
- [arrayCumSum](APIs/SharedUtilities/src/+sharedutilities/+arrays/arrayCumSum.m): `function [csVec] = arrayCumSum(inVec)`
- [arrayOrganizer2D](APIs/SharedUtilities/src/+sharedutilities/+arrays/arrayOrganizer2D.m): `function [reorganizedArray,linear_grid] = arrayOrganizer2D(arr,Dcell)`
- [blockReshape2D](APIs/SharedUtilities/src/+sharedutilities/+arrays/blockReshape2D.m): `function [outMat] = blockReshape2D(inMat,outCol)`
- [consMatLnB](APIs/SharedUtilities/src/+sharedutilities/+arrays/consMatLnB.m): `function [outMat] = consMatLnB(baseMat,indices)`
- [consMinValsLayer](APIs/SharedUtilities/src/+sharedutilities/+arrays/consMinValsLayer.m): `function [minMat] = consMinValsLayer(dataMat,dimension)`
- [consScalerMat](APIs/SharedUtilities/src/+sharedutilities/+arrays/consScalerMat.m): `function [scalerMat] = consScalerMat(inputData,patchProbs)`
- [fillin2D](APIs/SharedUtilities/src/+sharedutilities/+arrays/fillin2D.m): `function [outSlice] = fillin2D(inSlice,logicSlice)`
- [fillin3D](APIs/SharedUtilities/src/+sharedutilities/+arrays/fillin3D.m): `function [outMat] = fillin3D(inMat,logicMat)`
- [flatFill3D](APIs/SharedUtilities/src/+sharedutilities/+arrays/flatFill3D.m): `function [outMat] = flatFill3D(inMat,dimFills)`
- [generateFieldInterps](APIs/SharedUtilities/src/+sharedutilities/+arrays/generateFieldInterps.m): `function [outFields] = generateFieldInterps(ivec,inFields)`
- [generateMatrixSubdivisions](APIs/SharedUtilities/src/+sharedutilities/+arrays/generateMatrixSubdivisions.m): `function [outInds] = generateMatrixSubdivisions(inputArray,binWindow,overlapBool)`
- [imresize3_4mat](APIs/SharedUtilities/src/+sharedutilities/+arrays/imresize3_4mat.m): `function [outData] = imresize3_4mat(inData,scaleVec)`
- [inds3Dto2D](APIs/SharedUtilities/src/+sharedutilities/+arrays/inds3Dto2D.m): `function [outInds] = inds3Dto2D(inInds, size3D)`
- [lens2Blocks](APIs/SharedUtilities/src/+sharedutilities/+arrays/lens2Blocks.m): `function [logicMat,validCoord1,validCoord2] = lens2Blocks(vecLens1,vecLens2)`
- [rescaleCoords](APIs/SharedUtilities/src/+sharedutilities/+arrays/rescaleCoords.m): `function outCoords=rescaleCoords(inCoords,ogDims,newDims)`
- [genLenVec](APIs/SharedUtilities/src/+sharedutilities/+coordinates/genLenVec.m): `function [outVec] = genLenVec(contentsVec,repVec)`
- [genLineInds2D](APIs/SharedUtilities/src/+sharedutilities/+coordinates/genLineInds2D.m): `function [outInds] = genLineInds2D(matSize,cutInd,cutDim,lineStart,lineEnd)`
- [genReflVec](APIs/SharedUtilities/src/+sharedutilities/+coordinates/genReflVec.m): `function [reflVec] = genReflVec(inLength)`
- [getCCVectors](APIs/SharedUtilities/src/+sharedutilities/+coordinates/getCCVectors.m): `function [objSizes,objVoxels,objIDs]=getCCVectors(currCC)`
- [getUnitVecs](APIs/SharedUtilities/src/+sharedutilities/+coordinates/getUnitVecs.m): `function outMat=getUnitVecs(inMat)`
- [rescaleCoords_Inds](APIs/SharedUtilities/src/+sharedutilities/+coordinates/rescaleCoords_Inds.m): `function scaleInds=rescaleCoords_Inds(inputInds,ogDims,newDims)`
- [bndmod](APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/bndmod.m): `function [outVal] = bndmod(inVal,floorVal,ceilVal)`
- [cellIndSizes](APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/cellIndSizes.m): `function [outVec] = cellIndSizes(inCell,desCol)`
- [genericLenVec](APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/genericLenVec.m): `function [outVec] = genericLenVec(inVec)`
- [genScaledKVec](APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/genScaledKVec.m): `function outKs=genScaledKVec(dimSize,dimdx)`
- [logic2Ply](APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/logic2Ply.m): `function [] = logic2Ply(logicMat,saveDir,scaleMat)`
- [mod1b](APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/mod1b.m): `function [outNum] = mod1b(queryNums,baseNum)`
- [fastLinIntNDScale2](APIs/SharedUtilities/src/+sharedutilities/+numerics/fastLinIntNDScale2.m): `function imageInterp=fastLinIntNDScale2(inputStack)`
- [generate1DGaussian](APIs/SharedUtilities/src/+sharedutilities/+numerics/generate1DGaussian.m): `function gaussMat = generate1DGaussian(gsize, xc, sigmax)`
- [generate2DGaussian](APIs/SharedUtilities/src/+sharedutilities/+numerics/generate2DGaussian.m): `function gaussMat = generate2DGaussian(gsize, xc, yc, sigmax, sigmay)`
- [generate3DGaussian](APIs/SharedUtilities/src/+sharedutilities/+numerics/generate3DGaussian.m): `function gaussMat = generate3DGaussian(gsize, centers, sigmas, coordMode)`
- [generate3DGaussians](APIs/SharedUtilities/src/+sharedutilities/+numerics/generate3DGaussians.m): `function gaussMat = generate3DGaussians(gsize, centers, sigmas)`
- [generateNDHann](APIs/SharedUtilities/src/+sharedutilities/+numerics/generateNDHann.m): `function [hannFunc] = generateNDHann(matDims)`
- [LOG](APIs/SharedUtilities/src/+sharedutilities/+numerics/LOG.m): `function logstack = LOG(stack, sigma)`
- [logAB](APIs/SharedUtilities/src/+sharedutilities/+numerics/logAB.m): `function newLog=logAB(A,B)`
- [myconvn](APIs/SharedUtilities/src/+sharedutilities/+numerics/myconvn.m): `function convolved = myconvn(stack, filter)`
- [ndmeshgrid](APIs/SharedUtilities/src/+sharedutilities/+numerics/ndmeshgrid.m): `function [outMat1,outMat2,outMat3] = ndmeshgrid(inVec1, inVec2, inVec3)`
- [ndndgrid](APIs/SharedUtilities/src/+sharedutilities/+numerics/ndndgrid.m): `function [outMat1,outMat2,outMat3] = ndndgrid(inVec1, inVec2, inVec3)`
- [noNan](APIs/SharedUtilities/src/+sharedutilities/+numerics/noNan.m): `function outMat=noNan(inMat,replVal)`
- [nonZeroMean](APIs/SharedUtilities/src/+sharedutilities/+numerics/nonZeroMean.m): `function [outMat] = nonZeroMean(inMat, selDim)`
- [poissonDisc](APIs/SharedUtilities/src/+sharedutilities/+numerics/poissonDisc.m): `function [pts] = poissonDisc(sizeI,spacing,nPts,showIter)`
- [signedBWDist](APIs/SharedUtilities/src/+sharedutilities/+numerics/signedBWDist.m): `function [outMat] = signedBWDist(inMat)`
- [figSaves](APIs/SharedUtilities/src/+sharedutilities/+plotting/figSaves.m): `function figSaves(figHandle,saveDir,saveName,fileExts,saveBool)`
- [logAB](APIs/SharedUtilities/src/+sharedutilities/+plotting/logAB.m): `function newLog=logAB(A,B)`
- [loglogBin](APIs/SharedUtilities/src/+sharedutilities/+plotting/loglogBin.m): `function [meanLogXVals,meanLogYVals]=loglogBin(xVals,yVals,numBins)`
- [manVlnPlot](APIs/SharedUtilities/src/+sharedutilities/+plotting/manVlnPlot.m): `function [meanVal,medVal]=manVlnPlot(xData,yDataSet,yBins,maxNorm)`
- [plotVlns](APIs/SharedUtilities/src/+sharedutilities/+plotting/plotVlns.m): `function [allMeans,allMeds]=plotVlns(xData,yData,xSuperBin,yBin,maxNorm)`
- [progressBar](APIs/SharedUtilities/src/+sharedutilities/+plotting/progressBar.m): `function [progressObj] = progressBar(currInd,totalInds,progressObj,updatePrct)`
- [addFieldsStruct](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/addFieldsStruct.m): `function structObj=addFieldsStruct(structObj,fieldNames,fieldVals,structInds)`
- [addFieldStruct](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/addFieldStruct.m): `function structObj=addFieldStruct(structObj,fieldName,fieldVals,structInds)`
- [concatTablesOverT](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/concatTablesOverT.m): `function [superTable] = concatTablesOverT(dataDir,dataName,selTimes,storeVar,saveBool,saveName)`
- [structFields2Cell](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/structFields2Cell.m): `function [cellObj] = structFields2Cell(structObj,selFields,structRange)`
- [structFieldSizes](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/structFieldSizes.m): `function [numElmts] = structFieldSizes(inStruct,fieldName)`
- [structLenVec](APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/structLenVec.m): `function [outVec] = structLenVec(inStruct,desField)`
- [closedSurfaces_FieldsOnMesh](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+mapping/closedSurfaces_FieldsOnMesh.m): `%% Takes in meshes of segmented objects and samples velocities, intensities, and curvatures on faces`
- [threeSeg_meanIntProfiles](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+mapping/threeSeg_meanIntProfiles.m): `%% Takes in .h5 segmentation and int corrected .tif, returns int. profile`
- [closedSurfaces_h5ToMesh_EnforceNorms](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction/closedSurfaces_h5ToMesh_EnforceNorms.m): `%% Messy first take of a script to convert drop segmentations to meshes`
- [closedSurfaces_h5ToPointCloud](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction/closedSurfaces_h5ToPointCloud.m): `%% A first pass on how to extract surfaces of roughly drop-like objects`
- [closedSurfaces_splitPtCloudsMeshes](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction/closedSurfaces_splitPtCloudsMeshes.m): `%% A first pass on how to extract surfaces of roughly drop-like objects`
- [consPatchedSheetSurface_Flat](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction/consPatchedSheetSurface_Flat.m): `function [selectDataOut,newSurfInds,holeIndVec] = consPatchedSheetSurface_Flat(rawData,selectDataIn,surfPerim)`
- [obj2ply](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/obj2ply.m): `function [plyStruct] = obj2ply(objStruct, saveBool, outDir, outName)`
- [plySurf2TIF](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/plySurf2TIF.m): `function [] = plySurf2TIF(dataDir,dataName,outFile,outName)`
- [plywrite_norms](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/plywrite_norms.m): `function plywrite_norms(filename,faces,verts,vertnorms)`
- [readObj_remi](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/readObj_remi.m): `function [] = readObj_remi(fileString)`
- [saveObj2PlyFiles](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/saveObj2PlyFiles.m): `%% Define data info`
- [capPtCloudFlat](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/capPtCloudFlat.m): `function [cappedLayers] = capPtCloudFlat(topLayer, botLayer, capDim)`
- [confineMeshInMat](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/confineMeshInMat.m): `function [subCoords] = confineMeshInMat(matCoords,matDims)`
- [getMeshDims](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/getMeshDims.m): `function [objInfo] = getMeshDims(meshObj, pixDim, flipNorms)`
- [inBetweenFill](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/inBetweenFill.m): `function [midSection] = inBetweenFill(mat1, mat2)`
- [mesh2mat](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/mesh2mat.m): `function [outMat] = mesh2mat(verts,matDims)`
- [meshSideRemove](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/meshSideRemove.m): `function [Fcut,Vcut] = meshSideRemove(Fraw,Vraw, minCuts, maxCuts)`
- [remove_isolated_mesh_components](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/remove_isolated_mesh_components.m): `function [ newFace, newVertex, oldVertexIDx, C ] = remove_isolated_mesh_components( face, ...`
- [removeFacesVerts_Mesh](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/removeFacesVerts_Mesh.m): `function [ newFace, newVertex, oldVertexIDx, newVertexIDx ] = ...`
- [shiftMeshVerts](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/shiftMeshVerts.m): `%% Define data info`
- [split_mesh_into_components](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/split_mesh_into_components.m): `function splitMeshes = split_mesh_into_components( face, vertex, cutoff, saveBool, saveDir, ignoreBounds )`
- [split_single_mesh_object](APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/split_single_mesh_object.m): `function [validFaces, validVerts] = split_single_mesh_object(face, vertex, sortOrder, vertMeshIDs, meshID, saveBool, saveDir, ignoreBounds)`
- [intsAndSegBoundaries_Tiffs](APIs/VisualizationTools/src/+visualizationtools/intsAndSegBoundaries_Tiffs.m): `% Load tifs and segmentations/thresholded masks; generate drop boundaries`
- [intsAndSegBoundaries2DImgs_Tiffs](APIs/VisualizationTools/src/+visualizationtools/intsAndSegBoundaries2DImgs_Tiffs.m): `% Load tifs and segmentations/thresholded masks; generate drop boundaries`
- [mapFieldOnBlobSegs](APIs/VisualizationTools/src/+visualizationtools/mapFieldOnBlobSegs.m): `% Directory info`
- [plotBlobStatistics_rEff](APIs/VisualizationTools/src/+visualizationtools/plotBlobStatistics_rEff.m): `% Expects data from (test_)trajInfoFromOverlaps_MinAxis.m;`
- [plotDeltaRBnds](APIs/VisualizationTools/src/+visualizationtools/plotDeltaRBnds.m): `%% Takes in data calculated from blobDensityDeltaR_Blobs.m`
- [plotDeltaRSkels](APIs/VisualizationTools/src/+visualizationtools/plotDeltaRSkels.m): `%% Takes in data calculated from blobDensityDeltaR_Skels.m`
- [plotFilamentAlignments](APIs/VisualizationTools/src/+visualizationtools/plotFilamentAlignments.m): `%% From earlier scripts, split together a streamlined version for alignment`
- [plotFirstInertiaMomentData](APIs/VisualizationTools/src/+visualizationtools/plotFirstInertiaMomentData.m): `%% Plots data from estimateFirstInertiaMoment.m`
- [plotRInertiaStruct](APIs/VisualizationTools/src/+visualizationtools/plotRInertiaStruct.m): `%% Quick and dirty: plot quantities stored in sortedMat`
- [plotSortedMat_MultipleOverlap](APIs/VisualizationTools/src/+visualizationtools/plotSortedMat_MultipleOverlap.m): `%% Quick and dirty: plot quantities stored in sortedMat`
- [plotSortedMat_MultipleSave](APIs/VisualizationTools/src/+visualizationtools/plotSortedMat_MultipleSave.m): `%% Quick and dirty: plot quantities stored in sortedMat`
- [plotSortedMat](APIs/VisualizationTools/src/+visualizationtools/plotSortedMat.m): `%% Quick and dirty: plot quantities stored in sortedMat`
- [stitchSkelsAndShells](APIs/VisualizationTools/src/+visualizationtools/stitchSkelsAndShells.m): `%% Combine blob skeletons with blob surface contours, then save in tiffs`
- [tiffs_BlobOverTime](APIs/VisualizationTools/src/+visualizationtools/tiffs_BlobOverTime.m): `%% Test: given a trajectory ID, make tifs of blobs over time`
- [getPolyCoords](APIs/VisualizationTools/src/+visualizationtools/+display/getPolyCoords.m): `function [outXs,outYs] = getPolyCoords(yCoords,yHeights,xCoords)`
- [manVlnPlot](APIs/VisualizationTools/src/+visualizationtools/+display/manVlnPlot.m): `function [meanVal,medVal] = manVlnPlot(xData,yDataSet,yBins,maxNorm)`
- [plotMeanStdPoly](APIs/VisualizationTools/src/+visualizationtools/+display/plotMeanStdPoly.m): `function [] = plotMeanStdPoly(meanVals,stdVals,xVals,currColor,alphaVal,lineColor)`
- [plotVanHoveCorrs](APIs/VisualizationTools/src/+visualizationtools/+display/plotVanHoveCorrs.m): `%% Takes in .mats with van Hove data; plots correlation functions`
- [plotVlns](APIs/VisualizationTools/src/+visualizationtools/+display/plotVlns.m): `function [allMeans,allMeds] = plotVlns(xData, yData, xSuperBin, yBin, maxNorm)`
- [figSaves](APIs/VisualizationTools/src/+visualizationtools/+export/figSaves.m): `function [] = figSaves(figHandle,saveDir,saveName,fileExts,saveBool)`
