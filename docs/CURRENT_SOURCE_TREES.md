# Current FARM directory guide

Updated October 15, 2026 after document and empty-folder cleanup. This is a directory guide, not the deferred public-function or test inventory.

```text
MeMo/
  APIs/
    FieldAnalysis/
    ImageStackIO/
    ObjectGeometry/
    ObjectRelativeProfiles/
    ObjectTracking/
    SegmentationTools/
    SharedUtilities/
    SurfaceFieldMapping/     # mesh/sheet work deferred
    VisualizationTools/
  Workflows/
    src/memoworkflow/
    examples/
  docs/
    reference/               # current glossary/Data Dictionary topic pages
    history/                 # superseded reviews, handoffs and snapshots
  tests/memotest/
  tools/                     # documentation maintenance
  test-data/                 # local fixtures and generated results
  local-dependencies/        # local external installations
```

API source folders use ordinary names such as `APIs/ObjectGeometry/src/objectgeometry`; obsolete empty `+...` namespace folders and empty in-package archive folders have been removed. Existing MATLAB and Python implementations were not moved or edited by this cleanup.

Use the [user guide](README.md), [reference topics](reference/README.md), [testing guide](../TESTING.md) and [naming migration guide](FARM-NAMING-MIGRATION.md) for current instructions. Earlier source-tree listings are retained in [historical documentation](history/README.md).

The sibling MeMo-Archive contains preserved historical source. Local datasets, dependency installations, MATLAB support files and Git metadata are outside this cleanup.
