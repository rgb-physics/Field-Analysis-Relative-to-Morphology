# Refactor progress

October 15, 2026. Work is in progress; this is not a claim that the entire suite
now meets every release convention. The approved release scope and deferred areas
remain in FIRST-RELEASE-SCOPE.md and FIRST-RELEASE-PLAN.md.

## First group implemented

Expanded control flow and clarified Inputs/Outputs, examples and operation notes:

- farmSetup, farmMakeSource, farmMakeExperiment and farmLoadSource.
- farmMakeObjectOptions, farmMakeQuery, farmMakeIntensityOptions and
  farmMakeProbabilityOptions.
- farmQueryFrame and farmRunFieldBatch.

farmRunFieldBatch now accepts Verbose=false by default. When requested, it prints
the current frame/index, processing, saving and completion. A regression test checks
logged frame order, known saved values, identities and existing-file protection.

The user separately approved formatting/help-only edits to farmSignedBWDist,
farmReturnSmoothBoundsBW, farmReturnSmoothBoundsIDed, farmReturnSmoothBound,
farmSkel3DBlobs, farmLOG, farmGaussD and farmMyconvn. Expressions were compared with
HEAD after removing comments/layout/separators; all matched. Attribution/license
blocks are preserved. Numerical implementations remain unchanged in these eight files.

After investigation and separate user agreement, farmSkel3DClean now allocates
zeros(size(inputMat)) instead of zeros(size(binSegs)), where binSegs was undefined.
The regression case preserves a connected 20-voxel component, removes three
singletons, and checks output dimensions/type. No selection formula was changed.

## Example and dependency setup

exampleObjectInspection is a synthetic, file-free example with editable settings,
stopping points, accessible geometry/query/profile results and display-only 3D
subsampling. Its comments explain stale downstream results and limitations of
resuming inside a batch loader/query. Source images are not modified.

farmInstallGaussdiff checks a supplied extracted provider folder, installs unchanged
required sources under ignored local-dependencies/GaussDiff, protects differing files
and prints each step. It does not download or redistribute the provider. farmSetup
adds that specific local folder for this session. See LOCAL-DEPENDENCY-SETUP.md.
The user's existing GaussDiff copy was installed locally and checked twice.

README and configuration documentation now describe TIFF/HDF5 support, deferred
ND2/mesh areas, the local dependency setup and the current farmMakeClasses entry.

## Verification

- First full licensed MATLAB R2023a run: 178 passed, zero failed/incomplete.
- Full run after the progress regression and approved historical help edits:
  179 passed, zero failed/incomplete. Report directory:
  test-data/workflow-results/all-tests_tpf7c16015_8e39_4f0b_9e6b_a2e1becacfc5.
- After the approved skeleton cleanup correction: all 38 ObjectGeometry checks
  passed. The synthetic example's known field relation and display-point count,
  plus the local GaussDiff check, passed in the focused final run.
- Code Analyzer reports no syntax diagnostics for changed MATLAB files. Existing
  matrix-style advice in the historical ID-layer function is not a syntax error.
- Git whitespace checks passed. These runs are not real-data scientific or
  performance acceptance; those requirements remain outstanding.

Progress logs are under test-data/workflow-results/refactor-validation, including
final-validation.log, focused-final-checks.log and gaussdiff-installation.log.

## TIFF transform group completed after user agreement

Completed formatting/help-only changes to these five retained ImageStackIO transforms:

| Function | Clarifications to document without changing behavior |
| --- | --- |
| farmCropTiffSave | XY[Z] crop arguments versus YXZ indexing; optional write conditions |
| farmExtend2DTiffAlongZ | Replication count and optional TIFF writing |
| farmGetLayersOverTimeFrom3DTif | Actually selects specified pages of one TIFF despite its historical name; output is uint16 |
| farmGetTotIntOver3DTiffs | Filename/frame selection and sum of double-converted voxel intensities |
| farmSplit3Dto2D | Selected slice exports; historical declared outputs are not assigned; no interface or overwrite-policy change in this proposal |

All five are under APIs/ImageStackIO/src/imagestackio/transforms. Preserve array
operations, public signatures, save conditions, attribution and current I/O choices.
Executable expressions match HEAD after comments/layout/separators are removed.
All 16 ImageStackIO validation checks passed, including synthetic transform and
round-trip checks. The progress log is
test-data/workflow-results/refactor-validation/tiff-transform-checks.log.
Code Analyzer reports no syntax diagnostics; existing unassigned-output and
exist-style messages in farmSplit3Dto2D are preserved. Git whitespace checks pass.
Any behavioral correction still requires separate discussion.

## Segmentation cleanup group completed after user agreement

Completed formatting/help-only changes to the following SegmentationTools cleanup
functions, preserving all formulas, thresholds, connectivity, padding, ID collision
rules, defaults, outputs and error identifiers:

- farmSidesHoleFill: explain axis permutation, padding and side-hole limitations.
- farmReturnSmoothBlobsBW: distinguish a thresholded interior from a boundary layer.
- farmReturnSmoothBlobsIDed: explain fast/slow ID assignment and overlapping selections.
- farmRemoveConObjs: explain largest-component selection versus component indices.

These functions are under APIs/SegmentationTools/src/segmentationtools/cleanup.
All four executable bodies match HEAD after removing comments/layout/separators.
All 25 SegmentationTools tests passed. The existing 2D transpose behavior of
farmSidesHoleFill was also checked and documented, not corrected. Code Analyzer
reports no diagnostics for these four files, and Git whitespace checks pass.
Log: test-data/workflow-results/refactor-validation/segmentation-cleanup-checks.log.

## Segmentation wrappers and planar filling completed after user agreement

Completed formatting/help-only changes to these three retained functions:

- farmH5toSmooth3Chans: document its historical channel/threshold/output order
  versus the current inside/wall/outside wrapper. It accepts an array, not a file.
- farmImbinarize3_4D: explain fourth-dimension thresholding, threshold-vector
  repetition and logical output, preserving the existing threshold behavior.
- farmFlatFill3D: document its 0/1/2 viewing-axis convention and union of fills
  calculated independently from the original mask.

The first two are under APIs/SegmentationTools/src/segmentationtools/binarization;
the third is under its cleanup folder. Preserve signatures, defaults, formulas,
channel/axis mappings, thresholds, outputs, validation and error identifiers.
Executable expressions match HEAD after removing comments/layout/separators.
All 25 SegmentationTools tests passed, including added known-answer assertions
for planar holes in XZ and YZ. Code Analyzer reports no diagnostics for the
three functions and test file; Git whitespace checks passed.

The old farmFlatFill3D help reversed the names of selectors 1 and 2. Tests confirm
the code uses 0=XY, 1=XZ and 2=YZ with YXZ arrays. Corrected the help, matching
example comment and historical-methods guide, without changing the calculation.
Log: test-data/workflow-results/refactor-validation/segmentation-wrapper-checks.log.

## Remaining public-function formatting/help pass

The user approved formatting/help-only edits to the 71 historical or adapted
functions listed in REMAINING-PUBLIC-REFACTOR.md. Those and the 62 remaining
modern functions have now received this pass: expanded statements, consistent
spacing, input/output help, and behavior notes checked against implementations.
Saved pre-pass copies were used to compare executable tokens for all 133.
Original redundant parentheses and statement echo behavior were retained.
This is a formatting/help review, not proof of scientific correctness or complete
conformance to every example and documentation requirement.

The full suite passed 180 checks before the subsequent helper import below.
Log: test-data/workflow-results/refactor-validation/remaining-public-tests.log.
PUBLIC-FUNCTION-REVIEW.csv records the reviewed functions separately from
internal dependencies and deferred/excluded functions.

## Supplied fieldOnObjs imported with user agreement

Added farmFieldOnObjs under ObjectGeometry/representation and updated the
historical farmCoords2Mat_2DFils caller to use it. The source supplied by the user
was fieldOnObjs.m from their aLENS Analysis/Functions folder. Its calculations,
input/output order, double output allocation and attribution are preserved.
The help explains column-major sample ordering, zero background and last-value
assignment at overlapping indices. No averaging or index reordering was added.
Two new test procedures cover unequal sample counts, output dimensions/type,
unchanged index/selection outputs, overlap, empty input and the endpoint caller.
All 40 ObjectGeometry tests passed.
Log: test-data/workflow-results/refactor-validation/field-on-objects-tests.log.

After the import and final statement-output preservation checks, the complete
suite passed 182 checks, with zero failures, incomplete checks or suite errors.
Log: test-data/workflow-results/refactor-validation/remaining-public-final-tests.log.
MATLAB R2023a Code Analyzer found no syntax errors in the 133 reviewed functions,
the imported helper and ObjectGeometry tests. Advisory messages remain, including
array growth, unused values and old suppression comments. They were not treated
as permission to change historical behavior.
Analyzer log: test-data/workflow-results/refactor-validation/remaining-public-analyzer.log.
Git whitespace checks passed. Full VisualizationTools/SurfaceFieldMapping suites,
manual visual checks, real-data validation and performance benchmarks are not
covered by this result.

## Still outstanding

Additional examples and confirmation of the conservative public-operation
inventory still need attention. Historical
behavior issues documented during review require separate decisions before fixes.
Python setup/integration, real-data checks and performance measurements remain.
Mesh/sheets, ND2 and the two historical estimators remain deferred; munkres-backed
farmSingleTimePointTrajGen remains outside the supported public interface.

## Current reference pages and deferred inventory

The user chose to complete topic pages for the existing glossary/Data Dictionary
and defer the full public-function/test inventory until remaining functionality
has been evaluated. The earlier 213-file lists remain planning/review records,
not a completed public-operation or assertion-coverage inventory. No new
function/test inventory is generated by the documentation builder.

The reference starts at docs/reference/README.md, with ten scientific topic
pages, an alphabetical index and a generated entry-location CSV. All 107 source
entries have one topic-page location, including the ten existing sampling
diagnostics. Concepts and quantities retain Glossary/DataDictionary labels;
defined FARM roles are marked as constructs, separately from container type.
Input layouts, MATLAB lookup commands, interpretation notes and diagnostic
column access are expandable. Definitions, types and layouts remain in
GLOSSARY-CAPABILITIES-MOCKUP.md; MATLAB reads that source without a build step.

tools/build_reference.py rebuilds only these documentation views. It uses the
Python standard library and validates freshness, local links/anchors, unique
entry placement and balanced details/code blocks. The earlier unverified
inventory-generator draft is retained locally under ignored validation outputs;
it is not part of the active builder or a completed deliverable.

Verification completed: the documentation rebuild and freshness/link checks
passed for 13 generated files. MATLAB R2023a passed all 23 SharedUtilities
tests, matched all 107 entry names/types/sections/groups against the generated
entry map, and executed all 118 MATLAB blocks in the topic pages. The diagnostic
example returned the stated mean, finite count, selected count and nonfinite
counts. No analysis implementation or MATLAB glossary schema/display changed.
Log: test-data/workflow-results/refactor-validation/reference-pages-matlab.log.

## Documentation and empty-folder cleanup

Moved eleven superseded documents plus the old source-tree snapshot into
docs/history, retaining annotated versions and the old candidate-scan CSV.
The history index explains each document's previous location and status;
individual documents are marked as historical snapshots. Current scientific
decisions, conventions, implementation notes and reference definitions remain
in the active documentation. The full function/test inventory is still deferred.

Updated the user-guide navigation, archived-document links and handoff paths.
Replaced the stale full-tree listing with a concise current directory guide.
Removed 56 confirmed-empty folders, including obsolete +namespace directories,
empty in-package archive folders and an empty Python cache. Removal was
nonrecursive and checked for emptiness immediately beforehand. Local datasets,
generated results, installed dependencies, MATLAB support files and Git metadata
were excluded. No MATLAB/Python implementation files were changed by this cleanup.

Active Markdown local-file links resolve; historical snapshots can retain stale
source-evidence paths. The glossary generator's check passed for all 13 generated
files and 107 entries. Git whitespace checks passed.
Removed-folder log: test-data/workflow-results/refactor-validation/removed-empty-folders.txt.
All four MATLAB layout/setup tests passed after cleanup. No empty folders remain
in the inspected package trees; excluded local-data/dependency/support trees
were not cleaned. Test log:
test-data/workflow-results/refactor-validation/document-cleanup-layout.log.
