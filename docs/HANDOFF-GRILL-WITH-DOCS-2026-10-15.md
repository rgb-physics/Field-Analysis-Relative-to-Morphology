# FARM handoff for grill-with-docs

Prepared October 15, 2026. Purpose: give a fresh agent the context needed to interview Remi about the remaining work toward a first usable FARM release. This is project context, not a new skill, a model-training dataset, or authorization to implement every item below.

## Starting prompt

```text
$grill-with-docs Read docs/HANDOFF-GRILL-WITH-DOCS-2026-10-15.md and verify it against the current repository. Help me define the remaining scope for a first usable FARM release. Preserve confirmed decisions unless current evidence contradicts them; explain any contradiction before proposing a change. Investigate repository facts yourself. Ask at most three questions per round, in plain English, with concrete examples and a recommended answer. Focus on unresolved scientific definitions, usability, validation, and release requirements. Do not repeat settled questions. Agree the scope with me before changing analysis code. Keep documentation changes separate from proposed implementation and identify what you intend to write before writing it.
```

If the named skill is unavailable, report that limitation and ask whether to use the interview routine described here. Do not claim that the skill was loaded. Its installation has not been verified in this chat.

## Project and evidence

- Repository: `C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo`.
- Public project name: **Field Analysis Relative to Morphology (FARM)**. The local folder can remain MeMo.
- MATLAB target: R2023a. Image Processing Toolbox and Signal Processing Toolbox were required by the original segmentation handoff. Verify dependencies for the selected operation; mesh tools, gfilter/gaussdiff, and Trackpy are separate dependencies.
- This handoff combines chat history with a limited check of current repository documentation. It is not an independent audit of all algorithms.
- Current README, TESTING.md, and the FARM migration documents were read when preparing this handoff. Git status showed extensive modified/deleted/untracked migration files. Do not discard, reset, clean, or overwrite this work. Commit/push status must be checked afresh.
- Historical assistant claims of completion or passing tests are evidence of prior reports, not proof that today's files pass.

Source chats:

| Chat | ID | Relevance |
| --- | --- | --- |
| Package Repo Refactor MAIN | `01a12884-f9fe-7ca0-8783-b18517e124a3` | Scientific decisions, implementation history, latest glossary fixes |
| Export Package Repo Refactor MAIN | `01a140fc-5f85-7b52-a3d7-7b8276dd8ee3` | Exported 686 user/assistant messages, including progress updates |
| Review Grill With Docs skill | `01a14183-92a9-7f32-ad43-4cf51a696c72` | Recommended a fresh project chat with a handoff and bounded interview rounds |

The main-chat snapshot exists outside the repository at:
`C:\Users\Remi Boros\Documents\Codex\2026-10-15\can\outputs\Package Repo Refactor MAIN - Transcript.json`
and the adjacent `Package Repo Refactor MAIN - Transcript.md`. It ends before the final naming migration and glossary-test fixes; consult newer chat messages and current files for those changes. The export omits tool calls and outputs.

## Read these first

Use repository-relative paths below, resolved from the root above.

1. `README.md`, `docs/README.md`, and `TESTING.md`: package purpose, navigation, available verification.
2. `docs/FARM-NAMING-MIGRATION.md`, `docs/FARM-MIGRATION-VALIDATION.md`: current naming, archive policy, checks and limitations.
3. `docs/FARM-FUNCTION-NAMES.json`, `docs/FARM-MIGRATION-MANIFEST.csv`, `docs/CURRENT_SOURCE_TREES.md`: exact function mapping and retained files.
4. `GLOSSARY-CAPABILITIES-MOCKUP.md`, `docs/MATLAB-GLOSSARY.md`, `farmGlossary.m`: terminology and interactive reference. The filename “MOCKUP” is historical; this document is used by the implemented reference.
5. `CONFIGURATION-BUILDERS.md`, `docs/READING-STRUCTURES.md`, `docs/CHANGING-AN-ANALYSIS.md`, `docs/WORKFLOW-1-WALKTHROUGH.md`: configuration and user experience.
6. `Workflows/examples/setupWorkflow1.m` through `setupWorkflow5.m`, plus `setupWorkflow2Staged.m`: user-facing analysis choices and the alternate staged presentation.
7. Relevant API README, function help, tests, and implementation for each question. `OPTIONS-AND-BUILDERS-AUDIT.md` is useful background but must be checked against code.
8. `docs/DATA-DICTIONARY-CANDIDATES.md` and `.csv`: candidate fields, not an approved requirement to document every implementation variable.

Read applicable AGENTS.md instructions before editing. Do not infer present behavior solely from old pseudocode, old handoffs, or archived functions.

## Confirmed design decisions

### Public interface and cleanup

- Ordinary folders organize APIs. Callable functions use descriptive `farm...` names rather than `+` namespaces. Use `farmSetup` to configure paths; do not restore namespaces without discussing a concrete reason.
- Examples include `farmReadTiff`, `farmMakeSource`, `farmMeasureObjects`, `farmMeasureFilaments`, and `farmGlossary`. Find exact current names in the mapping file.
- Internal `farmFAOptions`, `farmOGOptions`, and `farmSUOptions` use `(userOptions, defaults)`. Do not generalize that signature to unrelated public builders.
- Preserve original algorithms that active APIs use. Remove redundant interfaces after updating their consumers; indefinite compatibility with every historical name is unnecessary.
- Historical workflows, originals and redundant aliases were moved to sibling `MeMo-Archive`, preserving provenance. The archive is a folder, not a separately initialized/pushed Git repository. Never add it wholesale to the release MATLAB path.
- Builders return ordinary editable structs. No custom MATLAB classes were found during the earlier architecture review. Namespace folders were never classes.

### Data, identity, and memory

- Internal image organization is `[Y X Z C T]`; spatial arrays typically use YXZ. Verify each function's documented coordinate/component order rather than assuming spacing and XYZ vectors use identical order.
- Preserve geometry as linear voxel indices where appropriate, with grid size, axes, spacing, units, and source/transform metadata. Coordinates are appropriate when points do not lie at voxel centers.
- A binary mask receives connected-component identities. Supplied label IDs remain distinct; disconnected pieces sharing an ID can belong to the same ID group. Component identity is separate where needed.
- Join object measurements using `DatasetID + Frame + ObjectID`; add `ComponentID` when the representation requires it. Attach `TrajectoryID` as information rather than requiring it in the primary object key.
- Load manageable XYZ fields/supports for one frame, reuse them, then advance. Several fields may coexist for the same frame; do not require loading entire XYZT experiments.
- Prefer shared array operations, masks, linear indices and table grouping. Avoid unnecessary nested per-object loops, while measuring runtime and memory before optimizing.
- Keep source datasets unchanged. Write new outputs under package `test-data` in fresh locations without overwriting existing results.

### Scientific meaning

- Preserve quantitative corrected intensities across time. Do not introduce automatic per-frame stretching of the sampled intensity field. Optional 8-bit/downsampled Ilastik export is a separate operation with an explicit intensity range.
- Filaments are thin elongated structures in images. Skeletons are derived geometry, often inside blob-like structures. They are not synonyms.
- Geometry and support can contain identical indices: geometry describes a feature; support describes using locations in a calculation. Do not create extra containers merely to distinguish the roles.
- Geometry measurements, generated geometry, and field querying are independently usable operations. Users choose requested properties/statistics; avoid hidden expensive calculations.
- Scalar/component sampling uses finite values for standard statistics and reports NaN, positive Inf, and negative Inf separately. Empty geometry, empty selection and centroid fallback must remain distinguishable. Check operation-specific contracts before extending this policy.
- Empty-skeleton centroid sampling is supported with explicit fallback/empty flags, so users can omit those statistics later.
- Filament alignment is axial/nematic: reversing a director should not change alignment. Polar head–tail inference was deferred. Preserve dimension-specific normalization.
- `ExtentInVoxels` replaced the ambiguous `Lengths` field for the native principal-axis measurement. `ProjectedExtent` scales coordinates before PCA and measures the span of voxel centers along the major direction in physical units. They differ in definition as well as units. Neither is a curved contour length or a correction for optical blur. Single-voxel fallback uses spacing.
- Overlap tracking retains all accepted ancestry links separately from chosen trajectory inheritance. Default inheritance ranks overlap count; volume ranking is optional. Ancestor traversal must not accidentally include unrelated siblings.
- The original restriction to increments of one frame was superseded: track successive entries of a supplied frame vector, allow arbitrary spacing/order, and omit repeated frame numbers while retaining their first occurrence. Trackpy gaps and overlap behavior remain distinct concepts.
- Fourier work follows the samAdapted baseline with shared Hann/frequency helpers. Keep 2D/3D and separate slice results explicit. Mean subtraction is optional and off by default. Document power normalization; do not casually relabel outputs as power spectral density. Linear spatial correlation was selected for the simplified first pass.
- TIFF-based sheet analysis and mesh/PLY workflows are distinct. SurfaceFieldMapping redesign is deferred.

### Usability and documentation

- Explain in plain language without assuming substantial coding knowledge. Define necessary technical terms and show concrete inputs/outputs.
- User-facing setups should expose measurement properties, queries, names, statistics and non-default choices. Avoid hiding scientific choices inside helper functions or one unexplained all-encompassing config.
- Use generous blank lines, stage comments, and spaces around `=` in new code/examples. Preserve user-edited data settings.
- Source naming uses `NamePattern`; experiment timing uses independently defaulted `TimeStep = 1` and `TimeUnit = 'frame'`. Time step refers to original acquisition-frame increments.
- Use the agreed term “segmented category”; distinguish category IDs from individual region IDs. Boundary and finite-thickness layer are distinct. “Centered surface” generalization remains a discussion item, not blanket authorization to rename code.
- The written reference contains definitions, type annotations, and `Inputs: { Field* = type; ... }` layouts. Required fields have `*`. Entries without inputs return `Inputs: {''}`.
- One reference contains glossary concepts and a Data Dictionary. Lookup/search covers both by default; optional Section and SearchIn filters narrow it, and SearchIn accepts multiple fields.
- Search is case-insensitive. Historical direct lookup preferred exact spelling and reported ambiguous case-insensitive matches; verify the current implementation before explaining edge cases.
- Propagate terminology/schema changes through the written reference, MATLAB lookup/parser where relevant, help, guides, examples, tests and consumers. Avoid a second competing glossary.

## Workflows and datasets

| Example | Intended purpose |
| --- | --- |
| Preparation | Optional illumination/bleaching/reference correction; quantitative export; optional resized 8-bit Ilastik input |
| Workflow 1 | Optional segmentation, object properties, generated geometry, field sampling |
| Workflow 2 | Filament identification/properties and axial alignment relative to density-derived reference fields |
| Workflow 3 | Overlap lineage, ancestry/descendant selection, selected-history measurements |
| Workflow 4 | Selected-slice, projection and 3D spectra; spatial correlation |
| Workflow 5 | Geometry-relative conditional profiles, including intensity/alignment versus distance and segmented category |

Experiment 4 on drive O: was the real-data example. Its README is
`test-data/image-stacks/tiff/Time Series/DATASETS-README.txt`; historical metadata location was
`O:\Session 88\Exp 4 - Rmin Redo\1 Cropped MATLAB\metadata.mat`.
Drive access has not been rechecked here. Do not assume all sources exist on another machine. Use synthetic inputs where possible and inspect current setup settings before running anything expensive.

Filament context reported by Remi: spacing `[.55 .55 .7]` micrometers, typical length 3 micrometers, axial PSF FWHM 1.1 micrometers. Do not silently interpret that PSF width as Gaussian sigma. A more elaborate optics study was discussed and then set aside as unnecessary scope expansion.

## Validation state and commands

Current migration documentation reports:

- All 268 retained MATLAB files passed standalone R2023a syntax analysis.
- Static checks covered unique filenames, function/filename agreement, namespace removal, resolution, manifests and archive snapshots.
- Four Python bridge contract tests passed using a fake linker. This does not establish Trackpy algorithm correctness.
- Agent-side MATLAB runtime execution failed with License Manager Error -9, a username/license mismatch.

Latest main-chat runtime report: **176 checks passed and two SharedUtilities glossary tests failed**. One incomplete result overlapped a failure; it was not an extra distinct failing test. The agent then corrected line-spanning heading extraction and a stale `glossary` call inside evalc to `farmGlossary`. Syntax checks and extraction of all 107 written entries passed. No post-fix MATLAB runtime result was reported in the messages read for this handoff.

From the repository root in a licensed MATLAB session:

```matlab
farmSetup('IncludeExamples', true)
report = runAllTests;
```

Without local ImageStackIO fixtures:

```matlab
report = runAllTests('IncludeImageStackIO', false);
```

Read `TESTING.md` for saved report paths and failure interpretation. Passing synthetic tests does not establish real-data scientific accuracy, broad performance, or complete VisualizationTools/SurfaceFieldMapping coverage. Earlier user reports confirmed successive API suites passed before later edits; do not present those as verification of the current tree.

## Interview priorities: unresolved, not implementation orders

1. Define the release acceptance criteria: which workflows must run on representative data, which outputs must be visually checked, and what documentation a new user needs.
2. Confirm the latest glossary fixes with a runtime result and investigate any new failures before assuming release readiness.
3. Assess workflow usability using actual setup scripts and the staged workflow 2 experiment. Determine which concrete difficulties remain before proposing more builders or restructuring.
4. Bound VisualizationTools work around actual workflow outputs. Earlier candidates included overlays, profiles, time heatmaps, keyed measurement plots and lineage views; these were suggestions, not a finalized feature list.
5. Select necessary scientific checks: identity through joins, geometry/index mapping, skeleton/fallback behavior, filament extraction on TIFFs, anisotropic extent, many-to-many lineage, and real-data profile/spectral sanity checks. Prioritize with Remi rather than expanding all of them automatically.
6. Decide which Data Dictionary candidates are public contracts worth documenting. A scan inventory is not an obligation to expose all internal fields.
7. Confirm dependency/setup requirements and optional Python integration checks for the release. Leave mesh redesign deferred unless Remi changes that scope.
8. Check Git and archive portability before any requested release commit/push. Current migration work is uncommitted; do not infer permission to commit or publish from historical chat requests.

Cross-object filament/blob association, polar direction, extensive PSF compensation, and a wholesale mesh redesign were deferred. Isotropic distance operations were accepted provisionally, with broader anisotropy review deferred; this does not negate the separately implemented coordinate-scaled filament PCA.

## How to retain the interview outcome

Use this handoff as temporary context. Keep persistent project rules short and separate from progress. If asked to produce a project-specific reusable skill, use the skill-creation workflow, distinguish general interview procedure from FARM facts, and link the skill to current project references instead of embedding a transcript. Do not copy the friend's Git identity, C++ preferences, or other personal instructions into Remi's setup.

The earlier skill review described CONTEXT.md and docs/adr formats. Inspect the actual skill before adopting them, reuse the established glossary, and avoid duplicate sources of truth. Record only consequential agreed decisions. Do not write proposed choices as accepted facts, and do not create or install a skill merely because this handoff mentions one.
