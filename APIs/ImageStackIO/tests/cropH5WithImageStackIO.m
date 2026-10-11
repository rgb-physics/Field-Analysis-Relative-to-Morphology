%% Load, crop, and save an Ilastik probability HDF5 volume
% The workflow scripts historically call loadH5(file, '/exported_data',
% channels). This example uses the public ImageStackIO equivalent and keeps
% the working array in the repository convention [Y X Z C T].

testFolder = fileparts(mfilename('fullpath'));
repositoryRoot = fileparts(fileparts(fileparts(testFolder)));
testSupportFolder = fullfile(repositoryRoot, 'tests');
sourceFolder = fullfile(testFolder, '..', 'src');
addpath(testSupportFolder);
addpath(sourceFolder);

inputName = 'inOnOut_3ChannelSegmentation_cropped.h5';
outputName = 'inOnOut_3ChannelSegmentation_recropped.h5';
datasetPath = '/exported_data';
selectedChannels = 1:3;

h5Folder = fullfile(memotest.dataRoot(), 'image-stacks', 'hdf5');
inputPath = fullfile(h5Folder, inputName);
outputPath = fullfile(h5Folder, outputName);

% Ilastik probability exports used by the workflows are returned by
% MATLAB's h5read in C-Y-X-Z order. ImageStackIO normalizes this to Y-X-Z-C-T.
options = struct('SourceAxes', 'CYXZ', 'Channels', selectedChannels);
image = imagestackio.readH5(inputPath, datasetPath, options);
dataYXZC = image.Data;

% Use the central half of each spatial dimension. Replace these three
% ranges with explicit indices when a particular region is required.
spatialSize = size(dataYXZC, 1:3);
cropSize = max(1, floor(spatialSize / 4));
cropStart = floor((spatialSize - cropSize) / 4) + 1;
cropEnd = cropStart + cropSize - 1;
rowRange = cropStart(1):cropEnd(1);       % Y
columnRange = cropStart(2):cropEnd(2);    % X
sliceRange = cropStart(3):cropEnd(3);     % Z

croppedYXZCT = dataYXZC(rowRange, columnRange, sliceRange, :, :);

% This source file represents one time point, so write C-Y-X-Z to match the
% Ilastik layout expected by the existing workflow scripts.
assert(size(croppedYXZCT, 5) == 1, ...
    'This example expects a single time point in the input HDF5 dataset.');
croppedCYXZ = permute(croppedYXZCT(:, :, :, :, 1), [4 1 2 3]);

if isfile(outputPath)
    delete(outputPath);
end

outputSize = size(croppedCYXZ);
chunkSize = min(outputSize, [outputSize(1), 64, 64, 16]);
h5create(outputPath, datasetPath, outputSize, ...
    'Datatype', class(croppedCYXZ), ...
    'ChunkSize', chunkSize, ...
    'Deflate', 1);
h5write(outputPath, datasetPath, croppedCYXZ);
h5writeatt(outputPath, datasetPath, 'MATLAB_AXIS_ORDER', 'CYXZ');

fprintf('Loaded size [Y X Z C T]: %s\n', mat2str(size(dataYXZC)));
fprintf('Cropped size [Y X Z C T]: %s\n', mat2str(size(croppedYXZCT)));
fprintf('Saved cropped HDF5: %s\n', outputPath);
