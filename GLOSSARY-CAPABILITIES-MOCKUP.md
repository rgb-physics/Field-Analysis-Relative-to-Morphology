# Glossary and Data Dictionary — definitions and representations

In MATLAB, use `farmGlossary("Experiment")` for an entry, `farmGlossary("search", "distance")`
to search, or `catalog = farmGlossary` for the complete table. See
[MATLAB glossary usage and getters](docs/MATLAB-GLOSSARY.md).

For reading on GitHub, use the [scientific topic pages](docs/reference/README.md)
or [alphabetical entry index](docs/reference/terms.md). Those pages are generated
from this document, which remains the single editable source of definitions,
types and input layouts. Their expandable details keep extended notes out of
the initial view. The full public-function/test inventory is deferred until
the remaining functionality has been evaluated.

The Glossary defines concepts and workflow roles. The Data Dictionary at the
bottom defines named output fields. MATLAB searches both by default; optional
`Section` and `SearchIn` filters accept one name or a string array. `Section`
identifies Glossary or DataDictionary; `Group` records the topical subheading.

Inputs appear at the bottom of each entry and describe what is supplied to create, calculate, or select it. Concepts without a fixed input list say so explicitly. Contents describe stored or returned fields, not additional settings to enter. Input layouts use braces: Inputs: { FieldName* = type; }. An asterisk marks a field required for the specific form described; builders may supply generated fields automatically. Conditional requirements are stated explicitly. Generated-result layouts describe the resulting structure, not additional settings users must enter. Text means a string scalar or character vector. Optional defaults remain independent unless explicitly stated.

Bracketed text lists the data types or structures used to represent each term in this package. Some terms describe a role or physical feature and therefore have several representations. A scalar is one value, a vector is a list, and matrix here includes N-dimensional arrays. A scalar struct is one container whose fields may themselves hold large arrays.

## Glossary

### Containers and structure roles

**Array** [numeric or logical N-dimensional array]
Values arranged along one or more dimensions, with a fixed number of positions in each dimension.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Matrix** [numeric or logical N-dimensional array]
An array of values with a fixed size along each dimension. In this package, matrix can include more than two dimensions.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Struct** [scalar struct or struct array]
A collection of named fields that can store data, settings, or results. Each field has a name and a value.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Table** [MATLAB table]
Data arranged in named columns and rows. In a measurement table, each row describes the same object and frame across all columns.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Cell array** [cell array]
A collection whose entries can store values of different types and sizes.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Data** [numeric or logical scalar, vector or matrix]
The values being analyzed, such as image intensities or measured positions.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Metadata** [struct fields; table properties]
Information that explains the data, such as image spacing, units, dataset identity, or how results were obtained.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Options** [scalar struct]
A collection of settings that can control a particular operation.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Request / specification** [text list or query struct array]
Instructions describing what to select or calculate.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Configuration** [scalar struct]
A collection of settings that can be passed to one or more functions.
Settings can include file locations, image spacing, frames to
process, and analysis options.

Each setting has a name and a value, for example:
```matlab
c.Frames = 25:30;
```

The required settings depend on where the configuration is used.
See the relevant function's help for settings, accepted values,
and defaults.

Inputs: { Named settings and their values; required settings depend on where the configuration is used. }

**Result** [scalar, vector, matrix, table or struct; depends on calculation]
A value produced by a calculation, such as geometry, a field, measurements or a selection.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Payload** [scalar struct]
A collection of results chosen for saving, such as measurements, geometry, or diagnostic counts for one frame.

Example layout is workflow 1; all saved fields are chosen explicitly, with no universal required payload field.

Contents: { `Measurements` = table; `Seconds` = numeric scalar; `Diagnostics` = table; `Geometry` = struct; `Supports` = struct; `LocalInertia` = struct; }

Inputs: { Results chosen for saving; field names depend on the workflow. }

**Manifest** [scalar struct]
A collection describing saved results, such as file locations, combined measurement tables, or a summary of a processing run.

Example layout is workflow 1; other workflows may instead contain file lists or tracking results.

Contents: { `Directory` = text; `Measurements` = table; `Diagnostics` = table; }

Inputs: { Saved-result locations and summaries chosen by the workflow. }

### Dataset organization

**Dataset** [collection of files or arrays; described by a struct]
A related collection of data, stored in files or arrays.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Experiment** [scalar struct]
A description of the data to analyze, including its name, frames, timing, and where to load each data source.

For example, one experiment can describe intensity images and segmentation probabilities stored in separate folders.

Inputs: { `DatasetID`\* = text; `Frames`\* = numeric vector; `Sources`\* = struct of named source structs; `TimeStep` = positive numeric scalar (default 1); `TimeUnit` = text (default 'frame'); }

**Data source** [scalar struct]
A description of where and how to load data, including the file format, array axes, and spatial calibration.

Required markers depend on Format; file fields are not required for a custom loader.

Inputs: { `Format` = text; `Folder`\* = text (file source); `NamePattern`\* = text (file source); `DatasetPath`\* = text (HDF5 source); `Loader`\* = function handle (custom source); `SourceAxes` = text; `Spacing` = numeric vector; `SpacingUnit` = text; `Channels` = numeric vector; `TimeIndex` = numeric scalar; }

**Channel** [numeric index or text name; values in a matrix]
A separately stored image field or signal. Its interpretation depends on the dataset.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Frame** [numeric scalar; numeric vector for multiple values]
An identifier for an acquisition time point.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Time index** [numeric scalar; numeric vector for multiple values]
The position of a time point within an array. This position can differ from its acquisition frame number.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Time step** [numeric scalar; default 1]
The interval between original acquisition frames, expressed in the time unit. It can be supplied independently of that unit.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Time unit** [string scalar or character vector; default 'frame']
The unit used to express acquisition timing. It can be supplied independently of the time step.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Axes** [string scalar or character vector]
Names describing what each array dimension represents, such as Y, X, Z, channel, or time.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Coordinate order** [string scalar or character vector]
The order in which axis values are listed in a position, such as [Y X Z].

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Grid** [scalar struct with Size, Axes, Spacing and SpacingUnit]
A description of an array's size, axes, and spacing between spatial samples.

Layout shown for the representation converters: only Size is mandatory; other listed fields receive defaults.

Inputs: { `Size`\* = numeric vector; `Axes` = text; `Spacing` = numeric vector; `SpacingUnit` = text; }

**Voxel spacing** [numeric vector in YX/YXZ order]
The separation between neighboring spatial samples along each axis.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Units** [string scalar or character vector]
The scale used to express a quantity, such as voxels, micrometers or seconds.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

### Segmentation and identity

**Intensity field** [numeric matrix; optionally wrapped in a Data/Grid struct]
An array of measured signal values, such as fluorescence intensity at each image location.

Layout applies only to the optional wrapped-field representation.

Inputs: { `Data`\* = numeric or logical matrix; `Grid` = scalar struct; }

**Probability field** [numeric matrix; channel stacks include a channel dimension]
An array of probabilities or scores assigned to categories at each location, often exported by Ilastik.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Segmented category** [text name and numeric category ID; membership as mask or labels]
A meaning assigned to image locations, such as inside, boundary, outside, or background. One category can contain several separate regions.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Foreground mask** [logical matrix]
An array that marks selected locations as true and other locations as false. The selected locations can form several separate regions.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Connected component** [numeric index vector; groups in a bwconncomp struct]
A group of selected pixels or voxels connected according to a specified neighbor rule.

Layout applies to the component struct, not an individual raw index vector.

Contents: { `Connectivity`\* = numeric scalar; `ImageSize`\* = numeric vector; `NumObjects`\* = numeric scalar; `PixelIdxList`\* = cell array of numeric index vectors; }

Inputs: { Foreground mask and a neighbor rule for identifying connected locations. }

**Label matrix** [numeric integer-valued matrix]
An array assigning an integer ID to each location. Zero identifies background.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**ID group** [numeric ID plus index vector; or locations in a label matrix]
All locations assigned the same ID. These locations do not have to be connected.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Prepared geometry collection** [scalar struct containing IDs, Components and Grid]
A collection of object locations and IDs, together with the size and calibration of the array containing them.

This is generated by object preparation; users normally supply its constructor inputs instead of assembling these fields.

Contents: { `ObjectGeometryVersion`\* = numeric scalar; `ObjectIDs`\* = numeric vector; `Components`\* = component struct; `Grid`\* = scalar struct; `DatasetID`\* = text; `Frame`\* = numeric scalar; `SourceGrid` = struct or empty; `Transform` = mapping metadata or empty; `InputType` = text; }

Inputs: { Object locations and identity/grid settings; see farmPrepareObjects. }

### Geometry, supports and references

**Linear voxel indices** [numeric index vector; scalar for one index]
Numbers locating voxels in an array using MATLAB's linear indexing order.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Indices** [numeric index vector; scalar for one index]
Numbers identifying entries in a container. Their meaning depends on what is indexed: voxels, table rows or other entries.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Coordinates** [numeric N-by-D matrix; legacy functions may use D-by-N]
Positions expressed as values along named axes.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Geometry** [prepared/generated struct; indices or coordinates for raw representations]
A description of a structure's shape, extent, or spatial features, such as its boundary or skeleton.

Layout shows generated geometry; prepared membership uses the Prepared geometry collection layout. Each record contains ObjectID and Indices, with ComponentID, Status and Fallback as appropriate.

Contents: { `Type`\* = text; `Records`\* = struct array; `Grid`\* = scalar struct; `DatasetID` = text; `Frame` = numeric scalar; `Method` = text; `Options` = scalar struct; `SourceGrid` = struct or empty; `Transform` = mapping metadata or empty; }

Inputs: { Object locations, requested geometry type, and method settings; see farmGenerateGeometry. }

**Support** [prepared geometry/support struct, logical mask, numeric indices/labels or cell of index groups]
The locations selected for sampling a field or performing a calculation. These can be object locations, a boundary, a skeleton, or another selection.

Layout shows a generated prepared support. Raw selections or prepared geometry do not need this layout supplied manually.

Contents: { `SamplingVersion`\* = numeric scalar; `Name`\* = text; `Records`\* = struct array; `Grid`\* = scalar struct; `DatasetID`\* = text; `Frame`\* = numeric scalar; `Options` = scalar struct; }

Inputs: { input = selected locations or geometry; imageSize = array dimensions; options = sampling settings; see farmPrepareSupport. }

**Reference** [numeric field/vector, mask or geometry struct, according to calculation]
A geometry or quantity used to define or compare another measurement, such as a boundary used for distance measurements.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Boundary** [index vector or logical matrix; generated representation in a struct]
The edge of a region in 2D, or its surface in 3D, separating the region from its surroundings.

A boundary can be used to measure distances or compare directions relative to an object's surface.

Inputs: { input = object locations; type = 'boundary'; options = method settings; see farmGenerateGeometry. }

**Isosurface** [index/coordinate collection or mesh; neighborhood representation may be a mask]
A surface defined by a specified scalar-field value. Historical usage in this project also includes finite binned neighborhoods around such levels.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Distance-defined neighborhood** [index vector or logical matrix; generated representation in a struct]
Locations selected by a distance value or interval relative to a specified reference.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Layer** [index vector or logical matrix; generated representation in a struct]
A region of finite thickness. It can be defined around a surface or between field levels and need not wrap around another region.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Shell** [index vector or logical matrix; generated representation in a struct]
A layer surrounding a region; a useful descriptive special case rather than the general term for all layers.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Skeleton** [index vector or logical matrix; generated representation in a struct]
An internal representation of a structure that reduces its thickness while describing its shape. The result depends on the selected method.

Inputs: { input = object locations; type = 'skeleton'; options = method settings; see farmGenerateGeometry. }

**Filament** [mask or label matrix; prepared memberships in a struct]
An elongated, relatively thin structure present in image data.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Backbone** [numeric endpoint coordinates; legacy backbone struct]
A line through a filament's center, described by its direction and length.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Sheet** [mask or label matrix; prepared memberships in a struct]
A thin, surface-like structure present in image data.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Centered surface** [index vector or logical matrix; generated representation in a struct]
A calculated surface passing through the thickness of a structure.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Point cloud** [numeric coordinate matrix or voxel-index vector with grid metadata]
A collection of spatial positions without specified connections or faces between them.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Rendered geometry matrix** [logical mask or numeric matrix]
An array marking the locations of a geometry, such as a mask made from boundary indices.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Mesh** [numeric vertex/face matrices; sometimes grouped in a struct]
A representation of a surface using vertices and connections between them, such as triangular faces.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

### Sampling and measurements

**Property** [table variable; numeric scalar/vector, array or cell depending on property]
A measured characteristic of an object or geometry, such as volume or centroid.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Statistic** [numeric scalar/vector or table variable; histogram struct for counts/edges]
A value summarizing selected measurements, such as their mean, count, or variance.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Query** [scalar struct; struct array for multiple queries]
A request describing what field to sample, where to sample it, which statistics to calculate, and how to name the results.

The alternatives and conditional fields above are not forced pairs. The builder supplies statistic/settings defaults.

Inputs: { `Name`\* = text; `Support`\* = text; `Field` = text (required for a scalar query without Operation); `Operation` = function handle (alternative to Field); `Kind` = text; `Fields` = text list (required for vector queries); `Statistics` = text list; `Mode` = text; `Options` = scalar struct; }

**Field** [numeric matrix or ordered component collection; optional metadata struct]
A quantity defined at spatial locations.  

Layout applies to one wrapped scalar field; named component collections use the Vector field layout.

Inputs: { `Data`\* = numeric or logical matrix; `Grid` = scalar struct; }

**Scalar field** [numeric matrix; optionally wrapped in a Data/Grid struct]
A field with one numerical value at each location.

Layout applies only to the optional wrapped-field representation.

Inputs: { `Data`\* = numeric or logical matrix; `Grid` = scalar struct; }

**Vector field** [struct of named component matrices for sampling; some outputs use a component dimension]
A field with directional components at each location, such as three arrays storing Y, X, and Z components.

Inputs: { <component name>\* = numeric matrix or Data/Grid struct; }

**Vector component** [numeric matrix; optionally wrapped in a Data/Grid struct]
One directional component of a vector, such as its X component. This differs from a connected component of image locations.

Layout applies only to the optional wrapped-field representation.

Inputs: { `Data`\* = numeric or logical matrix; `Grid` = scalar struct; }

**Selected samples** [numeric vector]
Values read at the selected locations.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Finite samples** [numeric vector]
Selected numerical values excluding NaN and positive or negative infinity.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Diagnostic** [numeric count or logical flag; table variables and metadata structs]
A count, flag, or other result that helps explain whether a calculation had usable data or used a substitute.

The Data Dictionary defines the named sampling counts and flags listed under diagnostics.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Empty selection** [empty index vector or all-false mask; flagged in sampling results]
A selection containing no locations.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Fallback** [struct of substitute geometry/properties; logical flags and counts record its use]
A substitute used when the requested geometry or result is unavailable. Its use is recorded explicitly.

Generated fallback fields depend on the geometry method; these are not required user settings.

Contents: { `Centroid` = numeric XYZ vector; `PrincipalAxisLength` = numeric vector; `EigenVectors` = numeric matrix; }

Inputs: { Unavailable geometry or result, available substitute information, and settings enabling substitution for the selected method. }

**Length** [numeric scalar per group; vector/table column across groups]
A measure of extension along a specified path or direction; its calculation and units must be stated.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Width** [numeric scalar per group; vector/table column across groups]
A measure of thickness whose geometric definition and units must be stated.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Principal axes** [numeric direction matrix; eigenvalues/lengths in numeric vectors]
Directions calculated from an object's spatial distribution, describing the directions in which it spreads.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Projected extent** [numeric scalar per group; vector/table column across groups]
The difference between the largest and smallest coordinate projections along a specified direction.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Axial alignment** [result struct containing numeric scores/angles and logical validity]
A comparison of directions that treats opposite directions as equivalent. Reversing either direction leaves the alignment score unchanged.

Generated result fields are shown; these are not options supplied to the calculation.

Contents: { `Order` = numeric vector; `UnsignedAngle` = numeric vector; `SignedAngle` = numeric vector; `Dot` = numeric vector; `Valid` = logical vector; `Dimension` = numeric scalar; `Plane` = numeric vector; `Options` = scalar struct; }

Inputs: { Directions to compare and alignment settings; exact arguments depend on the selected alignment function. }

### Tracking and field analysis

**Detection** [table row with IDs, Frame and associated quantities]
An identified object at a particular acquisition frame.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Trajectory** [TrajectoryID column plus associated detection rows]
A sequence of detections assigned the same tracked identity over time.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Lineage** [detection/link/event tables in a tracking struct; optional digraph]
Recorded relationships connecting objects over time, including splits and merges.

Layout shows an overlap-tracking result; these are generated fields, not user-entered tracking settings.

Contents: { `Detections` = table; `Links` = table; `Events` = table; `GridMetadata` = cell array; `Options` = scalar struct; `Method` = text; `DatasetID` = text; }

Inputs: { Detections or object frames and tracking settings; exact arguments depend on the tracking method. }

**Ancestry** [selection struct containing detection table and IDs]
Objects found at earlier times by following recorded parent relationships backward from a selected object.

Generated selection result, not the seed input struct.

Contents: { `Detections` = table; `SeedDetectionIDs` = numeric vector; `BackgroundCoordinatesYXZ` = numeric coordinate matrix; `Status` = text; `Options` = scalar struct; }

Inputs: { tracking = tracking result; seed = starting selection; options.Direction = 'ancestors'; options.IncludeSeed = logical scalar (default true); options.Loader = frame loader when starting from coordinates; see farmSelectLineage. }

**Descendants** [selection struct containing detection table and IDs]
Objects found at later times by following recorded parent-to-child relationships from a selected object.

If an object splits, its descendants can include objects from more than one resulting branch.

Generated selection result, not the seed input struct.

Contents: { `Detections` = table; `SeedDetectionIDs` = numeric vector; `BackgroundCoordinatesYXZ` = numeric coordinate matrix; `Status` = text; `Options` = scalar struct; }

Inputs: { tracking = tracking result; seed = starting selection; options.Direction = 'descendants' (must be selected explicitly); options.IncludeSeed = logical scalar (default true); options.Loader = frame loader when starting from coordinates; see farmSelectLineage. }

**Split** [relationships in link/event tables]
A recorded relationship connecting one parent object to multiple child objects.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Merge** [relationships in link/event tables]
A recorded relationship connecting multiple parent objects to one child object.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Gap** [missing-frame interval; configured memory as a numeric scalar]
An interval during which a tracked object has no recorded detection.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Spectrum** [result struct containing numeric spectra/frequency axes and metadata]
A description of how much a signal varies at different spatial frequencies.

Layout shows a power-spectrum result; these fields are generated, not all required constructor inputs.

Contents: { `Radial` = struct; `FrequencyAxes` = cell array of numeric vectors; `GridSize` = numeric vector; `Spacing` = numeric vector; `SpacingUnit` = text; `MeanSubtract` = logical scalar; `Window` = logical scalar; `Normalization` = struct; `Power` = numeric matrix (optional); }

Inputs: { Sampled field and spectrum settings, including spatial calibration; see farmPowerSpectrum2D or farmPowerSpectrum3D. }

**Power** [numeric matrix or radial-statistics vectors]
Here, the squared magnitude of a Fourier-transform value.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Normalization** [numeric factor; descriptive factors/settings in a struct]
Rescaling values according to a stated rule or reference.

Layout shows spectral normalization metadata; other normalization operations can return different fields.

Contents: { `Method` = text; `AppliedFactor` = numeric scalar; `VoxelCount` = numeric scalar; `InputSum` = numeric scalar; `InputMean` = numeric scalar; `InputVariance` = numeric scalar; `WindowSum` = numeric scalar; `WindowSquaredSum` = numeric scalar; }

Inputs: { Values to rescale and settings for the selected normalization method. }

**Window** [numeric weighting matrix; logical option selects built-in windowing]
Weights applied to data before a calculation, such as a Fourier transform.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**Correlation** [numeric lag matrix; returned with lag axes/metadata in a struct]
A comparison of field values at different spatial separations.

Generated correlation result; additional provenance fields may be present.

Contents: { `Correlation` = numeric matrix; `LagAxes` = cell array of numeric vectors; `ZeroLagIndex` = numeric vector; `Boundary` = text; `Normalization` = text; `Spacing` = numeric vector; `SpacingUnit` = text; }

Inputs: { Fields to compare and correlation settings; exact arguments depend on the selected correlation function. }

**Conditional profile** [result struct containing binned-statistics table and edges]
Statistics of one quantity grouped by values of another, such as mean intensity grouped by distance from a boundary.

Generated conditional-statistics result.

Contents: { `Edges` = numeric vector; `Statistics` = table; `ExcludedCounts` = table; }

Inputs: { Measured values, conditioning values, bin edges, and calculation settings; see farmConditionalStatistics. }

**Bins** [numeric edge/center vectors; counts in vectors, matrices or tables]
Intervals used to group numerical values.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

### Workflow 1: recognize the roles in code

**experiment** [scalar struct]
The workflow variable containing the dataset description and named sources.

Inputs: { `DatasetID`\* = text; `Frames`\* = numeric vector; `Sources`\* = struct of named source structs; `TimeStep` = positive numeric scalar (default 1); `TimeUnit` = text (default 'frame'); }

**c.ObjectProperties** [cell array of character vectors or string array]
The workflow setting listing the region properties requested for measurement.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**c.GeometryOptions** [scalar struct with a per-geometry options struct]
The workflow settings controlling how each requested geometry is generated.

Inputs: { <geometry name> = scalar options struct; }

**c.Queries** [query struct array; empty for no sampling]
The workflow requests defining which fields to sample, at which supports, and which statistics to calculate.  

Each array entry follows this layout; the workflow also permits an empty query array.

Inputs: { `Name`\* = text; `Support`\* = text; `Field` = text (required for a scalar query without Operation); `Operation` = function handle (alternative to Field); `Kind` = text; `Fields` = text list (required for vector queries); `Statistics` = text list; `Mode` = text; `Options` = scalar struct; }

**objects** [scalar struct containing IDs, Components and Grid]
The workflow variable containing prepared voxel memberships, IDs and grid metadata.  

This is the generated prepared form, not the object-preparation options struct.

Contents: { `ObjectGeometryVersion`\* = numeric scalar; `ObjectIDs`\* = numeric vector; `Components`\* = component struct; `Grid`\* = scalar struct; `DatasetID`\* = text; `Frame`\* = numeric scalar; `SourceGrid` = struct or empty; `Transform` = mapping metadata or empty; `InputType` = text; }

Inputs: { Object locations and preparation settings; see farmPrepareObjects. }

**geometry** [scalar struct of named generated-geometry structs]
The workflow collection of generated spatial features.

Contents: { <geometry name> = generated geometry struct; }

Inputs: { Object locations and the requested geometry types and settings. }

**supports** [scalar struct of named selections/geometry structs]
The workflow collection naming the locations selected for sampling.  

Names must match the supports referenced by queries; there is no fixed universal support-name list.

Inputs: { <support name>\* = prepared geometry/support struct, mask, labels or indices; }

**fields** [scalar struct of named matrices or Data/Grid structs]
The workflow collection containing the actual arrays to be sampled.  

Names must match the fields referenced by queries; there is no fixed universal field-name list.

Inputs: { <field name>\* = numeric/logical matrix or Data/Grid struct; }

**properties** [MATLAB table]
The workflow table containing identity keys and requested measurements.

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**diagnostics** [MATLAB table]
The workflow table containing validity counts and flags:
[SelectedCount,FiniteCount,NaNCount,PositiveInfCount,NegativeInfCount,SelectionEmpty,GeometryEmpty,EmptyGeometryCount,UsedFallback,FallbackCount]

Inputs: { No fixed input list; this entry defines a concept or representation. See the function using it for accepted values. }

**payload** [scalar struct]
The workflow variable collecting outputs selected for saving at one frame.  

Workflow 1's selected saved fields; no universal payload fields are required.

Contents: { `Measurements` = table; `Seconds` = numeric scalar; `Diagnostics` = table; `Geometry` = struct; `Supports` = struct; `LocalInertia` = struct; }

Inputs: { Results explicitly chosen for saving in workflow 1. }

**manifest** [scalar struct]
The workflow variable collecting the run's combined results or output locations.  

Workflow 1 layout shown; exact fields depend on the workflow.

Contents: { `Directory` = text; `Measurements` = table; `Diagnostics` = table; }

Inputs: { Output locations and combined results collected by workflow 1. }

## Data Dictionary

Named fields below describe generated sampling results, not additional user inputs.
The names are suffixes: farmQueryField writes <FieldName>_<suffix>, and farmQueryFrame uses
<QueryName>_<suffix>. Vector component queries use <FieldName>_<ComponentName>_<suffix>.
Counts refer to one result row; field/query prefixes distinguish separate calculations.
These entries document behavior, not a universal set of columns required in every table.

### Sampling diagnostics

**SelectedCount** [double scalar per row; table column across rows]
The number of selected locations sampled. This includes locations whose sampled values are NaN or positive or negative infinity.

Produced by farmQueryField; retained separately for each component by queryVectorField. Includes samples that become NaN or infinite. SelectedCount equals FiniteCount+NaNCount+PositiveInfCount+NegativeInfCount. A sample operation must return one value per selected location.

Calculation detail: The number of selected voxel locations actually sampled after support preparation, including any applied centroid fallback. Indices are deduplicated within the resulting support group.

Inputs: { Sampled field values at the selected locations, after any requested sample operation. }

**FiniteCount** [double scalar per row; table column across rows]
The number of sampled values available for calculation. Values equal to NaN or positive or negative infinity are excluded.

A value of zero means no finite sampled values were available.

Produced by farmQueryField; independent per component in queryVectorField. FiniteCount can be zero while SelectedCount is nonzero. The requested Count statistic equals FiniteCount, not SelectedCount.

Inputs: { Sampled field values at the selected locations, after any requested sample operation. }

**NaNCount** [double scalar per row; table column across rows]
The number of sampled values equal to NaN. These values are excluded from statistics calculated from finite samples.

Produced by farmQueryField; independent per component in queryVectorField. Counts values after an optional sample operation, not invalid voxels elsewhere in the volume.

Inputs: { Sampled field values at the selected locations, after any requested sample operation. }

**PositiveInfCount** [double scalar per row; table column across rows]
The number of sampled values equal to positive infinity. These values are excluded from statistics calculated from finite samples.

Produced by farmQueryField; independent per component in queryVectorField. Reported separately from NegativeInfCount and NaNCount.

Inputs: { Sampled field values at the selected locations, after any requested sample operation. }

**NegativeInfCount** [double scalar per row; table column across rows]
The number of sampled values equal to negative infinity. These values are excluded from statistics calculated from finite samples.

Produced by farmQueryField; independent per component in queryVectorField. Reported separately from PositiveInfCount and NaNCount.

Inputs: { Sampled field values at the selected locations, after any requested sample operation. }

**SelectionEmpty** [logical scalar per row; table column across rows]
True when no locations remain selected for sampling. False means at least one location is selected, even if its value is not finite.

Produced by queryField. An empty skeleton with an applied centroid fallback can have SelectionEmpty = false and GeometryEmpty = true. A nonempty selection containing only nonfinite values has SelectionEmpty = false but FiniteCount = 0.

Inputs: { Selected locations after preparation and any enabled centroid substitution. }

**GeometryEmpty** [logical scalar per support record or result row]
True when the calculated geometry contains no locations before any substitute location is added.

Set by farmPrepareSupport for generated-geometry records and copied into farmQueryField results. Does not become false merely because fallback adds a centroid. For raw selections and prepared memberships this provenance flag defaults to false; an empty raw mask is instead indicated by SelectionEmpty. Some empty components do not make an otherwise nonempty combined geometry empty; inspect EmptyGeometryCount for that case.

Calculation detail: True when the source generated geometry has no computed indices. When generated components are combined by parent ID, true means every source component had empty geometry before fallback.

Inputs: { Calculated geometry records before centroid substitution; see farmPrepareSupport. }

**EmptyGeometryCount** [double scalar per support record or result row]
The number of calculated geometry records that contain no locations before any substitute location is added.

Set by farmPrepareSupport and copied into farmQueryField results. With component results this is zero or one; with components combined by parent ID it is the sum over source records. Raw selections and prepared memberships default to zero.

Inputs: { Calculated geometry records before centroid substitution; see farmPrepareSupport. }

**UsedFallback** [logical scalar per support record or result row]
True when an empty calculated skeleton is sampled at its rounded centroid instead. When records are combined, true means at least one record used this substitute.

Set by farmPrepareSupport and copied into farmQueryField results. Currently controlled by CentroidFallback; it does not describe every fallback mechanism in the package, such as the single-voxel ProjectedExtent fallback. SelectionEmpty can be false even though GeometryEmpty remains true.

Calculation detail: True when support preparation substitutes a rounded, nearest-voxel centroid for an empty generated skeleton record, or any constituent record uses that substitution when combined by parent ID.

Inputs: { Calculated skeleton records and the CentroidFallback setting; see farmPrepareSupport. }

**FallbackCount** [double scalar per support record or result row]
The number of skeleton records replaced by their rounded centroid for sampling. This counts records, rather than distinct sampled locations.

Set by farmPrepareSupport and copied into farmQueryField results. With component results this is zero or one; with components combined by parent ID it is summed. It counts substituted records, not unique fallback voxels: overlapping centroid locations may be deduplicated in the final selection.

Calculation detail: The number of source skeleton records for which centroid fallback was applied during support preparation.

Inputs: { Calculated skeleton records and the CentroidFallback setting; see farmPrepareSupport. }
