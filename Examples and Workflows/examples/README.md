# Editable examples and released workflows

Source datasets are read-only. Workflows that save results create fresh directories
under `tests/data/workflow-results`; existing results are not overwritten.

## Choose an example

| Entry | Purpose |
| --- | --- |
| [exampleObjectInspection.m](exampleObjectInspection.m) | Small synthetic task example: inspect objects, boundary geometry, field queries and profiles |
| [setupWorkflow1.m](setupWorkflow1.m) | Workflow 1: loading, segmentation, geometry and field sampling |
| [setupWorkflow2.m](setupWorkflow2.m) | Workflow 2: filament measurements and alignment to a distance-derived reference |
| [setupWorkflow2Staged.m](setupWorkflow2Staged.m) | Workflow 2 expressed as inspectable sections for a single frame |
| [setupActiveFoamE5.m](setupActiveFoamE5.m) | Active Foam E5 combined processing and alignment plots |
| [Active Foam E5 stages](activeFoamE5Stages/README.md) | The E5 processing divided into eight inspectable stage functions |

Workflows 3–5 and the preparation workflow are not included in this release.

## Getting started

```matlab
farmSetup('IncludeExamples', true);
edit setupWorkflow1
```

Workflow 1 defaults to synthetic data and exposes four processing stages. It opens
figures without saving by default; optional batching uses `farmWorkflow1Objects`.
Read the [walkthrough](../../docs/WORKFLOW-1-WALKTHROUGH.md) and
[stage guide](../../docs/WORKFLOW-1-STAGES.md).

The smaller object-inspection example also needs no image files. It retains
objects, geometry, measurements and profile tables in the workspace. It requires
Image Processing Toolbox and opens figures without writing files.

## Workflow 2

Review SETUP, DATA, ANALYSIS and PREVIEW before RUN. Edit repository/data paths,
spacing, category channels and thresholds for your experiment. The supplied
Experiment 4 paths and settings are examples, not universal defaults.
`farmWorkflow2Filaments(c)` forwards a configuration to the combined script's local
implementation without executing manual setup or previews.

Named sources are `Intensity560` (density), `Intensity647` (filaments) and
`Probabilities`. Source names do not constrain filenames. Check calibration and
spatial registration; matching dimensions or physical extents alone is insufficient.

The example uses axial alignment: reversing a director does not change alignment.
Filament selection, physical extent, reference validity and direction validity
remain explicit. Inspect segmentation and reference fields on your data.

For the existing flat Experiment 4 settings, see
[Experiment configuration](EXPERIMENT-CONFIGURATION.md).

## Active Foam E5

See the [definition and plotting guide](../../docs/ACTIVE-FOAM-E5-ALIGNMENT.md).
The combined setup passes measured workflow 2 output into plotting. Existing
measurements can be loaded for replotting without rereading source images.
The [stage guide](activeFoamE5Stages/README.md) explains the corresponding eight
stage functions and the `c.Results` values they pass between stages.

## Outputs and checks

Choose retained results explicitly. Geometry and full-volume fields can be much
larger than measurement tables. Calculation and saving are separate choices.

```matlab
results = runWorkflowExampleTests;
```

These checks use synthetic inputs. They do not establish real-data segmentation
or alignment accuracy. See [Testing](../../TESTING.md) for the complete runner and
coverage limits.
