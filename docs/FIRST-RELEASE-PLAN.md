# First usable FARM release: plan for review

Current sequencing decision, October 15, 2026: finish the topic pages for the
existing glossary/Data Dictionary entries now. Defer the full public-function
and test inventory until the remaining functionality has been evaluated. The
inventory work described below remains planned work, not completed evidence.

October 15, 2026. Planning only. The user has authorized this plan and documentation,
not analysis-code changes. FIRST-RELEASE-SCOPE.md records agreed requirements;
FARM-CODE-CONVENTIONS-DRAFT.md supplies the agreed conventions. Preserve existing
uncommitted work and user data settings. No commit, push or publication is implied.

## 1. Establish supported operations

RELEASE-FUNCTION-INVENTORY.csv lists every currently discovered MATLAB file under
API source trees (including Workflows), plus root setup/reference functions. Its 212 rows
are a file inventory, not 212 approved public operations:

- 165 possible public entries requiring confirmation against API references and
  consumers. Path visibility alone does not make a function public.
- 19 internal/private dependencies, verified through their consumers.
- One new supported setup function, farmInstallGaussdiff.
- 24 mesh/sheet-related files proposed as deferred under the agreed area deferral.
- farmSingleTimePointTrajGen explicitly excluded from public support; source preserved.
- Two historical estimators deferred by agreement pending scientific review:
  farmGenerateVanHove and farmGenerateStaticStructureFactor. Preserve sources
  and the reference to the user-supplied genCorrScaleMat helper.

Review public status before applying conventions or promising support. Each supported
public function must have a documented contract, conform to conventions, and have
observable numerical or contract checks. Internal dependencies remain relevant to
correctness even without standalone public documentation. Existing tests are evidence
to inspect, not an instruction to duplicate coverage.

The deferred inventory includes SurfaceFieldMapping, sheet-specific segmentation
and geometry, and mesh export through farmLogic2Ply. Shared functions such as
farmGenerateGeometry require mode-level treatment: boundary/blob operations stay
in scope while sheet and sheet-sampled methods are deferred. Review references,
examples and tests accordingly without silently removing scientific functionality.

## 2. Required capabilities and proposed work

| Area | Work to assess and complete | Release evidence |
| --- | --- | --- |
| Setup and I/O | Readable setup; accurate dependencies; TIFF/HDF5 sources, calibration and selection | Known-axis/channel/time fixtures, pixel/metadata round trips, actionable errors |
| Segmentation and objects | Explicit intensity/probability choices, object identity and selected properties | Known masks/labels, disconnected same-ID groups, empty results, real overlays |
| Geometry and coordinates | Independently request boundaries, blob skeletons, centers and distance-derived fields; preserve grid provenance | Known shapes, index mapping, coordinate order, fallback flags and documented distance units |
| Filament analysis | Extraction, native/scaled geometry and axial alignment with object-distance normals | Synthetic directors/anisotropic extent, reversal invariance, annotated real-data overlays |
| Sampling and profiles | Direct indices/supports, field composition, nearest-object and per-object distance profiles, centered distance regions | Known samples/bin membership, counts, empty/nonfinite contracts, explicit correspondence and identities |
| Time and tracking | Requestable temporal/population quantities; user-selected tracking and ancestry paths | Stable supplied frame order, identity joins, many-to-many links, selections excluding unrelated siblings |
| FieldAnalysis | Supported Fourier, correlation and statistical operations, with normalization and units explicit | Analytic frequencies, Parseval/normalization checks, known correlations and grouped statistics |
| Visualization | 2D overlays, measured-quantity plots, subsampled 3D fields on objects, distance-region display | Visual inspection with known geometry; display selection must not alter measurement inputs |
| Documentation | Unified glossary/dictionary topic pages with expandable detail; construct labels; compact default MATLAB display | Entry completeness, working lookups/search, verified examples/access paths and cross-links |
| Examples | Two complete demonstrations plus composable task examples and a version supporting stopping | Inspect intermediate data, change downstream settings and resume where supported; explain complicated stopping points |

The demonstrations are object boundary/field display with distance profiles over
space/time, and filament orientation versus distance-gradient normals of objects
from another corresponding channel. Current workflows are evaluation tools, not
the final release-example list. Workflows 1 and 2 may be reused after review.

## 3. Conventions and historical-edit gate

For every supported public operation, inspect naming, expanded layout, purpose
comments, help structure, accepted constructs, units/components, defaults, validation,
returned quantities and costly options. Preserve confirmed scientific definitions.
Do not infer equivalence of duplicate-looking algorithms.

Before editing an original/legacy/historical implementation, present its path,
provenance, proposed edits, numerical/interface implications and intended checks;
obtain the user's agreement. Formatting and help changes inside those files are
also covered. Inventory provenance flags are conservative reminders, not a completed
historical audit. Propose changes in bounded groups only after identifying the files.

Known review candidates include farmSkel3DBlobs, original boundary/skeleton helpers,
farmLOG/farmGaussD/farmMyconvn, TIFF transforms, retained tracking conversion helpers,
and historical FieldAnalysis statistics. Inclusion here does not authorize edits.

## 4. Dependencies and data

Use EXTERNAL-DEPENDENCIES-REVIEW.md for individual decisions. MATLAB toolboxes are
required for the supported operations. Confirm the complete list from code and
MATLAB dependency analysis; current evidence includes Image Processing and Signal
Processing, not a certified exhaustive list.

Provide a readable project-local verified gfilter installer/check, subject to
distribution terms. Python tracking is optional but strongly recommended: verify
actual MATLAB/Python/Trackpy operation and provide minimally invasive setup without
replacing the user's environment. Mesh dependency installation is postponed with
the mesh API; preserve its functionality inventory. Ilastik is an upstream producer,
FIJI is not an identified runtime requirement, ND2 is deferred, and munkres is excluded.

RELEASE-VALIDATION-DATASETS.md is the accessible user-data checklist. Reuse existing
fixtures where suitable; request only missing datasets/metadata after mapping checks.
Generate controlled scientific inputs synthetically. Read originals without changes
and save new outputs under fresh tests/data locations.

## 5. Validation and performance

Map each supported operation/mode to existing tests, uncovered behavior, known-answer
or contract checks, dependencies and required data. Visual and representative real-data
evaluation focuses on the two demonstrations. Historical comparisons supplement
independent expected results; disagreement requires investigation and discussion.

Rerun the licensed MATLAB suites after changes, including the glossary regression
fixes, and retain fresh reports. Latest inspected report: 176 passed, two SharedUtilities
failures, one overlapping incomplete result; fixes exist but no subsequent passing
report was found. Do not describe this as current runtime success.

Benchmark representative sizes/object counts for per-object profiles, frame-at-a-time
processing and display subsampling. Record environment, choices, elapsed time and
returned data sizes; report peak working memory only if measured. Measurements inform
limits; no acceptance thresholds have yet been agreed.

## 6. Proposed implementation order after approval

1. Resolve the remaining public-support classifications and produce an operation/test map.
2. Review conventions and historical-file proposals, securing the required agreement.
3. Complete dependency setup, public contracts and documentation access paths.
4. Close geometry/query/profile and visualization gaps without changing settled science.
5. Produce composable examples and stopping-capable demonstrations.
6. Run numerical, real-data, visual and performance checks; review results and limitations.
7. Reconcile references/manifests and deferred-feature claims before any separately
   requested commit or release action.

## Remaining decisions before a final implementation scope

- Confirm the detailed supported interface inventory; do not promise support for
  every path-visible utility by accident.
- Scientific profile details (population reduction, per-object bounds/cost policy,
  centered-region endpoints, correspondence and center meaning) remain explicit
  design decisions before implementing the affected operations.
- The function-reference example has been presented but its full format has not
  been approved. Preserve the approved default glossary display in the meantime.

Detailed code/interface choices may be resolved in the separate design discussion;
this plan does not silently accept proposed parameter names or implementations.

Implementation has begun following user approval. See REFACTOR-PROGRESS.md for
completed work, verification and the next historical-edit proposal.
