# FARM user guide

Start with a task and a guided script. You do not need to understand every API before loading your first dataset.

## Choose a starting point

| You want to… | Open |
|---|---|
| Understand what the variables contain | [Reading package structures](READING-STRUCTURES.md) |
| Follow one analysis from files to results | [Understanding workflow 1](WORKFLOW-1-WALKTHROUGH.md) |
| Change properties, statistics, supports or saved outputs | [Changing an analysis](CHANGING-AN-ANALYSIS.md) |
| Look up a term or a struct's field layout | [Glossary and Data Dictionary topics](reference/README.md) |
| Search terminology directly from MATLAB | [MATLAB glossary lookup and getters](MATLAB-GLOSSARY.md) |
| Write or adapt readable MATLAB code | [Code conventions (review draft)](../AI%20Workflow%20Handoff/FARM-CODE-CONVENTIONS-DRAFT.md) |

For a first visit, read Reading package structures, follow workflow 1, then use Changing an analysis as a reference while editing setup.

See [Testing](../TESTING.md) for available checks and their coverage limits.

## Choose an analysis

| Task | Guided script | Main inputs | Main result |
|---|---|---|---|
| Measure regions and fields within/on them | [setupWorkflow1](../Examples%20and%20Workflows/examples/setupWorkflow1.m) | Intensity plus probability fields, or supplied masks/labels | Per-frame and combined measurement tables |
| Compare filament directions with a spatial reference | [setupWorkflow2](../Examples%20and%20Workflows/examples/setupWorkflow2.m) | Filament intensity/masks plus in/on/out probabilities | Filament directions, sampled references and alignment |

Workflow 1 assigns frame-local IDs. The released workflows are 1, 2 and Active Foam E5.
Workflows 3–5 and the preparation workflow are not included.
See [Active Foam E5](ACTIVE-FOAM-E5-ALIGNMENT.md) and its
[stage guide](../Examples%20and%20Workflows/examples/activeFoamE5Stages/README.md).

## Before the first run

Workflow 1 now has [four visible stages](WORKFLOW-1-STAGES.md) and a synthetic
default. Run SETUP and DATA SOURCES, then stages 1–4 and DISPLAY. Saving and batch
execution are optional. The instructions below describe workflow 2; E5 has its own linked setup guide.

1. Open the chosen saved setup script in MATLAB.
2. In SETUP, enter the MeMo repository root and execute that section.
3. In DATA, enter source folders, filename patterns, source axes, calibration and frames.
4. In ANALYSIS, review segmented-category channels, thresholds, requests and options.
5. Run PREVIEW and check the data. Verify spatial registration as well as image dimensions.
6. Execute RUN when those choices look appropriate.

Use the sections in order in a fresh MATLAB workspace. Workflow 2 keeps its
local implementation at the bottom of each script. Workflow 1 exposes the
individual operations in its setup and keeps its batch runner in
farmWorkflow1Objects.m. The SETUP section adds the package code folders.

The supplied paths, channel numbers and thresholds are example choices for Experiment 4. They are not universal defaults. A filename pattern receives a frame number; DatasetPath selects the array inside an HDF5 file.

Quantitative intensity should already have the correction appropriate to your experiment. Workflow 1 does not silently normalize each frame.

## Where do outputs go?

The examples create a fresh directory under package tests/data/workflow-results. Source data is read-only. The returned result indicates the output location or file list, depending on the workflow.

Inspect the helper's OUTPUT CHOICES blocks to select retained fields. Calculation and saving are separate: geometry can be used to obtain statistics without saving its indices.

Each MAT payload is stored under the variable name result. For example:

```matlab
saved = load('<output folder>/frame010.mat');
frameResult = saved.result;
```

## Where the APIs fit

| API | Responsibility |
|---|---|
| ImageStackIO | Read/write images and describe their axes/calibration |
| Workflows | Describe experiments and load named sources at acquisition frames |
| SegmentationTools | Turn intensity/probability inputs into selected categories or foreground |
| ObjectGeometry | Prepare identified memberships, measure properties, generate/render geometry |
| ObjectRelativeProfiles | Sample fields at selected locations and calculate statistics |
| ObjectTracking | Link detections and traverse selected temporal relationships |
| FieldAnalysis | Spectra, correlation, conditional statistics and correction helpers |
| SharedUtilities | Common numerical, array and keyed-table helpers |
| VisualizationTools | Display/export tools; broader restructuring remains unfinished |
| SurfaceFieldMapping | Historical mesh workflows; its review remains deferred |

You normally start with a setup script rather than configure all APIs independently.

## Checks and further reference

Run report=runAllTests from the repository root to execute available automated checks. [Testing](../TESTING.md) explains fixture requirements, output reports and exclusions. Passing automated tests does not replace visual validation on your data.

For detailed construction interfaces, see [Configuration builders](../CONFIGURATION-BUILDERS.md). For geometry rendering, see [Representation helpers](../APIs/ObjectGeometry/REPRESENTATION.md).

Public names such as ObjectID, farmMakeClasses and farmNematicAlignment are still present even where the glossary proposes clearer terminology. The documentation is not a claim that every proposed rename/generalization has been implemented.
