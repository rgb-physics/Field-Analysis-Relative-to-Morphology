> Historical snapshot, retained October 15, 2026. Read the [current user guide](../README.md) and [history index](README.md) before following these older notes.

# API scope follow-up

Return to these items when refining the API boundaries and repository descriptions. The current first-pass organization is intentionally preserved until each decision is made.

## ImageStackIO

- [ ] Decide whether ND2 reading belongs in ImageStackIO. The package currently has TIFF and HDF5 readers, while ND2 handling is in workflows and depends on the ND2 SDK; the proposed `readND2.m` is not implemented.
- [ ] Decide whether reslicing belongs in ImageStackIO or remains workflow behavior. Current reslicing scripts are in workflows or legacy stack transforms rather than the core package.
- [ ] Revise the README's file-format claim after resolving ND2 support so it describes implemented API functionality accurately.

## ObjectGeometry

- [ ] Decide whether homeotropic thinning and sheet-midplane generation should move from sheet workflows/prototypes into ObjectGeometry, or whether the API description should narrow its claim.
- [ ] Locate and classify filament-orientation calculations currently in filament workflows; move reusable geometry operations into ObjectGeometry if appropriate, and keep experiment-specific orchestration in workflows.

## ObjectTracking

- [ ] Clarify that the current Trackpy-related functions translate data to and from Trackpy-compatible structures; they do not implement or invoke Trackpy. Decide whether to keep this interoperability in ObjectTracking, add a documented external dependency, or narrow the README wording.

## SurfaceFieldMapping

- [ ] Separate the dependency boundary between the MATLAB mesh API and workflows that invoke MeshLab/Python or compiled remeshing functions. Verify the actual external requirements, then update the README/API documentation to name only the dependencies required for the relevant layer.
