# FARM naming and archive migration

The release uses ordinary MATLAB folders and descriptive `farm` function names.
The repository folder can remain MeMo; renaming it is unnecessary.

```matlab
cd('path-to-MeMo')
farmSetup('IncludeExamples', true)
source = farmMakeSource('Folder', 'path-to-images', 'NamePattern', 't%03i.tif');
entry = farmGlossary("Experiment");
report = runAllTests;
```

`farmSetup` adds all API source subfolders and Workflows/src for this session.
Examples and tests are opt-in. It does not add datasets, archives or private
folders, and does not call savepath. Restart MATLAB, or remove old MeMo source
paths, before using the migrated tree if you previously saved package paths.
Do not add MeMo-Archive to the release path: archived files intentionally retain
their historical names and dependencies.

| Before | After |
| --- | --- |
| imagestackio.readTiff | farmReadTiff |
| imagestackio.config.makeSource | farmMakeSource |
| objectgeometry.objects.measureObjects | farmMeasureObjects |
| objectgeometry.centerlines.measureFilaments | farmMeasureFilaments |
| fieldSampling.queryFrame | farmQueryFrame |
| fieldanalysis.fourier.powerSpectrum2D | farmPowerSpectrum2D |
| glossary | farmGlossary |

The exact map is [FARM-FUNCTION-NAMES.json](FARM-FUNCTION-NAMES.json).
The [file manifest](FARM-MIGRATION-MANIFEST.csv) records original locations,
archive decisions and retained destinations. `setupWorkflow1` through
`setupWorkflow5`, `setupWorkflow2Staged`, and test runners retain familiar entry
names. Numbered workflow functions are now `farmWorkflow1Objects`, etc.
Internal options helpers are `farmFAOptions`, `farmOGOptions` and `farmSUOptions`,
all accepting `(userOptions, defaults)`. The general configurable builders keep
their own documented public signatures.

The sibling `../MeMo-Archive` mirrors archived files' original relative paths,
including the original NAMESPACE-NAMING-CONFLICTS-TREE.md. Its snapshots directory
also holds a verified pre-migration copy of every code/document file touched by
the migration. Image data, .git and local MathWorks preferences were excluded.
The archive is a folder; it is not separately initialized or pushed as a Git repository.

Archived: historical experiment workflows and API-embedded scripts, dated
archive/legacy folders, original Python workflow, redundant aliases and old
planning trees. Retained: original algorithms used by current APIs, reusable
mesh functions, the modern Python bridge, editable numbered workflows and tests.
The five retained TIFF transforms use farmWriteTiff where an old writer was
needed; this adds current writer validation/metadata and overwrite protection.
farmGetDistGrads now reads HDF5 through farmReadH5 with historical CXYZ source
axes explicit. Tests check that axis permutation.

The package's field names, coordinate conventions, algorithm choices and existing
error identifiers are retained. Known external dependencies such as gfilter
(gaussdiff), trackpy and mesh tools remain separate; this migration does not
implement them. Historical scripts may require their original environment and
are not claimed to be standalone runnable examples in the archive.

Run `report = runAllTests` in your licensed MATLAB session. Use
`runAllTests('IncludeImageStackIO', false)` when local TIFF/HDF5 fixtures are
unavailable. The naming/layout regression suite checks path resolution,
canonical options order, ordinary folders and synthetic HDF5 axis preservation.
