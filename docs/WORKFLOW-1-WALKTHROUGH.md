# Understanding workflow 1

[Guide home](README.md) · [Reading package structures](READING-STRUCTURES.md) · [Changing an analysis](CHANGING-AN-ANALYSIS.md)

Workflow 1 answers: **Which regions are present, what are their properties, and what values occur within them or at their boundaries?**

Start with [setupWorkflow1.m](../Workflows/examples/setupWorkflow1.m). You can edit the upper setup sections without first learning every API. The local function at the bottom performs the calculation. This page follows the variables in that script.

The [glossary](../GLOSSARY-CAPABILITIES-MOCKUP.md) defines terms. The [configuration reference](../CONFIGURATION-BUILDERS.md) lists builder interfaces.

## 1. What you supply

You need one quantitative intensity volume per selected frame, plus either:

- Probability fields from which regions can be segmented.
- Already prepared masks or ID labels, supplied through ObjectLoader.

Intensity and segmentation inputs must describe the same physical area. They may have different voxel spacing, but a similar shape or physical extent does not prove they are registered.

The script has these sections:

| Section | Your action |
|---|---|
| SETUP | Enter the MeMo repository location and add its required code folders. |
| DATA | Enter source folders, filename patterns, axes, spacing and selected frames. |
| ANALYSIS | Select segmentation settings, geometry, properties and sampling requests. |
| PREVIEW | Load and inspect a selected intensity frame. |
| RUN | Execute the workflow and inspect the returned table. |
| WORKFLOW IMPLEMENTATION | Read the processing steps; edit when changing operations or how they connect. |

Choose an existing entry from frames for previewing. The current editable script uses frames(10); if you shorten the selection, change that position to one that exists, such as frames(1).

## 2. Source descriptions: where the data comes from

In DATA, the variable intensity is initially a **source-description struct**:

```matlab
intensity = imagestackio.config.makeSource( ...
    'Folder',intDir,'NamePattern',intName, ...
    'Format','tiff','SourceAxes',intAxes, ...
    'Spacing',intVoxSize,'SpacingUnit','um');
```

It contains folder/name/calibration information. It does **not** contain a loaded image.

The probabilities source description works similarly. DatasetPath='/exported_data' names the array inside each HDF5 file, while Folder and NamePattern locate the file on disk.

| Question | Answer |
|---|---|
| What is stored? | Source description and reading settings. |
| Who creates it? | makeSource, using DATA inputs. |
| Who uses it? | loadSource, when a frame is requested. |
| What can you change? | Files, format, axes, channel/time selection and calibration. |

The loaded probability values are different from this description. Channels identify segmented categories; they do not yet identify individual connected regions.

## 3. experiment and c: description versus analysis choices

The experiment struct groups information about the dataset:

```matlab
experiment.DatasetID
experiment.Frames
experiment.TimeStep
experiment.TimeUnit
experiment.Sources.Intensity
experiment.Sources.Probabilities
```

These entries describe data and acquisition. They do not hold every frame's image matrix. Timing defaults independently to TimeStep=1 and TimeUnit='frame'; the supplied example explicitly uses physical acquisition timing.

The c struct groups what this workflow should do:

```matlab
c.Experiment = experiment;
c.ObjectProperties = {'Volume','Centroid'};
c.Supports = {'objects','boundary'};
c.PhysicalVolume = true;
```

c mixes several roles: dataset description, requests, operation settings and output location. It is a container of choices passed to the helper, not an additional scientific data representation.

## 4. Requests and options: what to calculate

ObjectProperties selects native measurements:

```matlab
c.ObjectProperties = {'Volume','Centroid','BoundingBox'};
```

The names are passed to measureObjects. Adding BoundingBox here changes the request without changing the helper's function calls.

PhysicalVolume is separate: native Volume remains a voxel count; PhysicalVolume multiplies that count by current voxel volume. Setting c.PhysicalVolume=false omits that additional column. If physical volume is requested without native Volume, the helper obtains the voxel count internally without adding an unwanted Volume column.

GeometryOptions controls how a requested feature is generated:

```matlab
c.GeometryOptions.boundary = struct( ...
    'Sigma',1,'LayerMean',0,'LayerWidth',1);
```

This contains settings, not boundary indices. The boundary option selects a finite-width layer in a smoothed signed-distance field. These parameters refer to that operation's grid; they are not automatically physical lengths.

Only supports listed in c.Supports are generated. A skeleton option entry can exist without producing a skeleton if skeleton is not selected.

MeasurementOptions is still present as an empty pass-through in the current setup. It has no additional purpose for this ordinary prepared-geometry 3-D analysis. Native 2-D intensity measurements have a use for it; general 3-D intensity statistics use queries.

## 5. Loading one frame: when descriptions become data

Within the helper:

```matlab
image = memoworkflow.loadSource(c.Experiment,'Intensity',frame);
intensity = image.Data(:,:,:,1,1);
```

Now image is a **loaded image struct**. Its Data field contains actual values; its other fields describe calibration, axes, identity and source selection.

The helper's intensity is a **numeric spatial matrix**. It is not the source-description struct called intensity in DATA: the script and local function have separate workspaces. Reused variable names do not mean the two values are the same type.

Intensity values are preserved. This workflow assumes any desired illumination/bleaching correction has already been performed upstream.

Processing proceeds frame by frame; it does not preload all acquisition times.

## 6. mask and objects: selected voxels and their identities

The helper calls:

```matlab
[objects,mask] = memoworkflow.objects(current,frame,size(intensity));
```

With probability inputs, it:

1. Adds the chosen foreground probability channels.
2. Applies the selected threshold.
3. Smooths the foreground on the probability grid.
4. Resizes its mask to the intensity grid using nearest-neighbor interpolation.
5. Prepares identified voxel groups.

mask is a **logical matrix**: true means selected foreground.

objects is a **prepared geometry struct**: it records which indices belong together and on which grid.

```matlab
objects.ObjectIDs
objects.Components.PixelIdxList
objects.Grid
```

Each cell of PixelIdxList contains one group's linear voxel indices, corresponding to the matching entry in ObjectIDs. Grid records size, axes, spacing and units needed to interpret those indices.

For masks, connected components determine groups. With supplied labels and InputType='labels', all voxels sharing an ID remain one group even when disconnected.

IDs here are frame-local. Workflow 1 does not establish lineage or trajectories.

## 7. properties: a table, not another mask

```matlab
properties = objectgeometry.objects.measureObjects( ...
    objects,c.ObjectProperties,c.MeasurementOptions);
```

properties contains one row per ID group at the frame. Identity columns tell you which group the measurements describe.

Volume is a voxel count. Centroid is an XYZ coordinate vector stored within a table variable. PhysicalVolume is expressed in the recorded spatial unit cubed.

Changing requested columns does not change the underlying membership indices in objects. Tables and spatial matrices serve different purposes.

## 8. geometry and supports: often the same locations, different roles

```matlab
geometry.boundary = objectgeometry.objects.generateGeometry( ...
    objects,'boundary',c.GeometryOptions.boundary);
supports.objects = objects;
supports.boundary = geometry.boundary;
```

geometry.boundary is a **generated geometry struct**, with indices stored in Records:

```matlab
geometry.boundary.Records
geometry.boundary.Grid
```

Records associate component indices with parent IDs. One ID group can have multiple disconnected component records.

supports is a collection naming the selections available to a query. supports.boundary initially contains the same geometry as geometry.boundary. There is no second boundary calculation.

The role changes: geometry describes a spatial feature, while support says to evaluate values at those locations. Whole-region membership is also a support, so supports.objects is available without generating an extra feature.

To view a dense matrix:

```matlab
boundaryMask = objectgeometry.representation.geometryToMatrix(supports.boundary);
```

This renders actual stored indices. It does not fill the boundary's interior.

## 9. fields and queries: values versus instructions

The helper makes a named collection of actual matrices:

```matlab
fields.Intensity = intensity;
fields.InteriorDistanceVoxels = distance;
```

The two matrices describe the same grid but contain different quantities.

InteriorDistanceVoxels is calculated by bwdist(~mask). It measures distance to background in voxels, using the combined foreground mask. It is not automatically an ID-specific or physically calibrated distance.

A query contains instructions:

```matlab
q = objectrelativeprofiles.config.makeQuery( ...
    'Name','IntensityOnboundary', ...
    'Field','Intensity', ...
    'Support','boundary', ...
    'Statistics',{'Mean','Max'});
```

Read this as: **Take the Intensity matrix, select values at the boundary support for each ID group, and calculate their mean and maximum.**

| Query field | What it refers to |
|---|---|
| Field | A named input matrix, such as fields.Intensity. |
| Support | A named selection, such as supports.boundary. |
| Statistics | Operations on the selected values. |
| Name | The prefix for output column names. |
| Options | Additional settings for that query's sampling/statistics. |

These names have different roles. A query contains neither the full intensity matrix nor its boundary indices.

### A small illustrative calculation

Suppose one group's selected boundary locations contain intensity values:

```text
10, 20, 30
```

The query above produces Mean=20 and Max=30. The main table receives columns named IntensityOnboundary_Mean and IntensityOnboundary_Max.

If interior locations contain different values, a query using Support='objects' calculates different statistics even though Field remains 'Intensity'.

You can remove or replace queries without changing the helper. Query support names must be selected in c.Supports, and field names must exist in fields. Introducing a newly calculated field requires defining its production step as well as requesting its statistics.

## 10. Sampling results and diagnostics

```matlab
results = objectrelativeprofiles.fieldSampling.queryFrame(fields,supports,c.Queries);
```

The result is a table of keyed statistics and diagnostic counts/flags. It is attached to properties by identity, not by assuming row positions match.

A field named Max is a requested statistic; FiniteCount is an interpretation count. They answer different questions. Invalid readings can reduce the number used for statistics; an empty skeleton can trigger a flagged fallback.

By default:

```matlab
result.Measurements  % requested properties/statistics and identity columns
result.Diagnostics   % keyed counts and validity/fallback flags
```

Set c.IncludeDiagnostics=true to include diagnostic columns in Measurements too. An empty c.Queries allows a properties-only run.

## 11. Choosing what survives the frame

The OUTPUT CHOICES block builds the saved payload:

```matlab
payload = struct('Measurements',properties,'Seconds',toc(timer));
payload.Diagnostics = diagnostics;
% payload.Geometry = geometry;
% payload.Supports = supports;
```

Measurements are saved without geometry indices by default. Uncomment Geometry to retain generated features, or Supports to also retain whole-region membership. Comment out Diagnostics if that frame table is not wanted.

Each MAT file stores a variable named result. To inspect one frame later:

```matlab
saved = load(fullfile(result.Directory,'frame010.mat'));
frameMeasurements = saved.result.Measurements;
```

The end-of-run manifest separately combines measurement tables and, by default, diagnostic tables. Its assignments are another explicit output choice; changing a frame payload does not automatically change the manifest.

Saved files are created in a fresh directory under package test-data. Original inputs are read-only. If indices are omitted, adding a new field query later requires regenerating the selections from the original inputs and retained configuration.

## Where to make a change

| Desired change | Edit |
|---|---|
| Different dataset/files/calibration | DATA |
| Different segmentation threshold/channels | ANALYSIS foreground settings |
| Volume versus centroid versus other native properties | ObjectProperties |
| Different boundary thickness or skeleton method | GeometryOptions |
| Which supports to generate | Supports |
| Mean versus Max, quantiles or other supported statistics | Queries and query Options |
| Diagnostic visibility | IncludeDiagnostics |
| Which calculated outputs to save | OUTPUT CHOICES assignments |
| New reference field or different processing algorithm | The helper's relevant function-call block |

The separate APIs are tools used by these blocks. You do not need to configure every API merely to run this example.
