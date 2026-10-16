# Field Analysis Relative to Morphology

**Measure image-derived fields on, within, and around segmented structures.**

From this folder, run `farmSetup` to add the API functions to MATLAB's path.
Use `farmSetup('IncludeExamples', true)` for the editable workflows, or
`report = runAllTests;` for all available automated checks.

Functions use descriptive names such as `farmReadTiff`, `farmMakeSource` and
`farmMeasureObjects`. Ordinary folders group the code; calls no longer use
MATLAB package namespaces. See the [FARM migration guide](docs/FARM-NAMING-MIGRATION.md)
for the function-name map and archive locations.
See [Testing](TESTING.md) for coverage, fixture requirements and saved reports.

Browse the [glossary and Data Dictionary by scientific topic](docs/reference/README.md)
or use the [alphabetical entry index](docs/reference/terms.md). Definitions,
representations and input layouts have expandable details. The pages cover the
current documented entries; the full public-function/test inventory is deferred.

New to the package? Follow [Understanding workflow 1](docs/WORKFLOW-1-WALKTHROUGH.md)
to distinguish source descriptions, loaded matrices, geometry, queries and results.

This MATLAB project organizes tools and workflows for measuring image-derived fields in coordinate systems defined by segmented morphologies. It supports sampling relative to centers, skeletons, and boundaries, and includes geometry-specific analysis for elongated particles, spheroids, and sheets. Object-tracking tools preserve object lineage through merges and splits.

The workflows begin with microscopy stacks and pixel-classification probability fields; the latter are commonly produced by Ilastik*. The code provides image reading, saving, reslicing, correction for images and thresholding and refinement of probability fields to define object masks. Separate workflows exist for different geometric representations such as volumetric objects, sheets, filaments, skeletons, and point clouds. Fields like intensity, orientation, or velocity can then be mapped on geometric representations to measure time-, space-, and object-dependent statistics.

Internal image arrays use `[Y X Z C T]`. Workflows combine the following APIs for specific datasets and analyses:

**FieldAnalysis** - Fourier analysis, spatial averaging and cross-correlation<br>
**ImageStackIO** - TIFF and HDF5 stack reading and writing; ND2 support is deferred.<br>
**ObjectGeometry** - Define geometric qualities of objects: line-like skeletonization, sheet-like midplanes via homeotropic thinning, filament orientations and other properties, and boundaries<br>
**ObjectRelativeProfiles** - Sample fields relative to object geometry<br>
**ObjectTracking** - Track objects via overlapping IDs, define lineages, identify merging and splitting, and isolate objects. Also hosts particle tracking via trackpy.<br>
**SegmentationTools** - Generate masks and labels from probability fields, or detect bright-on-dark filaments directly using the historical LoG route. Ilastik is a common upstream source rather than a package-wide requirement.<br>
**SharedUtilities** - Functions used across the package<br>
**SurfaceFieldMapping** - Retained mesh operations; mesh and sheet APIs are deferred pending rigorous study.<br>
**VisualizationTools** - Visualize results at different stages of analysis<br>

*Ilastik is an upstream source of pixel-classification probabilities; this codebase does not provide Ilastik's pixel classifier. https://www.ilastik.org/<br> 
MeshLab and other mesh-specific dependencies are documented in
[the dependency review](docs/EXTERNAL-DEPENDENCIES-REVIEW.md). They are not
requirements for the supported object-boundary and field-query examples.

For blob skeleton generation, install a local GaussDiff copy using the readable
[dependency setup instructions](docs/LOCAL-DEPENDENCY-SETUP.md). `farmSetup`
adds that local installation to the current MATLAB session without saving paths.

Segmentation behavior and preserved historical methods are recorded in `docs/SEGMENTATION_HISTORICAL_METHODS.md`. The current compatibility target is MATLAB R2023a. No native function used by the new SegmentationTools entry points is known here to be deprecated in R2023a; future compatibility issues will be recorded with the affected MATLAB function and FARM script path in that document.

Historical workflows, legacy I/O and redundant compatibility interfaces are
preserved outside this release in the sibling `MeMo-Archive` directory.
Reusable original algorithms remain in the APIs. The [current source tree](docs/CURRENT_SOURCE_TREES.md)
shows the retained release files. Mesh functionality retains its historical
algorithms and external dependencies; this naming migration does not redesign it.
