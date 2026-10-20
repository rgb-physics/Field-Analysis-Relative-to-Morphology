# Run all available automated checks

From the MeMo repository root in MATLAB:

```matlab
report = runAllTests;
```

The runner adds source/support paths, executes each of the twelve current matlab.unittest test files once, and then runs ImageStackIO fixture validation. It continues after test failures or suite setup/execution errors.
The ActiveFoamAlignment suite uses synthetic workflow 2 output tables to check
bin counts/variance, missing values, peak flags and equal-time averaging. It
does not require O: data or rerun filament extraction.

Inspect report.Summary, report.UnitResults and report.ImageStackIO. report.Passed is false if a test failed, remained incomplete or a suite could not execute. Failed and Incomplete counts can overlap in MATLAB; they should not be added to infer the number of distinct unsuccessful tests.

A fresh tests/data/workflow-results/all-tests_* directory holds report.mat, summary.csv and, when available, imagestackio.csv. Existing files and source datasets are not overwritten. Synthetic workflow tests also create their own fresh output folders.

ImageStackIO validation needs local tests/data/image-stacks/hdf5/*.h5 and at least two tests/data/image-stacks/tiff/xyz_chan*.tif files. Missing fixtures produce a suite execution error. To deliberately run only the synthetic/unit checks:

```matlab
report = runAllTests('IncludeImageStackIO',false);
```

For batch/CI use, save the report and then raise an error on unsuccessful checks:

```matlab
runAllTests('ThrowOnFailure',true);
```

Default ThrowOnFailure=false lets you inspect the returned report after failures.

Covered: SegmentationTools, ObjectGeometry, scalar/vector field sampling, ObjectTracking, FieldAnalysis, SharedUtilities, canonical numeric/visualization helpers, FARM naming/layout, workflow examples and configuration builders, plus ImageStackIO validation by default. The SharedUtilities regression runner is not invoked because its repeated API files are already included.

Not covered: manual visual validation scripts, real-data scientific comparisons, scalability benchmarks, deferred full VisualizationTools and SurfaceFieldMapping test suites. This runner collects existing coverage; it does not make the package fully scientifically validated.

MATLAB with the toolboxes/dependencies required by the individual suites is needed.
The most recent recorded full-suite run on October 15, 2026 passed 182 checks,
with no failures, incomplete checks or suite execution errors. See
[refactor progress](docs/REFACTOR-PROGRESS.md) for saved log locations and later
focused checks. This is recorded evidence for that revision, not a guarantee
that an edited checkout or another environment will pass.

