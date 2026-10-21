function [masks, info] = farmSmoothNChannelProbabilities(probabilities, channels, thresholds, options)
%FARMSMOOTHNCHANNELPROBABILITIES Segment probability channels into separate masks.
% Inputs:
%   probabilities   Finite real numeric array in [Y X Z C] order.
%   channels        Numeric vector of input channel numbers, such as [3 2 1].
%                   Use [] to select all channels in their stored order.
%   thresholds      One number for all selected channels, or one per channel
%                   in channels order. A value must be strictly greater than
%                   its threshold to be selected. Probabilities are not rescaled.
%   options         Optional scalar struct with the fields:
%                   OpeningRadius = nonnegative integer scalar;
%                   ChannelPrecedence = numeric vector of channel numbers;
%                   ReturnOpenedMasks = logical scalar;
%                   FillMethod = text ('none', 'nearest', or 'fill').
% Outputs:
%   masks           Logical [Y X Z N] array, one mask per selected channel,
%                   in channels order. No voxel belongs to more than one mask.
%   info            Settings, per-channel counts, overlap count before overlap
%                   removal, and the number of unclassified voxels.

if nargin < 4 || isempty(options)
    options = struct();
end
if ~(isnumeric(probabilities) && isreal(probabilities) && ...
     ~issparse(probabilities) && ~isempty(probabilities) && ...
     ndims(probabilities) <= 4 && all(isfinite(probabilities(:))))
    error('segmentationtools:InvalidProbabilities', 'Use finite real numeric [Y X Z C] data.');
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', 'Options must be a scalar struct.');
end
defaults = struct('OpeningRadius', 2, 'ChannelPrecedence', [], ...
    'ReturnOpenedMasks', false, 'FillMethod', 'none');
unknown = setdiff(fieldnames(options), fieldnames(defaults));
if ~isempty(unknown)
    error('segmentationtools:UnknownOption', 'Unknown option: %s', unknown{1});
end
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(options, names{i})
        options.(names{i}) = defaults.(names{i});
    end
end
if isempty(channels)
    channels = 1:size(probabilities, 4);
end
validateattributes(channels, {'numeric'}, {'real', 'finite', 'vector', 'integer', 'positive', 'nonempty'});
channels = double(channels(:).');
if numel(unique(channels)) ~= numel(channels)
    error('segmentationtools:DuplicateChannels', 'Selected channels must be unique.');
end
if any(channels > size(probabilities, 4))
    error('segmentationtools:ChannelOutOfRange', 'A selected channel exceeds the channel count.');
end
validateattributes(thresholds, {'numeric'}, {'real', 'finite', 'vector', 'nonempty'});
thresholds = double(thresholds(:).');
if isscalar(thresholds)
    thresholds = repmat(thresholds, 1, numel(channels));
end
if numel(thresholds) ~= numel(channels)
    error('segmentationtools:InvalidThresholdCount', 'Use one threshold or one per selected channel.');
end
precedence = options.ChannelPrecedence;
if isempty(precedence)
    precedence = channels;
end
validateattributes(precedence, {'numeric'}, {'real', 'finite', 'vector', 'integer', 'positive'});
precedence = double(precedence(:).');
if ~isequal(sort(precedence), sort(channels))
    error('segmentationtools:InvalidChannelPrecedence', ...
          'ChannelPrecedence must list every selected input channel exactly once.');
end
radius = options.OpeningRadius;
validateattributes(radius, {'numeric'}, {'real', 'finite', 'scalar', 'integer', 'nonnegative'});
validateattributes(options.ReturnOpenedMasks, {'logical'}, {'scalar'});
fillMethod = validatestring(options.FillMethod, {'none', 'nearest', 'fill'});
spatialSize = [size(probabilities, 1) size(probabilities, 2) size(probabilities, 3)];
opened = false([spatialSize numel(channels)]);
if radius > 0
    if spatialSize(3) == 1
        kernel = strel('disk', radius, 0);
    else
        kernel = strel('sphere', radius);
    end
end
for i = 1:numel(channels)
    candidate = farmThresholdProbabilityGroup( ...
                                              probabilities, channels(i), thresholds(i));
    if radius > 0
        candidate = imdilate(imerode(candidate, kernel), kernel);
    end
    opened(:, :, :, i) = candidate;
end
masks = false(size(opened));
claimed = false(spatialSize);
for channel = precedence
    i = find(channels == channel);
    masks(:, :, :, i) = opened(:, :, :, i) & ~claimed;
    claimed = claimed | masks(:, :, :, i);
end

% Fill Unclassified Locations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fill only after opening and overlap resolution; retain existing assignments.
unclassified = ~claimed;
unclassifiedBeforeFill = nnz(unclassified);
if unclassifiedBeforeFill > 0
    switch fillMethod
        case 'nearest'
            % One Euclidean transform identifies the nearest classified voxel.
            % Use voxel distances and MATLAB's nearest-voxel choice for ties.
            [~, nearestIndex] = bwdist(claimed, 'euclidean');
            nearestIndex = nearestIndex(unclassified);
            for i = 1:numel(channels)
                channelMask = masks(:, :, :, i);
                channelMask(unclassified) = channelMask(nearestIndex);
                masks(:, :, :, i) = channelMask;
            end
            claimed(:) = true;
        case 'fill'
            % Precedence lists input channel numbers, not output positions.
            i = find(channels == precedence(1));
            masks(:, :, :, i) = masks(:, :, :, i) | unclassified;
            claimed(:) = true;
    end
end

info = struct('Channels', channels, 'ChannelPrecedence', precedence, ...
              'ThresholdsUsed', thresholds, 'OpeningRadius', radius, ...
              'FillMethod', fillMethod, ...
              'VoxelCounts', reshape(sum(masks, [1 2 3]), 1, []), ...
              'OverlapVoxelCountBeforeResolution', nnz(sum(opened, 4) > 1), ...
              'UnclassifiedVoxelCountBeforeFill', unclassifiedBeforeFill, ...
              'FilledVoxelCount', unclassifiedBeforeFill - nnz(~claimed), ...
              'UnclassifiedVoxelCount', nnz(~claimed));
if options.ReturnOpenedMasks
    info.OpenedMasks = opened;
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSMOOTHNCHANNELPROBABILITIES Threshold, open, and resolve N channel masks.
% P is [Y X Z C]. CHANNELS=[] selects all channels in input order.
% THRESHOLDS is one shared value or one per selected channel, aligned with
% CHANNELS (not precedence). Comparisons are strict; no normalization occurs.
% MASKS is logical [Y X Z N], in CHANNELS order, and is always disjoint.
% Voxels not retained by any opened mask are handled by FillMethod.
%
% OPTIONS.OpeningRadius: nonnegative integer, default 2 voxels; 0 disables
% opening. Each candidate is eroded then dilated independently before overlap
% resolution. A disk is used for 2-D input and sphere for 3-D input. Radius
% is in voxel units; anisotropic spacing is not corrected.
% OPTIONS.ChannelPrecedence: actual INPUT CHANNEL NUMBERS in highest-to-lowest
% priority order. Must contain each selected channel exactly once. Defaults
% to CHANNELS order. Earlier channels win regardless of probability magnitude.
% Output channel order does not change when precedence changes.
% OPTIONS.ReturnOpenedMasks: logical, default false; retain opened masks in
% INFO.OpenedMasks after thresholding/opening, before overlap resolution or
% filling. A voxel can be true in multiple channels of this diagnostic array.
% This option does not change MASKS or control whether opening is performed.
% OPTIONS.FillMethod: text, default 'none'. Applied after opening and overlap
% resolution. Existing classified voxels keep their channel assignments.
%   'none'    Leave unclassified voxels false in all output masks.
%   'nearest' Copy the channel of the nearest classified voxel, using a single
%             Euclidean bwdist transform and its nearest-index output.
%             Distance is in voxel coordinates; no spatial calibration is
%             inferred. MATLAB chooses between equally near voxels.
%             This fills in 3-D for volumes and in 2-D for single-plane data.
%   'fill'    Assign every unclassified voxel to the highest-precedence channel.
% No distance transform is run for 'none', 'fill', or an already classified volume.
%
% INFO reports channels, precedence, thresholds, radius, per-channel voxel
% counts, overlap voxel count after opening/before resolution, and unclassified
% voxel count. VoxelCounts and UnclassifiedVoxelCount describe final masks.
% UnclassifiedVoxelCountBeforeFill records the number before filling, and
% FilledVoxelCount records how many were assigned by FillMethod.
% No additional background category is created.
%
% [m,info] = farmSmoothNChannelProbabilities( ...
%     p,[1 3 2],[0.2 0.5 0.5], ...
%     struct('OpeningRadius',1,'ChannelPrecedence',[3 1 2]));
%
% opts = struct('OpeningRadius', 1, 'FillMethod', 'nearest');
% [m, info] = farmSmoothNChannelProbabilities(p, [3 2 1], 0.6, opts);
