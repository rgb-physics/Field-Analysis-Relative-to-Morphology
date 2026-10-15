# Reading package structures

[Guide home](README.md) · [Workflow 1 walkthrough](WORKFLOW-1-WALKTHROUGH.md) · [Changing an analysis](CHANGING-AN-ANALYSIS.md)

The important question is not only “What MATLAB type is this?” but also **“What role does this value have?”** Two structs can contain entirely different things.

## The roles you will encounter

| Role | Contains | Does not imply |
|---|---|---|
| Data | Actual values to analyze | A filename is not a loaded image |
| Description | How to locate/interpret data | All frames have been loaded |
| Options | Settings for a particular operation | Every function accepts these settings |
| Request | What to calculate/select | The calculation has already run |
| Geometry | Locations describing extent/features, with calibration/identity | A dense matrix is required |
| Result | Calculated fields, geometry, tables or diagnostics | A universal output schema |
| Saved-output container | Results chosen to retain | Every temporary value is saved |

A container can combine roles. A loaded image combines data and metadata. The workflow configuration c combines an experiment description, analysis requests, settings and output choices.

## Matrices: actual values at locations

In this package, matrix includes N-dimensional rectangular arrays. An intensity matrix and a mask can have exactly the same shape while representing different things.

```matlab
size(intensity)       % rows, columns, Z planes
intensity(20,30,5)    % value at one YXZ location
mask(20,30,5)         % true/false selection at that location
```

A scalar field has one value per spatial location; it is not necessarily a single-number MATLAB scalar.

Images are normalized to YXZCT. Most analysis functions use one spatial YXZ field. Coordinate lists such as centroids commonly use XYZ. Matrix-axis order and coordinate order must not be conflated.

## Structs: named contents

A struct is a container with fields. Dots select those fields:

```matlab
image.Data
image.Spacing
```

Data contains the matrix; Spacing describes sample separation. Descriptive names do not enforce meaning by themselves.

```matlab
class(image)
fieldnames(image)
whos image
```

These reveal its type, field names and workspace size. They do not prove registration or scientific interpretation.

## Source description versus loaded image

A source description holds:

```text
Folder
NamePattern
Format
SourceAxes
Spacing
SpacingUnit
```

An HDF5 source also identifies DatasetPath. It may use a custom Loader instead of a file pattern.

A loaded image holds Data and metadata. Reading image.Data returns actual values; reading a source's NamePattern returns text describing filenames.

In setupWorkflow1, the DATA variable intensity is initially a source struct. Inside its local helper, intensity is a numeric matrix. These are different workspaces, despite the reused name.

## experiment versus c

experiment describes the dataset:

```text
experiment
  DatasetID
  Frames
  TimeStep
  TimeUnit
  Sources
    Intensity
    Probabilities
```

c connects that description to analysis choices:

```text
c
  Experiment
  ObjectProperties
  Supports
  GeometryOptions
  Queries
  PhysicalVolume
  IncludeDiagnostics
  OutputRoot
  ...
```

Neither is the main measurement table. Builders return structs; no package-defined MATLAB classes are necessary.

TimeStep defaults to 1 and TimeUnit to 'frame', independently. Spacing describes each source grid and must be updated when the representation is resampled.

## Geometry: groups of locations

Prepared objects holds identified memberships:

```text
objects
  ObjectIDs
  Components
    PixelIdxList
  Grid
    Size
    Axes
    Spacing
    SpacingUnit
```

PixelIdxList is a cell array. One cell holds the index vector for one ID group. A numeric ID does not specify whether its voxels are connected.

Generated geometry uses records:

```text
geometry.boundary
  Records
    ObjectID
    ComponentID
    Indices
    Status
    Fallback
  Grid
  Method
  Options
```

There can be several records for one parent ID because it has disconnected pieces. Indices identify entries on Grid; they are not automatically XYZ coordinates or physical positions.

Use geometryToMatrix to render these supported representations instead of manually remembering their different index-storage paths.

## Geometry versus support

```matlab
supports.objects = objects;
supports.boundary = geometry.boundary;
```

supports names the selections available for sampling. Boundary geometry can be used directly as a support; no new boundary is calculated by this assignment.

The comparison reference can be different: filament centroids select evaluation locations, while gradients sampled there provide alignment reference directions.

## Options versus requests

```matlab
c.GeometryOptions.boundary = struct('Sigma',1,'LayerWidth',1);
```

This is a setting for generating geometry. It contains no generated boundary indices.

```matlab
q = objectrelativeprofiles.config.makeQuery( ...
    'Name','BoundarySignal','Field','Intensity', ...
    'Support','boundary','Statistics',{'Mean'});
```

This is a request. Its strings identify the field, support and statistic; they do not contain those matrices or their sampled values.

A query's Options field supplies additional settings for its consumer. The same option name may mean different things in another API.

## Tables: quantities organized by identity

Named table columns store quantities of consistently defined types. For a measurement table, entries across a row describe the same identified region and frame.

```matlab
measurements.Properties.VariableNames
measurements(:,{'Frame','ObjectID','Volume'})
measurements.Volume
```

The first expression lists column names, the second returns a smaller table, and the third extracts the Volume values.

A table variable can hold more than one number per row: Centroid contains XYZ coordinates. A cell-valued variable can hold a histogram struct or a custom result.

DatasetID, Frame and ObjectID identify parent-group measurements. ComponentID is used when component-level results need distinction. TrajectoryID is additional tracking information, not a replacement for detection identity.

Attach tables using their keys. Equal row counts do not establish corresponding identities.

## Data columns versus metadata

Table measurements are visible columns. Metadata can reside elsewhere:

```matlab
measurements.Properties.VariableUnits
measurements.Properties.UserData
```

A result may retain grid, provenance and options here. Selecting fewer visible columns does not necessarily discard metadata.

Diagnostics such as FiniteCount and UsedFallback explain how a measurement was obtained. A zero intensity, an empty selection and a substituted centroid are different situations.

## payload, manifest and saved result

payload is the collection selected for one saved frame. manifest collects the run's combined outputs or file locations.

saveNew writes a MAT variable called result, regardless of the caller's local variable name:

```matlab
saved = load('<output folder>/frame010.mat');
saved.result.Measurements
```

In workflow 1, returned result is the run manifest. It is not the same container as the frame result read from disk.

The helper's temporary arrays are in its own workspace. To inspect them while running, use a breakpoint or insert a display inside the helper; they do not automatically appear in the script workspace.

For term definitions and field layouts, consult the [glossary](../GLOSSARY-CAPABILITIES-MOCKUP.md).
