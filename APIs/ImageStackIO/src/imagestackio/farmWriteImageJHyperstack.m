function farmWriteImageJHyperstack(imageInput, filePath, options)
%FARMWRITEIMAGEJHYPERSTACK Write a canonical [Y X Z C T] image as ImageJ TIFF.
% Inputs:
%   imageInput      Image array or normalized image struct containing Data.
%   filePath        Full input or output file path, including filename.
%   options         Operation settings struct.
% Outputs:
%   None. Requested file or graphics side effects occur during the call.

if nargin < 3 || isempty(options)
    options = struct();
end
if ~isstruct(options) || ~isscalar(options)
    error('imagestackio:InvalidOptions', ...
          'OPTIONS must be a scalar struct.');
end
filePath = localTextScalar(filePath, 'filePath');
[spacing, spacingUnit] = localGetSpacing(imageInput, options);
data = localGetData(imageInput);
if islogical(data)
    data = uint8(data);
elseif ~isa(data, 'uint8') && ~isa(data, 'uint16')
    error('imagestackio:UnsupportedPixelType', ...
          'ImageJ hyperstack writing accepts uint8, uint16, or logical pixels.');
end
writerOptions = localWriterOptions(options);
localCheckOutputPath(filePath, writerOptions.Overwrite);

numY = size(data, 1);
numX = size(data, 2);
numZ = size(data, 3);
numC = size(data, 4);
numT = size(data, 5);
pageData = permute(data, [1 2 4 3 5]);
pageData = reshape(pageData, [numY numX numC * numZ * numT]);

description = sprintf([ ...
                       'ImageJ=1.54c\n' ...
                       'images=%d\n' ...
                       'channels=%d\n' ...
                       'slices=%d\n' ...
                       'frames=%d\n' ...
                       'hyperstack=true\n' ...
                       'mode=composite\n' ...
                       'unit=%s\n' ...
                       'spacing=%.17g\n' ...
                       'loop=false\n' ...
                       'min=%.17g\n' ...
                       'max=%.17g\n' ...
                       'MATLAB_AXIS_ORDER=YXZCT'], ...
                      numC * numZ * numT, numC, numZ, numT, spacingUnit, spacing(3), ...
                      double(min(data(:))), double(max(data(:))));
calibration = struct( ...
                     'XResolution', 1 / spacing(2), ...
                     'YResolution', 1 / spacing(1));
farmWriteTiffPages(pageData, filePath, description, ...
                   writerOptions.Compression, calibration);
end

function [spacing, spacingUnit] = localGetSpacing(imageInput, options)
% Internal helper.
spacingOptions = options;
if isstruct(imageInput)
    if (~isfield(spacingOptions, 'Spacing') || ...
        isempty(spacingOptions.Spacing)) && isfield(imageInput, 'Spacing')
        spacingOptions.Spacing = imageInput.Spacing;
    end
    if (~isfield(spacingOptions, 'SpacingUnit') || ...
        isempty(spacingOptions.SpacingUnit)) && ...
            isfield(imageInput, 'SpacingUnit')
        spacingOptions.SpacingUnit = imageInput.SpacingUnit;
    end
end
[spacing, spacingUnit] = farmParseSpacingOptions(spacingOptions);
end

function data = localGetData(imageInput)
% Internal helper.
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
    if ~isnumeric(imageInput) && ~islogical(imageInput)
        error('imagestackio:InvalidImageData', ...
              'IMAGE must be a numeric/logical array or an image struct.');
    end
    if ndims(imageInput) > 5
        error('imagestackio:InvalidImageDimensions', ...
              'IMAGE must have at most five dimensions [Y X Z C T].');
    end
    data = reshape(imageInput, [size(imageInput, 1), size(imageInput, 2), ...
                                size(imageInput, 3), size(imageInput, 4), size(imageInput, 5)]);
end
end

function options = localWriterOptions(options)
% Internal helper.
if isfield(options, 'Overwrite')
    overwrite = options.Overwrite;
else
    overwrite = false;
end
if ~islogical(overwrite) || ~isscalar(overwrite)
    error('imagestackio:InvalidOverwrite', ...
          'OPTIONS.Overwrite must be a logical scalar.');
end
options.Overwrite = overwrite;
if isfield(options, 'Compression')
    compression = options.Compression;
else
    compression = 'LZW';
end
if isstring(compression) && isscalar(compression)
    compression = char(compression);
end
if ~ischar(compression) || ...
        ~any(strcmpi(compression, {'LZW', 'Deflate', 'None'}))
    error('imagestackio:InvalidCompression', ...
          'OPTIONS.Compression must be LZW, Deflate, or None.');
end
options.Compression = compression;
end

function localCheckOutputPath(filePath, overwrite)
% Internal helper.
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

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMWRITEIMAGEJHYPERSTACK Write a canonical [Y X Z C T] image as ImageJ TIFF.
%   Supports uint8, uint16, and logical pixel arrays. TIFF pages are stored
%   with C varying fastest, then Z, then T, with an ImageJ hyperstack
%   description to preserve the dimensions. OPTIONS supports Overwrite
%   (false by default), Compression ('LZW', 'Deflate', or 'None'), Spacing
%   in [Y X Z] order, and SpacingUnit. Spacing and SpacingUnit are taken
%   from an input image struct when present, then overridden by OPTIONS.
%   Their defaults are [1 1 1] and 'pixel'. FIJI receives X/Y calibration
%   through TIFF resolution tags and Z calibration through ImageJ metadata.
