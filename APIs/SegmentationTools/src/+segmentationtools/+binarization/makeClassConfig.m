function classes = makeClassConfig(channels, thresholds, options)
%MAKECLASSCONFIG Build semantic class definitions from compact arrays.
%   CLASSES = MAKECLASSCONFIG(CHANNELS, THRESHOLDS) creates one class for
%   each channel. CHANNELS may also be a cell array, where each cell lists
%   the probability channels that form one class. THRESHOLDS may be a
%   scalar, a numeric vector with one value per class, or a cell array with
%   one scalar/vector entry per class.
%
%   OPTIONS is an optional scalar struct:
%     Names          class names; defaults to class1, class2, ...
%     CombineMethods "sum" or "union" per class; default "sum"
%     IDs            positive integer output IDs; default 1:N
%
%   A class is a semantic segmentation result. A channel is one stored
%   probability field. A class may therefore use one or several channels.

if nargin < 3 || isempty(options)
    options = struct();
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', ...
        'options must be a scalar struct.');
end

channelGroups = localChannelGroups(channels);
numClasses = numel(channelGroups);
thresholdGroups = localThresholdGroups(thresholds, numClasses);
names = localTextList(options, 'Names', numClasses, "class" + (1:numClasses));
methods = localTextList(options, 'CombineMethods', numClasses, ...
    repmat("sum", 1, numClasses));
if isfield(options, 'IDs') && ~isempty(options.IDs)
    ids = options.IDs;
else
    ids = 1:numClasses;
end
validateattributes(ids, {'numeric'}, ...
    {'real','finite','vector','numel',numClasses,'integer','positive'}, ...
    mfilename, 'options.IDs');
if numel(unique(ids)) ~= numClasses
    error('segmentationtools:DuplicateClassIDs', ...
        'Every class ID must be unique.');
end

allowedMethods = ["sum" "union"];
classes = repmat(struct('Name', '', 'Channels', [], 'Thresholds', [], ...
    'CombineMethod', '', 'ID', 0), 1, numClasses);
for classIndex = 1:numClasses
    method = lower(methods(classIndex));
    if ~ismember(method, allowedMethods)
        error('segmentationtools:InvalidCombineMethod', ...
            'CombineMethods entries must be "sum" or "union".');
    end
    classThresholds = thresholdGroups{classIndex};
    if method == "sum" && numel(classThresholds) ~= 1
        error('segmentationtools:InvalidThresholdCount', ...
            'A summed channel group requires one threshold after summation.');
    end
    if method == "union" && ~(numel(classThresholds) == 1 || ...
            numel(classThresholds) == numel(channelGroups{classIndex}))
        error('segmentationtools:InvalidThresholdCount', ...
            ['A union group requires one shared threshold or one threshold ' ...
             'per source channel.']);
    end
    classes(classIndex).Name = char(names(classIndex));
    classes(classIndex).Channels = channelGroups{classIndex};
    classes(classIndex).Thresholds = classThresholds;
    classes(classIndex).CombineMethod = char(method);
    classes(classIndex).ID = double(ids(classIndex));
end
end

function groups = localChannelGroups(channels)
if isnumeric(channels)
    validateattributes(channels, {'numeric'}, ...
        {'real','finite','vector','integer','positive','nonempty'}, ...
        mfilename, 'channels');
    groups = num2cell(double(channels(:).'));
elseif iscell(channels) && ~isempty(channels)
    groups = cell(size(channels));
    for index = 1:numel(channels)
        validateattributes(channels{index}, {'numeric'}, ...
            {'real','finite','vector','integer','positive','nonempty'}, ...
            mfilename, sprintf('channels{%d}', index));
        groups{index} = double(channels{index}(:).');
    end
else
    error('segmentationtools:InvalidChannels', ...
        'channels must be a numeric vector or nonempty cell array.');
end
end

function groups = localThresholdGroups(thresholds, numClasses)
if isnumeric(thresholds)
    validateattributes(thresholds, {'numeric'}, ...
        {'real','finite','vector','nonempty'}, mfilename, 'thresholds');
    if isscalar(thresholds)
        groups = repmat({double(thresholds)}, 1, numClasses);
    elseif numel(thresholds) == numClasses
        groups = num2cell(double(thresholds(:).'));
    else
        error('segmentationtools:InvalidThresholdCount', ...
            'thresholds must be scalar or contain one value per class.');
    end
elseif iscell(thresholds) && numel(thresholds) == numClasses
    groups = cell(size(thresholds));
    for index = 1:numClasses
        validateattributes(thresholds{index}, {'numeric'}, ...
            {'real','finite','vector','nonempty'}, mfilename, ...
            sprintf('thresholds{%d}', index));
        groups{index} = double(thresholds{index}(:).');
    end
else
    error('segmentationtools:InvalidThresholds', ...
        ['thresholds must be numeric or a cell array with one entry ' ...
         'per class.']);
end
end

function values = localTextList(options, fieldName, count, defaults)
if isfield(options, fieldName) && ~isempty(options.(fieldName))
    values = string(options.(fieldName));
else
    values = string(defaults);
end
if isscalar(values)
    values = repmat(values, 1, count);
end
if numel(values) ~= count || any(strlength(values) == 0)
    error('segmentationtools:InvalidClassOption', ...
        'options.%s must contain one nonempty value per class.', fieldName);
end
values = reshape(values, 1, []);
end
