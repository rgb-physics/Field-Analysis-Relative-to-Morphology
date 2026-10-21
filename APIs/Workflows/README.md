# Workflows

Describe an experiment and load its named data sources. These functions are
available after `farmSetup`; examples do not have to be added to the path.

| Function | Purpose |
| --- | --- |
| `farmMakeExperiment` | Combine dataset identity, acquisition frames, timing, and named data sources. |
| `farmLoadSource` | Load one named source at one acquisition frame using ImageStackIO. |

Use `farmMakeSource` from ImageStackIO to describe each source:

```matlab
farmSetup;
source = farmMakeSource('Format', 'custom', 'Loader', @(frame) ones(8, 9, 4));
experiment = farmMakeExperiment('DatasetID', 'example', 'Frames', 25:30, ...
    'Sources', struct('Intensity', source), 'TimeStep', 30, 'TimeUnit', 's');
image = farmLoadSource(experiment, 'Intensity', 25);
```

The functions do not estimate calibration or register sources. Supply metadata
describing the data. Loaded arrays use YXZCT axes; spacing uses YXZ order.
`help farmMakeExperiment` and `help farmLoadSource` list accepted inputs.
`farmGlossary("Experiment")` and `farmGlossary("Source")` explain the constructs.

The [E5 setup](../../Examples%20and%20Workflows/examples/setupActiveFoamE5.m)
shows loading, segmentation, geometry, sampling, and alignment as explicit calls.
This API does not run those analyses automatically.
