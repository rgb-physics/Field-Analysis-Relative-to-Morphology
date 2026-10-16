# Release validation: datasets to provide

Working checklist from the release-scope discussion, October 15, 2026.
Return to this file when selecting validation data. This is not a request to
prepare everything immediately. Existing datasets can satisfy multiple rows.
The final mapping to public operations, expected results and tolerances remains
to be completed.

## Real data to provide or identify

| Needed input | Purpose | Selection status |
| --- | --- | --- |
| Small object-channel image series with corresponding probability maps or segmentations | Boundaries, centers, skeletons, distance profiles and temporal quantities | Not selected |
| Corresponding filament-channel images and object segmentations | Filament extraction, orientation and comparison with distance-gradient normals | Not selected |
| A few manually reviewed slices or annotated regions | Independent visual reference for acceptable boundaries and filament detections | Not selected |
| Short sequence containing movement, a merge and a split | Tracking and explicitly selected ancestry | Not selected |
| Representative TIFF/HDF5 files including channel/time metadata | Reader interpretation and round trips | Not selected |

## Metadata accompanying each selection

- Dataset identifier and file locations.
- File format and HDF5 dataset path where applicable.
- Axis order and channel meanings.
- Spatial spacing and units, with its axis order stated.
- Acquisition frame numbers, time step and time unit.
- Crop/origin and registration relationships between channels or sources;
  matching dimensions alone do not establish correspondence.
- Known limitations, annotations and which regions/frames were manually reviewed.

Select small representative subsets first. Preserve original datasets and write
generated outputs to fresh locations under package test-data.

## Inputs that do not require user-supplied data

Generate known shapes, analytic scalar/vector fields, controlled distance and
orientation cases, spectra, correlations, empty/invalid/fallback cases, and
controlled tracking cases synthetically. Numerical known-answer or public-contract
checks are required for every supported public operation. Historical-output
comparisons supplement those checks.

## Candidates to inspect before requesting new files

The handoff identifies Experiment 4 on drive O: and local test-data fixtures.
Neither availability nor suitability is established by this checklist. Reuse
them where appropriate after checking access, metadata and coverage.

See FIRST-RELEASE-SCOPE.md for agreed capabilities and validation scope.
