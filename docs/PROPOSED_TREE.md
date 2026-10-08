# Proposed project tree

This is the proposed organization for the **future analysis project family**, based on the merged `Active Foam Archive`, the ImageStackIO package, and the SegmentationTools proposal. The umbrella name is provisional. The tree groups reusable APIs separately from dataset workflows and separates material that should not enter active APIs. Function names are first-pass placements; files are not moved or rewritten by this document.

**Scope rules:** internal image arrays use `[Y X Z C T]`; ImageStackIO owns image-file boundaries; SegmentationTools owns masks and labels; geometry and field analysis build on those outputs. Completed 3D PIV remains its own repository and is excluded. Text-file reference conversion remains a separate utility. `.asv` autosaves are omitted from this tree.

```text
Field-Analysis-Relative-to-Morphology/       [GitHub repository root]
├── APIs/
│   ├── ImageStackIO/                               [existing package: imagestackio/]
│   │   ├── src/+imagestackio/
│   │   │   ├── readTiff.m
│   │   │   ├── readH5.m
│   │   │   ├── readND2.m                         [planned; SDK unresolved]
│   │   │   ├── inspectImage.m
│   │   │   ├── writeTiff.m
│   │   │   ├── writeImageJHyperstack.m
│   │   │   ├── private/
│   │   │   │   ├── normalizeAxes.m
│   │   │   │   ├── parseImageJDescription.m
│   │   │   │   ├── parseTiffAxisOrder.m
│   │   │   │   └── writeTiffPages.m
│   │   │   └── +legacy/                            [preserved source versions]
│   │   │       ├── loadH5.m
│   │   │       ├── save3DTiff.m
│   │   │       ├── fastWriteTiff.m
│   │   │       ├── saveNDTiffFIJI.m
│   │   │       ├── genTifTagRGB.m
│   │   │       └── +variants/saveNDTiffFIJI.m
│   │   ├── examples/
│   │   ├── tests/
│   │   └── README.md
│   ├── SegmentationTools/
│   │   ├── src/+segmentationtools/
│   │   │   ├── +binarization/
│   │   │   │   ├── imbinarize3_4D.m
│   │   │   │   └── h5toSmooth3Chans.m            [matrix + channel metadata → 3 masks]
│   │   │   ├── +cleanup/
│   │   │   │   ├── removeConObjs.m
│   │   │   │   ├── sidesHoleFill.m
│   │   │   │   └── dilateErodeSegWeights.m       [script-like; refactor candidate]
│   │   │   ├── +activeContours/
│   │   │   │   ├── activeContourFrame1.m         [separate reusable algorithm from workflow]
│   │   │   │   ├── activeContourFromH5.m         [workflow portions move below]
│   │   │   │   └── generateFirstGuess_morphsnakes.m
│   │   │   └── +morphologySpecific/
│   │   │       ├── +sheets/
│   │   │       │   ├── getCentralSlice.m
│   │   │       │   ├── returnTopBottom2DSheets.m
│   │   │       │   ├── returnCorrectedBinarizedSurfaceIndices.m
│   │   │       │   └── splitSurfaces_Threshold.m  [workflow portions move below]
│   │   │       └── +filaments/
│   │   │           └── [reusable detector extracted from LoG / threshold workflows]
│   │   ├── examples/
│   │   ├── tests/
│   │   └── README.md
│   ├── ObjectGeometry/
│   │   ├── src/+objectgeometry/
│   │   │   ├── +objects/
│   │   │   │   ├── blobMat2CCProps.m
│   │   │   │   ├── distTransFromBoundary.m
│   │   │   │   ├── getDistGrads.m
│   │   │   │   ├── returnSmoothBlobsBW.m
│   │   │   │   ├── returnSmoothBlobsIDed.m
│   │   │   │   ├── returnSmoothBound.m
│   │   │   │   ├── returnSmoothBoundsBW.m
│   │   │   │   ├── returnSmoothBoundsIDed.m
│   │   │   │   ├── skel3DBlobs.m
│   │   │   │   ├── skel3DClean.m
│   │   │   │   ├── skel3Dfrom2D.m
│   │   │   │   ├── skel3DPop.m
│   │   │   │   └── structCutOffThresh.m
│   │   │   ├── +centerlines/
│   │   │   │   ├── filBackBones2D.m
│   │   │   │   ├── filBackBonesND.m
│   │   │   │   ├── coords2Mat_2DFils.m
│   │   │   │   └── storeFilCCs.m               [review overlap with SegmentationTools]
│   │   │   └── +sheets/
│   │   │       ├── rescalePatch.m
│   │   │       └── struct2Mat_sheets.m
│   │   └── examples/skeletonization/
│   │       └── skel3DBlobs_Script.m              [adapt into a reusable function later]
│   ├── SurfaceFieldMapping/
│   │   └── src/+surfacefieldmapping/
│   │       ├── +meshConstruction/
│   │       │   ├── closedSurfaces_h5ToMesh_EnforceNorms.m
│   │       │   ├── closedSurfaces_h5ToPointCloud.m
│   │       │   └── closedSurfaces_splitPtCloudsMeshes.m
│   │       ├── +meshOperations/
│   │       │   ├── confineMeshInMat.m
│   │       │   ├── getMeshDims.m
│   │       │   ├── mesh2mat.m
│   │       │   ├── meshSideRemove.m
│   │       │   ├── remove_isolated_mesh_components.m
│   │       │   ├── removeFacesVerts_Mesh.m
│   │       │   ├── shiftMeshVerts.m
│   │       │   ├── split_mesh_into_components.m
│   │       │   └── split_single_mesh_object.m
│   │       ├── +mapping/
│   │       │   ├── closedSurfaces_FieldsOnMesh.m
│   │       │   └── threeSeg_meanIntProfiles.m
│   │       └── +meshIO/                         [format readers/writers; review dependencies]
│   │           ├── obj2ply.m
│   │           ├── plywrite_norms.m
│   │           ├── readObj_remi.m
│   │           ├── saveObj2PlyFiles.m
│   │           └── plySurf2TIF.m
│   ├── ObjectRelativeProfiles/
│   │   └── src/+objectrelativeprofiles/
│   │       ├── +distance/
│   │       │   ├── blobDensityDeltaR_Blobs.m
│   │       │   ├── blobDensityDeltaR_Skels.m
│   │       │   ├── distanceBinning.m
│   │       │   ├── dropIntensitiesDistRings.m
│   │       │   └── getMTProfile_afterSeg.m
│   │       ├── +objectMetrics/
│   │       │   ├── blobInertiaTensorCalcs.m
│   │       │   ├── blobPropsFromTrajs.m
│   │       │   ├── blobPropsFromTrajs_R_Inertia.m
│   │       │   ├── estimateFirstInertiaMoment.m
│   │       │   ├── meanPropsOverTime.m
│   │       │   ├── dropSurfacesCenters.m
│   │       │   ├── blobVolDistsFromCCs.m
│   │       │   ├── blobVolFractFromh5.m
│   │       │   ├── blobVolFractFromTifs.m
│   │       │   ├── percolationAnalysis.m
│   │       │   ├── secondSegQuant.m
│   │       │   └── volFractAndIntGlobal_Modular.m
│   │       └── +fieldSampling/
│   │           ├── regionInts_Sheets.m
│   │           ├── getHeightProfiles_eachLayer.m
│   │           ├── getIntensityFluxes_2DSheets.m
│   │           ├── getMaxInt_eachLayer.m
│   │           ├── getMeanIntPerZOverT.m
│   │           └── rough_MeanIntProfile.m             [review status]
│   ├── ObjectTracking/
│   │   └── src/+objecttracking/
│   │       ├── consObjMatSelTrajs.m
│   │       ├── generateTrajsFromObjs.m
│   │       ├── getTimeObjTrajTableFromPyTrajs.m
│   │       ├── mat2pyTrackMat.m
│   │       ├── singleTimePointTrajGen.m
│   │       ├── tot2ts.m
│   │       ├── ts2tot.m
│   │       └── +blobLineage/
│   │           ├── digraphOverlapTracking.m
│   │           ├── digraphOverlapTracking_UniqueIDs.m
│   │           ├── IsolateBlobLineage.m
│   │           ├── overlapBlobTrack_fromCCs.m
│   │           ├── overlapBlobTracking.m
│   │           └── overlapBlobTracking_TrackObjectProps.m
│   ├── FieldAnalysis/
│   │   └── src/+fieldanalysis/
│   │       ├── +fourier/
│   │       │   ├── fitToFunction.m
│   │       │   ├── get_meanimg_LiangADAPT.m
│   │       │   ├── get_meanimg_LiangOG.m
│   │       │   ├── get_ProfileScatterFunctions.m
│   │       │   ├── plotSpectra.m
│   │       │   ├── plotSpectra_Multiple.m
│   │       │   └── samCompare.m
│   │       └── +statistics/
│   │           ├── generateRadialMatrix.m
│   │           ├── generateStaticStructureFactor.m
│   │           ├── generateVanHove.m
│   │           └── radiallyAverageMatrix.m
│   ├── VisualizationTools/
│   │   └── src/+visualizationtools/
│   │       ├── mapFieldOnBlobSegs.m
│   │       ├── intsAndSegBoundaries_Tiffs.m
│   │       ├── intsAndSegBoundaries2DImgs_Tiffs.m
│   │       ├── plotBlobStatistics_rEff.m
│   │       ├── plotDeltaRBnds.m
│   │       ├── plotDeltaRSkels.m
│   │       ├── plotFilamentAlignments.m
│   │       ├── plotFirstInertiaMomentData.m
│   │       ├── plotRInertiaStruct.m
│   │       ├── plotSortedMat.m
│   │       ├── plotSortedMat_MultipleOverlap.m
│   │       ├── plotSortedMat_MultipleSave.m
│   │       ├── stitchSkelsAndShells.m
│   │       └── tiffs_BlobOverTime.m
│   ├── SharedUtilities/
│   │   └── src/+sharedutilities/
│   │       ├── +arrays/
│   │       │   ├── arrayCumSum.m
│   │       │   ├── arrayOrganizer2D.m
│   │       │   ├── blockReshape2D.m
│   │       │   ├── consMinValsLayer.m
│   │       │   ├── consScalerMat.m
│   │       │   ├── consMatLnB.m
│   │       │   ├── flatFill3D.m
│   │       │   ├── fillin2D.m
│   │       │   ├── fillin3D.m
│   │       │   ├── generateFieldInterps.m
│   │       │   ├── generateMatrixSubdivisions.m
│   │       │   ├── imresize3_4mat.m
│   │       │   ├── inds3Dto2D.m
│   │       │   ├── lens2Blocks.m
│   │       │   └── rescaleCoords.m
│   │       ├── +miscellaneous/
│   │       │   ├── bndmod.m
│   │       │   ├── cellIndSizes.m
│   │       │   ├── genericLenVec.m
│   │       │   ├── genScaledKVec.m
│   │       │   ├── logic2Ply.m
│   │       │   └── mod1b.m
│   │       ├── +coordinates/
│   │       │   ├── genLenVec.m
│   │       │   ├── genLineInds2D.m
│   │       │   ├── genReflVec.m
│   │       │   ├── getCCVectors.m
│   │       │   ├── getUnitVecs.m
│   │       │   └── rescaleCoords_Inds.m
│   │       ├── +structsAndTables/
│   │       │   ├── addFieldStruct.m
│   │       │   ├── addFieldsStruct.m
│   │       │   ├── concatTablesOverT.m
│   │       │   ├── structFields2Cell.m
│   │       │   ├── structFieldSizes.m
│   │       │   └── structLenVec.m
│   │       ├── +numerics/
│   │       │   ├── GaussD.m
│   │       │   ├── LOG.m
│   │       │   ├── fastLinIntNDScale2.m
│   │       │   ├── generate1DGaussian.m
│   │       │   ├── generate2DGaussian.m
│   │       │   ├── generate3DGaussian.m
│   │       │   ├── generate3DGaussians.m
│   │       │   ├── generateNDHann.m
│   │       │   ├── myconvn.m
│   │       │   ├── ndmeshgrid.m
│   │       │   ├── ndndgrid.m
│   │       │   ├── noNan.m
│   │       │   ├── nonZeroMean.m
│   │       │   ├── poissonDisc.m
│   │       │   └── signedBWDist.m
│   │       └── +plotting/
│   │           ├── figSaves.m
│   │           ├── logAB.m
│   │           ├── loglogBin.m
│   │           ├── manVlnPlot.m
│   │           ├── plotVlns.m
│   │           └── progressBar.m
│   └── TextReferenceConversion/
│       └── src/+textreferenceconversion/
│           ├── nbib2bibtex.m
│           ├── padTags.m
│           └── prepareOutLines.m
├── Workflows/
│   ├── imagePreparation/                       [Tiff/H5 manipulation, correction, cropping, reslicing]
│   │   ├── AccentuateFeatures.m
│   │   ├── batch_3DTo2D.m
│   │   ├── batchCropTifs.m
│   │   ├── batchCropGaussCorrTifs.m
│   │   ├── batchScaleDown3D.m
│   │   ├── batchSampleTifs.m
│   │   ├── batch_tifSubSampleTif.m
│   │   ├── corr3DTiff.m
│   │   ├── generateGaussCorrectionPerZ.m
│   │   ├── rasterCorrectionZ_3DTiff.m
│   │   ├── reslice5DND2.m
│   │   ├── selectZFrom3DTiffs.m
│   │   ├── stackTifs.m
│   │   └── timeSeries_zProjectionFrom3Ds.m
│   ├── segmentationAndImport/
│   │   ├── batch_3SegPerimeters.m
│   │   ├── batch_3SegSubsample.m
│   │   ├── batch_3SegtoPerims.m
│   │   ├── BatchConvertH5toTif.m
│   │   ├── BatchConvertH5toTif_DirtSub.m
│   │   ├── multiDir_batchH5toTif.m
│   │   └── h5toTif.m
│   ├── objects/                                 [droplet/blob project pipelines]
│   │   ├── A_blobsFromH5s.m
│   │   ├── B_blobTracking_StoreObjectProps.m
│   │   ├── C_corrBlobBndsPost.m
│   │   ├── BC_tifs2CC.m
│   │   ├── C_trajsFromBlobs.m
│   │   ├── D_consTrajStruct.m
│   │   ├── E_mergeTrajs.m
│   │   ├── F_getIntHists.m
│   │   ├── IsolateBlobs.m
│   │   ├── batch_RemoveEdgeObjs.m
│   │   └── blobVolFractFromTifs.m
│   ├── sheets/
│   │   ├── A_identifyFromH5_2DSheets.m
│   │   ├── B_generatePointClouds_SplitSheets.m
│   │   ├── C_DataOnMeshes.m
│   │   ├── D_PlotMeshStats.m
│   │   ├── h5ToMesh_homeoAndSplit.m
│   │   └── constructSegmentationTifs.m
│   ├── filaments/                              [elongated-particle detection and analyses]
│   │   ├── A_extractFilsFromTifs.m             [LoG filter + threshold]
│   │   ├── A_getFilamentStats_2Dand3D_FROMH5s.m
│   │   ├── h5Seg_FilamentPosOr.m                [threshold + component filtering]
│   │   ├── COMBINED_Fils2Aligns_InOnOut.m       [header notes this version does not work]
│   │   ├── C_fil2ObjAlignment.m
│   │   ├── C_fil2ObjAlignmentQTensor2D.m
│   │   ├── C_fil2ObjAlignmentQTensor3D.m
│   │   ├── sampleFilsInH5.m
│   │   ├── batch_densityDistributionAlongDeltaR.m
│   │   └── plotFilamentStats_2Dand3D.m
│   ├── meshProcessing/
│   │   ├── allMeshInfoPerTimePoint.m
│   │   ├── filmMeshObjects.m
│   │   ├── splitMeshObjectsOverTime.m
│   │   └── trackMeshCenters.m
│   ├── fourier/
│   │   ├── batch_FFTAnalysis_samAdapt3D.m
│   │   ├── batch_FFTAnalysis_samAdapted.m
│   │   └── batch_intensityFFTAnalysis.m
│   ├── SHG/
│   │   ├── annulus_Average.m
│   │   ├── comAnalysis.m
│   │   ├── combine_2chanSegs.m
│   │   ├── manualTile.m
│   │   ├── SHG_prelimAnalysis.m
│   │   └── SHG_prelimAnalysis_stackStats.m
│   ├── aLENS/
│   │   ├── analyzeClusterTrajectories.m
│   │   ├── getClusterData_Raw.m
│   │   ├── readDAT.m
│   │   └── trackClusterData_Trajectories.m
│   └── researchUtilities/
│       └── reference conversion is separated above
├── ArchiveReview/
│   ├── retired-candidates/                     [demarcated; inspect before excluding]
│   │   ├── former Retired/ folders from archive
│   │   └── files whose headers explicitly say retired, replaced, or not implemented
│   ├── purge-candidates/                        [proposed exclusions; keep archive copies]
│   │   ├── aLENS/globRepl2LT_OLD.m
│   │   ├── filaments/B_prepareFilamentStats_3D.m
│   │   ├── filaments/getMTLengthDist_From3DBW.m [not implemented]
│   │   ├── image-correction/generateGaussCorrectionMask_3DTiff.m
│   │   ├── image-correction/generateGaussCorrectionMaskPerZ_3DTiff.m
│   │   └── piv-coupled/                         [scope review]
│   │       ├── deltaH_PIV_Sheets.m
│   │       ├── intensityVSVelocity_DOTNormal.m
│   │       ├── storeMeshProps_2_AppendPIV_DECVals.m
│   │       └── velocityOrientationDistance.m
│   ├── one-off-workflows/                      [preserve provenance; not APIs]
│   ├── variants/                               [the 9 non-identical backup variants]
│   │   ├── manVlnPlot.m
│   │   ├── A_extractFilsFromTifs.m
│   │   ├── C_fil2ObjAlignment.m
│   │   ├── COMBINED_Fils2Aligns_InOnOut.m
│   │   ├── batch_FFTAnalysis_samAdapted.m
│   │   ├── distTransFromBoundary.m
│   │   ├── batch_tifSubSampleTif.m
│   │   ├── selectZFrom3DTiffs.m
│   │   └── saveNDTiffFIJI.m
│   ├── exact-duplicates/README.md              [manifest, not duplicate source copies]
│   ├── autosaves/                              [not copied; .asv files omitted]
│   └── vendor-review/                          [Chan-Vese omitted from merged archive]
├── docs/
│   ├── PROPOSED_TREE.md
│   ├── CURRENT_SOURCE_TREES.md
│   ├── ARCHIVE_COMBINED_TREE_FIRST_PASS.md
│   ├── SEGMENTATIONTOOLS_PROPOSED_TREE.md
│   └── MIGRATION_NOTES.md
└── scope-not-included/
    └── 3D-PIV/README.md                         [separate completed GitHub project]
```

## Routing of user-marked omissions

I routed all 112 user-marked archive paths into API/workflow groups, display subfolders, examples/prototypes, or ArchiveReview/purge-candidates. Entries retain their archive-relative source path here so same-named files from separate pipeline generations remain distinguishable. Purge-candidate means proposed exclusion for later confirmation; it does not delete the archive copy.

### `APIs/SharedUtilities/src/+sharedutilities/+miscellaneous`

- `bndmod.m` ← `Active Foam Archive/Additional Functions/bndmod.m`
- `cellIndSizes.m` ← `Active Foam Archive/Additional Functions/cellIndSizes.m`
- `genericLenVec.m` ← `Active Foam Archive/Additional Functions/genericLenVec.m`
- `genScaledKVec.m` ← `Active Foam Archive/Additional Functions/genScaledKVec.m`
- `logic2Ply.m` ← `Active Foam Archive/Additional Functions/logic2Ply.m`
- `mod1b.m` ← `Active Foam Archive/Additional Functions/mod1b.m`

### `Workflows/aLENS/functions`

- `conncompDG.m` ← `Active Foam Archive/aLENS Analysis/Functions/conncompDG.m`
- `dat2Mat_Fils.m` ← `Active Foam Archive/aLENS Analysis/Functions/dat2Mat_Fils.m`
- `dg2g.m` ← `Active Foam Archive/aLENS Analysis/Functions/dg2g.m`
- `fieldOnObjs.m` ← `Active Foam Archive/aLENS Analysis/Functions/fieldOnObjs.m`
- `getPairsFieldVals.m` ← `Active Foam Archive/aLENS Analysis/Functions/getPairsFieldVals.m`
- `globRepl2LT.m` ← `Active Foam Archive/aLENS Analysis/Functions/globRepl2LT.m`
- `globRepl2Traj.m` ← `Active Foam Archive/aLENS Analysis/Functions/globRepl2Traj.m`
- `mapWrap.m` ← `Active Foam Archive/aLENS Analysis/Functions/mapWrap.m`
- `readGlobalID.m` ← `Active Foam Archive/aLENS Analysis/Functions/readGlobalID.m`
- `rmedgeAnneal.m` ← `Active Foam Archive/aLENS Analysis/Functions/rmedgeAnneal.m`
- `rmNodeStatic.m` ← `Active Foam Archive/aLENS Analysis/Functions/rmNodeStatic.m`
- `Traj2Props.m` ← `Active Foam Archive/aLENS Analysis/Functions/Traj2Props.m`

### `ArchiveReview/purge-candidates/aLENS`

- `globRepl2LT_OLD.m` ← `Active Foam Archive/aLENS Analysis/Retired/globRepl2LT_OLD.m`

### `APIs/ObjectTracking/src/+objecttracking`

- `addFieldStruct2Traj.m` ← `Active Foam Archive/Analysis - Blobs/Functions/addFieldStruct2Traj.m`

### `Workflows/segmentationAndImport`

- `generateBlobsFromH5Segs.m` ← `Active Foam Archive/Analysis - Blobs/Functions/generateBlobsFromH5Segs.m`

### `Workflows/objects/trajectoryExports`

- `tifsOfTraj_TOT.m` ← `Active Foam Archive/Analysis - Blobs/Functions/tifsOfTraj_TOT.m`
- `tifsOfTraj_trajs.m` ← `Active Foam Archive/Analysis - Blobs/Functions/tifsOfTraj_trajs.m`

### `Workflows/objects/profiles`

- `batch_densityDistributionAlongDeltaR_TIFS.m` ← `Active Foam Archive/Analysis - Drops/batch_densityDistributionAlongDeltaR_TIFS.m`

### `Workflows/objects/blob-pipeline`

- `B_blobsFromH5s.m` ← `Active Foam Archive/Analysis - Drops/Blob Analysis CORE/B_blobsFromH5s.m`

### `APIs/ObjectTracking/src/+objecttracking/+blobLineage`

- `digraphOverlapTracking_UniqueIDs.m` ← `Active Foam Archive/Analysis - Drops/digraphOverlapTracking_UniqueIDs.m`
- `digraphOverlapTracking.m` ← `Active Foam Archive/Analysis - Drops/digraphOverlapTracking.m`
- `IsolateBlobLineage.m` ← `Active Foam Archive/Analysis - Drops/IsolateBlobLineage.m`
- `overlapBlobTrack_fromCCs.m` ← `Active Foam Archive/Analysis - Drops/overlapBlobTrack_fromCCs.m`
- `overlapBlobTracking_TrackObjectProps.m` ← `Active Foam Archive/Analysis - Drops/overlapBlobTracking_TrackObjectProps.m`
- `overlapBlobTracking.m` ← `Active Foam Archive/Analysis - Drops/overlapBlobTracking.m`

### `APIs/SegmentationTools/examples/objectMaskPreparation`

- `generateErodedFrame.m` ← `Active Foam Archive/Analysis - Drops/generateErodedFrame.m`

### `Workflows/objects/display`

- `plotGlobalQuantities.m` ← `Active Foam Archive/Analysis - Drops/plotGlobalQuantities.m`

### `APIs/ObjectGeometry/examples/skeletonization`

- `skel3DBlobs_Script.m` ← `Active Foam Archive/Analysis - Drops/skel3DBlobs_Script.m`

### `Workflows/filaments/alignment-pipeline-thesis-timeline`

- `AlignmentOVERVIEW.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/AlignmentOVERVIEW.m`
- `AppendDensePropsToFilCCs.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/AppendDensePropsToFilCCs.m`
- `Display_AverageAlignment_InOnOutBin.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display_AverageAlignment_InOnOutBin.m`
- `Display_AvgAlign_FromRBins.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display_AvgAlign_FromRBins.m`
- `Display_FilamentsAndBoundaries.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display_FilamentsAndBoundaries.m`
- `Display3Channel_InOnOutCoMs3D.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display3Channel_InOnOutCoMs3D.m`
- `Display3Channel_InOnOutFils3D.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display3Channel_InOnOutFils3D.m`
- `DisplayGradPerim.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/DisplayGradPerim.m`
- `DisplayInOnOut_SparseOnDense2DSlice.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/DisplayInOnOut_SparseOnDense2DSlice.m`
- `rp3DAssignRBins.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/rp3DAssignRBins.m`

### `Workflows/filaments/alignment-pipeline`

- `AppendDensePropsToFilCCs.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline/AppendDensePropsToFilCCs.m`
- `rp3DAssignRBins.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline/rp3DAssignRBins.m`

### `Workflows/filaments/alignment-pipeline/display`

- `Display_AverageAlignment_InOnOutBin.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display_AverageAlignment_InOnOutBin.m`
- `Display_AvgAlign_FromRBins.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display_AvgAlign_FromRBins.m`
- `Display_Filaments2DCuts.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display_Filaments2DCuts.m`
- `Display_FilamentsAndBoundaries.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display_FilamentsAndBoundaries.m`
- `Display3Channel_InOnOutFils3D.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display3Channel_InOnOutFils3D.m`
- `DisplayGradPerim.m` ← `Active Foam Archive/Analysis - Filaments/Alignment Pipeline/DisplayGradPerim.m`

### `Workflows/filaments/measurements`

- `B_prepareFilamentStats_2D.m` ← `Active Foam Archive/Analysis - Filaments/B_prepareFilamentStats_2D.m`
- `getMTLengthDist_From3DCC.m` ← `Active Foam Archive/Analysis - Filaments/getMTLengthDist_From3DCC.m`
- `getMTLengthDist.m` ← `Active Foam Archive/Analysis - Filaments/getMTLengthDist.m`

### `Workflows/filaments`

- `COMBINED_getFilamentStats2D.m` ← `Active Foam Archive/Analysis - Filaments/COMBINED_getFilamentStats2D.m`
- `COMBINED_plotFilamentStats2D.m` ← `Active Foam Archive/Analysis - Filaments/COMBINED_plotFilamentStats2D.m`

### `Workflows/filaments/final-analysis`

- `alignStatsOverTime.m` ← `Active Foam Archive/Analysis - Filaments/Final Analysis/alignStatsOverTime.m`
- `COMBINED_Fils2Aligns_InOnOut_TIFS.m` ← `Active Foam Archive/Analysis - Filaments/Final Analysis/COMBINED_Fils2Aligns_InOnOut_TIFS.m`
- `ConcatTableQuantities.m` ← `Active Foam Archive/Analysis - Filaments/Final Analysis/ConcatTableQuantities.m`
- `prepareTifsForFilProps.m` ← `Active Foam Archive/Analysis - Filaments/Final Analysis/prepareTifsForFilProps.m`

### `Workflows/filaments/final-analysis/display`

- `Display_Filaments2DCuts.m` ← `Active Foam Archive/Analysis - Filaments/Final Analysis/Display_Filaments2DCuts.m`

### `ArchiveReview/purge-candidates/not-implemented`

- `getMTLengthDist_From3DBW.m` ← `Active Foam Archive/Analysis - Filaments/getMTLengthDist_From3DBW.m`

### `ArchiveReview/one-off-workflows/filaments`

- `getFilAligns.m` ← `Active Foam Archive/Analysis - Filaments/One Off/getFilAligns.m`

### `Workflows/filaments/display`

- `PLOT_overlayAlignsAndGrads.m` ← `Active Foam Archive/Analysis - Filaments/PLOT_overlayAlignsAndGrads.m`

### `ArchiveReview/purge-candidates/filaments`

- `B_prepareFilamentStats_3D.m` ← `Active Foam Archive/Analysis - Filaments/Retired/B_prepareFilamentStats_3D.m`

### `ArchiveReview/purge-candidates/piv-coupled`

- `velocityOrientationDistance.m` ← `Active Foam Archive/Analysis - Filaments/velocityOrientationDistance.m`
- `deltaH_PIV_Sheets.m` ← `Active Foam Archive/Analysis - Sheets/Quantification Scripts/deltaH_PIV_Sheets.m`
- `intensityVSVelocity_DOTNormal.m` ← `Active Foam Archive/Analysis - Sheets/Quantification Scripts/intensityVSVelocity_DOTNormal.m`
- `storeMeshProps_2_AppendPIV_DECVals.m` ← `Active Foam Archive/Analysis - Sheets/Quantification Scripts/storeMeshProps_2_AppendPIV_DECVals.m`

### `Workflows/meshProcessing`

- `getGrowthFromMesh.m` ← `Active Foam Archive/Analysis - Meshes General/Functions/getGrowthFromMesh.m`
- `iterateThroughMeshes.m` ← `Active Foam Archive/Analysis - Meshes General/Quantification Scripts/iterateThroughMeshes.m`

### `Workflows/sheets/prototypes`

- `rough_homeotropicThinning.m` ← `Active Foam Archive/Analysis - Sheets/CORE Homeotropic Pt Cloud/rough_homeotropicThinning.m`
- `temp_LapSmoothField.m` ← `Active Foam Archive/Analysis - Sheets/CORE Homeotropic Pt Cloud/temp_LapSmoothField.m`

### `APIs/ObjectGeometry/src/+objectgeometry/+sheets`

- `rescalePatch.m` ← `Active Foam Archive/Analysis - Sheets/Functions/rescalePatch.m`
- `struct2Mat_sheets.m` ← `Active Foam Archive/Analysis - Sheets/Functions/struct2Mat_sheets.m`

### `APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+sheetProfiles`

- `correlateHeightIntensity.m` ← `Active Foam Archive/Analysis - Sheets/Quantification Scripts/correlateHeightIntensity.m`
- `storeMeshProps_1_IntsCurvesVF.m` ← `Active Foam Archive/Analysis - Sheets/Quantification Scripts/storeMeshProps_1_IntsCurvesVF.m`
- `storeMeshProps_Combined.m` ← `Active Foam Archive/Analysis - Sheets/Quantification Scripts/storeMeshProps_Combined.m`

### `APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations`

- `capPtCloudFlat.m` ← `Active Foam Archive/Analysis - Sheets/Tubular Prep Functions/capPtCloudFlat.m`
- `inBetweenFill.m` ← `Active Foam Archive/Analysis - Sheets/Tubular Prep Functions/inBetweenFill.m`

### `Workflows/imagePreparation/illuminationCorrection`

- `corr3DTiff_Simplify.m` ← `Active Foam Archive/Analysis - Tiffs/CORE Image Preparation/corr3DTiff_Simplify.m`
- `sparseChannelCorr.m` ← `Active Foam Archive/Analysis - Tiffs/CORE Image Preparation/sparseChannelCorr.m`
- `generate4DLayerStore_ZandT.m` ← `Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/generate4DLayerStore_ZandT.m`
- `generateArea_BoundingBox.m` ← `Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/generateArea_BoundingBox.m`
- `nzFlat.m` ← `Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/nzFlat.m`

### `APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling`

- `getMeanIntensityOverTime3D.m` ← `Active Foam Archive/Analysis - Tiffs/getMeanIntensityOverTime3D.m`

### `APIs/FieldAnalysis/src/+fieldanalysis/+statistics`

- `twoFieldsCrossCorr.m` ← `Active Foam Archive/Analysis - Tiffs/twoFieldsCrossCorr.m`

### `APIs/VisualizationTools/src/+visualizationtools/+display`

- `getPolyCoords.m` ← `Active Foam Archive/Data Plotting/getPolyCoords.m`
- `plotMeanStdPoly.m` ← `Active Foam Archive/Data Plotting/plotMeanStdPoly.m`
- `plotVanHoveCorrs.m` ← `Active Foam Archive/Data Plotting/plotVanHoveCorrs.m`

### `APIs/SharedUtilities/src/+sharedutilities/+arrays`

- `consMinValsLayer.m` ← `Active Foam Archive/Manipulation - Matrices/consMinValsLayer.m`
- `consScalerMat.m` ← `Active Foam Archive/Manipulation - Matrices/consScalerMat.m`
- `flatFill3D.m` ← `Active Foam Archive/Manipulation - Matrices/flatFill3D.m`
- `generateFieldInterps.m` ← `Active Foam Archive/Manipulation - Matrices/generateFieldInterps.m`
- `generateMatrixSubdivisions.m` ← `Active Foam Archive/Manipulation - Matrices/generateMatrixSubdivisions.m`

### `APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction`

- `consPatchedSheetSurface_Flat.m` ← `Active Foam Archive/Manipulation - Matrices/consPatchedSheetSurface_Flat.m`

### `Workflows/imagePreparation/nd2-and-channel-examples`

- `nd2Sideview.m` ← `Active Foam Archive/Manipulation - Tiffs/Batch Process/nd2Sideview.m`
- `renameFiles.m` ← `Active Foam Archive/Manipulation - Tiffs/Batch Process/renameFiles.m`
- `rough_stitchChannels_avis.m` ← `Active Foam Archive/Manipulation - Tiffs/Batch Process/rough_stitchChannels_avis.m`
- `Updated_nd2Sideview.m` ← `Active Foam Archive/Manipulation - Tiffs/Batch Process/Updated_nd2Sideview.m`
- `Updated_nd2XYView.m` ← `Active Foam Archive/Manipulation - Tiffs/Batch Process/Updated_nd2XYView.m`

### `ArchiveReview/purge-candidates/image-correction`

- `generateGaussCorrectionMask_3DTiff.m` ← `Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/Retired/generateGaussCorrectionMask_3DTiff.m`
- `generateGaussCorrectionMaskPerZ_3DTiff.m` ← `Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/Retired/generateGaussCorrectionMaskPerZ_3DTiff.m`

### `Workflows/imagePreparation/reslicing`

- `nonZeroFlatten.m` ← `Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/nonZeroFlatten.m`
- `tile2DTifs.m` ← `Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/tile2DTifs.m`
- `timeSeries_sideStackFrom3D.m` ← `Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/timeSeries_sideStackFrom3D.m`

### `APIs/ImageStackIO/legacy-or-stack-transforms`

- `cropTiffSave.m` ← `Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/cropTiffSave.m`
- `extend2DTiffAlongZ.m` ← `Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/extend2DTiffAlongZ.m`
- `getLayersOverTimeFrom3DTif.m` ← `Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/getLayersOverTimeFrom3DTif.m`
- `getTotIntOver3DTiffs.m` ← `Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/getTotIntOver3DTiffs.m`
- `split3Dto2D.m` ← `Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/split3Dto2D.m`

## Folder intent and boundaries

- **ImageStackIO** is the first implemented package and owns TIFF/HDF5 read/write and axis normalization. Keep ND2 planned until its SDK dependency is resolved. Cropping, reslicing, projections, and illumination correction stay in workflows.
- **SegmentationTools** groups binarization and cleanup generically, then provides morphology-specific sheet and filament methods. Filament detection scripts stay workflows until their pure array algorithms are extracted. A shape family should become a standalone API only if it grows into a reusable toolbox.
- **ObjectGeometry** provides boundaries, distance transforms, centers, skeletons, and object descriptors from masks or labels. Shell-generating boundary functions belong here, not in SegmentationTools.
- **SurfaceFieldMapping** covers mesh construction, mesh operations, and transfer/sampling of image fields on meshes. Mesh file formats may later split into their own API if usage justifies it.
- **ObjectRelativeProfiles** measures fields by distance to boundaries, centers, skeletons, or surfaces; the tree includes generic object metrics as likely neighbors, with exact API boundary still open.
- **ObjectTracking** owns identity association and trajectory conversion. Domain-specific blob pipelines remain under `Workflows/objects`.
- **FieldAnalysis** contains reusable Fourier and spatial-statistics operations. Fourier batch scripts stay in workflows. PIV-dependent calculations are excluded.
- **VisualizationTools** is a provisional API. Keep plotting/visualization functions only when they are reusable and configuration-driven; move dataset-specific displays into workflows.
- **SharedUtilities** is intentionally provisional. During API extraction, move a helper into the API that owns the concept where possible; keep only genuinely cross-cutting utilities here.
- **Workflows** hold experiment-specific orchestration, file paths/configuration, and combinations of APIs. Filaments are a workflow/domain here even though reusable filament segmentation methods sit inside SegmentationTools.
- **ArchiveReview** is a holding area for preservation and review. Being in a `Retired` source folder alone does not prove a file should be deleted; source and replacement checks come first.

## Candidates intentionally outside this future API family

- All completed 3D PIV source remains in its separate repository. The merged archive's `Velocity Calculation/Functions/README.md` points there; do not copy those functions into this project.
- Chan-Vese vendor code and `ChenVese_Extracted.m` were omitted from the merged archive by the earlier archive instruction. This tree does not reintroduce them.
- Exact duplicates remain documented by the archive manifest rather than copied into the new APIs. Non-identical variants are preserved under `ArchiveReview/variants` until compared.
- `.asv` autosaves and private experimental datasets are not part of the proposed public source tree.

## Status of this tree

This is a project-level architecture tree with the central reusable candidates and representative workflow entry points named. It is not an exhaustive file-by-file copy manifest: the merged archive remains the record of every preserved source file, and the candidate indexes under this mockup retain the broader source filename inventories. Names marked as workflow candidates or header-reported nonworking have not been repaired or tested. No code has been moved and no retired candidates have been deleted.





