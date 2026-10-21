function [inside, wall, outside, info] = farmSmoothInOnOutProbabilities(probabilities, channels, thresholds, options)
%FARMSMOOTHINONOUTPROBABILITIES Historical in/on/out opening workflow.
% Inputs:
%   probabilities   Loaded probability array in YXZC order.
%   channels        Selected probability channels or channel groups.
%   thresholds      Thresholds corresponding to the selected channels or groups.
%   options         Optional scalar struct with the fields:
%                   OpeningRadius = nonnegative integer scalar;
%                   SpanSpace = logical scalar;
% Outputs:
%   inside          Cleaned inside mask.
%   wall            Cleaned wall mask.
%   outside         Cleaned outside mask.
%   info            Threshold, opening and coverage metadata.

if nargin < 4 || isempty(options)
    options = struct();
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', ...
          'options must be a scalar struct.');
end
validateattributes(channels, {'numeric'}, ...
                   {'real', 'finite', 'vector', 'numel', 3, 'integer', 'positive'}, ...
                   mfilename, 'channels');
if isscalar(thresholds)
    thresholds = repmat(thresholds, 1, 3);
end
validateattributes(thresholds, {'numeric'}, ...
                   {'real', 'finite', 'vector', 'numel', 3}, mfilename, 'thresholds');
radius = localOption(options, 'OpeningRadius', 2);
validateattributes(radius, {'numeric'}, ...
                   {'real', 'finite', 'scalar', 'integer', 'nonnegative'}, ...
                   mfilename, 'options.OpeningRadius');
spanSpace = localOption(options, 'SpanSpace', false);
if ~(islogical(spanSpace) && isscalar(spanSpace))
    error('segmentationtools:InvalidSpanSpace', ...
          'options.SpanSpace must be a logical scalar.');
end

candidate = false([size(probabilities, 1), size(probabilities, 2), ...
                   size(probabilities, 3), 3]);
for classIndex = 1:3
    candidate(:, :, :, classIndex) = ...
        farmThresholdProbabilityGroup( ...
                                      probabilities, channels(classIndex), thresholds(classIndex));
end
if radius == 0
    cleaned = candidate;
else
    structuringElement = strel('sphere', radius);
    cleaned = false(size(candidate));
    for classIndex = 1:3
        cleaned(:, :, :, classIndex) = imdilate( ...
                                             imerode(candidate(:, :, :, classIndex), structuringElement), ...
                                             structuringElement);
    end
end

inside = cleaned(:, :, :, 1);
outside = cleaned(:, :, :, 3) & ~inside;
if spanSpace
    wall = ~(inside | outside);
else
    wall = cleaned(:, :, :, 2);
end
info = struct('SemanticOrder', {{'inside', 'wall', 'outside'}}, ...
              'HistoricalAliases', {{'in', 'on', 'out'}}, 'Channels', channels, ...
              'ThresholdsUsed', thresholds, 'OpeningRadius', radius, ...
              'SpanSpace', spanSpace);
end

function value = localOption(options, name, defaultValue)
% Internal helper.
if isfield(options, name)
    value = options.(name);
else
    value = defaultValue;
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSMOOTHINONOUTPROBABILITIES Historical in/on/out opening workflow.
%   Inputs use semantic order [inside, wall, outside]. Each selected channel
%   is strictly thresholded and opened using erosion followed by dilation.
%
%   OPTIONS.OpeningRadius defaults to 2 voxels. OPTIONS.SpanSpace defaults
%   to false. When SpanSpace=true, wall is the complement of cleaned inside
%   and outside. Otherwise wall is thresholded/opened independently, which
%   can overlap the other returned masks. This preserves the historical
%   h5toSmooth3Chans behavior behind a clearly named function.
