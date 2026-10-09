# Field Analysis Relative to Morphology

**Measure image-derived fields on, within, and around segmented structures.**

This MATLAB project organizes tools and workflows for measuring image-derived fields in coordinate systems defined by segmented morphologies. It supports sampling relative to centers, skeletons, and boundaries, and includes geometry-specific analysis for elongated particles, spheroids, and sheets. Object-tracking tools preserve object lineage through merges and splits.

The workflows begin with microscopy stacks and pixel-classification probability fields; the latter are commonly produced by Ilastik*. The code provides image reading, saving, reslicing, correction for images and thresholding and refinement of probability fields to define object masks. Separate workflows exist for different geometric representations such as volumetric objects, sheets, filaments, skeletons, and point clouds. Fields like intensity, orientation, or velocity can then be mapped on geometric representations to measure time-, space-, and object-dependent statistics.

Internal image arrays use `[Y X Z C T]`. Workflows combine the following APIs for specific datasets and analyses:

**FieldAnalysis** - Fourier analysis, spatial averaging and cross-correlation
**ImageStackIO** - Stack reading and writing for .tifs, .nd2s, and .h5s
**ObjectGeometry** - Define geometric qualities of objects: line-like skeletonization, sheet-like midplanes via homeotropic thinning, filament orientations and other properties, and boundaries
**ObjectRelativeProfiles** - Sample fields relative to object geometry
**ObjectTracking** - Track objects via overlapping IDs, define lineages, identify merging and splitting, and isolate objects. Also hosts particle tracking via trackpy.
**SegmentationTools** - Generate objects from pixel segmentations*
**SharedUtilities** - Functions used across the package
**SurfaceFieldMapping** - Point cloud to mesh conversion, mesh operations, field-sampling on mesh faces; relies on external installation**
**VisualizationTools** - Visualize results at different stages of analysis

*Ilastik is an upstream source of pixel-classification probabilities; this codebase does not provide Ilastik's pixel classifier. https://www.ilastik.org/
**https://www.meshlab.net/

This repository is a first-pass organization of code from the private archive and the existing ImageStackIO package. Source code has not been refactored or validated in MATLAB as part of this organization. See `docs/PROPOSED_TREE.md` for the proposed architecture and `docs/MIGRATION_CHECKLIST.md` for the source mapping and copy record. 
