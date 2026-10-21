function image = farmReadH5(filePath, datasetPath, options)
%FARMREADH5 Read an HDF5 dataset and normalize it to [Y X Z C T] array order.
% Inputs:
%   filePath        Full input or output file path, including filename.
%   datasetPath     HDF5 dataset path within the file.
%   options         Optional scalar struct with the fields:
%                   SourceAxes = character vector or string scalar;
%                   Channels = positive integer vector or [];
%                   Spacing = positive numeric three-element vector;
%                   SpacingUnit = character vector or string scalar;
% Outputs:
%   image           Image struct containing normalized Data, YXZCT axes and source metadata.

if nargin < 2 || isempty(datasetPath)
    error('imagestackio:MissingDatasetPath', ...
          'Specify the HDF5 dataset path to read.');
end
if nargin < 3 || isempty(options)
    options = struct();
end
if ~isstruct(options) || ~isscalar(options)
    error('imagestackio:InvalidOptions', ...
          'OPTIONS must be a scalar struct.');
end
[spacing, spacingUnit] = farmParseSpacingOptions(options);

filePath = localTextScalar(filePath, 'filePath');
datasetPath = localTextScalar(datasetPath, 'datasetPath');
if datasetPath(1) ~= '/'
    datasetPath = ['/' datasetPath];
end

datasetInfo = h5info(filePath, datasetPath);
[metadataAxes, metadataAxisSource] = localReadAxisAttribute(datasetInfo);

if isfield(options, 'SourceAxes') && ~isempty(options.SourceAxes)
    sourceAxes = localValidateAxes(options.SourceAxes);
    axisSource = 'options.SourceAxes';
    if ~isempty(metadataAxes)
        try
            parsedMetadataAxes = localValidateAxes(metadataAxes);
        catch
            parsedMetadataAxes = '';
            warning('imagestackio:InvalidAxisMetadata', ...
                    ['The MATLAB_AXIS_ORDER attribute is not a supported axis ' ...
                     'string; using the explicit OPTIONS.SourceAxes value.']);
        end
        if ~isempty(parsedMetadataAxes) && ...
                ~strcmp(sourceAxes, parsedMetadataAxes)
            warning('imagestackio:SourceAxesOverridesMetadata', ...
                    ['OPTIONS.SourceAxes (%s) differs from the dataset ' ...
                     'MATLAB_AXIS_ORDER attribute (%s); using the explicit option.'], ...
                    sourceAxes, parsedMetadataAxes);
        end
    end
elseif ~isempty(metadataAxes)
    sourceAxes = localValidateAxes(metadataAxes);
    axisSource = metadataAxisSource;
else
    error('imagestackio:SourceAxesRequired', ...
          ['Could not determine the dimensions of the array returned by ' ...
           'h5read. Set OPTIONS.SourceAxes, for example "CYXZ".']);
end

rawData = h5read(filePath, datasetPath);
[data, sourceDimensions] = farmNormalizeAxes(rawData, sourceAxes);

if isfield(options, 'Channels') && ~isempty(options.Channels)
    channels = options.Channels;
    if ~isnumeric(channels) || ~isvector(channels) || ...
            any(~isfinite(channels)) || any(channels < 1) || ...
            any(channels ~= fix(channels))
        error('imagestackio:InvalidChannels', ...
              'OPTIONS.Channels must contain positive integer indices.');
    end
    if any(channels > size(data, 4))
        error('imagestackio:ChannelOutOfRange', ...
              'A requested channel exceeds the channel dimension (%d).', ...
              size(data, 4));
    end
    data = data(:, :, :, channels, :);
end

image = struct();
image.Data = data;
image.Axes = 'YXZCT';
image.SourceAxes = sourceAxes;
image.SourceAxesSource = axisSource;
image.SourceDimensions = sourceDimensions;
image.FilePath = filePath;
image.DatasetPath = datasetPath;
image.DatasetInfo = datasetInfo;
image.Spacing = spacing;
image.SpacingUnit = spacingUnit;
end

function value = localTextScalar(value, argumentName)
% Internal helper.
if isstring(value) && isscalar(value)
    value = char(value);
elseif ~ischar(value) || ~isrow(value)
    error('imagestackio:InvalidTextInput', ...
          '%s must be a character row vector or string scalar.', argumentName);
end
if isempty(value)
    error('imagestackio:EmptyTextInput', '%s cannot be empty.', argumentName);
end
end

function [axes, source] = localReadAxisAttribute(datasetInfo)
% Internal helper.
axes = '';
source = '';
if ~isfield(datasetInfo, 'Attributes') || isempty(datasetInfo.Attributes)
    return
end

for attributeIndex = 1:numel(datasetInfo.Attributes)
    attribute = datasetInfo.Attributes(attributeIndex);
    if strcmpi(attribute.Name, 'MATLAB_AXIS_ORDER')
        axes = attribute.Value;
        source = 'HDF5 MATLAB_AXIS_ORDER attribute';
        return
    end
end
end

function axes = localValidateAxes(value)
% Internal helper.
if isstring(value) && isscalar(value)
    value = char(value);
end
if ~ischar(value) || ~isrow(value)
    error('imagestackio:InvalidSourceAxes', ...
          'SourceAxes must be a character row vector or string scalar.');
end

axes = upper(regexprep(value, '[\s,_-]', ''));
validAxes = 'YXZCT';
if isempty(axes) || any(~ismember(axes, validAxes)) || ...
        numel(unique(axes)) ~= numel(axes) || ...
        ~all(ismember('YX', axes))
    error('imagestackio:InvalidSourceAxes', ...
          ['SourceAxes must list unique axes from Y, X, Z, C, and T, ' ...
           'including both Y and X (for example "CYXZ").']);
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMREADH5 Read an HDF5 dataset and normalize it to [Y X Z C T] array order.
%   IMAGE = farmReadH5(FILEPATH, DATASETPATH, OPTIONS) reads the
%   requested HDF5 dataset and returns a struct containing the normalized
%   array, axis labels, source-axis information, and HDF5 dataset metadata.
%
%   DATASETPATH is required. OPTIONS is an optional struct with fields:
%       SourceAxes  Axis labels for the array returned by h5read, such as
%                   "CYXZ". Use this when the file does not contain the
%                   supported MATLAB_AXIS_ORDER attribute.
%       Channels    Channel indices to retain after normalization. By
%                   default, all channels are retained.
%       Spacing     Spatial sample spacing in [Y X Z] order. The default
%                   is [1 1 1].
%       SpacingUnit Unit for Spacing, such as "um" or "nm". The default
%                   is "pixel".
%
%   The only automatically recognized axis attribute is
%   MATLAB_AXIS_ORDER. Its value must describe the order returned by
%   MATLAB's h5read function, not an assumed on-disk byte order.
