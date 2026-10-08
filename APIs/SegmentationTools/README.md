# SegmentationTools

SegmentationTools converts pixel-classification probabilities into masks and labels through binarization and cleanup. Ilastik commonly produces the upstream probability fields; this package handles downstream segmentation operations and does not replace the Ilastik classifier.

Reusable algorithms and example workflows are separated in the proposed structure. Implementations are preserved without refactoring in this first-pass copy.
