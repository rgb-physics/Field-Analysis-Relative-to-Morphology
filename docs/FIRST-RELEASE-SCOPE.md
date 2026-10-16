# First usable FARM release: scope discussion

Planning record, October 15, 2026. This records user-confirmed requirements;
it does not authorize implementation or claim that current functions satisfy them.
Confirmed decisions in HANDOFF-GRILL-WITH-DOCS-2026-10-15.md remain the baseline.

## Confirmed purpose

Identify object geometry, display it with source fields, and query field profiles
over space and time. The general capability includes comparing fields derived
from two geometries at explicitly selected sampling sites.

Release demonstrations must cover:

- Detect an object's boundary, display the boundary and original field in 2D/3D,
  and quantify intensity against separation from the boundary. Liquid droplets
  undergoing liquid-liquid phase separation are a motivating use case.
- Measure filament orientations and compare them with object-surface normals
  obtained from a distance-transform gradient. The objects can originate in a
  different channel but must occupy corresponding spatial locations.

Examples should expose reusable stages: load data; define objects from pixel
segmentations or raw data; define geometry and coordinates; query fields at
specified locations or over distance bins; sample explicit indices; combine
fields before analysis; visualize results. Boundaries, skeletons, and centers
are requested geometric features; the precise meaning of center remains open.

## Confirmed usability

Users edit a setup and can stop at intermediate stages, inspect data and
quantities, change downstream settings, and resume without repeating upstream
loading and extraction. Staged evaluation must be available, but the current
staged workflow presentation is too cumbersome to adopt as the final design.
The implementation interface remains undecided.

Provide a version with stopping available and notes identifying stages where
stopping/resuming is complicated. Do not imply every point is safely resumable.
Required MATLAB toolboxes are release requirements, not optional dependencies.
Evaluate external software integrations individually before assigning release
status; no blanket optional-dependency exemption has been agreed.

External dependency decisions are recorded in EXTERNAL-DEPENDENCIES-REVIEW.md.
Provide a particularly legible, user-readable project-local gfilter setup script,
with verified installation subject to redistribution terms, presence checks and
a functional test, avoiding global path changes. Python tracking is optional but
strongly recommended, with easy, minimally invasive setup. Mesh dependencies are
optional outside mesh functionality and need documented roles.

farmSingleTimePointTrajGen is excluded from the supported public release
interface, so munkres is not a release requirement. Preserve its historical source;
this decision does not authorize modifying or removing it. All retained supported
public functions remain subject to the agreed conventions and validation.

The current five workflows support visual confirmation and personal evaluation
of code formatting. They are not the required release examples. Release
workflows will differ; workflows 1 and 2 may be retained.

## Mesh/sheet deferral and performance evidence

Defer farmGenerateVanHove and farmGenerateStaticStructureFactor pending scientific
review. Preserve their historical sources and the reference to the user-supplied
genCorrScaleMat helper; no integration or estimator changes are authorized.

Postpone the entire mesh/sheet API area until rigorous study, including its
conventions review and release validation. This supersedes earlier suggestions
to require the retained public mesh functions in the first release. Preserve
their sources; no archive restoration or redesign is authorized. Shared public
functions with sheet-specific modes require mode-level classification rather
than deferring unrelated boundary/blob operations.

Measure runtime and memory on representative inputs, especially independent
per-object distance profiles and subsampled 3D displays. Record input sizes and
distinguish returned-array size from peak working memory. Agree practical limits
after collecting measurements; no numerical performance threshold is settled.

Prepare a concrete release plan with an interface inventory, proposed changes,
validation/data requirements and historical-edit approval gates before seeking
implementation agreement. See FIRST-RELEASE-PLAN.md.

## Confirmed visual and numerical evaluation

Acceptance requires both visual inspection and numerical checks. Specific
datasets, expected values, tolerances, and pass criteria remain undecided.

Requested visual outputs include 2D image overlays, plots of measured quantities,
subsampling of fields on objects before 3D display, and representations of
binned distances, described by the user as "binned isosurfaces". The distinction
between a finite distance band and an isosurface remains to be resolved.

## Confirmed query and documentation requirements

All retained public functions must meet the agreed code conventions before
release, not only functions used by the demonstrations. Before editing any
original/legacy/historical implementation, identify the function and proposed
change, discuss implications with the user, and obtain agreement. Scope planning
does not authorize implementation changes.

Document every public construct and returned quantity, including request and
access paths, while omitting incidental internal variables. Present one example
entry for the user to format before propagating a documentation layout.

### Agreed reference presentation

Organize the written reference into scientific topic pages, with glossary
concepts and Data Dictionary quantities together on each page. Preserve their
Glossary/DataDictionary classification, give each entry one canonical home, and
cross-link related topics. Use expandable details for extended documentation.
The specific topic boundaries and expansion headings remain proposed.

Preserve the existing default farmGlossary display structure:

```text
Mean [numeric scalar; table column for multiple groups]
DataDictionary / Summary statistics

The arithmetic average of the selected values.
Inputs: {''}
```

This is an approved display example, not a claim that Mean is implemented as an
entry. Additional information must not clutter this default presentation; its
MATLAB access interface remains undecided.

Identify appropriate entries as constructs using the definition agreed in
FARM-CODE-CONVENTIONS-DRAFT.md: an item with a defined FARM role and documented
representation, such as Experiment, Data source, Query or Geometry. Functions
and incidental intermediate variables are not constructs. Do not equate
construct status with a MATLAB container type or with Glossary/DataDictionary
classification. The visual placement of the designation remains undecided.

Require numerical known-answer or contract checks for every supported public
operation. Concentrate representative real-data and visual evaluation on the two
agreed demonstrations; historical comparisons supplement these checks. Prepare
a list of real data and metadata the user must provide, distinguishing these
from synthetic fixtures that can be generated without user data.

Provide small independently usable task examples alongside the two complete
demonstrations. State prerequisites and returned quantities so users can compose
analyses and inspect intermediate results.

Offer both nearest-object distance profiles and independent per-object distance
profiles explicitly. Per-object computation may be substantially slower; its
implementation, spatial extent, and performance policy require discussion.

Population summaries are requestable quantities. Prioritize access to the data
users want to plot and documentation making that access discoverable. Emphasize
the existing Data Dictionary, with glossary concepts where helpful. Individual
histories depend on the user's initial tracking choice and subsequent ancestry
navigation; no automatic ancestry aggregation policy has been agreed.

The user describes a binned distance region by a scalar center and a width:
center -1 with width 2 gives bounds -3 and 1. This establishes the example's
extent; the canonical parameter name and endpoint inclusion remain open.

## Open scientific and interface choices

- Distance sign, reference, bin edges, and per-object cost/selection policy.
- Population reduction/weighting and explicit tracking/ancestry access paths.
- Canonical centered-region terminology, endpoint rules, and rendering.
- Definition of centers, including geometric centroid versus weighted center.
- Sampling sites and correspondence for geometry-derived field comparisons.
- Intermediate-stage execution interface and retained current-frame state.
- Bounded scientific checks, dependency requirements, and release documentation.

## Repository evidence inspected

Existing ObjectGeometry helpers render index geometry as masks or labels.
ObjectRelativeProfiles supports explicit indices, grouped supports, scalar and
vector statistics, and operations combining named fields at corresponding
indices. Its documentation defers cross-time operations and motion correspondence.
VisualizationTools documents only retained violin/export helpers; the requested
display experience has not been established by this inspection.

The latest inspected saved all-tests summary reports 176 passed checks and two
SharedUtilities failures, with one overlapping incomplete result. The two
reported glossary fixes are present in source; no newer passing runtime report
was found. This is recorded evidence, not a new test execution.
