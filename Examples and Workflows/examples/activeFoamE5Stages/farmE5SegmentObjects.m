function c = farmE5SegmentObjects(c)
%FARME5SEGMENTOBJECTS Convert probabilities into inside, boundary/on, and outside regions.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.SemanticChannels: source channels in [inside, boundary/on, outside] order.
%   c.Thresholds: threshold for each selected probability category.
%   c.OpeningRadius: morphological opening radius in probability-grid voxels.
%   c.FillMethod: 'none', 'nearest', or highest-precedence 'fill' after opening.
%   c.RegionInterpolation: nearest-neighbor interpolation for category labels.
% Earlier results read:
%   c.Results.Probabilities: probability array from farmE5LoadData.
%   c.Results.TargetSize: target intensity-grid dimensions from farmE5LoadData.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.RegionMasks, SegmentationInfo: probability-grid masks and calculation details.
%   c.Results.Regions: intensity-grid labels, 0 unclassified, 1 inside, 2 on, 3 outside.
%   c.Results.InsideMask, BoundaryRegionMask, OutsideMask: intensity-grid category masks.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
probabilities = c.Results.Probabilities;
targetSize = c.Results.TargetSize;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[regionMasks, segmentationInfo] = farmSmoothNChannelProbabilities( ...
    probabilities, c.SemanticChannels, c.Thresholds, ...
    struct('OpeningRadius', c.OpeningRadius, 'FillMethod', c.FillMethod));
regions = zeros(size(probabilities, 1), size(probabilities, 2), size(probabilities, 3), 'uint8');
for category = 1:3
    categoryMask = regionMasks(:, :, :, category);
    regions(categoryMask) = category;
end
% Place the categories on the intensity grid. This assumes the
% supplied sources describe the same physical field of view.
% Resampling uses user-supplied metadata; calibration is not estimated.
regions = imresize3(regions, targetSize, c.RegionInterpolation);
insideMask = regions == 1;
boundaryRegionMask = regions == 2;
outsideMask = regions == 3;

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.RegionMasks = regionMasks;
c.Results.SegmentationInfo = segmentationInfo;
c.Results.Regions = regions;
c.Results.InsideMask = insideMask;
c.Results.BoundaryRegionMask = boundaryRegionMask;
c.Results.OutsideMask = outsideMask;
end
