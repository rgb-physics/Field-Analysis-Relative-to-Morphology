# ImageStackIO tests

Run the comprehensive validation from MATLAB with:

```matlab
results = runImageStackIOValidation;
```

The runner discovers the three source datasets in this folder, exercises
the public API and compatible legacy utilities, prints every result, and
removes its temporary output files after completion. Shared TIFF and HDF5
fixtures are resolved through `farmTestDataRoot` from the repository-level
`tests/data` directory.
