# FARM code conventions — review draft

Agreed in the design interview on October 15, 2026. This separate draft records
confirmed decisions for review; it does not claim that existing code already
complies. It authorizes no implementation changes, release work or migration of
shared documentation. Release scope and workflow etiquette remain in their
respective chats.

Use **must** for correctness requirements, **should** for conventions with
justified exceptions, and **prefer** for flexible preferences. This distinction
primarily serves design and contributor guidance. User documentation should give
direct, task-specific instructions.

## Terminology and constructs

Use the existing glossary explicitly and consistently. Do not create a competing
glossary. Compact variable names should derive from the corresponding glossary
terms: for example, an intensity data source can be `intSrc`, and intensity data
can be `intData`.

Proposed addition to the existing glossary, retained here pending integration:

> **Construct** — An item with a defined FARM role and documented representation,
> such as an Experiment, Data source, Query or Geometry. A construct may be
> represented by a struct, array, table or another documented form. Functions
> and incidental intermediate variables are not constructs.

Functions perform operations on constructs; APIs organize related operations.
Use specific glossary terms whenever possible. Distinguish a construct's meaning
from its MATLAB container: an Experiment is represented by a scalar struct.

## Design and organization

- Retain ordinary API folders and descriptive `farm...` callable names. Use
  `farmSetup` for paths; do not restore package namespaces without discussing a
  concrete reason. Builders return ordinary editable structs.
- Preserve the independent use of measurement, geometry generation and field
  querying. Keep scientific selections explicit and avoid unrelated calculations.
- Extract a function when it performs a coherent, reusable task with clear
  inputs and outputs. Do not extract fragments merely to shorten another function.
- Keep a function in the API responsible for its meaning, even if another API
  calls it. Reserve `SharedUtilities` for general operations such as array
  manipulation and keyed table joins.
- When editing, check for effectively duplicated implementations. Compare purpose,
  inputs, units, defaults and edge cases before calling them equivalent. Explain
  proposed consolidation, ownership and behavioral differences, and agree before
  implementing it.
- Composed structs are appropriate for meaningful entities or coordinated tasks.
  Pass the whole construct when the function needs its context; otherwise pass
  the relevant inputs and settings. Lower-level functions should not need to
  understand an entire workflow configuration.
- Calculation functions return results. Prepare figures from those returned
  results.

Workflow etiquette is not settled here. The stated direction is small task
examples ("bites") that can later be combined into workflows; composition may
be nonlinear. The parallel chat owns those organization decisions.

## Naming and consistency

- Public functions retain `farm` followed by a descriptive operation name.
- Local variables should be short but descriptive. Shortening words is acceptable;
  use lower camel case when combining words. Prefer fewer than 10 characters,
  without treating that preference as a limit.
- Loop indices should identify what is being iterated: `tInd` for frames/times
  and `objInd` for objects, for example. Comments should explain the iteration
  when its meaning is not evident.
- Keep existing long, descriptive public fields, options and table column names.
- Names, units and defaults should agree across operations when their meanings
  agree. Handle exceptions explicitly rather than silently forcing consistency.
  Examples include coordinate/component ordering required by `quiver` and the
  differences between `ndgrid` and `meshgrid`.
- Use current callable names in help and error messages. Treat public field,
  default, unit and interface changes individually: identify affected callers
  and saved outputs, discuss the change, and update consumers and documentation
  together. Add compatibility aliases only for a concrete need; indefinite
  compatibility with every historical interface is unnecessary.

## Code layout and comments

Use expanded code everywhere in new or heavily edited code, with generous blank
lines, stage comments and spaces around `=`. This is not an instruction to
reformat untouched historical algorithms.

```matlab
if nargin < 3
    options = struct();
end
```

Comments should explain purpose, what loops iterate over, scientific assumptions
and consequential conversions. Distinguish axis reordering, unit conversion and
resampling between grids. State source and destination conventions. For
resampling, explain interpolation and registration assumptions where relevant.

Approved axis-reordering comment template:

```matlab
% Convert centroid columns from XYZ to YXZ for array indexing.
yxz = xyz(:, [2 1 3]);
```

Grid spacing and coordinate/component order must not be conflated. Internal image
arrays use `[Y X Z C T]`, while individual functions may require XYZ coordinates.
Preserve documented operation-specific conventions and make adaptations explicit.

## Validation and errors

- Public entry points must check essential structure and values, including when
  users supply editable structs directly rather than using builders.
- Builders validate settings without loading data. Operations validate relevant
  relationships between actual inputs when they receive them, such as matching
  array dimensions. Matching dimensions alone does not establish registration.
- Define required fields and meanings for constructs exchanged between public
  functions. Validate requirements relevant to the operation; temporary internal
  structs do not each require dedicated builders or validators.
- Reuse validators where several functions need the same checks.
- Reject invalid or unsupported requests with actionable errors: identify the
  problem, expected input and correction. Include a reference to the equivalent
  glossary entity, using a verified entry name.
- Do not silently ignore options or substitute a different calculation. Preserve
  explicitly supported and documented fallbacks, such as empty-skeleton centroid
  sampling and its distinguishing flags.

## Cost, memory and batch progress

Separate what to calculate, return and save where these choices materially affect
runtime or memory. Calculate needed prerequisites, but avoid unrelated properties.
Document costly options and dependencies.

Cost depends on data size, object count and requested outputs. Inspect likely
costs first, such as extra full-volume reads, volume-sized allocations, skeleton
generation, Fourier transforms and retained voxel indices. Where practical,
compare representative runs with an option enabled and disabled, recording elapsed
time and returned-array size. Returned-array size is not peak working memory.
Distinguish measured costs from estimates; prefer concrete descriptions of work
and allocations over an unexplained "expensive" label.

Preserve scientific definitions, identity relationships and exceptional-value
behavior during optimization. Consult original implementations when available.
Notify the user when a potentially more efficient implementation is identified.
Prefer shared array operations where appropriate, but retain readable loops when
they are suitable. Measure runtime and memory before adding optimization complexity.

Preserve the confirmed frame-at-a-time processing approach: reuse manageable
same-frame fields and supports before advancing rather than requiring full XYZT
experiments in memory.

Batch processes iterating over time should optionally print the current file
number or iteration index when available. For example:

```text
Processing frame 14 (3 of 11)
```

## Verification and behavior changes

Test observable scientific behavior and public contracts rather than local
variable names or internal organization. Relevant checks include identity through
joins, axial alignment under director reversal, physical-unit behavior under
spacing changes, empty/fallback results and operation-specific nonfinite handling.

Use original implementations as references where available. Also use known-answer
synthetic examples: agreement with historical output alone cannot establish
correctness. Investigate disagreements and discuss them before accepting behavior
changes. An intentional correction should have an explicit expected result.

## Function documentation format

Public analysis functions use the following layout, scaled to their complexity:

1. Top help: purpose, Inputs and Outputs, with no blank comment lines before
   Inputs or Outputs; related functions may follow.
2. Expanded implementation.
3. Below the implementation: Behavior, Examples, Matching Results, Units and
   Coordinates, as applicable.

The top help does not include a sentence announcing the lower sections. MATLAB's
`help` displays the top block; the lower sections are read in the source.
Internal helpers are marked internal and receive sufficient maintenance guidance
without requiring the full public format. API references identify supported public
entry points; path visibility alone does not establish public status.

Provide multiple examples for effectively overloaded functions or distinct usage
modes, such as skeleton versus boundary geometries. Show mode-specific inputs and
options and explain how the results differ. Use verified callable syntax.

Approved layout example (implementation deliberately abbreviated; not executable
replacement code):

```matlab
function [props, objects] = farmMeasureObjects(input, requested, options)
%FARMMEASUREOBJECTS Measure selected properties of segmented objects.
% Inputs:
%   input      Object representation accepted by farmPrepareObjects.
%   requested  Native property names. Defaults to {'Centroid'}.
%   options    Object preparation settings. Defaults to an empty struct.
% Outputs:
%   props      Table of identity columns and requested measurements.
%   objects    Prepared object representation used for measurement.
%
% See also farmPrepareObjects, farmMeasureFilaments, farmQueryFrame

if nargin < 2 || isempty(requested)
    requested = {'Centroid'};
end

if nargin < 3
    options = struct();
end

% ... remainder of implementation ...

end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Only requested properties are calculated.
% options.Intensity supplies matching grayscale data for native 2-D
% intensity measurements; it is not supported for 3-D input.
% Empty foreground returns zero measurement rows while retaining the
% requested column layout.
% Available properties depend on MATLAB's installed version.
%
%
% EXAMPLE
% -------------------------------------------------------------------------
% props = farmMeasureObjects(mask, {'Volume', 'Centroid'});
%
%
% MATCHING RESULTS
% -------------------------------------------------------------------------
% Match measurements using DatasetID, Frame and ObjectID together.
% ObjectID alone does not identify an object across datasets or frames.
%
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Native geometric measurements use pixel/voxel units.
% Centroid, BoundingBox and VoxelList use MATLAB's XYZ coordinate order.
% Image array dimensions use YX in 2-D and YXZ in 3-D.
```

The example's matching rule concerns this operation. Other documented
representations may also require `ComponentID`; `TrajectoryID` remains information
about tracking rather than a replacement object key.

## Repository evidence and review boundary

Checked against current repository files during this interview:

- `README.md`, `docs/README.md`, `docs/FARM-NAMING-MIGRATION.md` and `farmSetup.m`:
  ordinary folders, descriptive names and path configuration.
- `CONFIGURATION-BUILDERS.md` and
  `Examples and Workflows/src/memoworkflow/config/farmMakeExperiment.m`: editable configuration,
  timing defaults and configuration checks.
- `APIs/ObjectGeometry/src/objectgeometry/objects/farmMeasureObjects.m`:
  preparation reuse, selected measurements, grid validation, table identity,
  coordinate conventions and empty-foreground schema handling.
- `Examples and Workflows/examples/setupWorkflow1.m`, `farmWorkflow1Objects.m` in the same
  folder, and `setupWorkflow2Staged.m`: existing organization alternatives, not
  an agreement to reorganize workflows.
- `GLOSSARY-CAPABILITIES-MOCKUP.md`: current terminology and representations;
  Construct is proposed here rather than already present in that reference.

Existing compressed code, legacy help references and historical identifiers are
not evidence of compliance with these conventions. Their correction requires
separate agreed implementation work. This documentation-only draft makes no
runtime validation or release-readiness claim.
