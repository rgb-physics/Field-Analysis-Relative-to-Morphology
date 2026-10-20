# Current FARM directory guide

Updated October 20, 2026 after package folder reorganization. This is a directory guide, not the deferred public-function or test inventory.

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
      tools/                 # reference-page builder
    SurfaceFieldMapping/     # mesh/sheet work deferred
    VisualizationTools/
  Examples and Workflows/
    src/memoworkflow/
    examples/
  docs/
    reference/               # current glossary/Data Dictionary topic pages
    history/                 # superseded reviews, handoffs and snapshots
  tests/
    memotest/                # shared MATLAB test helpers
    data/                    # local fixtures and generated results
  local-dependencies/        # local external installations
```

API source folders use ordinary names such as `APIs/ObjectGeometry/src/objectgeometry`.
`Examples and Workflows` replaces `Workflows`, and `tests/data` replaces
`test-data`. API-specific test suites stay beside their APIs. The reference-page
builder now lives under `APIs/SharedUtilities/tools`. MATLAB's generated
`MathWorks` preferences folder is ignored and is not part of the package.

Use the [user guide](README.md), [reference topics](reference/README.md), [testing guide](../TESTING.md) and [naming migration guide](FARM-NAMING-MIGRATION.md) for current instructions. Earlier source-tree listings are retained in [historical documentation](history/README.md).

The sibling MeMo-Archive contains preserved historical source. Local datasets, dependency installations, MATLAB support files and Git metadata are outside this cleanup.
