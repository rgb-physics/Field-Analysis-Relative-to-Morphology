# Understanding workflow 1

[User guide](README.md) · [Four-stage workflow document](WORKFLOW-1-STAGES.md) · [Editable setup](../Examples%20and%20Workflows/examples/setupWorkflow1.m)

Workflow 1 identifies objects, defines geometry and measures fields at those
locations. The setup now exposes the calculation in four separate stages, rather
than keeping it in a local function below the settings.

| Stage | Read or edit | Inspect afterward |
| --- | --- | --- |
| 1. Data loading | Named sources and current acquisition frame | `intensity`, `probabilities`, image metadata |
| 2. Object segmentation | Category channels, threshold, smoothing and properties | `mask`, `objects`, `properties` |
| 3. Geometry definition | Whole objects, boundary shell, optional skeleton | `geometry`, `supports`, distance fields |
| 4. Field sampling | Named queries, selected statistics and profile bins | `sampling`, `measurements`, `diagnostics`, `distanceProfile` |

The default uses a small synthetic dataset so you can inspect the result without
external files. Your Experiment 4 data settings remain under the real-data option.
`showFigures = true` displays the object/boundary overlay and distance profile;
`savePreview` and `runBatch` default false.

Start by opening `setupWorkflow1.m`, checking its repository path, then running
the sections in order. The [four-stage document](WORKFLOW-1-STAGES.md) explains
each input, returned value, interpretation and stopping point.

Useful values to inspect after stage 4:

```matlab
measurements.IntensityOnboundary_Mean
diagnostics.IntensityOnboundary_FiniteCount
distanceProfile.Statistics
```

Source descriptions are editable structs; loaded values are arrays; objects and
geometry describe locations; queries request calculations; measurements are
tables. See [Reading package structures](READING-STRUCTURES.md) and the
[glossary topic pages](reference/README.md).

For batch execution, `farmWorkflow1Objects(c)` uses the same analysis choices and
processes one frame at a time. It remains compatible with earlier configurations.
The implementation is now in that function, separate from the editable setup.
