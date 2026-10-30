function farmWriteImageJAxesTiff(data, filePath, options)
%FARMWRITEIMAGEJAXESTIFF Write explicitly labeled axes as a contiguous ImageJ TIFF.
% Inputs:
%   data       uint8, uint16, or logical image array.
%   filePath   Destination .tif or .tiff file; parent folder must exist.
%   options    Scalar struct with fields:
%              SourceAxes = required axis labels, e.g. 'YXC' or [1 2 4];
%              Overwrite = false;
%              Spacing = [1 1 1], always in Y X Z order;
%              SpacingUnit = 'pixel';
% Outputs:
%   None. Writes one uncompressed classic TIFF with ImageJ dimensions.

if nargin < 3 || ~isstruct(options) || ~isscalar(options)
    error('imagestackio:InvalidOptions', 'Supply scalar OPTIONS with SourceAxes.');
end
if ~isfield(options, 'SourceAxes')
    error('imagestackio:SourceAxesRequired', 'Specify SourceAxes, for example ''YXC''.');
end
allowed = {'SourceAxes', 'Overwrite', 'Spacing', 'SpacingUnit'};
if any(~ismember(fieldnames(options), allowed))
    error('imagestackio:UnknownOptions', ...
        'Supported options are SourceAxes, Overwrite, Spacing, and SpacingUnit. Compression is always None.');
end
if islogical(data)
    data = uint8(data);
end
if ~(isa(data, 'uint8') || isa(data, 'uint16')) || isempty(data) || ~isreal(data) || issparse(data)
    error('imagestackio:UnsupportedPixelType', 'Use a nonempty, full uint8, uint16, or logical array.');
end

% Interpret numeric axis labels against the canonical Y X Z C T positions.
axes = options.SourceAxes;
canonical = 'YXZCT';
if isnumeric(axes)
    validateattributes(axes, {'numeric'}, {'vector', 'integer', '>=', 1, '<=', 5});
    axes = canonical(axes(:).');
elseif isstring(axes) && isscalar(axes)
    axes = char(axes);
end
if ~ischar(axes) || ~isrow(axes) || numel(axes) < 2 || numel(axes) > 5
    error('imagestackio:InvalidAxes', 'SourceAxes must label two to five dimensions.');
end
axes = upper(axes);
if any(~ismember(axes, canonical)) || numel(unique(axes)) ~= numel(axes) || ...
        nnz(ismember(axes, 'YXZ')) < 2
    error('imagestackio:InvalidAxes', 'Use unique Y/X/Z/C/T labels including at least two spatial axes.');
end

% Axis normalization: reorder and insert singleton axes, without resampling pixels.
[data, ~] = farmNormalizeAxes(data, axes);
[spacing, unit] = farmParseSpacingOptions(options);
if any(double(unit) > 127)
    error('imagestackio:InvalidSpacingUnit', 'Use an ASCII unit label such as ''um''.');
end
overwrite = false;
if isfield(options, 'Overwrite')
    overwrite = options.Overwrite;
end
validateattributes(overwrite, {'logical'}, {'scalar'});
if isstring(filePath) && isscalar(filePath)
    filePath = char(filePath);
end
if ~ischar(filePath) || ~isrow(filePath) || isempty(filePath)
    error('imagestackio:InvalidPath', 'Supply a nonempty file path.');
end
[parent, ~, extension] = fileparts(filePath);
if ~any(strcmpi(extension, {'.tif', '.tiff'})) || (~isempty(parent) && ~isfolder(parent))
    error('imagestackio:InvalidPath', 'Use .tif/.tiff and an existing parent folder.');
end
if isfile(filePath) && ~overwrite
    error('imagestackio:OutputExists', 'Output exists; set Overwrite=true to replace it.');
end

numY = size(data, 1);
numX = size(data, 2);
numZ = size(data, 3);
numC = size(data, 4);
numT = size(data, 5);
numPages = numZ * numC * numT;
pixelBytes = 1 + isa(data, 'uint16');
pageBytes = numY * numX * pixelBytes;

description = sprintf(['ImageJ=1.54c\nimages=%d\nchannels=%d\nslices=%d\n' ...
    'frames=%d\nhyperstack=true\nmode=composite\nunit=%s\nspacing=%.17g\n' ...
    'loop=false\nmin=%g\nmax=%g\nMATLAB_AXIS_ORDER=YXZCT\n'], ...
    numPages, numC, numZ, numT, unit, spacing(3), double(min(data(:))), double(max(data(:))));
description = [uint8(description), uint8(0)];

% Place ALL pixel pages before ALL directories. ImageJ and ordinary TIFF readers
% therefore see the same pixels. TIFF offsets are zero-based byte positions.
numTags = 14;
directoryBytes = 2 + numTags * 12 + 4;
firstDirectory = 8 + pageBytes * numPages;
firstDirectory = firstDirectory + mod(firstDirectory, 2);
resolutionOffset = firstDirectory + directoryBytes * numPages;
descriptionOffset = resolutionOffset + 16;
fileBytes = descriptionOffset + numel(description);
if fileBytes >= double(intmax('uint32'))
    error('imagestackio:ClassicTiffLimit', 'Output exceeds classic TIFF capacity; split the dataset into smaller files.');
end

% Represent XY pixel density as bounded unsigned TIFF rational values.
[xNum, xDen] = localResolution(1 / spacing(2));
[yNum, yDen] = localResolution(1 / spacing(1));
[fileID, message] = fopen(filePath, 'w', 'ieee-le');
if fileID < 0
    error('imagestackio:OpenFailed', 'Cannot open output: %s', message);
end
cleanup = onCleanup(@() fclose(fileID));
fwrite(fileID, uint8('II'), 'uint8');
fwrite(fileID, 42, 'uint16');
fwrite(fileID, firstDirectory, 'uint32');

% ImageJ page order: C varies fastest, then Z, then T. Each page is row-major.
for tInd = 1:numT
    for zInd = 1:numZ
        for cInd = 1:numC
            page = data(:, :, zInd, cInd, tInd).';
            fwrite(fileID, page, class(data));
        end
    end
end
if ftell(fileID) < firstDirectory
    fwrite(fileID, 0, 'uint8');
end

% Baseline TIFF directories describe the same contiguous grayscale pages.
for pageInd = 1:numPages
    pixelOffset = 8 + (pageInd - 1) * pageBytes;
    entries = [256 4 1 numX; 257 4 1 numY; 258 3 1 pixelBytes * 8; ...
        259 3 1 1; 262 3 1 1; 270 2 numel(description) descriptionOffset; ...
        273 4 1 pixelOffset; 277 3 1 1; 278 4 1 numY; 279 4 1 pageBytes; ...
        282 5 1 resolutionOffset; 283 5 1 resolutionOffset + 8; ...
        296 3 1 1; 339 3 1 1];
    fwrite(fileID, numTags, 'uint16');
    for tagInd = 1:numTags
        fwrite(fileID, entries(tagInd, 1:2), 'uint16');
        fwrite(fileID, entries(tagInd, 3:4), 'uint32');
    end
    nextDirectory = 0;
    if pageInd < numPages
        nextDirectory = firstDirectory + pageInd * directoryBytes;
    end
    fwrite(fileID, nextDirectory, 'uint32');
end
fwrite(fileID, [xNum xDen yNum yDen], 'uint32');
fwrite(fileID, description, 'uint8');
if ftell(fileID) ~= fileBytes || ~isempty(ferror(fileID))
    error('imagestackio:WriteFailed', 'TIFF output was not completely written: %s', filePath);
end
end

function [numerator, denominator] = localResolution(value)
% Internal helper: approximate positive TIFF resolution without integer overflow.
limit = double(intmax('uint32'));
denominator = min(1e6, floor(limit / value));
if denominator < 1 || value < 1 / 1e6
    error('imagestackio:ResolutionRange', 'Spacing is outside the supported TIFF resolution range.');
end
numerator = max(1, round(value * denominator));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% SourceAxes labels the input dimensions, not desired output resizing. Any
% permutation/subset of YXZCT containing at least two spatial axes is supported. Missing axes
% are singleton. Numeric labels identify canonical axes: Y=1 X=2 Z=3 C=4 T=5.
% Spacing always follows YXZ, independent of SourceAxes. No resampling occurs.
% Compression is intentionally uncompressed. Classic TIFF only, below 4 GB.
% Pixel pages are contiguous; directories follow pixels, avoiding the previous
% interleaved-directory/ImageJ-header mismatch. Channel names/time calibration
% are not supplied. Output is grayscale channel pages, not interleaved RGB.
%
% EXAMPLES
% -------------------------------------------------------------------------
% options = struct('SourceAxes', 'YXC', 'Spacing', [.367 .367 1.5], ...
%     'SpacingUnit', 'um');
% farmWriteImageJAxesTiff(planes, 'channels.tif', options);
% options.SourceAxes = [1 2 4]; % Same declaration as YXC.
