> Historical snapshot, retained October 15, 2026. Read the [current user guide](../README.md) and [history index](README.md) before following these older notes.

# Current FARM source tree

Generated after the ordinary-folder migration. Historical material is in the sibling MeMo-Archive.

```text
MeMo/
├── APIs/
│   ├── FieldAnalysis/
│   │   ├── archive/
│   │   │   └── 2026-10-13/
│   │   ├── examples/
│   │   │   └── exampleFieldAnalysis.m
│   │   ├── src/
│   │   │   ├── +fieldanalysis/
│   │   │   │   ├── +conditional/
│   │   │   │   ├── +internal/
│   │   │   │   ├── +preprocessing/
│   │   │   │   └── +spatialCorrelation/
│   │   │   └── fieldanalysis/
│   │   │       ├── conditional/
│   │   │       │   ├── farmConditionalStatistics.m
│   │   │       │   └── farmJointHistogram.m
│   │   │       ├── fourier/
│   │   │       │   ├── farmFrequencyCoordinates.m
│   │   │       │   ├── farmPowerSpectrum2D.m
│   │   │       │   ├── farmPowerSpectrum3D.m
│   │   │       │   ├── farmRadialAverage.m
│   │   │       │   └── farmSelectSlicesAnalysis.m
│   │   │       ├── internal/
│   │   │       │   ├── farmFAField.m
│   │   │       │   ├── farmFAOptions.m
│   │   │       │   ├── farmFAReduce.m
│   │   │       │   └── farmFASpectrum.m
│   │   │       ├── preprocessing/
│   │   │       │   ├── farmApplyIlluminationCorrection.m
│   │   │       │   ├── farmFitIlluminationCorrection.m
│   │   │       │   └── farmScaleToReferenceTotal.m
│   │   │       ├── spatialCorrelation/
│   │   │       │   ├── farmAutoCorrelation.m
│   │   │       │   └── farmCrossCorrelation.m
│   │   │       └── statistics/
│   │   │           ├── farmGenerateRadialMatrix.m
│   │   │           ├── farmGenerateStaticStructureFactor.m
│   │   │           ├── farmGenerateVanHove.m
│   │   │           ├── farmLoglogBin.m
│   │   │           ├── farmPairedFieldStatistics.m
│   │   │           └── farmRadiallyAverageMatrix.m
│   │   ├── tests/
│   │   │   ├── runFieldAnalysisTests.m
│   │   │   └── testFieldAnalysis.m
│   │   └── README.md
│   ├── ImageStackIO/
│   │   ├── examples/
│   │   │   └── README.md
│   │   ├── src/
│   │   │   ├── +imagestackio/
│   │   │   │   ├── +config/
│   │   │   │   └── +legacy/
│   │   │   └── imagestackio/
│   │   │       ├── config/
│   │   │       │   └── farmMakeSource.m
│   │   │       ├── private/
│   │   │       │   ├── farmNormalizeAxes.m
│   │   │       │   ├── farmParseImageJDescription.m
│   │   │       │   ├── farmParseSpacingOptions.m
│   │   │       │   ├── farmParseTiffAxisOrder.m
│   │   │       │   ├── farmResolveTiffSpacing.m
│   │   │       │   └── farmWriteTiffPages.m
│   │   │       ├── transforms/
│   │   │       │   ├── farmCropTiffSave.m
│   │   │       │   ├── farmExtend2DTiffAlongZ.m
│   │   │       │   ├── farmGetLayersOverTimeFrom3DTif.m
│   │   │       │   ├── farmGetTotIntOver3DTiffs.m
│   │   │       │   └── farmSplit3Dto2D.m
│   │   │       ├── farmInspectImage.m
│   │   │       ├── farmReadH5.m
│   │   │       ├── farmReadTiff.m
│   │   │       ├── farmWriteImageJHyperstack.m
│   │   │       └── farmWriteTiff.m
│   │   ├── tests/
│   │   │   ├── cropH5WithImageStackIO.m
│   │   │   ├── README.md
│   │   │   ├── runImageStackIOValidation.asv
│   │   │   ├── runImageStackIOValidation.m
│   │   │   └── stitchTiffChannels.m
│   │   └── README.md
│   ├── ObjectGeometry/
│   │   ├── archive/
│   │   │   ├── 2026-10-12/
│   │   │   └── 2026-10-13-shared-repair/
│   │   │       └── +objectgeometry/
│   │   │           ├── +internal/
│   │   │           └── +objects/
│   │   ├── examples/
│   │   │   ├── skeletonization/
│   │   │   │   └── skel3DBlobs_Script.m
│   │   │   ├── exploreObjectGeometry.m
│   │   │   ├── farmAuditFilamentOrientation.m
│   │   │   └── farmValidateFilamentProjectedExtent.m
│   │   ├── src/
│   │   │   ├── +objectgeometry/
│   │   │   │   ├── +config/
│   │   │   │   ├── +internal/
│   │   │   │   ├── +orientation/
│   │   │   │   └── +representation/
│   │   │   └── objectgeometry/
│   │   │       ├── centerlines/
│   │   │       │   ├── farmCoords2Mat_2DFils.m
│   │   │       │   ├── farmFilBackBones2D.m
│   │   │       │   ├── farmFilBackBonesND.m
│   │   │       │   ├── farmMeasureFilaments.m
│   │   │       │   └── farmStoreFilCCs.m
│   │   │       ├── config/
│   │   │       │   └── farmMakeObjectOptions.m
│   │   │       ├── internal/
│   │   │       │   ├── farmOGBroadenRaster.m
│   │   │       │   ├── farmOGOptions.m
│   │   │       │   ├── farmOGRasterIndices.m
│   │   │       │   ├── farmOGRasterOptions.m
│   │   │       │   ├── farmOGRepresentationGrid.m
│   │   │       │   └── farmOGValidateKeys.m
│   │   │       ├── objects/
│   │   │       │   ├── farmAttachMeasurements.m
│   │   │       │   ├── farmBlobMat2CCProps.m
│   │   │       │   ├── farmConcatenateMeasurements.m
│   │   │       │   ├── farmDistanceGradients.m
│   │   │       │   ├── farmDistTransFromBoundary.m
│   │   │       │   ├── farmGenerateGeometry.m
│   │   │       │   ├── farmGetDistGrads.m
│   │   │       │   ├── farmLocalInertia.m
│   │   │       │   ├── farmMeasureObjects.m
│   │   │       │   ├── farmObjectDistanceGradients.m
│   │   │       │   ├── farmPrepareObjects.m
│   │   │       │   ├── farmReturnSmoothBound.m
│   │   │       │   ├── farmReturnSmoothBoundsBW.m
│   │   │       │   ├── farmReturnSmoothBoundsIDed.m
│   │   │       │   ├── farmSkel3DBlobs.m
│   │   │       │   ├── farmSkel3DClean.m
│   │   │       │   ├── farmSkel3Dfrom2D.m
│   │   │       │   ├── farmSkel3DPop.m
│   │   │       │   └── farmStructCutOffThresh.m
│   │   │       ├── orientation/
│   │   │       │   └── farmNematicAlignment.m
│   │   │       ├── representation/
│   │   │       │   ├── farmGeometryToMatrix.m
│   │   │       │   ├── farmPointsToMatrix.m
│   │   │       │   └── farmSegmentsToMatrix.m
│   │   │       └── sheets/
│   │   │           ├── farmRescalePatch.m
│   │   │           └── farmStruct2Mat_sheets.m
│   │   ├── tests/
│   │   │   ├── README.md
│   │   │   ├── runObjectGeometryTests.m
│   │   │   └── testObjectGeometry.m
│   │   ├── README.md
│   │   └── REPRESENTATION.md
│   ├── ObjectRelativeProfiles/
│   │   ├── archive/
│   │   │   └── 2026-10-13-shared-repair/
│   │   │       └── +objectrelativeprofiles/
│   │   │           └── +fieldSampling/
│   │   ├── examples/
│   │   │   └── exampleFieldQueries.m
│   │   ├── src/
│   │   │   ├── +objectrelativeprofiles/
│   │   │   │   └── +config/
│   │   │   └── objectrelativeprofiles/
│   │   │       ├── config/
│   │   │       │   └── farmMakeQuery.m
│   │   │       └── fieldSampling/
│   │   │           ├── farmAttachResults.m
│   │   │           ├── farmConcatenateResults.m
│   │   │           ├── farmPrepareSupport.m
│   │   │           ├── farmQueryField.m
│   │   │           ├── farmQueryFrame.m
│   │   │           ├── farmQueryVectorField.m
│   │   │           └── farmRunFieldBatch.m
│   │   ├── tests/
│   │   │   ├── runFieldSamplingTests.m
│   │   │   ├── testFieldSampling.m
│   │   │   └── testVectorFieldSampling.m
│   │   └── README.md
│   ├── ObjectTracking/
│   │   ├── archive/
│   │   │   ├── 2026-10-13/
│   │   │   └── 2026-10-13-shared-repair/
│   │   │       └── +objecttracking/
│   │   ├── examples/
│   │   │   └── exampleOverlapLineage.m
│   │   ├── python/
│   │   │   └── trackpy_bridge.py
│   │   ├── src/
│   │   │   ├── +objecttracking/
│   │   │   │   └── +trackpy/
│   │   │   └── objecttracking/
│   │   │       ├── trackpy/
│   │   │       │   ├── farmExportDetections.m
│   │   │       │   ├── farmImportLinks.m
│   │   │       │   └── farmTrackPositions.m
│   │   │       ├── farmAddFieldStruct2Traj.m
│   │   │       ├── farmAttachMembership.m
│   │   │       ├── farmConsObjMatSelTrajs.m
│   │   │       ├── farmGetTimeObjTrajTableFromPyTrajs.m
│   │   │       ├── farmLineageGraph.m
│   │   │       ├── farmMat2pyTrackMat.m
│   │   │       ├── farmOverlapLinks.m
│   │   │       ├── farmRenderTrackingFrame.m
│   │   │       ├── farmSelectLineage.m
│   │   │       ├── farmSelectTrajectories.m
│   │   │       ├── farmSingleTimePointTrajGen.m
│   │   │       ├── farmTot2ts.m
│   │   │       ├── farmTrackOverlaps.m
│   │   │       └── farmTs2tot.m
│   │   ├── tests/
│   │   │   ├── README.md
│   │   │   ├── runObjectTrackingTests.m
│   │   │   ├── test_trackpy_bridge.py
│   │   │   └── testObjectTracking.m
│   │   ├── PYTHON_INTEGRATION.md
│   │   └── README.md
│   ├── SegmentationTools/
│   │   ├── examples/
│   │   │   ├── objectMaskPreparation/
│   │   │   │   └── generateErodedFrame.m
│   │   │   └── README.md
│   │   ├── src/
│   │   │   ├── +segmentationtools/
│   │   │   │   └── +config/
│   │   │   └── segmentationtools/
│   │   │       ├── binarization/
│   │   │       │   ├── farmClassifyProbabilities.m
│   │   │       │   ├── farmClassifyProbabilityChannels.m
│   │   │       │   ├── farmH5toSmooth3Chans.m
│   │   │       │   ├── farmImbinarize3_4D.m
│   │   │       │   ├── farmRemapClassLabels.m
│   │   │       │   ├── farmSegmentInOnOutProbabilities.m
│   │   │       │   ├── farmSegmentIntensity.m
│   │   │       │   ├── farmSmoothInOnOutProbabilities.m
│   │   │       │   ├── farmSmoothNChannelProbabilities.m
│   │   │       │   └── farmThresholdProbabilityGroup.m
│   │   │       ├── cleanup/
│   │   │       │   ├── farmFlatFill3D.m
│   │   │       │   ├── farmRemoveConObjs.m
│   │   │       │   ├── farmReturnSmoothBlobsBW.m
│   │   │       │   ├── farmReturnSmoothBlobsIDed.m
│   │   │       │   └── farmSidesHoleFill.m
│   │   │       ├── config/
│   │   │       │   ├── farmMakeClasses.m
│   │   │       │   ├── farmMakeIntensityOptions.m
│   │   │       │   └── farmMakeProbabilityOptions.m
│   │   │       ├── io/
│   │   │       │   ├── farmReadProbabilityTiff.m
│   │   │       │   └── farmWriteMaskTiff.m
│   │   │       └── morphologySpecific/
│   │   │           └── sheets/
│   │   │               ├── farmGetCentralSlice.m
│   │   │               ├── farmReturnCorrectedBinarizedSurfaceIndices.m
│   │   │               ├── farmReturnTopBottom2DSheets.m
│   │   │               └── farmReturnTopBottom2DSheetsConfigurable.m
│   │   ├── tests/
│   │   │   ├── exploreRealSegmentationData.m
│   │   │   ├── farmValidateInOnOutImplementations.m
│   │   │   ├── README.md
│   │   │   ├── runSegmentationToolsTests.m
│   │   │   ├── SegmentationToolsTestDiagnostics.log
│   │   │   └── testSegmentationTools.m
│   │   └── README.md
│   ├── SharedUtilities/
│   │   ├── archive/
│   │   │   ├── 2026-10-13/
│   │   │   ├── 2026-10-13-ownership/
│   │   │   └── 2026-10-13-shared-repair/
│   │   │       └── +sharedutilities/
│   │   │           ├── +arrays/
│   │   │           ├── +coordinates/
│   │   │           ├── +miscellaneous/
│   │   │           ├── +numerics/
│   │   │           ├── +plotting/
│   │   │           └── +structsAndTables/
│   │   ├── src/
│   │   │   ├── +sharedutilities/
│   │   │   │   ├── +config/
│   │   │   │   ├── +documentation/
│   │   │   │   └── +internal/
│   │   │   └── sharedutilities/
│   │   │       ├── arrays/
│   │   │       │   ├── farmArrayCumSum.m
│   │   │       │   ├── farmArrayOrganizer2D.m
│   │   │       │   ├── farmBlockReshape2D.m
│   │   │       │   ├── farmConsMatLnB.m
│   │   │       │   ├── farmConsMinValsLayer.m
│   │   │       │   ├── farmConsScalerMat.m
│   │   │       │   ├── farmFillin2D.m
│   │   │       │   ├── farmFillin3D.m
│   │   │       │   ├── farmGenerateFieldInterps.m
│   │   │       │   ├── farmGenerateMatrixSubdivisions.m
│   │   │       │   ├── farmImresize3_4mat.m
│   │   │       │   ├── farmInds3Dto2D.m
│   │   │       │   ├── farmLens2Blocks.m
│   │   │       │   └── farmRescaleCoords.m
│   │   │       ├── config/
│   │   │       │   └── farmParseOptions.m
│   │   │       ├── coordinates/
│   │   │       │   ├── farmGenLenVec.m
│   │   │       │   ├── farmGenLineInds2D.m
│   │   │       │   ├── farmGenReflVec.m
│   │   │       │   ├── farmGetCCVectors.m
│   │   │       │   ├── farmGetUnitVecs.m
│   │   │       │   └── farmRescaleCoords_Inds.m
│   │   │       ├── documentation/
│   │   │       │   ├── farmGetGlossaryDataType.m
│   │   │       │   ├── farmGetGlossaryEntry.m
│   │   │       │   ├── farmGetGlossaryInputOptions.m
│   │   │       │   ├── farmGetGlossaryInputs.m
│   │   │       │   ├── farmGlossaryEntries.m
│   │   │       │   └── farmSearchGlossary.m
│   │   │       ├── internal/
│   │   │       │   ├── farmSUKeyError.m
│   │   │       │   ├── farmSUOptions.m
│   │   │       │   └── farmSUSelectGlossaryEntries.m
│   │   │       ├── miscellaneous/
│   │   │       │   ├── farmBndmod.m
│   │   │       │   ├── farmCellIndSizes.m
│   │   │       │   ├── farmGenericLenVec.m
│   │   │       │   ├── farmGenScaledKVec.m
│   │   │       │   ├── farmLogic2Ply.m
│   │   │       │   └── farmMod1b.m
│   │   │       ├── numerics/
│   │   │       │   ├── farmFastLinIntNDScale2.m
│   │   │       │   ├── farmGaussD.m
│   │   │       │   ├── farmGenerate1DGaussian.m
│   │   │       │   ├── farmGenerate2DGaussian.m
│   │   │       │   ├── farmGenerate3DGaussian.m
│   │   │       │   ├── farmGenerate3DGaussians.m
│   │   │       │   ├── farmGenerateNDHann.m
│   │   │       │   ├── farmLOG.m
│   │   │       │   ├── farmLogAB.m
│   │   │       │   ├── farmMyconvn.m
│   │   │       │   ├── farmNdmeshgrid.m
│   │   │       │   ├── farmNdndgrid.m
│   │   │       │   ├── farmNoNan.m
│   │   │       │   ├── farmNonZeroMean.m
│   │   │       │   ├── farmPoissonDisc.m
│   │   │       │   └── farmSignedBWDist.m
│   │   │       ├── plotting/
│   │   │       │   └── farmProgressBar.m
│   │   │       └── structsAndTables/
│   │   │           ├── farmAddFieldsStruct.m
│   │   │           ├── farmAddFieldStruct.m
│   │   │           ├── farmAttachByKeys.m
│   │   │           ├── farmConcatenateByKeys.m
│   │   │           ├── farmConcatTablesOverT.m
│   │   │           ├── farmStructFields2Cell.m
│   │   │           ├── farmStructFieldSizes.m
│   │   │           ├── farmStructLenVec.m
│   │   │           └── farmValidateTableKeys.m
│   │   ├── tests/
│   │   │   ├── runSharedUtilitiesTests.m
│   │   │   ├── testCanonicalUtilities.m
│   │   │   ├── testFarmLayout.m
│   │   │   └── testSharedUtilities.m
│   │   └── README.md
│   ├── SurfaceFieldMapping/
│   │   └── src/
│   │       └── surfacefieldmapping/
│   │           ├── meshConstruction/
│   │           │   └── farmConsPatchedSheetSurface_Flat.m
│   │           ├── meshIO/
│   │           │   ├── farmObj2ply.m
│   │           │   ├── farmPlySurf2TIF.m
│   │           │   ├── farmPlywrite_norms.m
│   │           │   └── farmReadObj_remi.m
│   │           └── meshOperations/
│   │               ├── farmCapPtCloudFlat.m
│   │               ├── farmConfineMeshInMat.m
│   │               ├── farmGetMeshDims.m
│   │               ├── farmInBetweenFill.m
│   │               ├── farmMesh2mat.m
│   │               ├── farmMeshSideRemove.m
│   │               ├── farmRemove_isolated_mesh_components.m
│   │               ├── farmRemoveFacesVerts_Mesh.m
│   │               ├── farmSplit_mesh_into_components.m
│   │               └── farmSplit_single_mesh_object.m
│   └── VisualizationTools/
│       ├── src/
│       │   ├── +visualizationtools/
│       │   │   └── +export/
│       │   └── visualizationtools/
│       │       ├── display/
│       │       │   ├── farmGetPolyCoords.m
│       │       │   ├── farmManVlnPlot.m
│       │       │   ├── farmPlotMeanStdPoly.m
│       │       │   └── farmPlotVlns.m
│       │       └── export/
│       │           └── farmFigSaves.m
│       └── README.md
├── docs/
│   ├── API_SCOPE_REVIEW.md
│   ├── CHANGING-AN-ANALYSIS.md
│   ├── CURRENT_SOURCE_TREES.md
│   ├── DATA-DICTIONARY-CANDIDATES.csv
│   ├── DATA-DICTIONARY-CANDIDATES.md
│   ├── FARM-FUNCTION-NAMES.json
│   ├── FARM-MIGRATION-MANIFEST.csv
│   ├── FARM-MIGRATION-VALIDATION.md
│   ├── FARM-NAMING-MIGRATION.md
│   ├── MATLAB-GLOSSARY.md
│   ├── MIGRATION_NOTES.md
│   ├── READING-STRUCTURES.md
│   ├── README.md
│   ├── SEGMENTATION_HISTORICAL_METHODS-rboros.md
│   ├── SEGMENTATION_HISTORICAL_METHODS.md
│   ├── SEGMENTATION_WORKFLOW_EXTRACTION_REVIEW.md
│   └── WORKFLOW-1-WALKTHROUGH.md
├── tests/
│   ├── +memotest/
│   └── memotest/
│       ├── farmTestDataRoot.m
│       └── farmTestFilamentExtentAngleSweep.m
├── Workflows/
│   ├── examples/
│   │   ├── +memoworkflow/
│   │   ├── memoworkflow/
│   │   │   ├── farmWorkflowIntensity.m
│   │   │   ├── farmWorkflowNewRun.m
│   │   │   ├── farmWorkflowObjects.m
│   │   │   ├── farmWorkflowReference.m
│   │   │   ├── farmWorkflowRegions.m
│   │   │   ├── farmWorkflowSaveNew.m
│   │   │   └── farmWorkflowSetColumnUnit.m
│   │   ├── EXPERIMENT-CONFIGURATION.md
│   │   ├── farmBenchmarkWorkflowScaling.m
│   │   ├── farmExperiment4Config.m
│   │   ├── farmPreparationExample.m
│   │   ├── farmPreviewExperiment4.m
│   │   ├── farmWorkflow1Objects.m
│   │   ├── farmWorkflow2Filaments.m
│   │   ├── farmWorkflow3Lineage.m
│   │   ├── farmWorkflow4Spectra.m
│   │   ├── farmWorkflow5Profiles.m
│   │   ├── README.md
│   │   ├── runConfigBuilderTests.m
│   │   ├── runWorkflowExampleTests.m
│   │   ├── setupWorkflow1.m
│   │   ├── setupWorkflow2.m
│   │   ├── setupWorkflow2Staged.m
│   │   ├── setupWorkflow3.m
│   │   ├── setupWorkflow4.m
│   │   ├── setupWorkflow5.m
│   │   ├── testConfigBuilders.m
│   │   └── testWorkflowExamples.m
│   └── src/
│       ├── +memoworkflow/
│       │   └── +config/
│       └── memoworkflow/
│           ├── config/
│           │   └── farmMakeExperiment.m
│           └── farmLoadSource.m
├── .gitignore
├── CONFIGURATION-BUILDERS.md
├── farmGlossary.m
├── farmSetup.m
├── GLOSSARY-CAPABILITIES-MOCKUP.md
├── HANDOFF_SEGMENTATIONTOOLS_TESTING_2026-10-10-rboros.md
├── HANDOFF_SEGMENTATIONTOOLS_TESTING_2026-10-10.md
├── logoPlaceholder.png
├── OPTIONS-AND-BUILDERS-AUDIT.md
├── README.md
├── runAllTests.m
└── TESTING.md
```
