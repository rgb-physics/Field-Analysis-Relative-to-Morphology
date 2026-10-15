function [mask, info] = farmThresholdProbabilityGroup(probabilities, channels, thresholds, options)
%FARMTHRESHOLDPROBABILITYGROUP Threshold one semantic probability class.
%   MASK = THRESHOLDPROBABILITYGROUP(P, CHANNELS, THRESHOLDS, OPTIONS)
%   accepts P in [Y X Z C] order. A [Y X Z] array is one channel.
%
%   OPTIONS.CombineMethod is "sum" (default) or "union". Sum adds the
%   requested probability channels, then applies one strict threshold.
%   Union applies strict thresholds independently and unions the masks.
%   Union accepts one shared threshold or one threshold per channel.
%   Inputs are not normalized internally.
%
%   OPTIONS.ReturnScore controls whether INFO.Score is retained. The score
%   is the summed probability for "sum" and the maximum selected-channel
%   probability for "union". It defaults to false to avoid retaining an
%   additional full-size array when it is not needed.

if nargin < 4 || isempty(options)
    options = struct();
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', ...
        'options must be a scalar struct.');
end
if ~(isnumeric(probabilities) && isreal(probabilities) && ...
        ~issparse(probabilities) && ~isempty(probabilities) && ...
        ndims(probabilities) <= 4)
    error('segmentationtools:InvalidProbabilities', ...
        'probabilities must be a nonempty real [Y X Z C] numeric array.');
end
validateattributes(channels, {'numeric'}, ...
    {'real','finite','vector','integer','positive','nonempty'}, ...
    mfilename, 'channels');
channels = double(channels(:).');
numChannels = size(probabilities, 4);
if any(channels > numChannels)
    error('segmentationtools:ChannelOutOfRange', ...
        'A requested channel exceeds the available channel count (%d).', ...
        numChannels);
end
validateattributes(thresholds, {'numeric'}, ...
    {'real','finite','vector','nonempty'}, mfilename, 'thresholds');
thresholds = double(thresholds(:).');

method = localOption(options, 'CombineMethod', 'sum');
method = lower(string(method));
if ~isscalar(method) || ~ismember(method, ["sum" "union"])
    error('segmentationtools:InvalidCombineMethod', ...
        'options.CombineMethod must be "sum" or "union".');
end
returnScore = localOption(options, 'ReturnScore', false);
if ~(islogical(returnScore) && isscalar(returnScore))
    error('segmentationtools:InvalidReturnScore', ...
        'options.ReturnScore must be a logical scalar.');
end

selected = double(probabilities(:, :, :, channels));
if method == "sum"
    if numel(thresholds) ~= 1
        error('segmentationtools:InvalidThresholdCount', ...
            'Summed channels require one threshold.');
    end
    score = sum(selected, 4);
    mask = score > thresholds(1);
else
    if isscalar(thresholds)
        thresholds = repmat(thresholds, 1, numel(channels));
    elseif numel(thresholds) ~= numel(channels)
        error('segmentationtools:InvalidThresholdCount', ...
            ['Union requires one shared threshold or one threshold per ' ...
             'selected channel.']);
    end
    thresholdShape = reshape(thresholds, 1, 1, 1, []);
    mask = any(selected > thresholdShape, 4);
    score = max(selected, [], 4);
end

info = struct();
info.Channels = channels;
info.ThresholdsUsed = thresholds;
info.CombineMethod = char(method);
info.StrictThreshold = true;
if returnScore
    info.Score = score;
end
end

function value = localOption(options, name, defaultValue)
if isfield(options, name)
    value = options.(name);
else
    value = defaultValue;
end
end
