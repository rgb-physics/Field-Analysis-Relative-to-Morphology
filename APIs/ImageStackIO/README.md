# ImageStackIO

ImageStackIO owns image-file loading and saving, stack inspection, axis normalization, and retained stack-transform helpers. The internal axis convention is `[Y X Z C T]`.

`farmWriteImageJAxesTiff` is a separate, explicit-axis ImageJ writer. Supply
`SourceAxes='YXC'` (or `[1 2 4]` with Y/X/Z/C/T mapped to 1/2/3/4/5),
`Spacing` in YXZ order, `SpacingUnit`, and optionally `Overwrite=true`.
It reuses native axis normalization and writes contiguous, uncompressed pixels
with TIFF directories after the pixels, so ImageJ headers and TIFF directories
describe the same stack. Arbitrary permutations/subsets of YXZCT including Y/X
are supported, as are XZ/YZ planes with the missing spatial axis singleton;
arbitrary new axis types are not. Classic TIFF files must remain
below 4 GB. Existing writers are unchanged. The dedicated regression file is
`tests/testFarmWriteImageJAxesTiff.m`; viewer verification is still required.

Grayscale multipage TIFFs without recognized axis metadata default to
`SourceAxes='YXZ'`, treating pages as Z slices. Explicit SourceAxes and
recognized TIFF/ImageJ axis metadata take precedence. Set SourceAxes='YXT'
for a metadata-free time stack. Single-page layouts remain YX (or YXC for
color); color page stacks still require explicit axes or recognized metadata.
SourceAxesSource records whether the default, metadata, or an option was used.

Image loaders return spatial calibration as `Spacing` in `[Y X Z]` order and `SpacingUnit` as text. Pass these values as loader options, for example `struct('Spacing', [0.2 0.2 0.5], 'SpacingUnit', 'um')`. `farmReadTiff` preserves embedded TIFF/ImageJ calibration when options are omitted; missing calibration defaults to `[1 1 1]` and `pixel`. `SpacingSource` records whether calibration came from options, TIFF/ImageJ metadata, or the default.

`farmWriteTiff` and `farmWriteImageJHyperstack` accept the same calibration fields in their options or in an input image struct. They write X/Y calibration as TIFF resolution tags and Z spacing plus the unit in the ImageJ description so FIJI can manage the spatial calibration.

The ND2 reader is planned but not implemented; its SDK dependency remains unresolved. Legacy writers/readers are preserved in the sibling MeMo-Archive. The five farm-prefixed stack-transform helpers retain the original array operations and use the current TIFF writer where needed. Outputs therefore use its pixel-type validation, metadata and default overwrite protection.
