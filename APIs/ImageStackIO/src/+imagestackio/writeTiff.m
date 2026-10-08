function writeTiff(imageInput, filePath, options)
%WRITETIFF Write a grayscale YXZ image or image struct as a TIFF stack.
%   imagestackio.writeTiff(IMAGE, FILEPATH, OPTIONS) writes one 2D image or
%   a Z stack. IMAGE can be a numeric YX/Z array, or an image struct with
%   Data in [Y X Z C T] order. C and T must be singleton dimensions.
%   Numeric input is interpreted as [Y X Z]. Supported pixel classes are
%   uint8, uint16, and logical. OPTIONS fields: Overwrite (false by default)
%   and Compression ('LZW' by default; also 'Deflate' or 'None').

if nargin < 3 || isempty(options)
    options = struct();
end
if ~isstruct(options) || ~isscalar(options)
    error('imagestackio:InvalidOptions', ...
        'OPTIONS must be a scalar struct.');
end
filePath = localTextScalar(filePath, 'filePath');
data = localGetData(imageInput);
if size(data, 4) ~= 1 || size(data, 5) ~= 1
    error('imagestackio:UseImageJWriter', ...
        ['writeTiff writes a single-channel, single-timepoint stack. ' ...
         'Use writeImageJHyperstack to preserve C and T dimensions.']);
end
data = data(:, :, :, 1, 1);
data = localSupportedPixelType(data);
writerOptions = localWriterOptions(options);
localCheckOutputPath(filePath, writerOptions.Overwrite);
description = sprintf('MATLAB_AXIS_ORDER=YXZ');
writeTiffPages(data, filePath, description, writerOptions.Compression);
end

function data = localGetData(imageInput)
if isstruct(imageInput)
    if ~isfield(imageInput, 'Data') || ~isfield(imageInput, 'Axes') || ...
            ~strcmpi(char(imageInput.Axes), 'YXZCT')
        error('imagestackio:InvalidImageStruct', ...
            'IMAGE struct must contain Data and Axes="YXZCT".');
    end
    data = imageInput.Data;
    if (~isnumeric(data) && ~islogical(data)) || ndims(data) > 5
        error('imagestackio:InvalidImageData', ...
            'IMAGE.Data must be a numeric/logical array with at most five dimensions.');
    end
else
    data = imageInput;
    if ~isnumeric(data) && ~islogical(data)
        error('imagestackio:InvalidImageData', ...
            'IMAGE must be a numeric/logical array or an image struct.');
    end
    if ndims(data) > 3
        error('imagestackio:InvalidImageDimensions', ...
            'Numeric input must have [Y X] or [Y X Z] dimensions.');
    end
    data = reshape(data, [size(data, 1), size(data, 2), size(data, 3), 1, 1]);
end
end

function data = localSupportedPixelType(data)
if islogical(data)
    data = uint8(data);
elseif ~isa(data, 'uint8') && ~isa(data, 'uint16')
    error('imagestackio:UnsupportedPixelType', ...
        'TIFF writers currently accept uint8, uint16, or logical pixels.');
end
end

function options = localWriterOptions(options)
options.Overwrite = localOption(options, 'Overwrite', false);
if ~islogical(options.Overwrite) || ~isscalar(options.Overwrite)
    error('imagestackio:InvalidOverwrite', ...
        'OPTIONS.Overwrite must be a logical scalar.');
end
options.Compression = localOption(options, 'Compression', 'LZW');
if isstring(options.Compression) && isscalar(options.Compression)
    options.Compression = char(options.Compression);
end
if ~ischar(options.Compression) || ...
        ~any(strcmpi(options.Compression, {'LZW', 'Deflate', 'None'}))
    error('imagestackio:InvalidCompression', ...
        'OPTIONS.Compression must be LZW, Deflate, or None.');
end
end

function value = localOption(options, name, defaultValue)
if isfield(options, name)
    value = options.(name);
else
    value = defaultValue;
end
end

function localCheckOutputPath(filePath, overwrite)
[folder, ~, extension] = fileparts(filePath);
if ~any(strcmpi(extension, {'.tif', '.tiff'}))
    error('imagestackio:InvalidTiffExtension', ...
        'Output path must end in .tif or .tiff.');
end
if ~isempty(folder) && ~isfolder(folder)
    error('imagestackio:MissingOutputFolder', ...
        'Output folder does not exist: %s', folder);
end
if isfile(filePath) && ~overwrite
    error('imagestackio:OutputExists', ...
        'Output already exists. Set OPTIONS.Overwrite=true to replace it.');
end
end
