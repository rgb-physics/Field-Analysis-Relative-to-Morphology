# Migration checklist

File-by-file first-pass checklist derived from `PROPOSED_TREE.md`. Paths use the local checkout folder `MeMo` as their root. This checklist documents the copy plan; the archived source remains unchanged.

## Scope and rules

- [x] Create a separate `MeMo` directory and keep `Active Foam Archive` unchanged.
- [x] Copy only entries listed in the proposed tree and its explicit user-marked routing section. The 140 paths left omitted remain out of scope.
- [x] Keep 3D PIV separate; do not restore Chan-Vese files; do not include `.asv` autosaves or private datasets.
- [x] Copy and SHA-256 verify each available source file; `readND2.m` remains planned.
- [x] Resolve ambiguous basename matches before copying; preserve non-identical backup variants at their planned `ArchiveReview/variants` destinations.
- [x] Create the proposed directory skeleton and README/docs entries; non-`.m` setup files are listed in the checklist notes below.

Source matches: 499 .m files searched under Active Foam Archive and imagestackio. Planned .m target entries: 351.

| Done | Proposed destination | Source candidate | Mapping note |
|---|---|---|---|
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/readTiff.m` | imagestackio/src/+imagestackio/readTiff.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/readH5.m` | imagestackio/src/+imagestackio/readH5.m | Copied; source path and content verified |
| ☐ | `MeMo/APIs/ImageStackIO/src/+imagestackio/readND2.m` | No source match found | Planned; SDK dependency unresolved |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/inspectImage.m` | imagestackio/src/+imagestackio/inspectImage.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/writeTiff.m` | imagestackio/src/+imagestackio/writeTiff.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/writeImageJHyperstack.m` | imagestackio/src/+imagestackio/writeImageJHyperstack.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/private/normalizeAxes.m` | imagestackio/src/+imagestackio/private/normalizeAxes.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/private/parseImageJDescription.m` | imagestackio/src/+imagestackio/private/parseImageJDescription.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/private/parseTiffAxisOrder.m` | imagestackio/src/+imagestackio/private/parseTiffAxisOrder.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/private/writeTiffPages.m` | imagestackio/src/+imagestackio/private/writeTiffPages.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/+legacy/loadH5.m` | imagestackio/src/+imagestackio/+legacy/loadH5.m | Selected existing ImageStackIO implementation |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/+legacy/save3DTiff.m` | imagestackio/src/+imagestackio/+legacy/save3DTiff.m | Selected existing ImageStackIO implementation |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/+legacy/fastWriteTiff.m` | imagestackio/src/+imagestackio/+legacy/fastWriteTiff.m | Selected existing ImageStackIO implementation |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/+legacy/saveNDTiffFIJI.m` | imagestackio/src/+imagestackio/+legacy/saveNDTiffFIJI.m | Selected package version; variant mapped separately |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/+legacy/genTifTagRGB.m` | imagestackio/src/+imagestackio/+legacy/genTifTagRGB.m | Selected existing ImageStackIO implementation |
| ☑ | `MeMo/APIs/ImageStackIO/src/+imagestackio/+legacy/+variants/saveNDTiffFIJI.m` | imagestackio/src/+imagestackio/+legacy/+variants/saveNDTiffFIJI.m | Direct path match |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+binarization/imbinarize3_4D.m` | Active Foam Archive/Manipulation - Matrices/imbinarize3_4D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+binarization/h5toSmooth3Chans.m` | Active Foam Archive/Manipulation - H5/H5 Functions/h5toSmooth3Chans.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+cleanup/removeConObjs.m` | Active Foam Archive/Manipulation - Matrices/removeConObjs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+cleanup/sidesHoleFill.m` | Active Foam Archive/Manipulation - Matrices/sidesHoleFill.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+cleanup/dilateErodeSegWeights.m` | Active Foam Archive/Additional Functions/Active Contouring/dilateErodeSegWeights.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+activeContours/activeContourFrame1.m` | Active Foam Archive/Additional Functions/Active Contouring/activeContourFrame1.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+activeContours/activeContourFromH5.m` | Active Foam Archive/Additional Functions/Active Contouring/activeContourFromH5.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+activeContours/generateFirstGuess_morphsnakes.m` | Active Foam Archive/Additional Functions/Active Contouring/generateFirstGuess_morphsnakes.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+morphologySpecific/+sheets/getCentralSlice.m` | Active Foam Archive/Additional Functions/Active Contouring/getCentralSlice.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+morphologySpecific/+sheets/returnTopBottom2DSheets.m` | Active Foam Archive/Additional Functions/Active Contouring/returnTopBottom2DSheets.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+morphologySpecific/+sheets/returnCorrectedBinarizedSurfaceIndices.m` | Active Foam Archive/Additional Functions/Active Contouring/returnCorrectedBinarizedSurfaceIndices.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SegmentationTools/src/+segmentationtools/+morphologySpecific/+sheets/splitSurfaces_Threshold.m` | Active Foam Archive/Additional Functions/Active Contouring/splitSurfaces_Threshold.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/blobMat2CCProps.m` | Active Foam Archive/Analysis - Blobs/Functions/blobMat2CCProps.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/distTransFromBoundary.m` | Active Foam Archive/Manipulation - H5/H5 Functions/distTransFromBoundary.m | Selected active archive copy; backup variant mapped separately |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/getDistGrads.m` | Active Foam Archive/Manipulation - H5/H5 Functions/getDistGrads.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBlobsBW.m` | Active Foam Archive/Analysis - Blobs/Functions/returnSmoothBlobsBW.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBlobsIDed.m` | Active Foam Archive/Analysis - Blobs/Functions/returnSmoothBlobsIDed.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBound.m` | Active Foam Archive/Analysis - Blobs/Functions/returnSmoothBound.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBoundsBW.m` | Active Foam Archive/Analysis - Blobs/Functions/returnSmoothBoundsBW.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/returnSmoothBoundsIDed.m` | Active Foam Archive/Analysis - Blobs/Functions/returnSmoothBoundsIDed.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/skel3DBlobs.m` | Active Foam Archive/Analysis - Blobs/Functions/skel3DBlobs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/skel3DClean.m` | Active Foam Archive/Analysis - Sheets/Functions/skel3DClean.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/skel3Dfrom2D.m` | Active Foam Archive/Analysis - Sheets/Functions/skel3Dfrom2D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/skel3DPop.m` | Active Foam Archive/Analysis - Sheets/Functions/skel3DPop.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+objects/structCutOffThresh.m` | Active Foam Archive/Analysis - Blobs/Functions/structCutOffThresh.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+centerlines/filBackBones2D.m` | Active Foam Archive/Analysis - Filaments/Functions/filBackBones2D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+centerlines/filBackBonesND.m` | Active Foam Archive/Analysis - Filaments/Functions/filBackBonesND.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+centerlines/coords2Mat_2DFils.m` | Active Foam Archive/Analysis - Filaments/Functions/coords2Mat_2DFils.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+centerlines/storeFilCCs.m` | Active Foam Archive/Analysis - Filaments/Functions/storeFilCCs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+sheets/rescalePatch.m` | Active Foam Archive/Analysis - Sheets/Functions/rescalePatch.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectGeometry/src/+objectgeometry/+sheets/struct2Mat_sheets.m` | Active Foam Archive/Analysis - Sheets/Functions/struct2Mat_sheets.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectGeometry/examples/skeletonization/skel3DBlobs_Script.m` | Active Foam Archive/Analysis - Drops/skel3DBlobs_Script.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction/closedSurfaces_h5ToMesh_EnforceNorms.m` | Active Foam Archive/Analysis - Blobs/Blob Mesh Analysis/closedSurfaces_h5ToMesh_EnforceNorms.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction/closedSurfaces_h5ToPointCloud.m` | Active Foam Archive/Analysis - Blobs/Blob Mesh Analysis/closedSurfaces_h5ToPointCloud.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction/closedSurfaces_splitPtCloudsMeshes.m` | Active Foam Archive/Analysis - Blobs/Blob Mesh Analysis/closedSurfaces_splitPtCloudsMeshes.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/confineMeshInMat.m` | Active Foam Archive/Manipulation - Meshes/confineMeshInMat.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/getMeshDims.m` | Active Foam Archive/Manipulation - Meshes/getMeshDims.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/mesh2mat.m` | Active Foam Archive/Manipulation - Meshes/mesh2mat.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/meshSideRemove.m` | Active Foam Archive/Manipulation - Meshes/meshSideRemove.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/remove_isolated_mesh_components.m` | Active Foam Archive/Manipulation - Meshes/remove_isolated_mesh_components.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/removeFacesVerts_Mesh.m` | Active Foam Archive/Manipulation - Meshes/removeFacesVerts_Mesh.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/shiftMeshVerts.m` | Active Foam Archive/Manipulation - Meshes/shiftMeshVerts.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/split_mesh_into_components.m` | Active Foam Archive/Manipulation - Meshes/split_mesh_into_components.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/split_single_mesh_object.m` | Active Foam Archive/Manipulation - Meshes/split_single_mesh_object.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+mapping/closedSurfaces_FieldsOnMesh.m` | Active Foam Archive/Analysis - Blobs/Blob Mesh Analysis/closedSurfaces_FieldsOnMesh.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+mapping/threeSeg_meanIntProfiles.m` | Active Foam Archive/Analysis - Blobs/Blob Mesh Analysis/threeSeg_meanIntProfiles.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/obj2ply.m` | Active Foam Archive/Manipulation - Meshes/obj2ply.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/plywrite_norms.m` | Active Foam Archive/Manipulation - Meshes/plywrite_norms.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/readObj_remi.m` | Active Foam Archive/Manipulation - Meshes/readObj_remi.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/saveObj2PlyFiles.m` | Active Foam Archive/Manipulation - Meshes/saveObj2PlyFiles.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshIO/plySurf2TIF.m` | Active Foam Archive/Manipulation - Meshes/plySurf2TIF.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/blobDensityDeltaR_Blobs.m` | Active Foam Archive/Analysis - Blobs/Quantification Scripts/blobDensityDeltaR_Blobs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/blobDensityDeltaR_Skels.m` | Active Foam Archive/Analysis - Blobs/Quantification Scripts/blobDensityDeltaR_Skels.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/distanceBinning.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/distanceBinning.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/dropIntensitiesDistRings.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/dropIntensitiesDistRings.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+distance/getMTProfile_afterSeg.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/getMTProfile_afterSeg.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobInertiaTensorCalcs.m` | Active Foam Archive/Analysis - Blobs/Quantification Scripts/blobInertiaTensorCalcs.m | Selected Blobs copy as geometry/trajectory analysis candidate |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobPropsFromTrajs.m` | Active Foam Archive/Analysis - Blobs/Quantification Scripts/blobPropsFromTrajs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobPropsFromTrajs_R_Inertia.m` | Active Foam Archive/Analysis - Blobs/Quantification Scripts/blobPropsFromTrajs_R_Inertia.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/estimateFirstInertiaMoment.m` | Active Foam Archive/Analysis - Blobs/Quantification Scripts/estimateFirstInertiaMoment.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/meanPropsOverTime.m` | Active Foam Archive/Analysis - Blobs/Quantification Scripts/meanPropsOverTime.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/dropSurfacesCenters.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/dropSurfacesCenters.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobVolDistsFromCCs.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/blobVolDistsFromCCs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobVolFractFromh5.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/blobVolFractFromh5.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/blobVolFractFromTifs.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/blobVolFractFromTifs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/percolationAnalysis.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/percolationAnalysis.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/secondSegQuant.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/secondSegQuant.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+objectMetrics/volFractAndIntGlobal_Modular.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/volFractAndIntGlobal_Modular.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/regionInts_Sheets.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/regionInts_Sheets.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getHeightProfiles_eachLayer.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/getHeightProfiles_eachLayer.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getIntensityFluxes_2DSheets.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/getIntensityFluxes_2DSheets.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getMaxInt_eachLayer.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/getMaxInt_eachLayer.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getMeanIntPerZOverT.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/getMeanIntPerZOverT.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/rough_MeanIntProfile.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/rough_MeanIntProfile.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/consObjMatSelTrajs.m` | Active Foam Archive/Tracking/consObjMatSelTrajs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/generateTrajsFromObjs.m` | Active Foam Archive/Tracking/generateTrajsFromObjs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/getTimeObjTrajTableFromPyTrajs.m` | Active Foam Archive/Tracking/getTimeObjTrajTableFromPyTrajs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/mat2pyTrackMat.m` | Active Foam Archive/Tracking/mat2pyTrackMat.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/singleTimePointTrajGen.m` | Active Foam Archive/Tracking/singleTimePointTrajGen.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/tot2ts.m` | Active Foam Archive/Tracking/tot2ts.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/ts2tot.m` | Active Foam Archive/Tracking/ts2tot.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/+blobLineage/digraphOverlapTracking.m` | Active Foam Archive/Analysis - Drops/digraphOverlapTracking.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/+blobLineage/digraphOverlapTracking_UniqueIDs.m` | Active Foam Archive/Analysis - Drops/digraphOverlapTracking_UniqueIDs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/+blobLineage/IsolateBlobLineage.m` | Active Foam Archive/Analysis - Drops/IsolateBlobLineage.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/+blobLineage/overlapBlobTrack_fromCCs.m` | Active Foam Archive/Analysis - Drops/overlapBlobTrack_fromCCs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/+blobLineage/overlapBlobTracking.m` | Active Foam Archive/Analysis - Drops/overlapBlobTracking.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/+blobLineage/overlapBlobTracking_TrackObjectProps.m` | Active Foam Archive/Analysis - Drops/overlapBlobTracking_TrackObjectProps.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+fourier/fitToFunction.m` | Active Foam Archive/Analysis - Fourier/fitToFunction.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+fourier/get_meanimg_LiangADAPT.m` | Active Foam Archive/Analysis - Fourier/get_meanimg_LiangADAPT.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+fourier/get_meanimg_LiangOG.m` | Active Foam Archive/Analysis - Fourier/get_meanimg_LiangOG.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+fourier/get_ProfileScatterFunctions.m` | Active Foam Archive/Analysis - Fourier/get_ProfileScatterFunctions.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+fourier/plotSpectra.m` | Active Foam Archive/Analysis - Fourier/plotSpectra.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+fourier/plotSpectra_Multiple.m` | Active Foam Archive/Analysis - Fourier/plotSpectra_Multiple.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+fourier/samCompare.m` | Active Foam Archive/Analysis - Fourier/samCompare.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+statistics/generateRadialMatrix.m` | Active Foam Archive/Manipulation - Matrices/generateRadialMatrix.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+statistics/generateStaticStructureFactor.m` | Active Foam Archive/Manipulation - Matrices/generateStaticStructureFactor.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+statistics/generateVanHove.m` | Active Foam Archive/Manipulation - Matrices/generateVanHove.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+statistics/radiallyAverageMatrix.m` | Active Foam Archive/Manipulation - Matrices/radiallyAverageMatrix.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/mapFieldOnBlobSegs.m` | Active Foam Archive/Analysis - Blobs/Visualization Scripts/mapFieldOnBlobSegs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/intsAndSegBoundaries_Tiffs.m` | Active Foam Archive/Analysis - Drops/Visualization Scripts/intsAndSegBoundaries_Tiffs.m | Selected Drops 488-channel workflow copy; alternate remains in archive |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/intsAndSegBoundaries2DImgs_Tiffs.m` | Active Foam Archive/Analysis - Blobs/Visualization Scripts/intsAndSegBoundaries2DImgs_Tiffs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotBlobStatistics_rEff.m` | Active Foam Archive/Analysis - Blobs/Visualization Scripts/plotBlobStatistics_rEff.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotDeltaRBnds.m` | Active Foam Archive/Analysis - Blobs/Data Plotting/plotDeltaRBnds.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotDeltaRSkels.m` | Active Foam Archive/Analysis - Blobs/Data Plotting/plotDeltaRSkels.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotFilamentAlignments.m` | Active Foam Archive/Analysis - Filaments/Data Plotting/plotFilamentAlignments.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotFirstInertiaMomentData.m` | Active Foam Archive/Analysis - Blobs/Data Plotting/plotFirstInertiaMomentData.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotRInertiaStruct.m` | Active Foam Archive/Analysis - Blobs/Data Plotting/plotRInertiaStruct.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotSortedMat.m` | Active Foam Archive/Analysis - Blobs/Data Plotting/plotSortedMat.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotSortedMat_MultipleOverlap.m` | Active Foam Archive/Analysis - Blobs/Data Plotting/plotSortedMat_MultipleOverlap.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/plotSortedMat_MultipleSave.m` | Active Foam Archive/Analysis - Blobs/Data Plotting/plotSortedMat_MultipleSave.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/stitchSkelsAndShells.m` | Active Foam Archive/Analysis - Blobs/Visualization Scripts/stitchSkelsAndShells.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/tiffs_BlobOverTime.m` | Active Foam Archive/Analysis - Blobs/Visualization Scripts/tiffs_BlobOverTime.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/arrayCumSum.m` | Active Foam Archive/Additional Functions/arrayCumSum.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/arrayOrganizer2D.m` | Active Foam Archive/Additional Functions/arrayOrganizer2D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/blockReshape2D.m` | Active Foam Archive/Additional Functions/blockReshape2D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/consMinValsLayer.m` | Active Foam Archive/Manipulation - Matrices/consMinValsLayer.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/consScalerMat.m` | Active Foam Archive/Manipulation - Matrices/consScalerMat.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/consMatLnB.m` | Active Foam Archive/Manipulation - Matrices/consMatLnB.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/flatFill3D.m` | Active Foam Archive/Manipulation - Matrices/flatFill3D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/fillin2D.m` | Active Foam Archive/Manipulation - Matrices/fillin2D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/fillin3D.m` | Active Foam Archive/Manipulation - Matrices/fillin3D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/generateFieldInterps.m` | Active Foam Archive/Manipulation - Matrices/generateFieldInterps.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/generateMatrixSubdivisions.m` | Active Foam Archive/Manipulation - Matrices/generateMatrixSubdivisions.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/imresize3_4mat.m` | Active Foam Archive/Manipulation - Matrices/imresize3_4mat.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/inds3Dto2D.m` | Active Foam Archive/Manipulation - Matrices/inds3Dto2D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/lens2Blocks.m` | Active Foam Archive/Additional Functions/lens2Blocks.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+arrays/rescaleCoords.m` | Active Foam Archive/Manipulation - Matrices/rescaleCoords.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/bndmod.m` | Active Foam Archive/Additional Functions/bndmod.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/cellIndSizes.m` | Active Foam Archive/Additional Functions/cellIndSizes.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/genericLenVec.m` | Active Foam Archive/Additional Functions/genericLenVec.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/genScaledKVec.m` | Active Foam Archive/Additional Functions/genScaledKVec.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/logic2Ply.m` | Active Foam Archive/Additional Functions/logic2Ply.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+miscellaneous/mod1b.m` | Active Foam Archive/Additional Functions/mod1b.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+coordinates/genLenVec.m` | Active Foam Archive/Additional Functions/genLenVec.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+coordinates/genLineInds2D.m` | Active Foam Archive/Additional Functions/genLineInds2D.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+coordinates/genReflVec.m` | Active Foam Archive/Additional Functions/genReflVec.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+coordinates/getCCVectors.m` | Active Foam Archive/Additional Functions/getCCVectors.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+coordinates/getUnitVecs.m` | Active Foam Archive/Additional Functions/getUnitVecs.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+coordinates/rescaleCoords_Inds.m` | Active Foam Archive/Manipulation - Matrices/rescaleCoords_Inds.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/addFieldStruct.m` | Active Foam Archive/Additional Functions/addFieldStruct.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/addFieldsStruct.m` | Active Foam Archive/Additional Functions/addFieldsStruct.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/concatTablesOverT.m` | Active Foam Archive/Additional Functions/concatTablesOverT.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/structFields2Cell.m` | Active Foam Archive/Additional Functions/structFields2Cell.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/structFieldSizes.m` | Active Foam Archive/Additional Functions/structFieldSizes.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+structsAndTables/structLenVec.m` | Active Foam Archive/Additional Functions/structLenVec.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/GaussD.m` | Active Foam Archive/Manipulation - Matrices/GaussD.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/LOG.m` | Active Foam Archive/Manipulation - Matrices/LOG.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/fastLinIntNDScale2.m` | Active Foam Archive/Manipulation - Matrices/fastLinIntNDScale2.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/generate1DGaussian.m` | Active Foam Archive/Manipulation - Matrices/generate1DGaussian.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/generate2DGaussian.m` | Active Foam Archive/Manipulation - Matrices/generate2DGaussian.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/generate3DGaussian.m` | Active Foam Archive/Manipulation - Matrices/generate3DGaussian.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/generate3DGaussians.m` | Active Foam Archive/Manipulation - Matrices/generate3DGaussians.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/generateNDHann.m` | Active Foam Archive/Manipulation - Matrices/generateNDHann.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/myconvn.m` | Active Foam Archive/Manipulation - Matrices/myconvn.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/ndmeshgrid.m` | Active Foam Archive/Manipulation - Matrices/ndmeshgrid.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/ndndgrid.m` | Active Foam Archive/Manipulation - Matrices/ndndgrid.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/noNan.m` | Active Foam Archive/Manipulation - Matrices/noNan.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/nonZeroMean.m` | Active Foam Archive/Manipulation - Matrices/nonZeroMean.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/poissonDisc.m` | Active Foam Archive/Additional Functions/poissonDisc.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+numerics/signedBWDist.m` | Active Foam Archive/Manipulation - Matrices/signedBWDist.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+plotting/figSaves.m` | Active Foam Archive/Additional Functions/figSaves.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+plotting/logAB.m` | Active Foam Archive/Additional Functions/logAB.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+plotting/loglogBin.m` | Active Foam Archive/Additional Functions/loglogBin.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+plotting/manVlnPlot.m` | Active Foam Archive/Additional Functions/manVlnPlot.m | Selected active archive copy; backup variant mapped separately |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+plotting/plotVlns.m` | Active Foam Archive/Additional Functions/plotVlns.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/SharedUtilities/src/+sharedutilities/+plotting/progressBar.m` | Active Foam Archive/Additional Functions/progressBar.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/TextReferenceConversion/src/+textreferenceconversion/nbib2bibtex.m` | Active Foam Archive/Reference Conversion/nbib2bibtex.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/TextReferenceConversion/src/+textreferenceconversion/padTags.m` | Active Foam Archive/Reference Conversion/padTags.m | Copied; source path and content verified |
| ☑ | `MeMo/APIs/TextReferenceConversion/src/+textreferenceconversion/prepareOutLines.m` | Active Foam Archive/Reference Conversion/prepareOutLines.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/AccentuateFeatures.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/AccentuateFeatures.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/batch_3DTo2D.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/batch_3DTo2D.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/batchCropTifs.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/batchCropTifs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/batchCropGaussCorrTifs.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/batchCropGaussCorrTifs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/batchScaleDown3D.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/batchScaleDown3D.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/batchSampleTifs.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/batchSampleTifs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/batch_tifSubSampleTif.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/batch_tifSubSampleTif.m | Selected active archive copy; backup variant mapped separately |
| ☑ | `MeMo/Workflows/imagePreparation/corr3DTiff.m` | Active Foam Archive/Analysis - Tiffs/CORE Image Preparation/corr3DTiff.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/generateGaussCorrectionPerZ.m` | Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/generateGaussCorrectionPerZ.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/rasterCorrectionZ_3DTiff.m` | Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/rasterCorrectionZ_3DTiff.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/reslice5DND2.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/reslice5DND2.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/selectZFrom3DTiffs.m` | Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/selectZFrom3DTiffs.m | Selected active archive copy; backup variant mapped separately |
| ☑ | `MeMo/Workflows/imagePreparation/stackTifs.m` | Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/stackTifs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/imagePreparation/timeSeries_zProjectionFrom3Ds.m` | Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/timeSeries_zProjectionFrom3Ds.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/segmentationAndImport/batch_3SegPerimeters.m` | Active Foam Archive/Manipulation - H5/batch_3SegPerimeters.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/segmentationAndImport/batch_3SegSubsample.m` | Active Foam Archive/Manipulation - H5/batch_3SegSubsample.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/segmentationAndImport/batch_3SegtoPerims.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/batch_3SegtoPerims.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/segmentationAndImport/BatchConvertH5toTif.m` | Active Foam Archive/Manipulation - H5/BatchConvertH5toTif.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/segmentationAndImport/BatchConvertH5toTif_DirtSub.m` | Active Foam Archive/Manipulation - H5/BatchConvertH5toTif_DirtSub.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/segmentationAndImport/multiDir_batchH5toTif.m` | Active Foam Archive/Manipulation - H5/multiDir_batchH5toTif.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/segmentationAndImport/h5toTif.m` | Active Foam Archive/Manipulation - H5/H5 Functions/h5toTif.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/A_blobsFromH5s.m` | Active Foam Archive/Analysis - Blobs/A_blobsFromH5s.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/B_blobTracking_StoreObjectProps.m` | Active Foam Archive/Analysis - Blobs/B_blobTracking_StoreObjectProps.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/C_corrBlobBndsPost.m` | Active Foam Archive/Analysis - Blobs/C_corrBlobBndsPost.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/BC_tifs2CC.m` | Active Foam Archive/Analysis - Drops/Blob Analysis CORE/BC_tifs2CC.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/C_trajsFromBlobs.m` | Active Foam Archive/Analysis - Drops/Blob Analysis CORE/C_trajsFromBlobs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/D_consTrajStruct.m` | Active Foam Archive/Analysis - Drops/Blob Analysis CORE/D_consTrajStruct.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/E_mergeTrajs.m` | Active Foam Archive/Analysis - Drops/Blob Analysis CORE/E_mergeTrajs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/F_getIntHists.m` | Active Foam Archive/Analysis - Drops/Blob Analysis CORE/F_getIntHists.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/IsolateBlobs.m` | Active Foam Archive/Analysis - Drops/IsolateBlobs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/batch_RemoveEdgeObjs.m` | Active Foam Archive/Analysis - Drops/batch_RemoveEdgeObjs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/objects/blobVolFractFromTifs.m` | Active Foam Archive/Analysis - Drops/Quantification Scripts/blobVolFractFromTifs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/sheets/A_identifyFromH5_2DSheets.m` | Active Foam Archive/Analysis - Sheets/CORE Two Sheet Og/A_identifyFromH5_2DSheets.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/sheets/B_generatePointClouds_SplitSheets.m` | Active Foam Archive/Analysis - Sheets/CORE Two Sheet Og/B_generatePointClouds_SplitSheets.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/sheets/C_DataOnMeshes.m` | Active Foam Archive/Analysis - Sheets/CORE Two Sheet Og/C_DataOnMeshes.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/sheets/D_PlotMeshStats.m` | Active Foam Archive/Analysis - Sheets/CORE Two Sheet Og/D_PlotMeshStats.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/sheets/h5ToMesh_homeoAndSplit.m` | Active Foam Archive/Analysis - Sheets/CORE Homeotropic Pt Cloud/h5ToMesh_homeoAndSplit.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/sheets/constructSegmentationTifs.m` | Active Foam Archive/Analysis - Sheets/One Time Scripts/constructSegmentationTifs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/filaments/A_extractFilsFromTifs.m` | Active Foam Archive/Analysis - Filaments/A_extractFilsFromTifs.m | Selected active archive copy; backup variant mapped separately |
| ☑ | `MeMo/Workflows/filaments/A_getFilamentStats_2Dand3D_FROMH5s.m` | Active Foam Archive/Analysis - Filaments/A_getFilamentStats_2Dand3D_FROMH5s.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/filaments/h5Seg_FilamentPosOr.m` | Active Foam Archive/Analysis - Filaments/h5Seg_FilamentPosOr.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/filaments/COMBINED_Fils2Aligns_InOnOut.m` | Active Foam Archive/Analysis - Filaments/COMBINED_Fils2Aligns_InOnOut.m | Selected active archive copy; backup variant mapped separately |
| ☑ | `MeMo/Workflows/filaments/C_fil2ObjAlignment.m` | Active Foam Archive/Analysis - Filaments/C_fil2ObjAlignment.m | Selected active archive copy; backup variant mapped separately |
| ☑ | `MeMo/Workflows/filaments/C_fil2ObjAlignmentQTensor2D.m` | Active Foam Archive/Analysis - Filaments/C_fil2ObjAlignmentQTensor2D.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/filaments/C_fil2ObjAlignmentQTensor3D.m` | Active Foam Archive/Analysis - Filaments/C_fil2ObjAlignmentQTensor3D.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/filaments/sampleFilsInH5.m` | Active Foam Archive/Analysis - Filaments/sampleFilsInH5.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/filaments/batch_densityDistributionAlongDeltaR.m` | Active Foam Archive/Analysis - Filaments/batch_densityDistributionAlongDeltaR.m | Selected Filaments copy to match workflow destination |
| ☑ | `MeMo/Workflows/filaments/plotFilamentStats_2Dand3D.m` | Active Foam Archive/Analysis - Filaments/plotFilamentStats_2Dand3D.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/meshProcessing/allMeshInfoPerTimePoint.m` | Active Foam Archive/Manipulation - Meshes Scripts/allMeshInfoPerTimePoint.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/meshProcessing/filmMeshObjects.m` | Active Foam Archive/Manipulation - Meshes Scripts/filmMeshObjects.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/meshProcessing/splitMeshObjectsOverTime.m` | Active Foam Archive/Manipulation - Meshes Scripts/splitMeshObjectsOverTime.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/meshProcessing/trackMeshCenters.m` | Active Foam Archive/Manipulation - Meshes Scripts/trackMeshCenters.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/fourier/batch_FFTAnalysis_samAdapt3D.m` | Active Foam Archive/Analysis - Fourier/batch_FFTAnalysis_samAdapt3D.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/fourier/batch_FFTAnalysis_samAdapted.m` | Active Foam Archive/Analysis - Fourier/batch_FFTAnalysis_samAdapted.m | Selected active archive copy; backup variant mapped separately |
| ☑ | `MeMo/Workflows/fourier/batch_intensityFFTAnalysis.m` | Active Foam Archive/Analysis - Fourier/batch_intensityFFTAnalysis.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/SHG/annulus_Average.m` | Active Foam Archive/SHG/annulus_Average.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/SHG/comAnalysis.m` | Active Foam Archive/SHG/comAnalysis.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/SHG/combine_2chanSegs.m` | Active Foam Archive/SHG/combine_2chanSegs.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/SHG/manualTile.m` | Active Foam Archive/SHG/manualTile.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/SHG/SHG_prelimAnalysis.m` | Active Foam Archive/SHG/SHG_prelimAnalysis.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/SHG/SHG_prelimAnalysis_stackStats.m` | Active Foam Archive/SHG/SHG_prelimAnalysis_stackStats.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/aLENS/analyzeClusterTrajectories.m` | Active Foam Archive/aLENS Analysis/Scripts/analyzeClusterTrajectories.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/aLENS/getClusterData_Raw.m` | Active Foam Archive/aLENS Analysis/Scripts/getClusterData_Raw.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/aLENS/readDAT.m` | Active Foam Archive/aLENS Analysis/Scripts/readDAT.m | Copied; source path and content verified |
| ☑ | `MeMo/Workflows/aLENS/trackClusterData_Trajectories.m` | Active Foam Archive/aLENS Analysis/Scripts/trackClusterData_Trajectories.m | Copied; source path and content verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/aLENS/globRepl2LT_OLD.m` | Active Foam Archive/aLENS Analysis/Retired/globRepl2LT_OLD.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/filaments/B_prepareFilamentStats_3D.m` | Active Foam Archive/Analysis - Filaments/Retired/B_prepareFilamentStats_3D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/image-correction/generateGaussCorrectionMask_3DTiff.m` | Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/Retired/generateGaussCorrectionMask_3DTiff.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/image-correction/generateGaussCorrectionMaskPerZ_3DTiff.m` | Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/Retired/generateGaussCorrectionMaskPerZ_3DTiff.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/piv-coupled/deltaH_PIV_Sheets.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/deltaH_PIV_Sheets.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/piv-coupled/intensityVSVelocity_DOTNormal.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/intensityVSVelocity_DOTNormal.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/piv-coupled/storeMeshProps_2_AppendPIV_DECVals.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/storeMeshProps_2_AppendPIV_DECVals.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/piv-coupled/velocityOrientationDistance.m` | Active Foam Archive/Analysis - Filaments/velocityOrientationDistance.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/variants/manVlnPlot.m` | Active Foam Archive/AF - Backup Variants/Additional Functions/manVlnPlot.m | Backup variant |
| ☑ | `MeMo/ArchiveReview/variants/A_extractFilsFromTifs.m` | Active Foam Archive/AF - Backup Variants/Analysis - Filaments/A_extractFilsFromTifs.m | Backup variant |
| ☑ | `MeMo/ArchiveReview/variants/C_fil2ObjAlignment.m` | Active Foam Archive/AF - Backup Variants/Analysis - Filaments/C_fil2ObjAlignment.m | Backup variant |
| ☑ | `MeMo/ArchiveReview/variants/COMBINED_Fils2Aligns_InOnOut.m` | Active Foam Archive/AF - Backup Variants/Analysis - Filaments/COMBINED_Fils2Aligns_InOnOut.m | Backup variant |
| ☑ | `MeMo/ArchiveReview/variants/batch_FFTAnalysis_samAdapted.m` | Active Foam Archive/AF - Backup Variants/Analysis - Fourier/batch_FFTAnalysis_samAdapted.m | Backup variant |
| ☑ | `MeMo/ArchiveReview/variants/distTransFromBoundary.m` | Active Foam Archive/AF - Backup Variants/Manipulation - h5/H5 Functions/distTransFromBoundary.m | Backup variant |
| ☑ | `MeMo/ArchiveReview/variants/batch_tifSubSampleTif.m` | Active Foam Archive/AF - Backup Variants/Manipulation - Tiffs/Batch Process/batch_tifSubSampleTif.m | Backup variant |
| ☑ | `MeMo/ArchiveReview/variants/selectZFrom3DTiffs.m` | Active Foam Archive/AF - Backup Variants/Manipulation - Tiffs/Reslice Scripts/selectZFrom3DTiffs.m | Backup variant |
| ☑ | `MeMo/ArchiveReview/variants/saveNDTiffFIJI.m` | Active Foam Archive/AF - Backup Variants/Manipulation - Tiffs/Tiff Manipulation Functions/saveNDTiffFIJI.m | Backup variant |
| ☑ | `MeMo/Workflows/aLENS/functions/conncompDG.m` | Active Foam Archive/aLENS Analysis/Functions/conncompDG.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/dat2Mat_Fils.m` | Active Foam Archive/aLENS Analysis/Functions/dat2Mat_Fils.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/dg2g.m` | Active Foam Archive/aLENS Analysis/Functions/dg2g.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/fieldOnObjs.m` | Active Foam Archive/aLENS Analysis/Functions/fieldOnObjs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/getPairsFieldVals.m` | Active Foam Archive/aLENS Analysis/Functions/getPairsFieldVals.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/globRepl2LT.m` | Active Foam Archive/aLENS Analysis/Functions/globRepl2LT.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/globRepl2Traj.m` | Active Foam Archive/aLENS Analysis/Functions/globRepl2Traj.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/mapWrap.m` | Active Foam Archive/aLENS Analysis/Functions/mapWrap.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/readGlobalID.m` | Active Foam Archive/aLENS Analysis/Functions/readGlobalID.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/rmedgeAnneal.m` | Active Foam Archive/aLENS Analysis/Functions/rmedgeAnneal.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/rmNodeStatic.m` | Active Foam Archive/aLENS Analysis/Functions/rmNodeStatic.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/aLENS/functions/Traj2Props.m` | Active Foam Archive/aLENS Analysis/Functions/Traj2Props.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectTracking/src/+objecttracking/addFieldStruct2Traj.m` | Active Foam Archive/Analysis - Blobs/Functions/addFieldStruct2Traj.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/segmentationAndImport/generateBlobsFromH5Segs.m` | Active Foam Archive/Analysis - Blobs/Functions/generateBlobsFromH5Segs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/objects/trajectoryExports/tifsOfTraj_TOT.m` | Active Foam Archive/Analysis - Blobs/Functions/tifsOfTraj_TOT.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/objects/trajectoryExports/tifsOfTraj_trajs.m` | Active Foam Archive/Analysis - Blobs/Functions/tifsOfTraj_trajs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/objects/profiles/batch_densityDistributionAlongDeltaR_TIFS.m` | Active Foam Archive/Analysis - Drops/batch_densityDistributionAlongDeltaR_TIFS.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/objects/blob-pipeline/B_blobsFromH5s.m` | Active Foam Archive/Analysis - Drops/Blob Analysis CORE/B_blobsFromH5s.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SegmentationTools/examples/objectMaskPreparation/generateErodedFrame.m` | Active Foam Archive/Analysis - Drops/generateErodedFrame.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/objects/display/plotGlobalQuantities.m` | Active Foam Archive/Analysis - Drops/plotGlobalQuantities.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/AlignmentOVERVIEW.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/AlignmentOVERVIEW.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/AppendDensePropsToFilCCs.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/AppendDensePropsToFilCCs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/Display_AverageAlignment_InOnOutBin.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display_AverageAlignment_InOnOutBin.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/Display_AvgAlign_FromRBins.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display_AvgAlign_FromRBins.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/Display_FilamentsAndBoundaries.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display_FilamentsAndBoundaries.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/Display3Channel_InOnOutCoMs3D.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display3Channel_InOnOutCoMs3D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/Display3Channel_InOnOutFils3D.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/Display3Channel_InOnOutFils3D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/DisplayGradPerim.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/DisplayGradPerim.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/DisplayInOnOut_SparseOnDense2DSlice.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/DisplayInOnOut_SparseOnDense2DSlice.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline-thesis-timeline/rp3DAssignRBins.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline - Thesis Timeline/rp3DAssignRBins.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline/AppendDensePropsToFilCCs.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline/AppendDensePropsToFilCCs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline/rp3DAssignRBins.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline/rp3DAssignRBins.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline/display/Display_AverageAlignment_InOnOutBin.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display_AverageAlignment_InOnOutBin.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline/display/Display_AvgAlign_FromRBins.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display_AvgAlign_FromRBins.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline/display/Display_Filaments2DCuts.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display_Filaments2DCuts.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline/display/Display_FilamentsAndBoundaries.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display_FilamentsAndBoundaries.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline/display/Display3Channel_InOnOutFils3D.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline/Display3Channel_InOnOutFils3D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/alignment-pipeline/display/DisplayGradPerim.m` | Active Foam Archive/Analysis - Filaments/Alignment Pipeline/DisplayGradPerim.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/measurements/B_prepareFilamentStats_2D.m` | Active Foam Archive/Analysis - Filaments/B_prepareFilamentStats_2D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/measurements/getMTLengthDist_From3DCC.m` | Active Foam Archive/Analysis - Filaments/getMTLengthDist_From3DCC.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/measurements/getMTLengthDist.m` | Active Foam Archive/Analysis - Filaments/getMTLengthDist.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/COMBINED_getFilamentStats2D.m` | Active Foam Archive/Analysis - Filaments/COMBINED_getFilamentStats2D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/COMBINED_plotFilamentStats2D.m` | Active Foam Archive/Analysis - Filaments/COMBINED_plotFilamentStats2D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/final-analysis/alignStatsOverTime.m` | Active Foam Archive/Analysis - Filaments/Final Analysis/alignStatsOverTime.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/final-analysis/COMBINED_Fils2Aligns_InOnOut_TIFS.m` | Active Foam Archive/Analysis - Filaments/Final Analysis/COMBINED_Fils2Aligns_InOnOut_TIFS.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/final-analysis/ConcatTableQuantities.m` | Active Foam Archive/Analysis - Filaments/Final Analysis/ConcatTableQuantities.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/final-analysis/prepareTifsForFilProps.m` | Active Foam Archive/Analysis - Filaments/Final Analysis/prepareTifsForFilProps.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/final-analysis/display/Display_Filaments2DCuts.m` | Active Foam Archive/Analysis - Filaments/Final Analysis/Display_Filaments2DCuts.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/purge-candidates/not-implemented/getMTLengthDist_From3DBW.m` | Active Foam Archive/Analysis - Filaments/getMTLengthDist_From3DBW.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/ArchiveReview/one-off-workflows/filaments/getFilAligns.m` | Active Foam Archive/Analysis - Filaments/One Off/getFilAligns.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/filaments/display/PLOT_overlayAlignsAndGrads.m` | Active Foam Archive/Analysis - Filaments/PLOT_overlayAlignsAndGrads.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/meshProcessing/getGrowthFromMesh.m` | Active Foam Archive/Analysis - Meshes General/Functions/getGrowthFromMesh.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/meshProcessing/iterateThroughMeshes.m` | Active Foam Archive/Analysis - Meshes General/Quantification Scripts/iterateThroughMeshes.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/sheets/prototypes/rough_homeotropicThinning.m` | Active Foam Archive/Analysis - Sheets/CORE Homeotropic Pt Cloud/rough_homeotropicThinning.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/sheets/prototypes/temp_LapSmoothField.m` | Active Foam Archive/Analysis - Sheets/CORE Homeotropic Pt Cloud/temp_LapSmoothField.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+sheetProfiles/correlateHeightIntensity.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/correlateHeightIntensity.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+sheetProfiles/storeMeshProps_1_IntsCurvesVF.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/storeMeshProps_1_IntsCurvesVF.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+sheetProfiles/storeMeshProps_Combined.m` | Active Foam Archive/Analysis - Sheets/Quantification Scripts/storeMeshProps_Combined.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/capPtCloudFlat.m` | Active Foam Archive/Analysis - Sheets/Tubular Prep Functions/capPtCloudFlat.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshOperations/inBetweenFill.m` | Active Foam Archive/Analysis - Sheets/Tubular Prep Functions/inBetweenFill.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/illuminationCorrection/corr3DTiff_Simplify.m` | Active Foam Archive/Analysis - Tiffs/CORE Image Preparation/corr3DTiff_Simplify.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/illuminationCorrection/sparseChannelCorr.m` | Active Foam Archive/Analysis - Tiffs/CORE Image Preparation/sparseChannelCorr.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/illuminationCorrection/generate4DLayerStore_ZandT.m` | Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/generate4DLayerStore_ZandT.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/illuminationCorrection/generateArea_BoundingBox.m` | Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/generateArea_BoundingBox.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/illuminationCorrection/nzFlat.m` | Active Foam Archive/Manipulation - Tiffs/Image Correction Functions/nzFlat.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ObjectRelativeProfiles/src/+objectrelativeprofiles/+fieldSampling/getMeanIntensityOverTime3D.m` | Active Foam Archive/Analysis - Tiffs/getMeanIntensityOverTime3D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/FieldAnalysis/src/+fieldanalysis/+statistics/twoFieldsCrossCorr.m` | Active Foam Archive/Analysis - Tiffs/twoFieldsCrossCorr.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/+display/getPolyCoords.m` | Active Foam Archive/Data Plotting/getPolyCoords.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/+display/plotMeanStdPoly.m` | Active Foam Archive/Data Plotting/plotMeanStdPoly.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/VisualizationTools/src/+visualizationtools/+display/plotVanHoveCorrs.m` | Active Foam Archive/Data Plotting/plotVanHoveCorrs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/SurfaceFieldMapping/src/+surfacefieldmapping/+meshConstruction/consPatchedSheetSurface_Flat.m` | Active Foam Archive/Manipulation - Matrices/consPatchedSheetSurface_Flat.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/nd2-and-channel-examples/nd2Sideview.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/nd2Sideview.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/nd2-and-channel-examples/renameFiles.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/renameFiles.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/nd2-and-channel-examples/rough_stitchChannels_avis.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/rough_stitchChannels_avis.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/nd2-and-channel-examples/Updated_nd2Sideview.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/Updated_nd2Sideview.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/nd2-and-channel-examples/Updated_nd2XYView.m` | Active Foam Archive/Manipulation - Tiffs/Batch Process/Updated_nd2XYView.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/reslicing/nonZeroFlatten.m` | Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/nonZeroFlatten.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/reslicing/tile2DTifs.m` | Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/tile2DTifs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/Workflows/imagePreparation/reslicing/timeSeries_sideStackFrom3D.m` | Active Foam Archive/Manipulation - Tiffs/Reslice Scripts/timeSeries_sideStackFrom3D.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ImageStackIO/legacy-or-stack-transforms/cropTiffSave.m` | Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/cropTiffSave.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ImageStackIO/legacy-or-stack-transforms/extend2DTiffAlongZ.m` | Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/extend2DTiffAlongZ.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ImageStackIO/legacy-or-stack-transforms/getLayersOverTimeFrom3DTif.m` | Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/getLayersOverTimeFrom3DTif.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ImageStackIO/legacy-or-stack-transforms/getTotIntOver3DTiffs.m` | Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/getTotIntOver3DTiffs.m | Copied; explicit source mapping verified |
| ☑ | `MeMo/APIs/ImageStackIO/legacy-or-stack-transforms/split3Dto2D.m` | Active Foam Archive/Manipulation - Tiffs/Tiff Manipulation Functions/split3Dto2D.m | Copied; explicit source mapping verified |

## Non-code setup tasks

- [x] Create the directories shown in `PROPOSED_TREE.md`, including `examples/`, `tests/`, and `ArchiveReview/` locations.
- [x] Add the root, package, and review README files and the proposed docs; preserve `MIGRATION_NOTES.md` as the migration record.
- [x] Add the 3D PIV pointer README and the historical exact-duplicates manifest README.
- [x] Review the existing `ImageStackIO` package against the proposed names; keep the ND2 reader marked as planned until its SDK dependency is resolved.

## Review queue

- Ambiguous source rows: 0. All were resolved and their selected source paths are recorded above.
- Missing/planned source rows: 1. `readND2.m` is planned; resolve the ND2 SDK dependency before implementation.
- The checklist is intentionally not a claim that every source has been verified as usable or tested.
