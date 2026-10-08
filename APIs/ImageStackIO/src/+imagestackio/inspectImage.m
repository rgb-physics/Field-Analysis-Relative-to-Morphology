function info = inspectImage(filePath, options)
%INSPECTIMAGE Inspect TIFF or HDF5 image metadata without loading pixels.
%   INFO = imagestackio.inspectImage(FILEPATH, OPTIONS) supports TIFF and
%   HDF5 files. For HDF5, OPTIONS.DatasetPath is required.

if nargin < 2 || isempty(options)
    options = struct();
end
if ~isstruct(options) || ~isscalar(options)
    error('imagestackio:InvalidOptions', ...
        'OPTIONS must be a scalar struct.');
end
if isstring(filePath) && isscalar(filePath)
    filePath = char(filePath);
end
if ~ischar(filePath) || ~isrow(filePath) || isempty(filePath)
    error('imagestackio:InvalidTextInput', ...
        'filePath must be a nonempty character row vector or string scalar.');
end

[~, ~, extension] = fileparts(filePath);
extension = lower(extension);
info = struct('FilePath', filePath, 'Format', '', 'Axes', '', ...
    'AxisMetadataSource', '', 'Metadata', [], 'Spacing', []);

switch extension
    case {'.tif', '.tiff'}
        tiffInfo = imfinfo(filePath);
        if isempty(tiffInfo)
            error('imagestackio:EmptyTiff', ...
                'The TIFF file has no readable pages.');
        end
        description = '';
        if isfield(tiffInfo(1), 'ImageDescription')
            description = tiffInfo(1).ImageDescription;
        end
        imageJ = parseImageJDescription(description);
        axes = parseTiffAxisOrder(description);
        if ~isempty(axes)
            info.Axes = axes;
            info.AxisMetadataSource = 'TIFF MATLAB_AXIS_ORDER metadata';
        elseif imageJ.IsHyperstack && ...
                imageJ.Channels * imageJ.Slices * imageJ.Frames == numel(tiffInfo)
            info.Axes = 'YXZCT';
            info.AxisMetadataSource = 'ImageJ hyperstack metadata';
        elseif numel(tiffInfo) == 1
            [page, ~] = imread(filePath, 1);
            if ndims(page) == 3
                info.Axes = 'YXC';
            else
                info.Axes = 'YX';
            end
            info.AxisMetadataSource = 'single-page TIFF layout';
        end
        info.Format = 'TIFF';
        info.Metadata = struct('Pages', tiffInfo, 'ImageJ', imageJ);

    case {'.h5', '.hdf5'}
        if ~isfield(options, 'DatasetPath') || isempty(options.DatasetPath)
            error('imagestackio:MissingDatasetPath', ...
                'Set OPTIONS.DatasetPath when inspecting an HDF5 file.');
        end
        datasetPath = options.DatasetPath;
        if isstring(datasetPath) && isscalar(datasetPath)
            datasetPath = char(datasetPath);
        end
        if ~ischar(datasetPath) || ~isrow(datasetPath) || isempty(datasetPath)
            error('imagestackio:InvalidDatasetPath', ...
                'OPTIONS.DatasetPath must be a nonempty text scalar.');
        end
        if datasetPath(1) ~= '/'
            datasetPath = ['/' datasetPath];
        end
        datasetInfo = h5info(filePath, datasetPath);
        info.Format = 'HDF5';
        info.Metadata = datasetInfo;
        info.Axes = localReadH5AxisOrder(datasetInfo);
        if ~isempty(info.Axes)
            info.AxisMetadataSource = ...
                'HDF5 MATLAB_AXIS_ORDER attribute';
        end
    otherwise
        error('imagestackio:UnsupportedFormat', ...
            'inspectImage currently supports TIFF and HDF5 files.');
end
end

function axes = localReadH5AxisOrder(datasetInfo)
axes = '';
if ~isfield(datasetInfo, 'Attributes') || isempty(datasetInfo.Attributes)
    return
end
for index = 1:numel(datasetInfo.Attributes)
    attribute = datasetInfo.Attributes(index);
    if strcmpi(attribute.Name, 'MATLAB_AXIS_ORDER')
        value = attribute.Value;
        if isstring(value) && isscalar(value)
            value = char(value);
        end
        if ischar(value) && isrow(value)
            axes = upper(regexprep(value, '[\s,_-]', ''));
        end
        return
    end
end
end
