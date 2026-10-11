function [probabilities, image] = readProbabilityTiff(filePath, options)
%READPROBABILITYTIFF Read a TIFF probability stack as [Y X Z C].
%   This wrapper uses imagestackio.readTiff, whose canonical representation
%   is [Y X Z C T]. ImageJ metadata is used when available. A TIFF with
%   channels and more than one time point requires OPTIONS.TimeIndex.
%
%   OPTIONS.SourceAxes is passed to imagestackio.readTiff when metadata is
%   missing or must be overridden. OPTIONS.TimeIndex selects one timepoint.
%   OPTIONS.TimeAsChannels=false by default. When true, singleton-C YXZT
%   data is explicitly reinterpreted as YXZC. This is never done silently.

if nargin < 2 || isempty(options)
    options = struct();
end
if ~(isstruct(options) && isscalar(options))
    error('segmentationtools:InvalidOptions', ...
        'options must be a scalar struct.');
end
readOptions = options;
readOptions = localRemoveField(readOptions, 'TimeIndex');
readOptions = localRemoveField(readOptions, 'TimeAsChannels');
image = imagestackio.readTiff(filePath, readOptions);
data = image.Data;
numChannels = size(data, 4);
numTimes = size(data, 5);
timeAsChannels = localOption(options, 'TimeAsChannels', false);
if ~(islogical(timeAsChannels) && isscalar(timeAsChannels))
    error('segmentationtools:InvalidTimeAsChannels', ...
        'options.TimeAsChannels must be a logical scalar.');
end

if timeAsChannels
    if numChannels ~= 1
        error('segmentationtools:CannotReinterpretTime', ...
            'TimeAsChannels requires a singleton channel dimension.');
    end
    probabilities = reshape(data, size(data,1), size(data,2), ...
        size(data,3), numTimes);
elseif numTimes == 1
    probabilities = data(:,:,:,:,1);
elseif isfield(options, 'TimeIndex') && ~isempty(options.TimeIndex)
    validateattributes(options.TimeIndex, {'numeric'}, ...
        {'real','finite','scalar','integer','>=',1,'<=',numTimes}, ...
        mfilename, 'options.TimeIndex');
    probabilities = data(:,:,:,:,options.TimeIndex);
else
    error('segmentationtools:TimeSelectionRequired', ...
        ['The TIFF contains %d time points. Set options.TimeIndex, or set ' ...
         'TimeAsChannels=true only when time pages actually represent classes.'], ...
        numTimes);
end
end

function value = localOption(options, name, defaultValue)
if isfield(options, name)
    value = options.(name);
else
    value = defaultValue;
end
end

function value = localRemoveField(value, name)
if isfield(value, name)
    value = rmfield(value, name);
end
end
