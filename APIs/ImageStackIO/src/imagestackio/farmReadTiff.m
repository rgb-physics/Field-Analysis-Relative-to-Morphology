function image = farmReadTiff(filePath, options)
%FARMREADTIFF Read a TIFF file and normalize it to [Y X Z C T] array order.
%   IMAGE = farmReadTiff(FILEPATH, OPTIONS) reads a TIFF image or
%   stack and returns a struct with normalized data and source metadata.
%   OPTIONS is an optional struct. SourceAxes labels the dimensions of the
%   array assembled from TIFF pages before normalization. For a grayscale
%   page stack, examples include "YXZ" and "YXT". For ImageJ hyperstacks,
%   embedded dimensions are used by default. Spacing gives spatial sample
%   spacing in [Y X Z] order. SpacingUnit gives its unit, such as "um" or
%   "nm". Explicit options override embedded TIFF/ImageJ calibration. When
%   neither is available, spacing defaults to [1 1 1] in pixels.
%   Grayscale multipage TIFFs without axis metadata default to YXZ (Z pages).
%   Explicit SourceAxes or recognized metadata take precedence; specify YXT
%   for a metadata-free time stack. Single-page/color layouts are preserved.

if nargin < 2 || isempty(options)
    options = struct();
end
if ~isstruct(options) || ~isscalar(options)
    error('imagestackio:InvalidOptions', ...
        'OPTIONS must be a scalar struct.');
end
filePath = localTextScalar(filePath, 'filePath');

fileInfo = imfinfo(filePath);
if isempty(fileInfo)
    error('imagestackio:EmptyTiff', 'The TIFF file has no readable pages.');
end
description = '';
if isfield(fileInfo(1), 'ImageDescription')
    description = fileInfo(1).ImageDescription;
end
imageJ = farmParseImageJDescription(description);
[spacing, spacingUnit, spacingSource] = farmResolveTiffSpacing( ...
    options, fileInfo(1), imageJ);
metadataAxes = farmParseTiffAxisOrder(description);

[firstPage, colorMap] = imread(filePath, 1);
firstPageSize = size(firstPage);
if numel(firstPageSize) > 3
    error('imagestackio:UnsupportedTiffPage', ...
        'TIFF pages must be two-dimensional grayscale or color images.');
end

numPages = numel(fileInfo);
if numPages == 1
    rawData = firstPage;
    if ndims(rawData) == 3
        inferredAxes = 'YXC';
    else
        inferredAxes = 'YX';
    end
else
    if ndims(firstPage) == 3
        rawData = zeros([firstPageSize numPages], 'like', firstPage);
        rawData(:, :, :, 1) = firstPage;
        for pageIndex = 2:numPages
            page = imread(filePath, pageIndex);
            if ~isequal(size(page), firstPageSize)
                error('imagestackio:InconsistentTiffPages', ...
                    'All TIFF pages must have the same dimensions.');
            end
            rawData(:, :, :, pageIndex) = page;
        end
        inferredAxes = '';
    else
        rawData = zeros([firstPageSize(1:2) numPages], 'like', firstPage);
        rawData(:, :, 1) = firstPage;
        for pageIndex = 2:numPages
            page = imread(filePath, pageIndex);
            if ~isequal(size(page), firstPageSize(1:2))
                error('imagestackio:InconsistentTiffPages', ...
                    'All TIFF pages must have the same dimensions.');
            end
            rawData(:, :, pageIndex) = page;
        end
        inferredAxes = '';
    end
end

if isfield(options, 'SourceAxes') && ~isempty(options.SourceAxes)
    sourceAxes = localValidateAxes(options.SourceAxes);
    axisSource = 'options.SourceAxes';
    if ~isempty(metadataAxes) && ~strcmp(sourceAxes, metadataAxes)
        warning('imagestackio:SourceAxesOverridesMetadata', ...
            ['OPTIONS.SourceAxes (%s) differs from the TIFF ' ...
             'MATLAB_AXIS_ORDER metadata (%s); using the explicit option.'], ...
            sourceAxes, metadataAxes);
    elseif imageJ.IsHyperstack
        warning('imagestackio:SourceAxesOverridesMetadata', ...
            ['OPTIONS.SourceAxes overrides the ImageJ hyperstack ' ...
             'channel/slice/frame metadata.']);
    end
    [data, sourceDimensions] = farmNormalizeAxes(rawData, sourceAxes);
elseif imageJ.IsHyperstack
    if ndims(firstPage) ~= 2
        error('imagestackio:UnsupportedImageJColorPages', ...
            'ImageJ hyperstack pages must be grayscale for axis reconstruction.');
    end
    if imageJ.Channels * imageJ.Slices * imageJ.Frames ~= numPages
        error('imagestackio:ImageJPageCountMismatch', ...
            'ImageJ channel, slice, and frame counts do not match TIFF pages.');
    end
    sourceAxes = 'YXZCT';
    axisSource = 'ImageJ hyperstack metadata';
    sourceDimensions = [firstPageSize(1:2), imageJ.Slices, ...
        imageJ.Channels, imageJ.Frames];
    pages = reshape(rawData, [firstPageSize(1:2) numPages]);
    pages = reshape(pages, [firstPageSize(1:2), imageJ.Channels, ...
        imageJ.Slices, imageJ.Frames]);
    data = permute(pages, [1 2 4 3 5]);
    data = reshape(data, [firstPageSize(1:2), imageJ.Slices, ...
        imageJ.Channels, imageJ.Frames]);
elseif ~isempty(metadataAxes)
    sourceAxes = metadataAxes;
    axisSource = 'TIFF MATLAB_AXIS_ORDER metadata';
    [data, sourceDimensions] = farmNormalizeAxes(rawData, sourceAxes);
elseif ~isempty(inferredAxes)
    sourceAxes = inferredAxes;
    axisSource = 'single-page TIFF layout';
    [data, sourceDimensions] = farmNormalizeAxes(rawData, sourceAxes);
elseif ndims(firstPage)==2
    sourceAxes = 'YXZ';
    axisSource = 'default YXZ page stack';
    [data, sourceDimensions] = farmNormalizeAxes(rawData, sourceAxes);
else
    error('imagestackio:SourceAxesRequired', ...
        ['This color TIFF has multiple pages but no recognized axis metadata. ' ...
         'Set OPTIONS.SourceAxes explicitly, for example "YXCZ".']);
end

image = struct();
image.Data = data;
image.Axes = 'YXZCT';
image.SourceAxes = sourceAxes;
image.SourceAxesSource = axisSource;
image.SourceDimensions = sourceDimensions;
image.FilePath = filePath;
image.DatasetPath = '';
image.DatasetInfo = fileInfo;
image.Spacing = spacing;
image.SpacingUnit = spacingUnit;
image.SpacingSource = spacingSource;
image.Colormap = colorMap;
image.ImageJ = imageJ;
image.PageCount = numPages;
end

function value = localTextScalar(value, argumentName)
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

function axes = localValidateAxes(value)
if isstring(value) && isscalar(value)
    value = char(value);
end
if ~ischar(value) || ~isrow(value)
    error('imagestackio:InvalidSourceAxes', ...
        'SourceAxes must be a character row vector or string scalar.');
end
axes = upper(regexprep(value, '[\s,_-]', ''));
if isempty(axes) || any(~ismember(axes, 'YXZCT')) || ...
        numel(unique(axes)) ~= numel(axes) || ~all(ismember('YX', axes))
    error('imagestackio:InvalidSourceAxes', ...
        ['SourceAxes must list unique axes from Y, X, Z, C, and T, ' ...
         'including both Y and X (for example "YXZ").']);
end
end
