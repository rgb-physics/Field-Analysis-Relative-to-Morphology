# Examples and Workflows

Start with the [editable examples and setup guide](examples/README.md).

Experimental sheet analysis is available separately in
[analyzeSheetFrame35.m](analyzeSheetFrame35.m). Its independent branch-cut
sections query patch extent and source-volume support and display candidate
seams, proposed cuts, and corrected point clouds. See the
[branch-correction guide](../APIs/ObjectGeometry/SURFACE-BRANCH-CORRECTION.md)
for settings, return fields, calibration, and validation limits. This dataset-
specific script is not one of the released workflows listed below.

The release includes:

- Workflow 1: object segmentation, geometry and field measurements.
- Workflow 2: filament measurements and alignment, including its staged example.
- Active Foam E5: combined processing and individually inspectable stages.

From the repository root in MATLAB:

```matlab
farmSetup('IncludeExamples', true);
edit setupWorkflow1
```

`examples/` holds editable setups, workflow functions and their tests.
Reusable experiment configuration and source loading are in the
[Workflows API](../APIs/Workflows/README.md), available through `farmSetup`.
Local input fixtures and generated outputs live under `tests/data/`.
