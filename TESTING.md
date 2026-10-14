# Run all available automated checks

From the MeMo repository root in MATLAB:

```matlab
report = runAllTests;
```

The runner adds source/support paths, executes each of the ten current matlab.unittest test files once, and then runs ImageStackIO fixture validation. It continues after test failures or suite setup/execution errors.

Inspect report.Summary, report.UnitResults and report.ImageStackIO. report.Passed is false if a test failed, remained incomplete or a suite could not execute. Failed and Incomplete counts can overlap in MATLAB; they should not be added to infer the number of distinct unsuccessful tests.

A fresh test-data/workflow-results/all-tests_* directory holds report.mat, summary.csv and, when available, imagestackio.csv. Existing files and source datasets are not overwritten. Synthetic workflow tests also create their own fresh output folders.

ImageStackIO validation needs local test-data/image-stacks/hdf5/*.h5 and at least two test-data/image-stacks/tiff/xyz_chan*.tif files. Missing fixtures produce a suite execution error. To deliberately run only the synthetic/unit checks:

```matlab
report = runAllTests('IncludeImageStackIO',false);
```

For batch/CI use, save the report and then raise an error on unsuccessful checks:

```matlab
runAllTests('ThrowOnFailure',true);
```

Default ThrowOnFailure=false lets you inspect the returned report after failures.

Covered: SegmentationTools, ObjectGeometry, scalar/vector field sampling, ObjectTracking, FieldAnalysis, SharedUtilities, ownership/visualization compatibility, workflow examples and configuration builders, plus ImageStackIO validation by default. The SharedUtilities regression runner is not invoked because its repeated API files are already included.

Not covered: manual visual validation scripts, real-data scientific comparisons, scalability benchmarks, deferred full VisualizationTools and SurfaceFieldMapping test suites. This runner collects existing coverage; it does not make the package fully scientifically validated.

MATLAB with the toolboxes/dependencies required by the individual suites is needed. This runner has been statically checked; execution must be confirmed in a licensed MATLAB session.

