function result = farmClassifyProbabilityChannels(probabilities, channels, thresholds, options)
%FARMCLASSIFYPROBABILITYCHANNELS Classify selected channels as distinct classes.
%   RESULT = CLASSIFYPROBABILITYCHANNELS(P, CHANNELS, THRESHOLDS, OPTIONS)
%   constructs one class per selected probability channel. When CHANNELS is
%   empty, every channel in P is selected. P is [Y X Z C].
%
%   OPTIONS.Names and OPTIONS.IDs customize class metadata.
%   OPTIONS.ClassifyOptions is passed to classifyProbabilities.

if nargin < 2 || isempty(channels)
    channels = 1:size(probabilities,4);
end
if nargin < 3 || isempty(thresholds)
    error('segmentationtools:ThresholdsRequired', ...
        'Supply one threshold or one threshold per selected channel.');
end
if nargin < 4 || isempty(options)
    options = struct();
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', ...
        'options must be a scalar struct.');
end

classOptions = struct();
if isfield(options,'Names')
    classOptions.Names = options.Names;
end
if isfield(options,'IDs')
    classOptions.IDs = options.IDs;
end
classOptions.CombineMethods = repmat("sum",1,numel(channels));
classes = farmMakeClasses( ...
    channels,thresholds,classOptions);
if isfield(options,'ClassifyOptions')
    classifyOptions = options.ClassifyOptions;
else
    classifyOptions = struct();
end
result = farmClassifyProbabilities( ...
    probabilities,classes,classifyOptions);
end
