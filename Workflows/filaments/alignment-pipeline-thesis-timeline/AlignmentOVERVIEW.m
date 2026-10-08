%% Overview of how I analyzed alignment parameter 2025-04-17
% Begin with 3D stacks of dense MT channel and sparse MT channel over time
%
% Prepare dense:
%   0) Split tifs
%   1) Correct intensity profiles: corr3DTiff_DirtIllum.m; rescale voxels
%   2) Segment three channels in Ilastik
%   3) Threshold segmentations into trinary images: BatchConvertH5toTif.m
%   To avoid swamping storage: run 4-5 once sparse centroids are found!
%   4) Generate signed distance transform: distTransFromBoundary.m
% 4.5) Contours around r=0 gives boundary between drops and bulk
%   5) Take gradient of distance transform
% Prepare sparse:
%   0) Split tifs
%   1) Define filament characterstics: A_extractFilsFromTifs.m (tophat)
%  
% Using sparse and dense (run dense 4-5 here):
%   - Sample grad(dist) and in/on/out class at each filament centroid:
%   COMBINED_Fil2Aligns_InOnOut.m (need to split into functions)
%   - Dot filament director with grad(dist)
%   - Define various order parameters for 2D and 3D (must implement)
%   - Plot average alignment parameter: displyAlignmentParameter.m

%% 2025-04-18
% Dense: BatchConvertH5toTif.m          (crop tifs, identify/binarize fils)
% Sparse: A_extractFilsFromTifs.m, AppendDensePropsToFil.CCs

% Display scripts:
%   - Display_FilamentsAndBoundaries.m: .tifs of filaments + drop bounds
%   - Display_Filaments2DCuts.m:        .tifs of filament oris/grads on img






