# SegmentationTools test handoff

Date: 2026-10-10
Repository: `rgb-physics/Field-Analysis-Relative-to-Morphology` (FARM)
Target MATLAB release: R2023a

This handoff is for continuing validation on a machine with MATLAB. It covers
the SegmentationTools API. The active-contour folder is intentionally excluded
from the complete automated suite.

## 1. Update and locate the repository

Use the dedicated FARM checkout, not the private PhD archive. From PowerShell:

```powershell
cd <path-to-Field-Analysis-Relative-to-Morphology>
git status
git pull
```

Do not discard local changes if `git status` is not clean. Resolve or preserve
them before pulling. In MATLAB, define the repository root using the actual
path on that machine:

```matlab
repositoryRoot = "C:\path\to\Field-Analysis-Relative-to-Morphology";
```

The checkout folder may have an older local name; confirm it is the FARM repo
with `git remote -v`.

## 2. Requirements

- MATLAB R2023a
- Image Processing Toolbox
- Signal Processing Toolbox for automatic sheet split tests (`findpeaks`)
- Write access to the repository test folder for the diagnostic log
- Write access to the system temporary directory for generated TIFF fixtures

Check the installation in MATLAB:

```matlab
version
ver
license('test','image_toolbox')
license('test','signal_toolbox')
```

The two `license` calls should return `1`.

## 3. Run the complete SegmentationTools suite

```matlab
testsDirectory = fullfile(repositoryRoot,'APIs','SegmentationTools','tests');
cd(testsDirectory)
results = runSegmentationToolsTests();
table(results)
```

Expected scope:

- 18 test procedures
- All 20 `.m` source files outside `activeContours` represented
- No failed or incomplete results
- Summary: `18 passed, 0 failed, 0 incomplete`

The suite covers:

- Class construction, strict thresholds, summed channels, and unioned channels
- Arbitrary channel classification and semantic inside/wall/outside wrapping
- Tie resolution, unclassified voxels, optional masks, and label volumes
- Historical `farmH5toSmooth3Chans` compatibility
- Class-label remapping and legacy `farmImbinarize3_4D`
- Planar filling, side-hole filling, component retention, and signed-distance
  cleanup for binary and ID-labeled volumes
- Mask TIFF and ImageJ hyperstack round trips
- Explicit time selection and explicit `TimeAsChannels` reinterpretation
- Central-slice detection, surface-hole interpolation, and both two-sheet
  separation implementations

The manifest test intentionally fails if source files outside active contours
have been added without corresponding test coverage.

Detailed output is written to:

```text
APIs/SegmentationTools/tests/SegmentationToolsTestDiagnostics.log
```

The log is generated output and should not be committed unless specifically
needed for an issue report.

## 4. Run the focused in/on/out comparison

The complete suite checks invariants. The focused validation also produces
TIFFs for visual assessment:

```matlab
cd(testsDirectory)
report = farmValidateInOnOutImplementations();
report.OutputDirectory
```

Default output:

```matlab
fullfile(tempdir,'FARM-SegmentationTools-in-on-out')
```

Inspect these files in MATLAB or FIJI:

- `input_probabilities_YXZC.tif`
- `generalized_class_labels.tif`
- `generalized_masks_YXZC.tif`
- `historical_masks_YXZC.tif`
- `diagnostics_overlap_unclassified_changed.tif`

Confirm that:

1. IDs 1, 2, and 3 correspond to inside, wall, and outside.
2. Generalized output masks do not overlap.
3. Voxels below every selected threshold remain label 0.
4. The overlap diagnostic marks candidate conflicts before resolution.
5. Exact score ties select the first class definition.
6. Historical and generalized results may differ because the historical method
   applies per-class morphological opening and does not enforce the same final
   disjoint policy.

## 5. Evaluate a real probability file

For a `[Y X Z C]` ImageJ TIFF:

```matlab
opts = struct();
opts.InputFile = "C:\path\to\probabilities.tif";
opts.Channels = [1 3 2];             % [inside wall outside] in this file
opts.Thresholds = [0.2 0.5 0.5];
opts.OutputDirectory = fullfile(tempdir,'FARM-real-in-on-out');
report = farmValidateInOnOutImplementations(opts);
```

For HDF5:

```matlab
opts.InputFile = "C:\path\to\probabilities.h5";
opts.DatasetPath = "/exported_data";
opts.ReadOptions = struct('SourceAxes','CYXZ'); % only if metadata is absent
report = farmValidateInOnOutImplementations(opts);
```

Use the axis order that actually describes the file. HDF5 and TIFF data are
normalized through ImageStackIO before segmentation.

For a TIFF whose metadata describes `[Y X Z T]`, select a time point normally:

```matlab
opts.ReadOptions = struct('TimeIndex',1);
```

Set the following only when the time pages truly encode probability classes:

```matlab
opts.ReadOptions = struct('TimeAsChannels',true);
```

Time and class channels are never interchanged silently.

## 6. How to assess failures

For each failed test, record:

- Test procedure name
- Full MATLAB diagnostic and stack trace
- MATLAB release and installed toolbox versions
- Operating system
- Whether the failure occurs with synthetic data, real data, or both
- For real files: array size, class, source axes, spacing, and relevant metadata
- Visual screenshots or representative slices when the numerical output runs
  but appears scientifically wrong

Do not immediately weaken an assertion. First determine whether the cause is:

1. A test assumption that does not match the documented historical behavior.
2. A MATLAB release or toolbox difference.
3. An ImageStackIO metadata/axis-order problem.
4. A genuine implementation defect.
5. A scientifically unresolved policy, such as the one-sided historical
   signed-distance cleanup or future sheet-fragment reassignment.

The historical algorithms and currently deferred decisions are recorded in:

```text
docs/SEGMENTATION_HISTORICAL_METHODS.md
docs/SEGMENTATION_WORKFLOW_EXTRACTION_REVIEW.md
```

## 7. Return results to this account

Send back:

- The final summary line from `runSegmentationToolsTests`
- `SegmentationToolsTestDiagnostics.log` if anything fails
- The displayed `report` from the focused validation
- Your visual notes for the five generated TIFFs
- Any real-data file dimensions and axis metadata used

Do not commit generated TIFFs or the diagnostic log yet. Real data will be
selected jointly for future `test-data` and examples after the first manual
comparison.
