# Local GaussDiff setup

GaussDiff supplies gfilter for blob-core skeleton generation. Other operations,
such as boundary profiles in exampleObjectInspection, do not require it.

This setup uses MATLAB R2023a and Image Processing Toolbox. Obtain an extracted
gaussdiff folder containing gfilter.m and gaussiankernel.m (MathWorks File Exchange
19696). Keep the provider's license information. FARM does not download or
redistribute these third-party source files.

From the repository root, replace the path below with your extracted folder:

```matlab
report = farmInstallGaussdiff('C:/downloads/gaussdiff');
```

The installer prints its steps, checks constant-field smoothing and derivatives,
and copies the required files unchanged into local-dependencies/GaussDiff. It also
copies LICENSE/COPYING files if present. Different existing source files are not
overwritten. The folder is ignored by Git. No add-ons are installed and no saved
MATLAB path or Python environment is changed.

For later MATLAB sessions, run farmSetup from the repository root. To repeat the
basic check without supplying a source folder:

```matlab
report = farmInstallGaussdiff;
```

These checks establish availability and simple numerical behavior, not complete
verification of the skeleton algorithm or compatibility with every provider version.
