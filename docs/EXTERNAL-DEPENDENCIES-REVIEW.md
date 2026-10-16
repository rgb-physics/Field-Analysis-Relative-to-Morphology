# External dependency review

October 15, 2026. Source/documentation inventory, not an installation or runtime
audit. All external integrations require individual evaluation. Required MATLAB
toolboxes are separate release requirements. Further unresolved calls discovered
during the full public-operation review must be added here.

| Item | Evidence and role | Status |
| --- | --- | --- |
| Python with NumPy, pandas and Trackpy | trackpy_bridge.py imports the packages; farmTrackPositions invokes the bridge | Direct integration; actual linking and MATLAB/Python execution need evaluation |
| gaussdiff gfilter | farmSkel3DBlobs calls gfilter for Gaussian derivatives | Direct external MATLAB dependency |
| munkres | farmSingleTimePointTrajGen calls munkres | Direct external MATLAB dependency in retained historical implementation |
| inpolyhedron | farmGetMeshDims calls inpolyhedron | Direct external MATLAB dependency |
| plywrite | farmObj2ply, farmSplit_single_mesh_object and farmLogic2Ply call plywrite; farmPlywrite_norms is a different function | Missing from retained file inventory; provider and compatibility unresolved |
| gut_matlab | Attribution/dependency comments in farmGetMeshDims and farmMeshSideRemove | Current mesh-side removal calls retained farmRemoveFacesVerts_Mesh; need distinguish provenance from remaining runtime dependencies |
| MeshLab | Root README says it is required and invoked from MATLAB | No direct invocation found in inspected retained sources; current release role unresolved |
| Ilastik | Upstream source of pixel-classification probabilities | No direct execution found; producer interoperability rather than universal runtime dependency |
| FIJI/ImageJ | TIFF metadata compatibility and manual inspection | No direct execution found; compatibility/visual-check role |
| ND2 reader SDK/provider | ImageStackIO README says reader is planned, not implemented | No provider selected; not an implemented integration |

## User decisions

- Python/NumPy/pandas/Trackpy: optional but strongly recommended. Setup must be
  easy and minimally invasive; evaluate actual integration, not only fake-linker tests.
- gfilter: important. Provide a legible, user-readable dependency setup script
  offering project-local installation of a verified copy when missing, subject
  to redistribution terms, with presence checks and a small functional test.
  Avoid global MATLAB path changes. Implementation is pending scope agreement.
- munkres: ignored for this release. Exclude farmSingleTimePointTrajGen from
  the supported public release interface while preserving its historical source.
  No source removal or modification is authorized by that classification.
- inpolyhedron: optional, mesh API only.
- plywrite: important, optional when not using mesh functionality.
- gut_matlab and MeshLab: important for mesh functionality, optional otherwise;
  document the functionalities associated with each.
- Ilastik: not required; explain its upstream pixel-classification role.
- ND2: desirable eventually, optional and not required now.
- FIJI: user asked whether it is required. No FIJI execution/API bridge was found
  in inspected retained code. MATLAB reads/writes ImageJ TIFF metadata directly;
  FIJI remains a viewer/interoperability target, not an identified runtime requirement.

The inventory table above records original findings, not superseding these decisions.

## Mesh functionality findings

farmGetMeshDims calls inpolyhedron for voxel inclusion, eulerCharacteristic for
Euler characteristic, and isManifoldMesh for manifold/border checks. Its comments
attribute dependencies to gut_matlab and inpolyhedron; providers of the two
topology helpers still need verification. farmMeshSideRemove references gut_matlab
in comments but currently uses retained farmRemoveFacesVerts_Mesh for clipping.

MeshLab invocation was found in archived point-cloud/sheet workflows, not inspected
retained source. Archived descriptions include point-cloud sampling and normal
processing, followed by Poisson/screened-Poisson surface reconstruction. Exact
filter assets, parameters and Python launcher dependencies need a separate review;
this finding does not restore archived workflows to release scope.

## Supplied helper requiring integration review

The user supplied genCorrScaleMat.m from Documents/MATLAB/For Emmanuel/Dependencies.
It constructs a 2D/3D product of reflected-index vectors with the requested input
dimensions. It calls genReflVec; the retained FARM counterpart is farmGenReflVec.
farmGenerateVanHove still calls the absent old helper name. Source was inspected,
not copied, renamed or changed. Integration and scientific normalization checks
remain necessary before claiming this operation is usable.

Subsequent scope decision: defer farmGenerateVanHove and
farmGenerateStaticStructureFactor pending scientific review. Helper integration
is therefore deferred too; retain this source reference for that future work.

## Bundled third-party implementations

farmLOG, farmGaussD and farmMyconvn retain ImSAnE attribution/license comments.
They are bundled code, not evidence that users must install ImSAnE. Include
provenance/license review and obtain user agreement before editing historical
implementations.

Python transitive requirements and any dependencies of external MATLAB packages
must be checked when their specific provider/version is selected. This list is
not a claim that all indirect dependencies have been resolved.

## Implemented local GaussDiff setup

farmInstallGaussdiff accepts an extracted provider folder, checks small constant-field
smoothing and first-derivative results, and installs unchanged required sources locally.
farmSetup adds only that specific dependency folder for the session. Existing differing
files are protected; global paths are not saved. The installer does not yet download
or redistribute third-party code. See LOCAL-DEPENDENCY-SETUP.md.
