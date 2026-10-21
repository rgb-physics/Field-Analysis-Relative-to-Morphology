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
  tests/data/workflow-results/all-tests_tpf7c16015_8e39_4f0b_9e6b_a2e1becacfc5.
- After the approved skeleton cleanup correction: all 38 ObjectGeometry checks
  passed. The synthetic example's known field relation and display-point count,
  plus the local GaussDiff check, passed in the focused final run.
- Code Analyzer reports no syntax diagnostics for changed MATLAB files. Existing
  matrix-style advice in the historical ID-layer function is not a syntax error.
- Git whitespace checks passed. These runs are not real-data scientific or
  performance acceptance; those requirements remain outstanding.

Progress logs are under tests/data/workflow-results/refactor-validation, including
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
tests/data/workflow-results/refactor-validation/tiff-transform-checks.log.
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
Log: tests/data/workflow-results/refactor-validation/segmentation-cleanup-checks.log.

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
Log: tests/data/workflow-results/refactor-validation/segmentation-wrapper-checks.log.

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
Log: tests/data/workflow-results/refactor-validation/remaining-public-tests.log.
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
Log: tests/data/workflow-results/refactor-validation/field-on-objects-tests.log.

After the import and final statement-output preservation checks, the complete
suite passed 182 checks, with zero failures, incomplete checks or suite errors.
Log: tests/data/workflow-results/refactor-validation/remaining-public-final-tests.log.
MATLAB R2023a Code Analyzer found no syntax errors in the 133 reviewed functions,
the imported helper and ObjectGeometry tests. Advisory messages remain, including
array growth, unused values and old suppression comments. They were not treated
as permission to change historical behavior.
Analyzer log: tests/data/workflow-results/refactor-validation/remaining-public-analyzer.log.
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
Log: tests/data/workflow-results/refactor-validation/reference-pages-matlab.log.

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
Removed-folder log: tests/data/workflow-results/refactor-validation/removed-empty-folders.txt.
All four MATLAB layout/setup tests passed after cleanup. No empty folders remain
in the inspected package trees; excluded local-data/dependency/support trees
were not cleaned. Test log:
tests/data/workflow-results/refactor-validation/document-cleanup-layout.log.

## Workflow 1 rebuilt as an inspectable staged example

setupWorkflow1.m now separates source descriptions, current-frame loading,
probability segmentation/object measurement, geometry definition, and field
sampling. Its default is a small synthetic two-object example; the original
Experiment 4 paths, axes, frame selection, thresholds and calibration remain
available with useSynthetic=false. Figures are enabled by default, while saving
and batch execution are disabled. Intermediate arrays, objects, geometry,
supports, sampling tables and diagnostics remain in the workspace.

Moved the previous local batch implementation into farmWorkflow1Objects.m,
retaining existing named-source and older configuration paths. Added explicit
SaveGeometry/SaveSupports choices, optional pooled signed-distance ProfileEdges,
and per-frame progress with Verbose=true. Profile distances remain isotropic
voxel distances against the combined foreground; this does not implement
independent per-object profiles or choose population/ancestry reductions.

docs/WORKFLOW-1-STAGES.md documents the four stages, result access paths,
calibration/registration assumptions, rerun requirements and save/batch behavior.
Updated the walkthrough and related guides to match. No original scientific
implementation was edited as part of this workflow change.

Validation includes a synthetic staged-versus-batch comparison of known masks,
volumes, measurement/diagnostic values, units, per-frame metadata, saved geometry
and distance profiles. The initial full run passed 182 checks and exposed a new
test's incorrect expectation that combined-table metadata equals single-frame
metadata. The test now verifies the existing FrameMetadata wrapper separately
and compares saved frame tables exactly. The affected workflow/configuration
suites passed all 22 tests after that correction; see workflow1-stages-confirmed-tests.log.
The rest of the preceding full-suite run passed; the full suite was not repeated
after the test-only metadata expectation correction and final display adjustment.
Static analysis found no syntax errors; advisory messages concern editable
constant switches and historical diagnostic-list growth. Local document links
and Git whitespace checks passed. The synthetic display was also rendered to
workflow1-staged-preview.png under the ignored refactor-validation folder.

## Active Foam E5 alignment workflow — October 20, 2026

Added setupActiveFoamE5, farmActiveFoamE5Config, farmProcessActiveFoamE5 and
farmPlotActiveFoamAlignment under Examples and Workflows/examples. The setup
explicitly passes workflow 2 output to the plotting function; plotting can reuse
saved measurements without rereading microscopy sources. The guide is
docs/ACTIVE-FOAM-E5-ALIGNMENT.md.

Processed only E5 frames 25–30: six corrected 647 TIFFs and six segmentation
HDF5 fields under read-only O:/Session 88. Confirmed YXZ spacings are
[.55 .55 .7] um for images and [1.5 1.5 1.5] um for probabilities. Semantic
[inside,on/wall,outside] channels are [3,2,1]. The acquisition interval is 30 s;
elapsed plotting time is explicitly (Frame-25)*30 s, not absolute acquisition time.
Workflow 2 uses its existing detection settings; they were not tuned to match
the expected experimental narrative. Added optional stage progress messages only.

The run returned 49,876 detections; 36,557 have selected finite alignment/distance
values. Three lie outside plotted distance edges [-20,30] um. Rod-level means,
counts, sample variances and empty-bin NaNs are retained. SD shading describes
dispersion, not confidence in the mean. No structure-weighted or ancestry
aggregation was inferred. Order3D has isotropic expectation zero.

Count-qualified moving peaks are broad in all six frames. The fixed-window
representative distance is -7.5 um; the computational boundary remains at zero.
The initial interior band overlaps the fixed-peak band, explicitly documented.
Structural stages were not assigned from these six frames. The four synthetic
alignment tests passed and new files passed standalone R2023a syntax analysis.

Actual results after the concurrent repository-folder migration are under
tests/data/workflow-results/active-foam-E5-frames025-030/
active-foam-E5_tp71912f48_fd21_4623_8afd_18cb2372ef62.
Final plots and CSV/MAT summaries are in alignment-plots-final. Older saved
directory metadata records the pre-migration test-data location; the plotting
setup resolves its output path from the current saved-file location.
Logs and per-frame checkpoints are retained. Source files on O: were not modified.

Final regression verification in a fresh MATLAB session passed **188 checks**,
with zero failed/incomplete checks or suite execution errors. An earlier run
started during the folder migration had stale test-data paths on its MATLAB
search path; its results were superseded by this clean-session run. The existing
setup now excludes saved data/source snapshots from the test path.
Log: tests/data/workflow-results/refactor-validation/active-foam-E5-clean-session-tests.log.
Standalone analysis of all five new E5 MATLAB files reports no diagnostics.

### Glossary wording guidance (2026-10-20)
Updated Configuration using the user-approved wording. Future glossary edits should define the entry itself in everyday language, explain named settings with concrete examples, and distinguish a construct's contents from function inputs and generated results. Describe constructs as existing independently of their later use. Name the relevant function explicitly when directing readers to field requirements; avoid unexplained phrases such as receiving function. Review Experiment, Boundary, and Descendants with the user before extending this wording pass. The full glossary wording review remains pending.

### Glossary and Data Dictionary wording pass (2026-10-20)
Applied the agreed plain-language style to the 107 existing entries. Inputs now appears at the bottom of each entry in source, topic pages, and MATLAB display. Stored/generated field lists are retained under Contents rather than presented as user inputs. Concepts without fixed arguments say so; Data Dictionary inputs describe the sampled values or geometry used. Checked the boundary and lineage-selection signatures and documented that descendant selection requires Direction='descendants'. Updated the lookup guide and existing tests for descriptive input text. No scientific calculations or new inventory entries were added. This completes the wording pass noted above; a full function-specific input inventory remains deferred.
### E5 public-API stages and Workflows API (2026-10-20)

Moved farmMakeExperiment and farmLoadSource into APIs/Workflows/src without changing their interfaces or loading/calibration behavior. Updated setup paths, active directory documentation, and the two existing inventory path records; no full inventory was undertaken.

Replaced setupActiveFoamE5's processing-helper call with visible loading, segmentation, filament measurement, boundary geometry, distance-gradient, centroid-support, field-query, alignment, and save operations. Settings are included in the script; the separate configuration function is optional. Package field-query functions sample single-voxel centroid supports and retain diagnostics separately. An explicit cast preserves the existing BoundaryDistance numeric type. Missing files are reported and skipped. O: inputs remain read only. Results and logs use fresh ignored local run directories. The current frame's arrays remain available for inspection; arrays from all frames are not accumulated.

Improved help and task comments in farmPrepareSupport, farmQueryField, farmQueryVectorField, farmMakeExperiment, and farmLoadSource. Historical calculation implementations were not edited. No previews are run automatically. The existing peak/plot example remains optional and disabled by default.

Validation: all 191 available automated checks passed with no failures, incomplete checks, or suite errors. The new integration check executes the script's actual processing section on small synthetic TIFF/HDF5 files with anisotropic spacing and a coarser probability grid. Measurements, column names and numeric types match the unchanged Workflow 2 path, and a missing second frame is skipped. No real E5 images were loaded during this refactor. Log: tests/data/workflow-results/refactor-validation/E5-public-api-full-tests.log. Combined report: tests/data/workflow-results/all-tests_tp9463e26d_36b3_474e_a771_57e63e17e9cc.

Pending user discussion: general analysis and visualization functions, including field displays, mean/variance field displays, contours, table-column plots, and their relationship to existing calculation APIs. Do not introduce or restructure those interfaces as part of this staged-script change.
### E5 processing choices moved into configuration (2026-10-20)

Moved the requested filament-property list and boundary dilation radius out of the processing loop in setupActiveFoamE5. Reviewed the remaining stages and exposed the fixed segmentation method, extent width floor, isotropic working spacing, interpolation methods, gradient derivative units, scalar/vector sampling statistics, and projected alignment plane alongside their related settings. Updated the optional farmActiveFoamE5Config with the same fields. Kept calculated arrays, per-frame identities, and assembly of API argument structs in the loop. Defaults and scientific calculations are unchanged; comments identify properties/statistics required by subsequent stages.
### E5 individual-stage teaching functions (2026-10-20)

Added Examples and Workflows/examples/activeFoamE5Stages with eight functions for loading, segmentation, filament detection/measurement, boundary geometry, distance-gradient directions, field sampling, alignment, and saving. Every function accepts and returns only c, as requested. Existing settings remain at the root; per-frame intermediates are stored in c.Results. Help comments enumerate relevant configuration fields, preceding results, and returned fields. The existing combined script remains intact for comparison.

The folder also contains a guide and a script calling all eight stages across c.Frames using farmActiveFoamE5Config. c.Frame selects the current acquisition; c.RunDirectory holds the new local save directory. Loading a frame clears prior per-frame results. No try/catch, previews, or analysis/visualization interfaces were added. The first seven functions perform calculations without saving files; the eighth saves measurement tables and metadata and refuses to overwrite a frame file. The driver writes combined Workflow 2 observations and a progress log. Local test outputs remain ignored by Git.

Validation: all five E5 tests passed. The expanded integration test compares intermediate distance fields, centroid supports, sampling diagnostics, and measurement values/types with the combined workflow using anisotropic synthetic TIFF/HDF5 data. It also runs the new multi-frame example on those synthetic files, checks missing-frame handling, verifies stale results are cleared on load, and verifies output overwrite protection. All nine new MATLAB files passed Code Analyzer. No real E5 sources were read. Test log: tests/data/workflow-results/refactor-validation/E5-individual-stages-tests.log. General analysis and visualization work remains deferred for user discussion.
### Per-frame E5 stage timings (2026-10-20)

Both the combined setup and separate-stage example script now record one timing row per requested frame. TotalSeconds is first, Frame is second, and eight named stage-duration columns follow, with Completed last. Totals sum the measured stages; configuration, timing-file writes, combined-output writes, and other driver work are excluded. Skipped frames retain their loading duration, NaN for unrun stages, and Completed=false. Each script updates stage-timings.csv and stage-timings.mat after completed or skipped frames and includes the final table in Workflow2.StageTimings. The modular script also exposes c.StageTimings. Individual teaching-function bodies remain unchanged; timing wraps their calls in the driver.

All five E5 tests passed, including checks of column order, frame rows, nonnegative stage durations, exact row sums, skipped-frame NaNs/flags, and saved MAT/CSV files for both implementations. Both scripts passed Code Analyzer. No real E5 data was processed. Log: tests/data/workflow-results/refactor-validation/E5-stage-timing-tests.log.
### FillMethod for probability-channel segmentation (2026-10-20)

Added FillMethod to farmSmoothNChannelProbabilities with default 'none', single-transform 'nearest', and highest-precedence 'fill'. Filling runs after opening and overlap resolution and preserves existing assignments. Nearest uses bwdist's nearest-index output, voxel-coordinate Euclidean distance, and MATLAB's tie choice. No transform runs for the other modes or for fully classified volumes. ReturnOpenedMasks still returns the pre-resolution/pre-fill intermediate. Added FillMethod, UnclassifiedVoxelCountBeforeFill, and FilledVoxelCount diagnostics; existing final counts describe final masks. Kept the help header compact with option names/types and detailed descriptions at the bottom.

Exposed c.FillMethod='none' in the E5 config and combined setup and passed it through the separate segmentation stage and earlier region helper. Historical calculation implementations were not edited. Default mask assignments remain unchanged.

Validation: all 29 SegmentationTools tests and 10 configuration tests passed, including four new tests for nearest 2-D/3-D assignments and MATLAB ties, precedence-based fill, filling after opening, preserved assignments/diagnostics, and unchanged default-none behavior. The broader E5 integration test reached a draft plotting section appended to setupActiveFoamE5Stages and failed at heatmap() without arguments; this user-edited section was left unchanged. Earlier comparisons in that test passed. Code Analyzer and whitespace checks passed for the changed calculation function.

Read-only timing measurement on frame 25's 3,267,000-voxel probability grid, threshold 0.6 and opening radius 1: three measured repetitions after warm-up gave median total function times 0.16309 s ('none'), 0.29138 s ('nearest'), and 0.13567 s ('fill'). Both filling modes assigned 305,790 voxels with zero unclassified locations left. Loading was excluded; no filament detection or full workflow was rerun. Timings are machine/run-specific. Results: tests/data/workflow-results/refactor-validation/FillMethod-benchmark.csv and .mat; log: FillMethod-benchmark.log in the same ignored folder.
