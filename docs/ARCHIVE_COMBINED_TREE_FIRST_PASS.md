# Merged archive tree

This tree reflects the local merged archive currently created. Source repositories remain untouched. No GitHub repository was created or pushed.

## Routing rules

- Exact duplicates were identified by SHA-256. For each matching group, the latest modified copy was kept; ties preferred Active Foam.
- Exact duplicate files from Active Foam - Backup are listed in AF - Backup Duplicates/README.md instead of copied.
- Backup files at the same relative path as Active Foam files with different contents were copied into AF - Backup Variants/.
- Chan-Vese folders and their contents, every ChenVese_Extracted.m, and SHG/a.ps were omitted.
- Velocity Calculation/Functions contains only a README pointing to the separate 3D PIV GitHub repository. Its URL still needs to be filled in.
- The conversation-created batch_3SegtoPerims_pathConfigExample.m was omitted.

Filesystem timestamps can be affected by copying and cloud sync. The duplicate manifest records the original timestamps used as one clue when choosing retained copies.

## Counts

- Eligible source files considered: 738
- Source files copied into the archive: 536
- 3D PIV function files intentionally omitted and replaced by a README: 11
- SHG/a.ps intentionally omitted: 1
- Exact backup duplicates documented in the manifest: 190
- Backup variants copied: 9
- Total files in the merged archive, including the two README files: 538

## Tree

~~~text
Active Foam Archive/
├── Additional Functions/
│   ├── Active Contouring/
│   │   ├── activeContourFrame1.m
│   │   ├── activeContourFromH5.m
│   │   ├── dilateErodeSegWeights.m
│   │   ├── generateFirstGuess_morphsnakes.m
│   │   ├── getCentralSlice.m
│   │   ├── returnCorrectedBinarizedSurfaceIndices.m
│   │   ├── returnTopBottom2DSheets.m
│   │   └── splitSurfaces_Threshold.m
│   ├── Retired/
│   │   ├── Poisson Disk Elimination/
│   │   │   └── test1.m
│   │   ├── generateNDHannBorder.m
│   │   └── radialAutoCorr.m
│   ├── addFieldsStruct.m
│   ├── addFieldStruct.m
│   ├── arrayCumSum.m
│   ├── arrayOrganizer2D.m
│   ├── blockReshape2D.m
│   ├── bndmod.m
│   ├── cellIndSizes.m
│   ├── concatTablesOverT.m
│   ├── figSaves.m
│   ├── genericLenVec.m
│   ├── genLenVec.m
│   ├── genLineInds2D.m
│   ├── genReflVec.m
│   ├── genScaledKVec.m
│   ├── genTifTagRGB.m
│   ├── getCCVectors.m
│   ├── getUnitVecs.m
│   ├── lens2Blocks.m
│   ├── logAB.m
│   ├── logic2Ply.m
│   ├── loglogBin.m
│   ├── manVlnPlot.asv
│   ├── manVlnPlot.m
│   ├── mod1b.m
│   ├── pipInstallMATLAB.py
│   ├── pipInstallPython.m
│   ├── pixIDStruct2CC.m
│   ├── plotVlns.m
│   ├── poissonDisc.m
│   ├── progressBar.m
│   ├── saveNDTifs_Test.m
│   ├── scatInt2DSlicesOver3D.m
│   ├── structFields2Cell.m
│   ├── structFieldSizes.m
│   └── structLenVec.m
├── AF - Backup Duplicates/
│   └── README.md
├── AF - Backup Variants/
│   ├── Additional Functions/
│   │   └── manVlnPlot.m
│   ├── Analysis - Filaments/
│   │   ├── A_extractFilsFromTifs.m
│   │   ├── C_fil2ObjAlignment.m
│   │   └── COMBINED_Fils2Aligns_InOnOut.m
│   ├── Analysis - Fourier/
│   │   └── batch_FFTAnalysis_samAdapted.m
│   ├── Manipulation - h5/
│   │   └── H5 Functions/
│   │       └── distTransFromBoundary.m
│   └── Manipulation - Tiffs/
│       ├── Batch Process/
│       │   └── batch_tifSubSampleTif.m
│       ├── Reslice Scripts/
│       │   └── selectZFrom3DTiffs.m
│       └── Tiff Manipulation Functions/
│           └── saveNDTiffFIJI.m
├── aLENS Analysis/
│   ├── Functions/
│   │   ├── conncompDG.m
│   │   ├── dat2Mat_Fils.m
│   │   ├── dg2g.m
│   │   ├── fieldOnObjs.m
│   │   ├── getPairsFieldVals.m
│   │   ├── globRepl2LT.m
│   │   ├── globRepl2Traj.m
│   │   ├── mapWrap.m
│   │   ├── readGlobalID.m
│   │   ├── rmedgeAnneal.m
│   │   ├── rmNodeStatic.m
│   │   └── Traj2Props.m
│   ├── Retired/
│   │   └── globRepl2LT_OLD.m
│   └── Scripts/
│       ├── analyzeClusterTrajectories.m
│       ├── getClusterData_Raw.m
│       ├── readDAT.m
│       └── trackClusterData_Trajectories.m
├── Analysis - Blobs/
│   ├── Blob Mesh Analysis/
│   │   ├── closedSurfaces_FieldsOnMesh.m
│   │   ├── closedSurfaces_h5ToMesh_EnforceNorms.m
│   │   ├── closedSurfaces_h5ToPointCloud.m
│   │   ├── closedSurfaces_splitPtCloudsMeshes.m
│   │   └── threeSeg_meanIntProfiles.m
│   ├── Data Plotting/
│   │   ├── plotDeltaRBnds.m
│   │   ├── plotDeltaRSkels.m
│   │   ├── plotFirstInertiaMomentData.asv
│   │   ├── plotFirstInertiaMomentData.m
│   │   ├── plotRInertiaStruct.m
│   │   ├── plotSortedMat_MultipleOverlap.m
│   │   ├── plotSortedMat_MultipleSave.m
│   │   └── plotSortedMat.m
│   ├── Functions/
│   │   ├── addFieldStruct2Traj.m
│   │   ├── blobMat2CCProps.m
│   │   ├── generateBlobsFromH5Segs.m
│   │   ├── generateTracksFromStoreStruct.m
│   │   ├── returnSmoothBlobsBW.m
│   │   ├── returnSmoothBlobsIDed.m
│   │   ├── returnSmoothBound.m
│   │   ├── returnSmoothBoundsBW.m
│   │   ├── returnSmoothBoundsIDed.m
│   │   ├── skel3DBlobs.m
│   │   ├── structCutOffThresh.m
│   │   ├── tifsOfTraj_TOT.m
│   │   └── tifsOfTraj_trajs.m
│   ├── Quantification Scripts/
│   │   ├── blobDensityDeltaR_Blobs.m
│   │   ├── blobDensityDeltaR_Skels.m
│   │   ├── blobInertiaTensorCalcs.m
│   │   ├── blobPropsFromTrajs_R_Inertia.m
│   │   ├── blobPropsFromTrajs.m
│   │   ├── estimateFirstInertiaMoment.m
│   │   └── meanPropsOverTime.m
│   ├── Visualization Scripts/
│   │   ├── intsAndSegBoundaries_Tiffs.m
│   │   ├── intsAndSegBoundaries2DImgs_Tiffs.m
│   │   ├── mapFieldOnBlobSegs.m
│   │   ├── metadata.m
│   │   ├── plotBlobStatistics_rEff.m
│   │   ├── stitchSkelsAndShells.m
│   │   └── tiffs_BlobOverTime.m
│   ├── A_blobsFromH5s.asv
│   ├── A_blobsFromH5s.m
│   ├── B_blobTracking_StoreObjectProps.m
│   └── C_corrBlobBndsPost.m
├── Analysis - Drops/
│   ├── Blob Analysis CORE/
│   │   ├── A_fullPipelineOutline.m
│   │   ├── B_blobsFromH5s.asv
│   │   ├── B_blobsFromH5s.m
│   │   ├── BC_tifs2CC.m
│   │   ├── C_trajsFromBlobs.m
│   │   ├── D_consTrajStruct.m
│   │   ├── E_mergeTrajs.m
│   │   └── F_getIntHists.m
│   ├── Drop Surface Meshes/
│   │   └── closedSurfaces_FieldsOnMesh.asv
│   ├── Functions/
│   │   └── skel3DBlobs.asv
│   ├── Quantification Scripts/
│   │   ├── blobs_InOnOut_VolMassRho.asv
│   │   ├── blobs_InOnOut_VolMassRho.m
│   │   ├── blobVolDistsFromCCs.m
│   │   ├── blobVolFractFromh5.m
│   │   ├── blobVolFractFromTifs.m
│   │   ├── dropIntensitiesDistRings.m
│   │   ├── dropSurfacesCenters.m
│   │   ├── percolationAnalysis.m
│   │   ├── plot_avgH5Quants.m
│   │   ├── plotDropStatistics_misc.m
│   │   ├── secondSegQuant.m
│   │   ├── volFractAndIntGlobal_Modular.m
│   │   ├── volFractAndIntGlobalPlots.m
│   │   └── volNumSurfPlot.m
│   ├── Retired/
│   │   ├── dropTrackingFromStorageStructure.m
│   │   ├── getDropCenters.m
│   │   └── isolatedDrop.m
│   ├── Tracking Misc. Scripts/
│   │   └── TEST_GraphTrajFind.m
│   ├── Visualization Scripts/
│   │   ├── intsAndSegBoundaries_Tiffs.asv
│   │   └── intsAndSegBoundaries_Tiffs.m
│   ├── batch_densityDistributionAlongDeltaR_TIFS.asv
│   ├── batch_densityDistributionAlongDeltaR_TIFS.m
│   ├── batch_densityDistributionAlongDeltaR.m
│   ├── batch_RemoveEdgeObjs.m
│   ├── binSegDists_Smooth.m
│   ├── blobInertiaTensorCalcs.asv
│   ├── blobInertiaTensorCalcs.m
│   ├── blobInertiaTensorPlot.asv
│   ├── blobInertiaTensorPlot.m
│   ├── colorBlobs_SortedMat.asv
│   ├── colorBlobs_SortedMat.m
│   ├── digraphOverlapTracking_UniqueIDs.m
│   ├── digraphOverlapTracking.m
│   ├── generateErodedFrame.m
│   ├── IsolateBlobLineage.m
│   ├── IsolateBlobs.m
│   ├── jasper_fresh.m
│   ├── jasper_TrackBlobConstituents.m
│   ├── overlapBlobTrack_fromCCs.m
│   ├── overlapBlobTracking_TrackObjectProps.m
│   ├── overlapBlobTracking.m
│   ├── plotGlobalQuantities.m
│   ├── skel3DBlobs_Script.asv
│   ├── skel3DBlobs_Script.m
│   ├── test_constructTifsFromObjs.m
│   ├── test_InVOnInts_IsolatedBlob.m
│   ├── test_labeledVolFrac.m
│   ├── test_mergingDropAnalysis.m
│   ├── test_NumVolsFromStruct.m
│   ├── test_trajInfoFromOverlaps_MinAxis.asv
│   ├── test_trajInfoFromOverlaps_MinAxis.m
│   ├── test_trajInfoFromOverlaps.asv
│   ├── test_trajInfoFromOverlaps.m
│   └── test_trajlessMinRInfo.m
├── Analysis - Filaments/
│   ├── Alignment Pipeline/
│   │   ├── AppendDensePropsToFilCCs.m
│   │   ├── Display_AverageAlignment_InOnOutBin.m
│   │   ├── Display_AvgAlign_FromRBins.m
│   │   ├── Display_Filaments2DCuts.m
│   │   ├── Display_FilamentsAndBoundaries.m
│   │   ├── Display3Channel_InOnOutFils3D.m
│   │   ├── DisplayGradPerim.m
│   │   ├── DisplayInOnOut_SparseOnDense2DSlice.m
│   │   └── rp3DAssignRBins.m
│   ├── Alignment Pipeline - Thesis Timeline/
│   │   ├── AlignmentOVERVIEW.m
│   │   ├── AppendDensePropsToFilCCs.m
│   │   ├── Display_AverageAlignment_InOnOutBin.m
│   │   ├── Display_AvgAlign_FromRBins.asv
│   │   ├── Display_AvgAlign_FromRBins.m
│   │   ├── Display_FilamentsAndBoundaries.m
│   │   ├── Display3Channel_InOnOutCoMs3D.m
│   │   ├── Display3Channel_InOnOutFils3D.m
│   │   ├── DisplayGradPerim.m
│   │   ├── DisplayInOnOut_SparseOnDense2DSlice.m
│   │   └── rp3DAssignRBins.m
│   ├── Data Plotting/
│   │   ├── plotFilamentAlignments.m
│   │   └── prepareTifsForFilProps.asv
│   ├── Final Analysis/
│   │   ├── alignStatsOverTime.m
│   │   ├── COMBINED_Fils2Aligns_InOnOut_TIFS.m
│   │   ├── ConcatTableQuantities.m
│   │   ├── Display_Filaments2DCuts.m
│   │   └── prepareTifsForFilProps.m
│   ├── Functions/
│   │   ├── coords2Mat_2DFils.m
│   │   ├── filBackBones2D.m
│   │   ├── filBackBonesND.m
│   │   └── storeFilCCs.m
│   ├── One Off/
│   │   ├── getFilAligns.asv
│   │   └── getFilAligns.m
│   ├── Retired/
│   │   ├── B_prepareFilamentStats_2D.m
│   │   └── B_prepareFilamentStats_3D.m
│   ├── A_extractFilsFromTifs.m
│   ├── A_getFilamentStats_2Dand3D_FROMH5s.m
│   ├── B_prepareFilamentStats_2D.m
│   ├── batch_densityDistributionAlongDeltaR.m
│   ├── C_fil2ObjAlignment.m
│   ├── C_fil2ObjAlignmentQTensor2D.m
│   ├── C_fil2ObjAlignmentQTensor3D.m
│   ├── COMBINED_Fils2Aligns_InOnOut.m
│   ├── COMBINED_getFilamentStats2D.m
│   ├── COMBINED_plotFilamentStats2D.m
│   ├── DISPLAY_alignmentsOnField.m
│   ├── DISPLAY_filamentsDistBin.m
│   ├── displayAlignmentParameter.m
│   ├── filAngVSIntGrad.m
│   ├── getMTLengthDist_From3DBW.m
│   ├── getMTLengthDist_From3DCC.m
│   ├── getMTLengthDist.m
│   ├── h5Seg_FilamentPosOr.m
│   ├── overlayFilamentsOnField.m
│   ├── PLOT_overlayAlignsAndGrads.m
│   ├── PLOT_QTensor3D_OutInOnBin.m
│   ├── plotFilamentStats_2Dand3D.m
│   ├── sampleFilsInH5.m
│   ├── structureTensorTests.asv
│   ├── structureTensorTests.m
│   └── velocityOrientationDistance.m
├── Analysis - Fourier/
│   ├── batch_FFTAnalysis_samAdapt3D.m
│   ├── batch_FFTAnalysis_samAdapted.m
│   ├── batch_intensityFFTAnalysis.m
│   ├── fitToFunction.m
│   ├── get_meanimg_LiangADAPT.m
│   ├── get_meanimg_LiangOG.m
│   ├── get_ProfileScatterFunctions.m
│   ├── plotSpectra_Multiple.asv
│   ├── plotSpectra_Multiple.m
│   ├── plotSpectra.m
│   └── samCompare.m
├── Analysis - Meshes General/
│   ├── Functions/
│   │   └── getGrowthFromMesh.m
│   └── Quantification Scripts/
│       └── iterateThroughMeshes.m
├── Analysis - Sheets/
│   ├── CORE Homeotropic Pt Cloud/
│   │   ├── h5ToMesh_homeoAndSplit.asv
│   │   ├── h5ToMesh_homeoAndSplit.m
│   │   ├── rough_homeotropicThinning.m
│   │   ├── temp_LapSmoothField.asv
│   │   └── temp_LapSmoothField.m
│   ├── CORE Two Sheet Og/
│   │   ├── A_identifyFromH5_2DSheets.m
│   │   ├── B_generatePointClouds_SplitSheets.m
│   │   ├── C_DataOnMeshes.m
│   │   └── D_PlotMeshStats.m
│   ├── Functions/
│   │   ├── rebuildMat.m
│   │   ├── rescalePatch.m
│   │   ├── skel3DClean.m
│   │   ├── skel3Dfrom2D.m
│   │   ├── skel3DPop.m
│   │   └── struct2Mat_sheets.m
│   ├── One Time Scripts/
│   │   ├── constructSegmentationTifs.m
│   │   └── temp_splitDECAndData.m
│   ├── Quantification Scripts/
│   │   ├── correlateHeightIntensity.m
│   │   ├── deltaH_PIV_Sheets.asv
│   │   ├── deltaH_PIV_Sheets.m
│   │   ├── distanceBinning.m
│   │   ├── getHeightProfiles_eachLayer.m
│   │   ├── getIntensityFluxes_2DSheets.m
│   │   ├── getMaxInt_eachLayer.m
│   │   ├── getMeanIntPerZOverT.m
│   │   ├── getMTProfile_afterSeg.m
│   │   ├── intensityVSVelocity_DOTNormal.asv
│   │   ├── intensityVSVelocity_DOTNormal.m
│   │   ├── regionInts_Sheets.asv
│   │   ├── regionInts_Sheets.m
│   │   ├── rough_MeanIntProfile.m
│   │   ├── storeMeshProps_1_IntsCurvesVF.asv
│   │   ├── storeMeshProps_1_IntsCurvesVF.m
│   │   ├── storeMeshProps_2_AppendPIV_DECVals.m
│   │   ├── storeMeshProps_Combined.asv
│   │   ├── storeMeshProps_Combined.m
│   │   └── TEST_MeshToSegDistMatch.m
│   ├── Tubular Prep Functions/
│   │   ├── capPtCloudFlat.m
│   │   └── inBetweenFill.m
│   └── Visualization/
│       └── view_fieldsFromStruct.m
├── Analysis - Tiffs/
│   ├── CORE Image Preparation/
│   │   ├── corr3DTiff_DirtCorr.m
│   │   ├── corr3DTiff_DirtIllum.asv
│   │   ├── corr3DTiff_RasterDirtIllum.m
│   │   ├── corr3DTiff_Simplify.asv
│   │   ├── corr3DTiff_Simplify.m
│   │   ├── corr3DTiff.asv
│   │   ├── corr3DTiff.m
│   │   └── sparseChannelCorr.m
│   ├── FFT and Structure/
│   │   └── batchProcessStructurePower.m
│   ├── getMeanIntensityOverTime3D.m
│   ├── manyDirs_CorrTifs.asv
│   ├── manyDirs_CorrTifs.m
│   └── twoFieldsCrossCorr.m
├── Data Plotting/
│   ├── getPolyCoords.m
│   ├── MATLAB_HELP_DisplayGlitch.m
│   ├── plotMeanStdPoly.m
│   └── plotVanHoveCorrs.m
├── Manipulation - H5/
│   ├── H5 Functions/
│   │   ├── distTransFromBoundary.m
│   │   ├── getDistGrads.m
│   │   ├── h5toSmooth3Chans.m
│   │   ├── h5toTif.m
│   │   └── loadH5.m
│   ├── batch_3SegPerimeters.m
│   ├── batch_3SegSubsample.asv
│   ├── batch_3SegSubsample.m
│   ├── BatchConvertH5toTif_DirtSub.m
│   ├── BatchConvertH5toTif.asv
│   ├── BatchConvertH5toTif.m
│   └── multiDir_batchH5toTif.m
├── Manipulation - Matrices/
│   ├── consMatLnB.m
│   ├── consMinValsLayer.m
│   ├── consPatchedSheetSurface_Flat.m
│   ├── consScalerMat.m
│   ├── fastLinIntNDScale2.m
│   ├── fillin2D.m
│   ├── fillin3D.m
│   ├── flatFill3D.m
│   ├── GaussD.m
│   ├── generate1DGaussian.m
│   ├── generate2DGaussian.m
│   ├── generate3DGaussian.m
│   ├── generate3DGaussians.m
│   ├── generateFieldInterps.m
│   ├── generateMatrixSubdivisions.m
│   ├── generateNDHann.m
│   ├── generateRadialMatrix.m
│   ├── generateStaticStructureFactor.m
│   ├── generateVanHove.m
│   ├── imbinarize3_4D.m
│   ├── imresize3_4mat.m
│   ├── inds3Dto2D.m
│   ├── LOG.m
│   ├── myconvn.m
│   ├── ndmeshgrid.m
│   ├── ndndgrid.m
│   ├── noNan.m
│   ├── nonZeroMean.m
│   ├── radiallyAverageMatrix.m
│   ├── removeConObjs.m
│   ├── rescaleCoords_Inds.m
│   ├── rescaleCoords.m
│   ├── sidesHoleFill.m
│   └── signedBWDist.m
├── Manipulation - Meshes/
│   ├── confineMeshInMat.m
│   ├── getMeshDims.m
│   ├── mesh2mat.m
│   ├── meshSideRemove.m
│   ├── obj2ply.m
│   ├── plySurf2TIF.m
│   ├── plywrite_norms.m
│   ├── readObj_remi.m
│   ├── remi_remove_IDed_mesh_object.m
│   ├── remi_sort_mesh_objects.m
│   ├── remove_isolated_mesh_components.m
│   ├── removeFacesVerts_Mesh.m
│   ├── saveObj2PlyFiles.m
│   ├── shiftMeshVerts.m
│   ├── split_mesh_into_components.m
│   └── split_single_mesh_object.m
├── Manipulation - Meshes Scripts/
│   ├── Retired/
│   │   ├── getSplitMeshGrowthComps.m
│   │   ├── intensityInOnMesh.m
│   │   └── storeMeshInfoTimeSeries.m
│   ├── allMeshInfoPerTimePoint.m
│   ├── filmMeshObjects.m
│   ├── splitMeshObjectsOverTime.m
│   └── trackMeshCenters.m
├── Manipulation - Tiffs/
│   ├── Batch Process/
│   │   ├── AccentuateFeatures.asv
│   │   ├── AccentuateFeatures.m
│   │   ├── batch_3DTo2D.m
│   │   ├── batch_3SegtoPerims.m
│   │   ├── batch_tifSubSampleTif.asv
│   │   ├── batch_tifSubSampleTif.m
│   │   ├── batch_upscaleSmooth.m
│   │   ├── batchCropGaussCorrTifs.m
│   │   ├── batchCropTifs.m
│   │   ├── batchH5SubSampleTif_complex.m
│   │   ├── batchh5SubsampleTif.m
│   │   ├── batchSampleTifs.m
│   │   ├── batchScaleDown3D.m
│   │   ├── metadata.m
│   │   ├── nd2Sideview.m
│   │   ├── renameFiles.m
│   │   ├── reslice5DND2.m
│   │   ├── rough_stitchChannels_avis.m
│   │   ├── Updated_nd2Sideview.m
│   │   ├── Updated_nd2XYView.asv
│   │   └── Updated_nd2XYView.m
│   ├── Image Correction Functions/
│   │   ├── Retired/
│   │   │   ├── generateGaussCorrectionMask_3DTiff.m
│   │   │   └── generateGaussCorrectionMaskPerZ_3DTiff.m
│   │   ├── Copy_of_generateGaussCorrectionMask_3DTiff.m
│   │   ├── generate4DLayerStore_ZandT.m
│   │   ├── generateArea_BoundingBox.m
│   │   ├── generateGaussCorrectionPerZ.m
│   │   ├── generatePerimeterArea_BoundingBox.m
│   │   ├── nzFlat.m
│   │   └── rasterCorrectionZ_3DTiff.m
│   ├── Reslice Scripts/
│   │   ├── nonZeroFlatten.m
│   │   ├── selectZFrom3DTiffs.asv
│   │   ├── selectZFrom3DTiffs.m
│   │   ├── stackTifs.asv
│   │   ├── stackTifs.m
│   │   ├── tile2DTifs.m
│   │   ├── timeSeries_sideStackFrom3D.m
│   │   └── timeSeries_zProjectionFrom3Ds.m
│   ├── Retired/
│   │   ├── A_removeZRastering_SplitTimes.m
│   │   ├── B_generateBleachScaledGaussians_SplitTimes.m
│   │   ├── C_correctIlluminationProfile_SplitTimes.m
│   │   ├── D_correctAroundDirt_SplitTimes.m
│   │   ├── gaussCorrTif.m
│   │   ├── generateBleachScaledGaussians.m
│   │   └── generateDirtMask.m
│   ├── Tests/
│   │   ├── butterworthFilter.py
│   │   ├── GaussSubTests_script.m
│   │   ├── LiangTest.m
│   │   ├── TEST_getIntDistBounds.m
│   │   ├── test_pythonButterWorth.m
│   │   ├── TEST_threeStepCorr.m
│   │   └── tophatDirtandGaussCorr.m
│   └── Tiff Manipulation Functions/
│       ├── cropTiffSave.m
│       ├── extend2DTiffAlongZ.m
│       ├── fastWriteTiff.m
│       ├── getLayersOverTimeFrom3DTif.m
│       ├── getTotIntOver3DTiffs.m
│       ├── replicateTiffSlicesAlongDim.m
│       ├── save3DTiff.m
│       ├── saveNDTiffFIJI.asv
│       ├── saveNDTiffFIJI.m
│       └── split3Dto2D.m
├── One Off Scripts/
│   ├── appendIntsSTD_Blobs.m
│   ├── averageIntOverZ.asv
│   ├── averageIntOverZ.m
│   ├── BilayerCrossSections.m
│   ├── calcCorrAndStrucFact.m
│   ├── colorplay.m
│   ├── convolvePSFDemo.m
│   ├── corrMatSizes.m
│   ├── CowbrainCrawl.m
│   ├── cropAVI.m
│   ├── extractFoamDetails_ROUGH.m
│   ├── filDirDist_QI.m
│   ├── forJakob_WriteCSV.asv
│   ├── forJakob_WriteCSV.m
│   ├── fromBlobs_MTK4Isolated.m
│   ├── gelRead.m
│   ├── generateSideView3DLogicStructs.m
│   ├── generateSideView3DTifSeries.m
│   ├── getIntsOverTimeMultipleDirs.m
│   ├── intensity2D_SheetBuckleCollapse.m
│   ├── isolatedAssembliesFromIntensities.m
│   ├── MakeBulkBlobs.m
│   ├── metadata.m
│   ├── MTK4_FakeTwoChannel.m
│   ├── MTProfile_DistFromK4.m
│   ├── padImage.m
│   ├── ParaviewColormap.m
│   ├── permuteTifs.m
│   ├── prepTifs_EarlySheetCurvatures.m
│   ├── RadhikaData_2013_Velocities.asv
│   ├── RadhikaData_2013_Velocities.m
│   ├── readMP4.m
│   ├── recolorBlobs_PercAndChilds.asv
│   ├── recolorBlobs_PercAndChilds.m
│   ├── reconstruct_SheetDynamics.m
│   ├── removeSmallBlobs.m
│   ├── renormalizeInts.m
│   ├── rminPhi_compare.m
│   ├── rMinStats_CORRMinAxisDims.m
│   ├── ROUGH_isolate3DBilayerStructure.m
│   ├── roughVolumeFrac_BILAYERS.m
│   ├── selFrame_SkelBndTif.m
│   ├── sheets_ViewCurvatures.asv
│   ├── sheets_ViewCurvatures.m
│   ├── stitchBlobStatsFromDiffFiles.asv
│   ├── stitchBlobStatsFromDiffFiles.m
│   ├── TotalIntensitiesOverTime.m
│   ├── viewMeshFields_overTime_NOPIV.m
│   ├── viewMeshFields_overTime.asv
│   ├── viewMeshFields_overTime.m
│   ├── visualize3DDot.m
│   └── zeroShiftBlobIDs.m
├── Reference Conversion/
│   ├── nbib2bibtex.m
│   ├── padTags.m
│   └── prepareOutLines.m
├── Retired/
│   ├── Phase Analysis/
│   │   ├── MTK4_2D_IntensityPhaseSpace.asv
│   │   ├── MTK4_2D_IntensityPhaseSpace.m
│   │   └── multiColorQuiver.m
│   ├── batchProcessMeshGrowths.m
│   ├── bulkIndStruct2CCs.m
│   ├── Copy_of_Noah_CoarseningRoadMapEg.m
│   ├── costMatrixTest.m
│   ├── cutRemeshDownsampleMesh.m
│   ├── Ilastikh5ToPlyIsoSurfaceConvert.m
│   ├── Noah_CoarseningRoadMapEg.m
│   ├── plotMeshProperties.m
│   ├── removeMeshEdges.m
│   └── take1GetScaleFromMesh.m
├── SHG/
│   ├── annulus_Average.m
│   ├── comAnalysis.m
│   ├── combine_2chanSegs.m
│   ├── manualTile.m
│   ├── SHG_prelimAnalysis_stackStats.m
│   └── SHG_prelimAnalysis.m
├── Tracking/
│   ├── Retired/
│   │   ├── generatePythonNDArray4TrackPy_storeStruct.asv
│   │   ├── generatePythonNDArray4TrackPy_storeStruct.m
│   │   ├── generatePythonNDArray4TrackPy.m
│   │   ├── getTrajObjTimeTable.m
│   │   └── simpletrackerRevamp.m
│   ├── cens2TrajsSimple.py
│   ├── consObjMatSelTrajs.m
│   ├── generateTrajObjTifsFromTifs.m
│   ├── generateTrajsFromObjs.m
│   ├── getTimeObjTrajTableFromPyTrajs.m
│   ├── guassiansOnIlastikObjectCenters.m
│   ├── mat2pyTrackMat.m
│   ├── saveSelTrajObjsAsTiff.m
│   ├── segDrops2TrajColoredTifs.m
│   ├── singleTimePointTrajGen.m
│   ├── tot2ts.m
│   └── ts2tot.m
├── Velocity Calculation/
│   ├── Functions/
│   │   └── README.md
│   └── Scripts/
│       ├── batch_VelDivergence.m
│       └── PIVfromH5Tif.m
└── README_dependencies.txt
~~~




