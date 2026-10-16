> Historical snapshot, retained October 15, 2026. Read the [current user guide](../README.md) and [history index](README.md) before following these older notes.

# FARM migration validation — 2026-10-15

The ordinary-folder migration was checked with MATLAB R2023a's standalone
Code Analyzer across all 268 retained MATLAB files. No syntax diagnostics were
reported. Existing style, allocation and historical-code warnings remain;
Code Analyzer does not establish numerical correctness.

Additional static checks passed:

- 253 top-level function definitions match their filenames.
- All MATLAB filenames are unique, including scripts, ignoring case.
- API source files use farm-prefixed names and no + folders remain in code.
- No executable calls to the former package namespaces remain.
- Referenced farm functions resolve to retained functions or local helpers;
  private helpers are only called from their permitted folder scope.
- The SegmentationTools coverage manifest matches its retained source files.
- Every destination in the migration manifest exists.
- 314 archived originals match their pre-migration snapshot bytes.
- Git's whitespace check passes.

The four Python bridge contract tests passed. These use a fake linker and
verify the bridge contract; they do not validate Trackpy's tracking algorithm.

The full MATLAB test suite could not execute in this agent's environment:
MATLAB returned License Manager Error -9 (username/license mismatch). Run
the following in your licensed MATLAB session from the MeMo folder:

```matlab
farmSetup('IncludeExamples', true)
report = runAllTests;
```

The combined runner includes the new testFarmLayout suite: ordinary source
folders and unique names, public function lookup, consistent options-helper
argument order, and a synthetic HDF5 channel/axis regression. The synthetic
workflow tests continue to exercise the numbered setups' local implementations.
Retired alias comparisons were replaced with canonical expected-result checks.

ImageStackIO's fixture runner retains modern I/O and stack-transform coverage;
retired writer checks are preserved with the original runner in MeMo-Archive.
A synthetic HDF5 mapping check also runs without external fixtures.

Original scientific algorithms were retained. Intentional implementation
adaptations are documented in the [migration guide](../FARM-NAMING-MIGRATION.md):
consistent options order, explicit historical HDF5 axes, and the current TIFF
writer for retained transforms. Source datasets, Git history and local MATLAB
preferences were excluded from the archive/migration operations.
