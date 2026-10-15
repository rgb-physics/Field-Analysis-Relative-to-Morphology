# Changing an analysis

[Guide home](README.md) · [Workflow 1 walkthrough](WORKFLOW-1-WALKTHROUGH.md) · [Reading package structures](READING-STRUCTURES.md)

These examples apply to setupWorkflow1. Edit its ANALYSIS section, rerun that section, then execute RUN. DATA changes require rebuilding the source/experiment configuration too.

A setup edit changes arguments or requests. A helper edit is needed when adding a new processing operation or input-loading step. None of the examples below modifies original source files.

## 1. Request different region properties

Replace the property list:

```matlab
c.ObjectProperties = {'Volume','Centroid','BoundingBox'};
c.PhysicalVolume = false;
```

This requests native properties and omits the separately calculated PhysicalVolume column. Property availability follows MATLAB regionprops/regionprops3 for the input dimensionality.

To request physical volume without returning native Volume:

```matlab
c.ObjectProperties = {'Centroid'};
c.PhysicalVolume = true;
```

The helper obtains the voxel count internally for conversion. It does not force an unwanted Volume column into the output.

MeasurementOptions is currently an empty pass-through with no additional requirement for this ordinary 3-D analysis. Intensity measurements below use field queries.

## 2. Choose a smaller set of statistics

Replace the complete query list:

```matlab
c.Supports = {'objects'};
c.Queries = objectrelativeprofiles.config.makeQuery( ...
    'Name','RegionSignal','Field','Intensity', ...
    'Support','objects','Statistics',{'Mean','Max'});
```

The main table includes RegionSignal_Mean and RegionSignal_Max, rather than the four default queries. ObjectProperties still controls the separate region measurements.

Name chooses output prefixes. Field must match an actual entry in the helper's fields collection; Support must match an available support.

## 3. Use different statistics on different supports

```matlab
c.Supports = {'objects','boundary'};
c.Queries = [
    objectrelativeprofiles.config.makeQuery( ...
        'Name','InteriorSignal','Field','Intensity', ...
        'Support','objects','Statistics',{'Mean','Sum'})
    objectrelativeprofiles.config.makeQuery( ...
        'Name','BoundarySignal','Field','Intensity', ...
        'Support','boundary','Statistics',{'Mean','Std'})
    ];
```

Each query is independent. Changing its Statistics does not change the geometry or the other query.

Boundary support here is the generated boundary-referenced layer. Its statistics need not equal those from the entire region.

## 4. Adjust geometry generation

```matlab
c.Supports = {'objects','boundary'};
c.GeometryOptions.boundary = struct( ...
    'Sigma',1,'LayerMean',0,'LayerWidth',2);
```

LayerWidth is half-width in the operation's grid units. LayerMean positions the selected layer in the smoothed signed-distance field. These settings change selected locations, not just how a figure is drawn.

To request a skeleton:

```matlab
c.Supports = {'objects','skeleton'};
c.GeometryOptions.skeleton = struct('Method','blob','Sigma',1);
c.Queries = objectrelativeprofiles.config.makeQuery( ...
    'Name','SkeletonSignal','Field','Intensity', ...
    'Support','skeleton','Statistics',{'Mean','Max'});
```

The historical blob skeleton method requires its Gaussian-derivative dependency. Skeletons are geometry, not detected filament regions. Empty geometry/fallback behavior is recorded in diagnostics.

Removing boundary from Supports also requires removing any query referring to boundary.

## 5. Supply query-specific options

Quantiles:

```matlab
c.Queries = objectrelativeprofiles.config.makeQuery( ...
    'Name','RegionSignal','Field','Intensity','Support','objects', ...
    'Statistics',{'Quantiles'}, ...
    'Options',struct('Quantiles',[.1 .5 .9]));
```

Each table row's RegionSignal_Quantiles contains the three requested quantiles.

Histogram:

```matlab
c.Queries = objectrelativeprofiles.config.makeQuery( ...
    'Name','RegionSignal','Field','Intensity','Support','objects', ...
    'Statistics',{'Histogram'}, ...
    'Options',struct('BinEdges',0:100:5000));
```

The histogram variable holds a cell containing Counts and Edges for each row. Choose BinEdges or NumBins, not both.

Sample versus population standard deviation:

```matlab
c.Queries = objectrelativeprofiles.config.makeQuery( ...
    'Name','RegionSignal','Field','Intensity','Support','objects', ...
    'Statistics',{'Std'}, ...
    'Options',struct('VarianceNormalization',1));
```

VarianceNormalization=1 uses population normalization; 0 is the sample default. These settings belong to this query, not every statistic in the run.

## 6. Calculate a custom statistic

```matlab
reducers = struct('PeakToPeak',@(values) max(values)-min(values));
c.Queries = objectrelativeprofiles.config.makeQuery( ...
    'Name','RegionSignal','Field','Intensity','Support','objects', ...
    'Statistics',{'Mean'}, ...
    'Options',struct('CustomOperations',reducers));
```

Custom reducers receive finite selected values. Here the additional output is RegionSignal_PeakToPeak; custom reducer outputs are stored in cells. Reducers should define appropriate behavior for empty inputs.

This changes the requested operation without editing the sampling engine.

## 7. Transform values before calculating statistics

```matlab
c.Queries = objectrelativeprofiles.config.makeQuery( ...
    'Name','OffsetSignal','Support','objects', ...
    'Fields',{'Intensity'}, ...
    'Operation',@(fields) fields.Intensity-5, ...
    'Mode','field','Statistics',{'Mean','Max'});
```

This illustrative operation returns a same-sized field with a fixed offset removed for analysis. It neither changes the source file nor silently estimates an offset.

Mode='samples' instead gives an operation the selected value vectors and requires one output value per selected location. Mode='field' gives matching arrays and requires a matching output field. Operations can call named user functions.

A new independent image field requires a loading/production step in the helper before a query can reference it. Merely inventing a new Field name in setup does not load its data.

## 8. Use supplied masks or IDs

```matlab
c.ObjectLoader = @(frame) myMaskLoader(frame);
c.ObjectInputType = 'mask';
```

myMaskLoader is a user-written function returning a same-intensity-grid spatial mask. This bypasses probability segmentation.

For supplied labels:

```matlab
c.ObjectLoader = @(frame) myLabelLoader(frame);
c.ObjectInputType = 'labels';
```

Labels preserve ID groups, including disconnected pieces. Explicit labels mode prevents binary-valued label 1 from being split into components. The loader's grid must match the intensity grid; matching dimensions alone is not registration.

## 9. Run property measurements without field statistics

```matlab
c.ObjectProperties = {'Volume','Centroid'};
c.Supports = {'objects'};
c.Queries = [];
```

The helper skips field sampling. The current example still loads intensity for its analysis grid and creates its standard distance field; this is not a promise of a separately optimized properties-only pipeline.

## 10. Inspect selections and diagnostics

Within the helper, after supports have been constructed:

```matlab
boundaryMask = objectgeometry.representation.geometryToMatrix(supports.boundary);
z = round(size(boundaryMask,3)/2);
figure; imagesc(boundaryMask(:,:,z)); axis image;
```

For one ID group:

```matlab
boundaryMask = objectgeometry.representation.geometryToMatrix( ...
    supports.boundary,'ObjectIDs',7);
```

A breakpoint lets you inspect temporary variables without saving them.

After the run:

```matlab
result.Measurements
result.Diagnostics
```

Set c.IncludeDiagnostics=true before RUN to include the diagnostic columns in the main table too. Separate diagnostic tables remain saved by default.

## 11. Choose what to save

Edit the helper's explicit OUTPUT CHOICES assignments:

```matlab
payload = struct('Measurements',properties,'Seconds',toc(timer));
payload.Diagnostics = diagnostics;
% payload.Geometry = geometry;
% payload.Supports = supports;
```

Uncomment Geometry to retain generated features. Uncomment Supports to also retain whole-region membership. They can be large. Omitting them does not prevent their use for the current calculation.

To omit diagnostic tables from disk, comment out both payload.Diagnostics and the separate manifest.Diagnostics assignment. IncludeDiagnostics controls whether diagnostic columns appear in Measurements; if true, those columns still save with that table.

Optional LocalInertia can be enabled with explicit settings:

```matlab
c.LocalInertia = true;
c.InertiaOptions = struct('Radius',18,'Sigma',3,'SampleLimit',10000);
```

When skeleton geometry is requested it supplies the evaluation indices; otherwise the helper uses rounded centroids. This adds an independent geometric calculation, not an intensity statistic. Its payload assignment is another visible saving choice.

## 12. Keep identities when adding measurements later

New columns should be attached using identity keys, not copied according to current row positions:

```matlab
combined = objectrelativeprofiles.fieldSampling.attachResults( ...
    existingMeasurements,newMeasurements);
```

Both tables must describe corresponding DatasetID/Frame/ObjectID groups, with ComponentID where applicable. The join does not verify spatial registration.

If geometry was not retained, regenerate it from the same identified regions and settings before sampling another field. Independently resegmenting or reordering components does not guarantee that numeric IDs still mean the same regions.

## When to edit the helper

Edit setup for existing property choices, geometry options, queries/statistics, thresholds and source descriptions.

Edit helper logic for a new calculated reference, a new field-loading step, a different segmentation algorithm or a changed sequence of operations. The public APIs can do more than this example; the setup does not automatically assemble arbitrary new pipelines.
