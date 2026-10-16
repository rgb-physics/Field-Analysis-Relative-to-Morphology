# Remaining public-function refactor

Review plan, October 15, 2026. No claim of complete conformance or validation.

The user approved formatting/help-only changes to the listed 71 historical or
adapted functions. That approval is recorded for this pass; behavioral changes
still require separate agreement. The 62 modern functions are also included.
All 133 have now received the formatting/help pass, with executable expressions
checked against saved pre-pass copies. This is not full real-data validation.

Scope: all retained callable API functions outside internal/private folders,
except agreed deferred/excluded functions. Internal helpers remain correctness
dependencies. This conservatively includes retained utilities even when older
README lists are incomplete; it does not silently remove those functions.

The machine-readable list is PUBLIC-FUNCTION-REVIEW.csv.

## Historical implementations: proposed edits requiring agreement

Formatting and help only: expand statements; apply consistent spacing; add
Inputs/Outputs, actual defaults, units, identity and mode-specific notes from
the implementation. Preserve formulas, signatures, names, saved fields,
defaults, error identifiers, ordering, output types, exceptional values,
file writes and attribution/license text. Do not consolidate functions,
fix algorithms or change public behavior under this proposal.

Some adapted functions are included conservatively because their history
or scientific calculations require care. Each will still be inspected.

### FieldAnalysis

| Function | File |
| --- | --- |
| farmGenerateRadialMatrix | APIs/FieldAnalysis/src/fieldanalysis/statistics/farmGenerateRadialMatrix.m |
| farmLoglogBin | APIs/FieldAnalysis/src/fieldanalysis/statistics/farmLoglogBin.m |
| farmRadiallyAverageMatrix | APIs/FieldAnalysis/src/fieldanalysis/statistics/farmRadiallyAverageMatrix.m |

### ObjectGeometry

| Function | File |
| --- | --- |
| farmCoords2Mat_2DFils | APIs/ObjectGeometry/src/objectgeometry/centerlines/farmCoords2Mat_2DFils.m |
| farmFilBackBones2D | APIs/ObjectGeometry/src/objectgeometry/centerlines/farmFilBackBones2D.m |
| farmFilBackBonesND | APIs/ObjectGeometry/src/objectgeometry/centerlines/farmFilBackBonesND.m |
| farmMeasureFilaments | APIs/ObjectGeometry/src/objectgeometry/centerlines/farmMeasureFilaments.m |
| farmStoreFilCCs | APIs/ObjectGeometry/src/objectgeometry/centerlines/farmStoreFilCCs.m |
| farmBlobMat2CCProps | APIs/ObjectGeometry/src/objectgeometry/objects/farmBlobMat2CCProps.m |
| farmDistanceGradients | APIs/ObjectGeometry/src/objectgeometry/objects/farmDistanceGradients.m |
| farmDistTransFromBoundary | APIs/ObjectGeometry/src/objectgeometry/objects/farmDistTransFromBoundary.m |
| farmGetDistGrads | APIs/ObjectGeometry/src/objectgeometry/objects/farmGetDistGrads.m |
| farmLocalInertia | APIs/ObjectGeometry/src/objectgeometry/objects/farmLocalInertia.m |
| farmObjectDistanceGradients | APIs/ObjectGeometry/src/objectgeometry/objects/farmObjectDistanceGradients.m |
| farmStructCutOffThresh | APIs/ObjectGeometry/src/objectgeometry/objects/farmStructCutOffThresh.m |
| farmNematicAlignment | APIs/ObjectGeometry/src/objectgeometry/orientation/farmNematicAlignment.m |

### ObjectTracking

| Function | File |
| --- | --- |
| farmAddFieldStruct2Traj | APIs/ObjectTracking/src/objecttracking/farmAddFieldStruct2Traj.m |
| farmConsObjMatSelTrajs | APIs/ObjectTracking/src/objecttracking/farmConsObjMatSelTrajs.m |
| farmGetTimeObjTrajTableFromPyTrajs | APIs/ObjectTracking/src/objecttracking/farmGetTimeObjTrajTableFromPyTrajs.m |
| farmMat2pyTrackMat | APIs/ObjectTracking/src/objecttracking/farmMat2pyTrackMat.m |
| farmTot2ts | APIs/ObjectTracking/src/objecttracking/farmTot2ts.m |
| farmTs2tot | APIs/ObjectTracking/src/objecttracking/farmTs2tot.m |

### SharedUtilities

| Function | File |
| --- | --- |
| farmArrayCumSum | APIs/SharedUtilities/src/sharedutilities/arrays/farmArrayCumSum.m |
| farmArrayOrganizer2D | APIs/SharedUtilities/src/sharedutilities/arrays/farmArrayOrganizer2D.m |
| farmBlockReshape2D | APIs/SharedUtilities/src/sharedutilities/arrays/farmBlockReshape2D.m |
| farmConsMatLnB | APIs/SharedUtilities/src/sharedutilities/arrays/farmConsMatLnB.m |
| farmConsMinValsLayer | APIs/SharedUtilities/src/sharedutilities/arrays/farmConsMinValsLayer.m |
| farmConsScalerMat | APIs/SharedUtilities/src/sharedutilities/arrays/farmConsScalerMat.m |
| farmFillin2D | APIs/SharedUtilities/src/sharedutilities/arrays/farmFillin2D.m |
| farmFillin3D | APIs/SharedUtilities/src/sharedutilities/arrays/farmFillin3D.m |
| farmGenerateFieldInterps | APIs/SharedUtilities/src/sharedutilities/arrays/farmGenerateFieldInterps.m |
| farmGenerateMatrixSubdivisions | APIs/SharedUtilities/src/sharedutilities/arrays/farmGenerateMatrixSubdivisions.m |
| farmImresize3_4mat | APIs/SharedUtilities/src/sharedutilities/arrays/farmImresize3_4mat.m |
| farmInds3Dto2D | APIs/SharedUtilities/src/sharedutilities/arrays/farmInds3Dto2D.m |
| farmLens2Blocks | APIs/SharedUtilities/src/sharedutilities/arrays/farmLens2Blocks.m |
| farmRescaleCoords | APIs/SharedUtilities/src/sharedutilities/arrays/farmRescaleCoords.m |
| farmGenLenVec | APIs/SharedUtilities/src/sharedutilities/coordinates/farmGenLenVec.m |
| farmGenLineInds2D | APIs/SharedUtilities/src/sharedutilities/coordinates/farmGenLineInds2D.m |
| farmGenReflVec | APIs/SharedUtilities/src/sharedutilities/coordinates/farmGenReflVec.m |
| farmGetCCVectors | APIs/SharedUtilities/src/sharedutilities/coordinates/farmGetCCVectors.m |
| farmGetUnitVecs | APIs/SharedUtilities/src/sharedutilities/coordinates/farmGetUnitVecs.m |
| farmRescaleCoords_Inds | APIs/SharedUtilities/src/sharedutilities/coordinates/farmRescaleCoords_Inds.m |
| farmBndmod | APIs/SharedUtilities/src/sharedutilities/miscellaneous/farmBndmod.m |
| farmCellIndSizes | APIs/SharedUtilities/src/sharedutilities/miscellaneous/farmCellIndSizes.m |
| farmGenericLenVec | APIs/SharedUtilities/src/sharedutilities/miscellaneous/farmGenericLenVec.m |
| farmGenScaledKVec | APIs/SharedUtilities/src/sharedutilities/miscellaneous/farmGenScaledKVec.m |
| farmMod1b | APIs/SharedUtilities/src/sharedutilities/miscellaneous/farmMod1b.m |
| farmFastLinIntNDScale2 | APIs/SharedUtilities/src/sharedutilities/numerics/farmFastLinIntNDScale2.m |
| farmGenerate1DGaussian | APIs/SharedUtilities/src/sharedutilities/numerics/farmGenerate1DGaussian.m |
| farmGenerate2DGaussian | APIs/SharedUtilities/src/sharedutilities/numerics/farmGenerate2DGaussian.m |
| farmGenerate3DGaussian | APIs/SharedUtilities/src/sharedutilities/numerics/farmGenerate3DGaussian.m |
| farmGenerate3DGaussians | APIs/SharedUtilities/src/sharedutilities/numerics/farmGenerate3DGaussians.m |
| farmGenerateNDHann | APIs/SharedUtilities/src/sharedutilities/numerics/farmGenerateNDHann.m |
| farmLogAB | APIs/SharedUtilities/src/sharedutilities/numerics/farmLogAB.m |
| farmNdmeshgrid | APIs/SharedUtilities/src/sharedutilities/numerics/farmNdmeshgrid.m |
| farmNdndgrid | APIs/SharedUtilities/src/sharedutilities/numerics/farmNdndgrid.m |
| farmNoNan | APIs/SharedUtilities/src/sharedutilities/numerics/farmNoNan.m |
| farmNonZeroMean | APIs/SharedUtilities/src/sharedutilities/numerics/farmNonZeroMean.m |
| farmPoissonDisc | APIs/SharedUtilities/src/sharedutilities/numerics/farmPoissonDisc.m |
| farmProgressBar | APIs/SharedUtilities/src/sharedutilities/plotting/farmProgressBar.m |
| farmAddFieldsStruct | APIs/SharedUtilities/src/sharedutilities/structsAndTables/farmAddFieldsStruct.m |
| farmAddFieldStruct | APIs/SharedUtilities/src/sharedutilities/structsAndTables/farmAddFieldStruct.m |
| farmConcatTablesOverT | APIs/SharedUtilities/src/sharedutilities/structsAndTables/farmConcatTablesOverT.m |
| farmStructFields2Cell | APIs/SharedUtilities/src/sharedutilities/structsAndTables/farmStructFields2Cell.m |
| farmStructFieldSizes | APIs/SharedUtilities/src/sharedutilities/structsAndTables/farmStructFieldSizes.m |
| farmStructLenVec | APIs/SharedUtilities/src/sharedutilities/structsAndTables/farmStructLenVec.m |

### VisualizationTools

| Function | File |
| --- | --- |
| farmGetPolyCoords | APIs/VisualizationTools/src/visualizationtools/display/farmGetPolyCoords.m |
| farmManVlnPlot | APIs/VisualizationTools/src/visualizationtools/display/farmManVlnPlot.m |
| farmPlotMeanStdPoly | APIs/VisualizationTools/src/visualizationtools/display/farmPlotMeanStdPoly.m |
| farmPlotVlns | APIs/VisualizationTools/src/visualizationtools/display/farmPlotVlns.m |
| farmFigSaves | APIs/VisualizationTools/src/visualizationtools/export/farmFigSaves.m |

## Verification

Save pre-edit copies, compare executable tokens before/after formatting,
inspect documented contracts, run MATLAB R2023a Code Analyzer and the
existing affected suites. Discovered behavioral problems are reported
separately and are not silently repaired.

Deferred mesh/sheet functions and modes, ND2, the two historical estimators
and munkres-backed tracking remain outside this refactor. Review shared
functions without changing their deferred modes.
