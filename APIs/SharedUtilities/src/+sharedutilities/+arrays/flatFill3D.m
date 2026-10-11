function [outMat] = flatFill3D(inMat,dimFills)
%FLATFILL3D Takes in a binarized 3D tiff inMat and fills in holes along the
%requested dimensions dimFills: 0 corresponds to xy, 1 corresponds to yz, 2
%corresponds to xz. dimFills can be a vector of these values.
% 2026-04-27 - Rémi Boros

% Compatibility wrapper added 2026-10-10. The implementation now resides
% in SegmentationTools because this operation changes a segmentation mask.
outMat = segmentationtools.cleanup.flatFill3D(inMat,dimFills);

end

