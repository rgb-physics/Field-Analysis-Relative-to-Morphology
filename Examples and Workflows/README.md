# Examples and Workflows

Start with the [editable examples and setup guide](examples/README.md).

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
