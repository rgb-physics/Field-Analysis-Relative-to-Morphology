# Glossary and capabilities — discussion mock-up

Terms are **bold**, definitions are plain text, and *capabilities are italicized*. This is a draft for review, not a terminology migration. Current public names are retained; proposed names and deferred capabilities are stated explicitly. The entries combine conceptual meaning with practical package navigation.

## Containers and structure roles

**Array / matrix**  
An arrangement of values. Matrix usually means two-dimensional; this package also uses spatial volumes and arrays with channel/time dimensions.

*Capabilities: ImageStackIO returns normalized image arrays in YXZCT order. Most analysis functions accept one YX or YXZ field at a time. Numerical type alone does not establish whether an array contains intensity, probabilities, labels or distances.*

**Struct**  
A collection of named fields. A struct is a container, not a guarantee that its contents are data, options or results.

*Capabilities: The package uses structs for source descriptions, experiments, settings, prepared geometry and outputs. image.Data holds values; query.Options holds settings. Builders return editable structs. No package-defined MATLAB class instance is needed to explain these interfaces.*

**Table**  
Named columns sharing the same rows. The calculation determines what a row represents.

*Capabilities: ObjectGeometry returns property tables; ObjectRelativeProfiles returns field statistics; ObjectTracking returns detection/link/event tables. Identity keys allow columns to be attached without assuming equal row order.*

**Cell array**  
A container whose entries can hold values with different shapes or types.

*Capabilities: Components.PixelIdxList holds one index vector per group. Property/statistic name lists commonly use cells of text. Histogram results may use cells containing counts and edges.*

**Data**  
The actual values being analyzed, rather than descriptions of where to find them or instructions for processing them.

*Capabilities: Examples include image.Data, intensity arrays, probabilities, distances and gradients. Source configurations contain loading information; they do not preload these arrays.*

**Metadata**  
Information about interpretation, identity, calibration or provenance.

*Capabilities: Image structs record axes/calibration; geometry carries IDs and Grid; tables retain provenance in Properties.UserData and units in Properties.VariableUnits where assigned. Metadata is not necessarily a visible table column.*

**Options**  
Settings controlling how one particular operation behaves.

*Capabilities: generateGeometry accepts method/layer/smoothing settings; queryField accepts quantiles, bins, variance normalization and custom reducers. Builders validate settings. Shared spellings such as Sigma do not guarantee the same meaning across functions.*

**Request / specification**  
Instructions stating what should be selected or calculated.

*Capabilities: ObjectProperties lists requested native measurements. Queries describe the input Field or Operation, selected Support, requested Statistics and output Name. Query Options supplies additional settings. These choices belong in setup rather than requiring changes to function-call logic.*

**Configuration**  
A reusable collection of descriptions, requests and options.

*Capabilities: experiment describes a dataset and its sources. Workflow c combines that description with analysis requests/settings and output choices. c is a mixed-purpose container, not an image or a measurement result.*

**Result**  
A value produced by a calculation, such as geometry, a field, measurements or a selection.

*Capabilities: Results can be inputs to later operations. Their role depends on their producing function: a struct returned by loadSource differs from one returned by generateGeometry.*

**Payload**  
The explicitly selected results to save for a frame or operation.

*Capabilities: Workflow 1 assigns Measurements and Seconds, with optional Diagnostics, Geometry or Supports. Omitting geometry from saving does not prevent using it temporarily. saveNew writes a MAT variable named result.*

**Manifest**  
A workflow-specific collection of output locations, combined tables or run summaries.

*Capabilities: Workflow 1 returns combined measurements/diagnostics; workflows 4–5 primarily return file lists. A manifest is not one universal schema or necessarily just a list of filenames.*

## Dataset organization

**Dataset / experiment**  
A dataset is a related body of inputs. An experiment description records dataset identity, acquisition frames/timing and named sources.

*Capabilities: memoworkflow.config.makeExperiment accepts DatasetID, Frames and Sources, plus optional TimeStep/TimeUnit. DatasetID keeps independent datasets distinct in table joins. The experiment struct does not load all images.*

**Data source**  
A description of how to load a field, with its axes and calibration.

*Capabilities: imagestackio.config.makeSource describes TIFF, HDF5 and custom-loader inputs. Folder and NamePattern identify files. DatasetPath identifies the array inside HDF5, not a disk directory. loadSource loads a requested frame. Pattern remains a legacy input alias.*

**Channel**  
A separately stored image field or signal. Its interpretation depends on the dataset.

*Capabilities: ImageStackIO represents channels on dimension C. Segmentation may combine multiple probability channels into one segmented category. A vector component need not be stored as an image channel.*

**Frame / time index / time step**  
Frame identifies acquisition time points in results. TimeIndex selects a stored position along an image's T dimension. TimeStep specifies the original acquisition-frame interval in TimeUnit.

*Capabilities: Acquisition Frame and stored TimeIndex are separate. Frames [10 12] with TimeStep=30 and TimeUnit='s' are separated by 60 seconds. Timing is supplied, not inferred from selected-frame spacing. Irregular timestamps are not represented by TimeStep alone.*

**Axes / coordinate order**  
Axes describe array dimensions; coordinate order describes the sequence of values in coordinate vectors.

*Capabilities: Image arrays use YXZCT; spatial grids use YX/YXZ. Native centroids and directors commonly use XY/XYZ. SourceAxes describes reader input before normalization. Coordinate converters explicitly distinguish XYZ from YXZ.*

**Grid / voxel spacing / units**  
A grid describes the dimensions and calibration of the current representation. Spacing records sample separation in matrix-axis order; units describe calibrated quantities.

*Capabilities: Geometry Grid describes current indices. SourceGrid/Transform can retain earlier representations. Resampling must update calibration. Equal dimensions or similar physical extents alone do not establish registration. Native region properties are not automatically rescaled merely because spacing is recorded.*

## Segmentation and identity

**Intensity field**  
An array representing measured signal values.

*Capabilities: segmentIntensity generates a basic mask using fixed or Otsu thresholding with optional cleanup. Fixed thresholds use original units. Sampling can summarize intensities without changing source values.*

**Probability field**  
An array interpreted as a category probability or score, often exported by Ilastik.

*Capabilities: SegmentationTools thresholds/composes probability channels and resolves category overlaps. Thresholded intensity and Gaussian-rendered geometry are not automatically calibrated probabilities.*

**Segmented category**  
A meaning assigned to voxels, such as inside, wall, outside or background. One category can contain many separate regions.

*Capabilities: segmentationtools.config.makeClasses defines names, channel groups, thresholds and category IDs. Existing API names still use Classes/Classify. Category IDs must not be confused with IDs of individual connected regions.*

**Foreground mask**  
A logical array selecting foreground voxels; it can contain zero, one or many connected components.

*Capabilities: SegmentationTools returns masks; ObjectGeometry can derive components from them. A mask does not itself establish identity across time.*

**Connected component**  
A foreground voxel group connected under a specified adjacency rule.

*Capabilities: prepareObjects uses bwconncomp for mask input, normally with 8-connectivity in 2-D or 26-connectivity in 3-D. Connectivity describes voxel adjacency, not biological identity.*

**Label matrix / ID group**  
A label matrix assigns integer IDs to voxels, with zero as background. An ID group contains all voxels sharing an ID, even when disconnected.

*Capabilities: prepareObjects preserves supplied IDs and measurement functions treat each group as one row. InputType='labels' resolves binary-valued labels. Current public fields retain the name ObjectID. The vague term measurement entity is omitted.*

**Prepared geometry collection**  
A structure holding voxel-index groups, their identities and current-grid metadata.

*Capabilities: prepareObjects returns ObjectIDs, Components.PixelIdxList and Grid. Inputs can be masks, labels, component structures or index groups. This result holds spatial membership rather than scalar measurements.*

## Geometry, supports and references

**Linear voxel indices / coordinates**  
Linear voxel indices locate entries within a particular array. Coordinates explicitly give positions along axes. Table-row indices select rows and are a separate use of indexing.

*Capabilities: Geometry primarily retains linear indices with Grid.Size. ind2sub/sub2ind convert representations. pointsToMatrix expects one-based current voxel coordinates, not physical positions. Once context is clear, indices can abbreviate linear voxel indices.*

**Geometry**  
A spatial representation of a structure's extent or features.

*Capabilities: ObjectGeometry prepares voxel groups, generates boundaries/skeletons and measures properties. Geometry may be stored as indices or coordinates with metadata; it need not be a dense matrix or measurement table.*

**Support**  
The locations selected for evaluating a field or calculation. Support describes a selection's role; it need not be a different representation from its source geometry.

*Capabilities: queryFrame accepts named supports from prepared regions, generated geometry, masks or indices. In workflow 1, supports.boundary and geometry.boundary initially contain the same geometry. The proposed wording 'selected as reference' remains a discussion point: evaluation locations differ from comparison quantities in some workflows.*

**Reference**  
The geometry or quantity against which another quantity is defined or compared.

*Capabilities: A boundary defines a distance reference; a sampled gradient defines an alignment reference. In workflow 2, centroids provide evaluation locations, while sampled gradients provide comparison directions. These are distinct roles.*

**Boundary**  
The interface separating a region from its surroundings.

*Capabilities: Distance transforms can reference foreground/background or selected category boundaries. Current generateGeometry(...,'boundary') selects a finite-width layer in a signed-distance field; the output is not an infinitely thin mathematical boundary.*

**Isosurface / distance-defined neighborhood**  
Strictly, an isosurface selects a scalar field level. Historical usage in this project also encompasses binned neighborhoods around levels.

*Capabilities: We can use distance-defined neighborhood as an inclusive description while recording whether a request selects a level or a finite interval. Geometry layer generation selects distance intervals; conditional profiles bin distance values. These voxel selections are not necessarily mesh surfaces.*

**Layer**  
A region of finite thickness. It can be defined around a surface or between field levels and need not wrap around another region.

*Capabilities: returnSmoothBoundsBW selects between LayerMean minus/plus LayerWidth in a smoothed signed-distance field. LayerMean offsets the layer; LayerWidth is its half-width. The boundary is the construction reference, while the layer is the output.*

**Shell**  
A layer surrounding a region; a useful descriptive special case rather than the general term for all layers.

*Capabilities: Current boundary geometry uses Method='shell' by default, but layers can be offset or partial. Periphery is dropped from the proposed precise terminology.*

**Skeleton**  
A derived internal geometric feature, with its form determined by the selected method.

*Capabilities: generateGeometry produces component-specific skeleton records. Empty geometry retains status and fallback metadata. Sampling may use an identified centroid fallback without claiming that a skeleton exists. Blob skeletons are not filament detections.*

**Filament / backbone**  
A filament is an elongated, relatively thin structure in image data. A backbone is an idealized line through a center using a length and direction.

*Capabilities: measureFilaments measures filament regions without automatically skeletonizing them. Historical filBackBones2D/ND construct backbones. segmentsToMatrix renders supplied endpoint pairs; rasterization does not establish actual filament membership or measure its length.*

**Sheet / centered surface**  
A sheet is a thin image structure. A centered surface is a derived surface-like representation through its thickness.

*Capabilities: Current 'sheet'/'sheet-sampled' methods reuse sheet-specific historical implementations. Centered surface is proposed terminology and an eventual generalization; arbitrary orientations/topologies are not yet claimed. Existing methods are still grouped under skeleton generation.*

**Point cloud**  
A set of spatial locations without implied faces or connectivity.

*Capabilities: Generated sheet geometry can retain sampled points. pointsToMatrix renders coordinate rows; duplicate points occupy one voxel rather than adding density.*

**Rendered geometry matrix**  
A dense representation made from geometry locations.

*Capabilities: geometryToMatrix converts prepared/generated indices to a mask or ID labels. pointsToMatrix/segmentsToMatrix use explicit coordinate, rounding and bounds choices; optional Gaussian Sigma broadens occupancy before optional Threshold. Sigma is in voxels. The source geometry remains unchanged; grid and conversion metadata are returned.*

**Mesh**  
A surface representation with vertices and connectivity, such as faces.

*Capabilities: SurfaceFieldMapping contains historical construction, mapping and conversion tools. Its restructuring is deferred. Rasterizing mesh surfaces or interiors is separate from rendering voxel indices or isolated points.*

## Sampling and measurements

**Property / statistic**  
A property describes a measured region or geometry. A statistic summarizes selected values. The calculation and units make their precise meaning explicit.

*Capabilities: measureObjects supports native regionprops/regionprops3 properties. queryField supports Count, Sum, Mean, Median, Variance, Std, Min, Max, Quantiles and Histogram, plus custom reducers. These capability lists accompany the definition; results retain settings actually used rather than all possible settings.*

**Query**  
An instruction specifying a field or operation, selected support, requested statistics and output name.

*Capabilities: makeQuery constructs requests for queryFrame. Name sets output prefixes; Field identifies data; Support identifies evaluation locations. Operation combines same-frame fields or samples. Options carries function-specific settings. User requests can change without editing helper calls.*

**Scalar field / vector field / vector component**  
A scalar field provides one value per location. A vector field provides ordered components per location. Vector component differs from connected component.

*Capabilities: queryVectorField samples named components with explicit order. Component statistics use independently finite readings. Magnitudes require complete finite vectors at each voxel; covariance uses pairwise-finite samples and separate counts. One invalid voxel does not discard the rest of a support.*

**Selected samples / finite samples**  
Selected samples are readings at selected locations. Finite samples exclude NaN and positive/negative infinity.

*Capabilities: Sampling retains selected/finite counts and separate NaN/+Inf/-Inf counts. Statistics use finite readings according to documented scalar/vector rules. Zero is a valid reading, not a general missing-data marker.*

**Diagnostic / empty selection / fallback**  
Diagnostics describe validity and interpretation. Empty selections have no sampling locations. A fallback substitutes a known, explicitly flagged location when requested geometry is unavailable.

*Capabilities: Sampling records empty-geometry/fallback flags and counts. Empty sums may be zero while means remain NaN, so flags matter. Workflow 1 separates diagnostics from its visible measurement table. Geometry rendering excludes fallback by default.*

**Length / width / principal axes / projected extent**  
Different definitions of spatial size or direction. Their calculation and units must remain attached to the name.

*Capabilities: Native principal-axis lengths describe equivalent-region geometry. Scaled filament directions use coordinate-scaled covariance without resampling the image. ProjectedExtent measures the range of projections of voxel centers. Historical interior width sampled from boundary distance on skeleton indices must not be conflated with axis length or ExtentWidthFloor.*

**Axial alignment**  
Comparison of directions with 0–pi symmetry: reversing either direction leaves the alignment score unchanged.

*Capabilities: The current function nematicAlignment returns per-pair scores 2*cos(theta)^2-1 in 2-D and (3*cos(theta)^2-1)/2 in 3-D, plus angles and validity. Projection and pre-projection normal filtering are optional. axialAlignment is a proposed function name, not yet implemented. Negative scores are valid; unsigned alignment could misdescribe them.*

## Tracking and field analysis

**Detection / trajectory**  
A detection is an identified region at a frame. A trajectory records a selected continuation across detections.

*Capabilities: ObjectTracking records frame-local ObjectID plus DetectionID/TrajectoryID. Trajectory inheritance does not encode every parent-child relation. Trackpy provides position-based linking with optional gaps; overlap tracking emphasizes lineage and assumes modest displacement.*

**Lineage / ancestry / descendants**  
Lineage describes relations across detections. Ancestry follows parents; descendants follow children.

*Capabilities: trackOverlaps records splits/merges separately from trajectory inheritance. selectLineage follows directed parent/child links without collecting unrelated siblings by switching direction at an ancestor. Seeds can be IDs or supplied coordinates/frame.*

**Split / merge / gap**  
A split connects one parent to multiple children; a merge connects multiple parents to one child. A gap interrupts observed detections.

*Capabilities: Overlap tracking offers overlap-first/volume-first ranking and inheritance choices, comparing successive supplied frames without gap bridging. Trackpy memory supports gaps but does not currently provide the same branching model.*

**Spectrum / power / normalization / window**  
A spectrum describes frequency content. Power here means squared FFT magnitude. Normalization scales results; a window weights input samples before transformation.

*Capabilities: powerSpectrum2D/3D reuse the samAdapted convention with optional mean subtraction and windowing. Power is unnormalized; normalization factors are recorded. Selected-slice spectra differ from spectra of mean/max projections. Radial averaging supports hard bins or historical Gaussian weighting.*

**Correlation**  
Comparison of field values at relative displacements.

*Capabilities: autoCorrelation/crossCorrelation use the native unnormalized linear approach. Their mean-subtraction/window defaults are documented separately from spectral defaults. Workflow 4 retains radial correlation results rather than full temporary lag volumes.*

**Conditional profile / bins**  
A conditional profile summarizes readings grouped by another quantity. Bins specify intervals of that conditioning quantity.

*Capabilities: conditionalStatistics accepts matching arrays or sample vectors, explicit edges or a bin count, statistics and optional group IDs. Support selection occurs upstream. Distance binning alone does not imply grouping by region ID.*

## Workflow 1: recognize the roles in code

**experiment; c.ObjectProperties; c.GeometryOptions; c.Queries**  
experiment describes sources and acquisition. The c fields state requested measurements and operation settings.

*Capabilities: Source descriptions become actual images through loadSource. Requests/options are passed to measureObjects, generateGeometry and queryFrame. They do not themselves contain the loaded intensity array.*

**objects; geometry; supports; fields**  
objects contains prepared memberships; geometry collects generated features; supports names selections for sampling; fields contains actual arrays to sample.

*Capabilities: Geometry can be reused directly as a support. These names describe roles, not four mutually exclusive spatial data types.*

**properties; diagnostics; payload; manifest**  
properties holds measurement rows; diagnostics holds interpretation counts/flags; payload selects frame outputs; manifest collects run outputs.

*Capabilities: Tables retain identity keys for subsequent attachment. Geometry can be used without being saved. Regenerating omitted geometry later requires original inputs and retained settings.*
