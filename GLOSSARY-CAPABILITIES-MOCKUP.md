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

Inputs layouts use braces: Inputs: { FieldName* = type; }. An asterisk marks a field required for the specific form described; builders may supply generated fields automatically. Conditional requirements are stated explicitly. Generated-result layouts describe the resulting structure, not additional settings users must enter. Text means a string scalar or character vector. Optional defaults remain independent unless explicitly stated.

Bracketed text lists the data types or structures used to represent each term in this package. Some terms describe a role or physical feature and therefore have several representations. A scalar is one value, a vector is a list, and matrix here includes N-dimensional arrays. A scalar struct is one container whose fields may themselves hold large arrays.

## Glossary

### Containers and structure roles

**Array** [numeric or logical N-dimensional array]  
A rectangular arrangement of elements with a fixed number of positions along each dimension.

**Matrix** [numeric or logical N-dimensional array]  
In this package, an N-dimensional array of consistently typed elements, with a fixed extent along each dimension. The term is not restricted to two dimensions.

**Struct** [scalar struct or struct array]  
A collection of named fields. A struct is a container, not a guarantee that its contents are data, options or results.

**Table** [MATLAB table]  
Named columns storing quantities of consistently defined types. In a measurement table, items across one row correspond to the same identified region and frame; other tables use one row per defined record or relationship.

**Cell array** [cell array]  
A container whose entries can hold values with different shapes or types.

**Data** [numeric or logical scalar, vector or matrix]  
The actual values being analyzed, rather than descriptions of where to find them or instructions for processing them.

**Metadata** [struct fields; table properties]  
Information about interpretation, identity, calibration or provenance.

**Options** [scalar struct]  
Settings controlling how one particular operation behaves.

**Request / specification** [text list or query struct array]  
Instructions stating what should be selected or calculated.

**Configuration** [scalar struct]  
A collection of user-selected settings and requests that defines how an analysis should run.

**Result** [scalar, vector, matrix, table or struct; depends on calculation]  
A value produced by a calculation, such as geometry, a field, measurements or a selection.

**Payload** [scalar struct]  
The explicitly selected results to save for a frame or operation.  
Inputs: { `Measurements` = table; `Seconds` = numeric scalar; `Diagnostics` = table; `Geometry` = struct; `Supports` = struct; `LocalInertia` = struct; }

Example layout is workflow 1; all saved fields are chosen explicitly, with no universal required payload field.

**Manifest** [scalar struct]  
A workflow-specific collection of output locations, combined tables or run summaries.  
Inputs: { `Directory` = text; `Measurements` = table; `Diagnostics` = table; }

Example layout is workflow 1; other workflows may instead contain file lists or tracking results.

### Dataset organization

**Dataset** [collection of files or arrays; described by a struct]  
A related collection of input data.

**Experiment** [scalar struct]  
A description of a dataset's identity, acquisition frames, timing and named data sources.  
Inputs: { `DatasetID`\* = text; `Frames`\* = numeric vector; `Sources`\* = struct of named source structs; `TimeStep` = positive numeric scalar (default 1); `TimeUnit` = text (default 'frame'); }

**Data source** [scalar struct]  
A description of how to load a field, with its axes and calibration.  
Inputs: { `Format` = text; `Folder`\* = text (file source); `NamePattern`\* = text (file source); `DatasetPath`\* = text (HDF5 source); `Loader`\* = function handle (custom source); `SourceAxes` = text; `Spacing` = numeric vector; `SpacingUnit` = text; `Channels` = numeric vector; `TimeIndex` = numeric scalar; }

Required markers depend on Format; file fields are not required for a custom loader.

**Channel** [numeric index or text name; values in a matrix]  
A separately stored image field or signal. Its interpretation depends on the dataset.

**Frame** [numeric scalar; numeric vector for multiple values]  
An identifier for an acquisition time point.

**Time index** [numeric scalar; numeric vector for multiple values]  
The position of a time point within the stored time dimension of an array.

**Time step** [numeric scalar; default 1]  
The interval between original acquisition frames, expressed in the time unit. It can be supplied independently of that unit.

**Time unit** [string scalar or character vector; default 'frame']  
The unit used to express acquisition timing. It can be supplied independently of the time step.

**Axes** [string scalar or character vector]  
Names identifying what each array dimension represents.

**Coordinate order** [string scalar or character vector]  
The order of axis values within a coordinate vector.

**Grid** [scalar struct with Size, Axes, Spacing and SpacingUnit]  
The dimensions and spatial calibration of a sampled representation.  
Inputs: { `Size`\* = numeric vector; `Axes` = text; `Spacing` = numeric vector; `SpacingUnit` = text; }

Layout shown for the representation converters: only Size is mandatory; other listed fields receive defaults.

**Voxel spacing** [numeric vector in YX/YXZ order]  
The separation between neighboring spatial samples along each axis.

**Units** [string scalar or character vector]  
The scale used to express a quantity, such as voxels, micrometers or seconds.

### Segmentation and identity

**Intensity field** [numeric matrix; optionally wrapped in a Data/Grid struct]  
An array representing measured signal values.  
Inputs: { `Data`\* = numeric or logical matrix; `Grid` = scalar struct; }

Layout applies only to the optional wrapped-field representation.

**Probability field** [numeric matrix; channel stacks include a channel dimension]  
An array interpreted as a category probability or score, often exported by Ilastik.

**Segmented category** [text name and numeric category ID; membership as mask or labels]  
A meaning assigned to voxels, such as inside, wall, outside or background. One category can contain many separate regions.

**Foreground mask** [logical matrix]  
A logical array selecting foreground voxels; it can contain zero, one or many connected components.

**Connected component** [numeric index vector; groups in a bwconncomp struct]  
A foreground voxel group connected under a specified adjacency rule.  
Inputs: { `Connectivity`\* = numeric scalar; `ImageSize`\* = numeric vector; `NumObjects`\* = numeric scalar; `PixelIdxList`\* = cell array of numeric index vectors; }

Layout applies to the component struct, not an individual raw index vector.

**Label matrix** [numeric integer-valued matrix]  
An integer matrix assigning IDs to locations, with zero denoting background.

**ID group** [numeric ID plus index vector; or locations in a label matrix]  
All locations assigned the same ID, whether connected or disconnected.

**Prepared geometry collection** [scalar struct containing IDs, Components and Grid]  
A structure holding voxel-index groups, their identities and current-grid metadata.  
Inputs: { `ObjectGeometryVersion`\* = numeric scalar; `ObjectIDs`\* = numeric vector; `Components`\* = component struct; `Grid`\* = scalar struct; `DatasetID`\* = text; `Frame`\* = numeric scalar; `SourceGrid` = struct or empty; `Transform` = mapping metadata or empty; `InputType` = text; }

This is generated by object preparation; users normally supply its constructor inputs instead of assembling these fields.

### Geometry, supports and references

**Linear voxel indices** [numeric index vector; scalar for one index]  
Numbers locating voxels in a particular matrix using MATLAB's linear indexing order.

**Indices** [numeric index vector; scalar for one index]  
Numbers identifying entries in a container. Their meaning depends on what is indexed: voxels, table rows or other entries.

**Coordinates** [numeric N-by-D matrix; legacy functions may use D-by-N]  
Positions expressed as values along named axes.

**Geometry** [prepared/generated struct; indices or coordinates for raw representations]  
A spatial representation of a structure's extent or features.  
Inputs: { `Type`\* = text; `Records`\* = struct array; `Grid`\* = scalar struct; `DatasetID` = text; `Frame` = numeric scalar; `Method` = text; `Options` = scalar struct; `SourceGrid` = struct or empty; `Transform` = mapping metadata or empty; }

Layout shows generated geometry; prepared membership uses the Prepared geometry collection layout. Each record contains ObjectID and Indices, with ComponentID, Status and Fallback as appropriate.

**Support** [prepared geometry/support struct, logical mask, numeric indices/labels or cell of index groups]  
The locations selected for evaluating a field or calculation. Support describes a selection's role; it need not be a different representation from its source geometry.  
Inputs: { `SamplingVersion`\* = numeric scalar; `Name`\* = text; `Records`\* = struct array; `Grid`\* = scalar struct; `DatasetID`\* = text; `Frame`\* = numeric scalar; `Options` = scalar struct; }

Layout shows a generated prepared support. Raw selections or prepared geometry do not need this layout supplied manually.

**Reference** [numeric field/vector, mask or geometry struct, according to calculation]  
The geometry or quantity against which another quantity is defined or compared.

**Boundary** [index vector or logical matrix; generated representation in a struct]  
The interface separating a region from its surroundings.

**Isosurface** [index/coordinate collection or mesh; neighborhood representation may be a mask]  
A surface defined by a specified scalar-field value. Historical usage in this project also includes finite binned neighborhoods around such levels.

**Distance-defined neighborhood** [index vector or logical matrix; generated representation in a struct]  
Locations selected by a distance value or interval relative to a specified reference.

**Layer** [index vector or logical matrix; generated representation in a struct]  
A region of finite thickness. It can be defined around a surface or between field levels and need not wrap around another region.

**Shell** [index vector or logical matrix; generated representation in a struct]  
A layer surrounding a region; a useful descriptive special case rather than the general term for all layers.

**Skeleton** [index vector or logical matrix; generated representation in a struct]  
A derived internal geometric feature, with its form determined by the selected method.

**Filament** [mask or label matrix; prepared memberships in a struct]  
An elongated, relatively thin structure present in image data.

**Backbone** [numeric endpoint coordinates; legacy backbone struct]  
An idealized line representation through a filament's center, defined by a direction and length.

**Sheet** [mask or label matrix; prepared memberships in a struct]  
A thin, surface-like structure present in image data.

**Centered surface** [index vector or logical matrix; generated representation in a struct]  
A derived surface-like representation passing through the thickness of a structure.

**Point cloud** [numeric coordinate matrix or voxel-index vector with grid metadata]  
A set of spatial locations without implied faces or connectivity.

**Rendered geometry matrix** [logical mask or numeric matrix]  
A dense representation made from geometry locations.

**Mesh** [numeric vertex/face matrices; sometimes grouped in a struct]  
A surface representation with vertices and connectivity, such as faces.

### Sampling and measurements

**Property** [table variable; numeric scalar/vector, array or cell depending on property]  
A measured characteristic of a region or geometry.

**Statistic** [numeric scalar/vector or table variable; histogram struct for counts/edges]  
A quantity summarizing selected values.

**Query** [scalar struct; struct array for multiple queries]  
An instruction specifying a field or operation, selected support, requested statistics and output name.  
Inputs: { `Name`\* = text; `Support`\* = text; `Field` = text (required for a scalar query without Operation); `Operation` = function handle (alternative to Field); `Kind` = text; `Fields` = text list (required for vector queries); `Statistics` = text list; `Mode` = text; `Options` = scalar struct; }

The alternatives and conditional fields above are not forced pairs. The builder supplies statistic/settings defaults.

**Field** [numeric matrix or ordered component collection; optional metadata struct]  
A quantity defined at spatial locations.  
Inputs: { `Data`\* = numeric or logical matrix; `Grid` = scalar struct; }

Layout applies to one wrapped scalar field; named component collections use the Vector field layout.

**Scalar field** [numeric matrix; optionally wrapped in a Data/Grid struct]  
A field with one numerical value at each location.  
Inputs: { `Data`\* = numeric or logical matrix; `Grid` = scalar struct; }

Layout applies only to the optional wrapped-field representation.

**Vector field** [struct of named component matrices for sampling; some outputs use a component dimension]  
A field with an ordered set of directional components at each location.  
Inputs: { <component name>\* = numeric matrix or Data/Grid struct; }

**Vector component** [numeric matrix; optionally wrapped in a Data/Grid struct]  
One coordinate component of a vector; distinct from a connected component of voxels.  
Inputs: { `Data`\* = numeric or logical matrix; `Grid` = scalar struct; }

Layout applies only to the optional wrapped-field representation.

**Selected samples** [numeric vector]  
Values read at the selected locations.

**Finite samples** [numeric vector]  
Selected numerical values excluding NaN and positive or negative infinity.

**Diagnostic** [numeric count or logical flag; table variables and metadata structs]  
Information describing the validity or interpretation of a result.

The Data Dictionary defines the named sampling counts and flags listed under diagnostics.

**Empty selection** [empty index vector or all-false mask; flagged in sampling results]  
A selection containing no locations.

**Fallback** [struct of substitute geometry/properties; logical flags and counts record its use]  
An explicitly identified substitute used when the requested geometry or result is unavailable.  
Inputs: { `Centroid` = numeric XYZ vector; `PrincipalAxisLength` = numeric vector; `EigenVectors` = numeric matrix; }

Generated fallback fields depend on the geometry method; these are not required user settings.

**Length** [numeric scalar per group; vector/table column across groups]  
A measure of extension along a specified path or direction; its calculation and units must be stated.

**Width** [numeric scalar per group; vector/table column across groups]  
A measure of thickness whose geometric definition and units must be stated.

**Principal axes** [numeric direction matrix; eigenvalues/lengths in numeric vectors]  
Directions derived from the spatial distribution of a region, describing its dominant directions of spread.

**Projected extent** [numeric scalar per group; vector/table column across groups]  
The difference between the largest and smallest coordinate projections along a specified direction.

**Axial alignment** [result struct containing numeric scores/angles and logical validity]  
Comparison of directions with 0–pi symmetry: reversing either direction leaves the alignment score unchanged.  
Inputs: { `Order` = numeric vector; `UnsignedAngle` = numeric vector; `SignedAngle` = numeric vector; `Dot` = numeric vector; `Valid` = logical vector; `Dimension` = numeric scalar; `Plane` = numeric vector; `Options` = scalar struct; }

Generated result fields are shown; these are not options supplied to the calculation.

### Tracking and field analysis

**Detection** [table row with IDs, Frame and associated quantities]  
An identified region at a particular frame.

**Trajectory** [TrajectoryID column plus associated detection rows]  
A selected continuation of identity across detections.

**Lineage** [detection/link/event tables in a tracking struct; optional digraph]  
The relationships connecting detections through time.  
Inputs: { `Detections` = table; `Links` = table; `Events` = table; `GridMetadata` = cell array; `Options` = scalar struct; `Method` = text; `DatasetID` = text; }

Layout shows an overlap-tracking result; these are generated fields, not user-entered tracking settings.

**Ancestry** [selection struct containing detection table and IDs]  
The history reached by following parent relationships backward from a selected detection.  
Inputs: { `Detections` = table; `SeedDetectionIDs` = numeric vector; `BackgroundCoordinatesYXZ` = numeric coordinate matrix; `Status` = text; `Options` = scalar struct; }

Generated selection result, not the seed input struct.

**Descendants** [selection struct containing detection table and IDs]  
The detections reached by following child relationships forward from a selected detection.  
Inputs: { `Detections` = table; `SeedDetectionIDs` = numeric vector; `BackgroundCoordinatesYXZ` = numeric coordinate matrix; `Status` = text; `Options` = scalar struct; }

Generated selection result, not the seed input struct.

**Split** [relationships in link/event tables]  
A relationship connecting one parent detection to multiple child detections.

**Merge** [relationships in link/event tables]  
A relationship connecting multiple parent detections to one child detection.

**Gap** [missing-frame interval; configured memory as a numeric scalar]  
An interruption in the observed detections belonging to a trajectory.

**Spectrum** [result struct containing numeric spectra/frequency axes and metadata]  
A representation of a signal's content across spatial frequencies.  
Inputs: { `Radial` = struct; `FrequencyAxes` = cell array of numeric vectors; `GridSize` = numeric vector; `Spacing` = numeric vector; `SpacingUnit` = text; `MeanSubtract` = logical scalar; `Window` = logical scalar; `Normalization` = struct; `Power` = numeric matrix (optional); }

Layout shows a power-spectrum result; these fields are generated, not all required constructor inputs.

**Power** [numeric matrix or radial-statistics vectors]  
Here, the squared magnitude of a Fourier-transform value.

**Normalization** [numeric factor; descriptive factors/settings in a struct]  
Scaling a quantity according to a stated reference or convention.  
Inputs: { `Method` = text; `AppliedFactor` = numeric scalar; `VoxelCount` = numeric scalar; `InputSum` = numeric scalar; `InputMean` = numeric scalar; `InputVariance` = numeric scalar; `WindowSum` = numeric scalar; `WindowSquaredSum` = numeric scalar; }

Layout shows spectral normalization metadata; other normalization operations can return different fields.

**Window** [numeric weighting matrix; logical option selects built-in windowing]  
A weighting applied to input samples before an operation such as a Fourier transform.

**Correlation** [numeric lag matrix; returned with lag axes/metadata in a struct]  
Comparison of field values at relative displacements.  
Inputs: { `Correlation` = numeric matrix; `LagAxes` = cell array of numeric vectors; `ZeroLagIndex` = numeric vector; `Boundary` = text; `Normalization` = text; `Spacing` = numeric vector; `SpacingUnit` = text; }

Generated correlation result; additional provenance fields may be present.

**Conditional profile** [result struct containing binned-statistics table and edges]  
Statistics of a measured quantity grouped by values of another, conditioning quantity.  
Inputs: { `Edges` = numeric vector; `Statistics` = table; `ExcludedCounts` = table; }

Generated conditional-statistics result.

**Bins** [numeric edge/center vectors; counts in vectors, matrices or tables]  
Intervals used to group numerical values.

### Workflow 1: recognize the roles in code

**experiment** [scalar struct]  
The workflow variable containing the dataset description and named sources.  
Inputs: { `DatasetID`\* = text; `Frames`\* = numeric vector; `Sources`\* = struct of named source structs; `TimeStep` = positive numeric scalar (default 1); `TimeUnit` = text (default 'frame'); }

**c.ObjectProperties** [cell array of character vectors or string array]  
The workflow setting listing the region properties requested for measurement.

**c.GeometryOptions** [scalar struct with a per-geometry options struct]  
The workflow settings controlling how each requested geometry is generated.  
Inputs: { <geometry name> = scalar options struct; }

**c.Queries** [query struct array; empty for no sampling]  
The workflow requests defining which fields to sample, at which supports, and which statistics to calculate.  
Inputs: { `Name`\* = text; `Support`\* = text; `Field` = text (required for a scalar query without Operation); `Operation` = function handle (alternative to Field); `Kind` = text; `Fields` = text list (required for vector queries); `Statistics` = text list; `Mode` = text; `Options` = scalar struct; }

Each array entry follows this layout; the workflow also permits an empty query array.

**objects** [scalar struct containing IDs, Components and Grid]  
The workflow variable containing prepared voxel memberships, IDs and grid metadata.  
Inputs: { `ObjectGeometryVersion`\* = numeric scalar; `ObjectIDs`\* = numeric vector; `Components`\* = component struct; `Grid`\* = scalar struct; `DatasetID`\* = text; `Frame`\* = numeric scalar; `SourceGrid` = struct or empty; `Transform` = mapping metadata or empty; `InputType` = text; }

This is the generated prepared form, not the object-preparation options struct.

**geometry** [scalar struct of named generated-geometry structs]  
The workflow collection of generated spatial features.  
Inputs: { <geometry name> = generated geometry struct; }

**supports** [scalar struct of named selections/geometry structs]  
The workflow collection naming the locations selected for sampling.  
Inputs: { <support name>\* = prepared geometry/support struct, mask, labels or indices; }

Names must match the supports referenced by queries; there is no fixed universal support-name list.

**fields** [scalar struct of named matrices or Data/Grid structs]  
The workflow collection containing the actual arrays to be sampled.  
Inputs: { <field name>\* = numeric/logical matrix or Data/Grid struct; }

Names must match the fields referenced by queries; there is no fixed universal field-name list.

**properties** [MATLAB table]  
The workflow table containing identity keys and requested measurements.

**diagnostics** [MATLAB table]  
The workflow table containing validity counts and flags:
[SelectedCount,FiniteCount,NaNCount,PositiveInfCount,NegativeInfCount,SelectionEmpty,GeometryEmpty,EmptyGeometryCount,UsedFallback,FallbackCount]

**payload** [scalar struct]  
The workflow variable collecting outputs selected for saving at one frame.  
Inputs: { `Measurements` = table; `Seconds` = numeric scalar; `Diagnostics` = table; `Geometry` = struct; `Supports` = struct; `LocalInertia` = struct; }

Workflow 1's selected saved fields; no universal payload fields are required.

**manifest** [scalar struct]  
The workflow variable collecting the run's combined results or output locations.  
Inputs: { `Directory` = text; `Measurements` = table; `Diagnostics` = table; }

Workflow 1 layout shown; exact fields depend on the workflow.

## Data Dictionary

Named fields below describe generated sampling results, not additional user inputs.
The names are suffixes: farmQueryField writes <FieldName>_<suffix>, and farmQueryFrame uses
<QueryName>_<suffix>. Vector component queries use <FieldName>_<ComponentName>_<suffix>.
Counts refer to one result row; field/query prefixes distinguish separate calculations.
These entries document behavior, not a universal set of columns required in every table.

### Sampling diagnostics

**SelectedCount** [double scalar per row; table column across rows]
The number of selected voxel locations actually sampled after support preparation, including any applied centroid fallback. Indices are deduplicated within the resulting support group.

Produced by farmQueryField; retained separately for each component by queryVectorField. Includes samples that become NaN or infinite. SelectedCount equals FiniteCount+NaNCount+PositiveInfCount+NegativeInfCount. A sample operation must return one value per selected location.

**FiniteCount** [double scalar per row; table column across rows]
The number of sampled values that are neither NaN nor positive or negative infinity. Built-in scalar statistics use these finite values only.

Produced by farmQueryField; independent per component in queryVectorField. FiniteCount can be zero while SelectedCount is nonzero. The requested Count statistic equals FiniteCount, not SelectedCount.

**NaNCount** [double scalar per row; table column across rows]
The number of sampled values that are NaN, excluded from finite-sample scalar statistics.

Produced by farmQueryField; independent per component in queryVectorField. Counts values after an optional sample operation, not invalid voxels elsewhere in the volume.

**PositiveInfCount** [double scalar per row; table column across rows]
The number of sampled positive-infinity values, excluded from finite-sample scalar statistics.

Produced by farmQueryField; independent per component in queryVectorField. Reported separately from NegativeInfCount and NaNCount.

**NegativeInfCount** [double scalar per row; table column across rows]
The number of sampled negative-infinity values, excluded from finite-sample scalar statistics.

Produced by farmQueryField; independent per component in queryVectorField. Reported separately from PositiveInfCount and NaNCount.

**SelectionEmpty** [logical scalar per row; table column across rows]
True when the final selected index list is empty, after support preparation and any centroid fallback.

Produced by queryField. An empty skeleton with an applied centroid fallback can have SelectionEmpty = false and GeometryEmpty = true. A nonempty selection containing only nonfinite values has SelectionEmpty = false but FiniteCount = 0.

**GeometryEmpty** [logical scalar per support record or result row]
True when the source generated geometry has no computed indices. When generated components are combined by parent ID, true means every source component had empty geometry before fallback.

Set by farmPrepareSupport for generated-geometry records and copied into farmQueryField results. Does not become false merely because fallback adds a centroid. For raw selections and prepared memberships this provenance flag defaults to false; an empty raw mask is instead indicated by SelectionEmpty. Some empty components do not make an otherwise nonempty combined geometry empty; inspect EmptyGeometryCount for that case.

**EmptyGeometryCount** [double scalar per support record or result row]
The number of source generated-geometry records whose computed index lists were empty before fallback.

Set by farmPrepareSupport and copied into farmQueryField results. With component results this is zero or one; with components combined by parent ID it is the sum over source records. Raw selections and prepared memberships default to zero.

**UsedFallback** [logical scalar per support record or result row]
True when support preparation substitutes a rounded, nearest-voxel centroid for an empty generated skeleton record, or any constituent record uses that substitution when combined by parent ID.

Set by farmPrepareSupport and copied into farmQueryField results. Currently controlled by CentroidFallback; it does not describe every fallback mechanism in the package, such as the single-voxel ProjectedExtent fallback. SelectionEmpty can be false even though GeometryEmpty remains true.

**FallbackCount** [double scalar per support record or result row]
The number of source skeleton records for which centroid fallback was applied during support preparation.

Set by farmPrepareSupport and copied into farmQueryField results. With component results this is zero or one; with components combined by parent ID it is summed. It counts substituted records, not unique fallback voxels: overlapping centroid locations may be deduplicated in the final selection.
