# ImageStackIO

ImageStackIO owns image-file loading and saving, stack inspection, axis normalization, and legacy stack I/O implementations. The internal axis convention is `[Y X Z C T]`.

Image loaders return spatial calibration as `Spacing` in `[Y X Z]` order and `SpacingUnit` as text. Pass these values as loader options, for example `struct('Spacing', [0.2 0.2 0.5], 'SpacingUnit', 'um')`. `readTiff` preserves embedded TIFF/ImageJ calibration when options are omitted; missing calibration defaults to `[1 1 1]` and `pixel`. `SpacingSource` records whether calibration came from options, TIFF/ImageJ metadata, or the default.

`writeTiff` and `writeImageJHyperstack` accept the same calibration fields in their options or in an input image struct. They write X/Y calibration as TIFF resolution tags and Z spacing plus the unit in the ImageJ description so FIJI can manage the spatial calibration.

The ND2 reader is planned but not implemented; its SDK dependency remains unresolved. Existing implementations are preserved without refactoring in this first-pass copy.
