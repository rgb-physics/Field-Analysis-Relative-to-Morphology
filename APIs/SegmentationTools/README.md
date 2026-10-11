# SegmentationTools

SegmentationTools converts pixel-classification probabilities into masks and labels through binarization and cleanup. Ilastik is a common upstream source of probability fields, but it is not required for every segmentation route. Filaments can be segmented directly from bright-on-dark microscopy intensities with the historical Laplacian-of-Gaussian (LoG) method or from external probability fields.

Reusable algorithms and example workflows are separated in the proposed structure. Implementations are preserved without refactoring in this first-pass copy.

Probability arrays use `[Y X Z C]`; complete image structs use the project-wide `[Y X Z C T]` convention. The public in/on/out semantic order is `[inside wall outside]`. See `docs/SEGMENTATION_HISTORICAL_METHODS.md` for current behavior, historical alternatives, anisotropy notes, compatibility wrappers, and deferred work.
