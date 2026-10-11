# Shared test data

This directory contains immutable, repository-wide fixtures used by API tests and examples.

- `image-stacks/tiff/` contains TIFF and ImageJ TIFF fixtures.
- `image-stacks/hdf5/` contains HDF5 fixtures.

MATLAB tests should add the repository `tests` folder to the path and call:

```matlab
testDataRoot = memotest.dataRoot();
```

Tests must write generated files to a temporary folder rather than modifying these fixtures. Small, representative datasets should be preferred over complete microscopy acquisitions.

