# ObjectGeometry tests

In MATLAB R2023a with Image Processing Toolbox:

```matlab
cd('C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo\APIs\ObjectGeometry\tests')
results=runObjectGeometryTests();
table(results)
```

The runner adds the required source paths and stores a diagnostic log at
`fullfile(tempdir,'ObjectGeometryTestDiagnostics.log')`. It errors after running
the suite if any test fails or is incomplete. These focused tests do not claim
scientific acceptance of real data or coverage of all historical prototypes.
They emphasize preserved identity under sorting/filtering/concatenation,
disconnected labels, selectable native properties, filament-axis conventions,
scaled PCA, gradient smoothing and sign-invariant nematic alignment.

Run `../examples/exploreObjectGeometry.m` for a real-data visual experiment.
The external gaussdiff dependency of skel3DBlobs is documented separately;
its Hessian behavior requires the later dedicated tests/examples agreed in
the design discussion.
