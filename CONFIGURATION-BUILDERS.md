# Configuration builders

Builders return editable structs without loading images or running analysis. Accept a scalar options struct or name/value pairs; unknown names are rejected. API consumers still validate data-dependent requirements.

| Builder | Configuration / consumer |
|---|---|
| farmMakeSource | Format ('tiff', 'hdf5', 'custom'), Folder, NamePattern, DatasetPath, SourceAxes, Spacing, SpacingUnit, Channels, TimeIndex, Loader. Used by farmLoadSource. |
| farmMakeExperiment | DatasetID, named Sources, Frames, optional TimeStep and TimeUnit. Duplicates removed in supplied order. |
| farmMakeObjectOptions | farmPrepareObjects options; pass directly to prepareObjects/measureObjects or under Identity to measureFilaments/generateGeometry/trackOverlaps. |
| farmMakeQuery | Name, Support, Statistics, Field OR Operation; vector Kind uses Fields. Optional Options/Mode. Used by farmQueryFrame; outputs concatenate into one query array. |
| farmMakeClasses | Positional channels and thresholds; optional Names, CombineMethods, IDs. Used by classifyProbabilities. |
| farmMakeIntensityOptions | farmSegmentIntensity options, including Method/Threshold and cleanup/retention choices. Fixed thresholds use original units. |
| farmMakeProbabilityOptions | farmClassifyProbabilities options for resolving overlap and retaining outputs. Not farmSmoothNChannelProbabilities morphology/precedence options. |

Function help lists every option/default. Run `farmSetup` from the repository root to add API dependencies, including the Workflows API. Use `farmSetup('IncludeExamples', true)` for farmExperiment4Config and the guided workflows.

## Source defaults and loading

Format defaults to tiff. File sources require Folder and NamePattern; HDF5 additionally requires DatasetPath. NamePattern is passed to sprintf with one frame argument: give each channel filename pattern its own source. Custom sources require Loader=@(frame).

Pattern is a legacy input alias; source output contains only NamePattern. Both names may be supplied only when their values agree.

TimeStep defaults to 1 and TimeUnit defaults to 'frame', independently. Either may be supplied alone. TimeStep describes the original acquisition-frame interval, not the interval between selected frames; no unit conversion is inferred. TimeStepSeconds remains a legacy alias mapping to TimeStep and TimeUnit='s'; conflicting explicit old/new values are rejected. Experiment output contains only TimeStep/TimeUnit. Frames [10 12] with no timing overrides are separated by 2 frame units; with TimeStep=.5 and TimeUnit='min', they are separated by one minute.

Spacing defaults to [1 1 1] in YXZ, SpacingUnit to pixel. Enter measured calibration for physical analysis. SourceAxes defaults empty (reader metadata/default); metadata-free grayscale TIFFs fall back to YXZ, while ambiguous HDF5 needs explicit axes. Channels=[] retains all channels; TimeIndex=1 selects one stored time. These stored indices differ from acquisition Frame.

A custom loader returns a YXZ array or an image struct with Data and Axes='YXZCT'. Returned grid calibration takes precedence over source fallback. farmLoadSource loads a single acquisition frame and returns an image with DatasetID, Frame, SourceName and selection metadata. Nothing is loaded by builders.

## Workflow 1

[setupWorkflow1.m](Examples%20and%20Workflows/examples/setupWorkflow1.m) exposes loading, segmentation,
geometry and sampling as separate editor sections. Check the explicit repo path
in SETUP and execute sections in order. The default synthetic example needs no
image files; original source folders/patterns remain in DATA SOURCES for real data.
It builds an editable experiment and supplies analysis settings next to the calls
that use them. Optional batch execution calls farmWorkflow1Objects(c). See the
[four-stage workflow document](docs/WORKFLOW-1-STAGES.md).

Workflow 1 accepts optional c.Experiment, with named Intensity and Probabilities sources. Intensity must select one channel. Supplied c.ObjectLoader bypasses probabilities. c.Frames must be present in the experiment. Current intensity calibration determines object metadata/physical volume; probabilities retain their own spacing and must use matching units. Shared crop/origin must be verified: similar extents are insufficient.

Existing callers without c.Experiment retain their original loading path. All
five numbered setup scripts use explicit experiment/source descriptions.
Workflow 1 exposes four processing stages; its batch implementation is in
farmWorkflow1Objects.m. Workflows 2–5 keep their implementation as local helpers.
setupWorkflow2–5 use named Intensity560 (primary/density), Intensity647
(filament/secondary) and Probabilities sources as needed. The old workflow
function files for workflows 2–5 remain compatibility entry points and skip setup/previews when
called with c. Analysis settings remain partly in c; general run, support and
geometry builders are deferred. Experiment creation and source loading are in APIs/Workflows/src;
example helpers remain in Examples and Workflows/examples.

## Queries

Scalar Statistics defaults to Mean; vector defaults to MeanVector/MeanMagnitude. Query Name sets output column prefixes. Support selects a named geometry; Field selects a named data array. These names are distinct.

```matlab
q = farmMakeQuery( ...
    'Name','DensityOnBoundary','Support','boundary', ...
    'Field','Density','Statistics',{'Mean','Std'});
q2 = farmMakeQuery( ...
    'Name','Difference','Support','objects','Fields',{'A','B'}, ...
    'Operation',@(fields) fields.A-fields.B);
queries = [q q2];
```

Options passes consumer-specific settings such as bins, quantiles and custom reducers. Builders do not establish spatial registration or cross-object association.

## Compatibility and validation

farmMakeClasses constructs segmented-category definitions from channels and
thresholds. It is the ordinary-folder public entry point; it does not wrap a
remaining package-namespace function. The category construction algorithm is
preserved. Object preparation/intensity/classification consumers obtain default
definitions from their corresponding builders to avoid default drift.

Run from Examples and Workflows/examples:

```matlab
runConfigBuilderTests
runWorkflowExampleTests
```

Also rerun SegmentationTools and ObjectGeometry suites. New synthetic tests cover source/identity propagation, configuration errors, query consumer acceptance, class alias equivalence and workflow 1 with a different physical grid/unit. Workflow tests save fresh outputs under package tests/data; original datasets are read-only. MATLAB execution remains to be confirmed in a licensed user session.

