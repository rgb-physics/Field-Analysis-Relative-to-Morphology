# Historical radial functions

Original generateRadialMatrix.m and radiallyAverageMatrix.m preserved before
the corrected implementations replaced them on 2026-10-13.
Original source package: APIs/FieldAnalysis/src/+fieldanalysis/+statistics.

Corrections: even-grid dimensions, fftshift origin for odd/even grids, one
output per bin, empty-bin NaN, and default inclusion of radius zero.
The legacy wrapper preserves Gaussian left-edge weighting.
No full historical experiment workflow is declared replaced.
