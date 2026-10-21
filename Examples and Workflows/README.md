# Examples and Workflows

Start with the [editable examples and setup guide](examples/README.md).
The numbered `setupWorkflow1.m` through `setupWorkflow5.m` scripts configure
object measurements, filament alignment, lineage, spectra, and distance profiles.

From the repository root in MATLAB:

```matlab
farmSetup('IncludeExamples', true);
edit setupWorkflow1
```

`examples/` holds editable setups, workflow functions and their tests.
Reusable experiment configuration and source loading are in the
[Workflows API](../APIs/Workflows/README.md), available through `farmSetup`.
Local input fixtures and generated outputs live under `tests/data/`.
