function results = runImageStackIOValidation()
%RUNIMAGESTACKIOVALIDATION Exercise ImageStackIO with the bundled data.
%   RESULTS = runImageStackIOValidation() runs independent checks for the
%   public API, spatial calibration, round trips, validation errors, legacy
%   package functions, and historical stack transforms. All generated files
%   are placed in a temporary subfolder and removed when the run finishes.

testFolder = fileparts(mfilename('fullpath'));
repositoryRoot = fileparts(fileparts(fileparts(testFolder)));
testSupportFolder = fullfile(repositoryRoot, 'tests');
apiFolder = fullfile(testFolder, '..', 'src');
transformFolder = fullfile(testFolder, '..', 'legacy-or-stack-transforms');
addpath(testSupportFolder);
addpath(apiFolder);
addpath(transformFolder);

[h5Path, tiffPaths] = localFindInputs(memotest.dataRoot());
tempFolder = tempname;
mkdir(tempFolder);
cleanup = onCleanup(@() localRemoveFolder(tempFolder)); %#ok<NASGU>

checks = {
    'readTiff: load both XYZ inputs', ...
        @() localCheckReadTiffs(tiffPaths)
    'inspectImage: inspect source TIFF', ...
        @() localCheckInspectTiff(tiffPaths{1})
    'readTiff: explicit spacing override', ...
        @() localCheckTiffSpacingOverride(tiffPaths{1})
    'writeTiff: calibrated uint TIFF round trip', ...
        @() localCheckWriteTiffRoundTrip(tiffPaths{1}, tempFolder)
    'writeTiff: logical input conversion', ...
        @() localCheckLogicalTiff(tiffPaths{1}, tempFolder)
    'writeTiff: overwrite protection', ...
        @() localCheckOverwriteProtection(tiffPaths{1}, tempFolder)
    'writeImageJHyperstack: two-channel round trip', ...
        @() localCheckHyperstackRoundTrip(tiffPaths, tempFolder)
    'readH5: load all three channels', ...
        @() localCheckReadH5(h5Path)
    'readH5: channel selection', ...
        @() localCheckH5Channels(h5Path)
    'inspectImage: inspect HDF5 dataset', ...
        @() localCheckInspectH5(h5Path)
    'readH5: spacing defaults and override', ...
        @() localCheckH5Spacing(h5Path)
    'input validation: expected public API errors', ...
        @() localCheckExpectedErrors(tiffPaths{1}, h5Path, tempFolder)
    'legacy: loadH5', ...
        @() localCheckLegacyLoadH5(h5Path)
    'legacy: fastWriteTiff', ...
        @() localCheckLegacyFastWrite(tiffPaths{1}, tempFolder)
    'legacy: save3DTiff', ...
        @() localCheckLegacySave3D(tiffPaths{1}, tempFolder)
    'legacy: saveNDTiffFIJI', ...
        @() localCheckLegacySaveND(tiffPaths, tempFolder)
    'legacy: alternate saveNDTiffFIJI variant', ...
        @() localCheckLegacySaveNDVariant(tiffPaths, tempFolder)
    'legacy: genTifTagRGB', ...
        @() localCheckLegacyRgbTags()
    'stack transforms: crop and extend', ...
        @() localCheckCropAndExtend(tiffPaths{1})
    'stack transforms: split, layers, and intensity', ...
        @() localCheckFileTransforms(tiffPaths{1}, tempFolder)
    };

numChecks = size(checks, 1);
names = strings(numChecks, 1);
passed = false(numChecks, 1);
messages = strings(numChecks, 1);
for index = 1:numChecks
    names(index) = checks{index, 1};
    try
        checks{index, 2}();
        passed(index) = true;
        messages(index) = "PASS";
    catch exception
        messages(index) = string(getReport(exception, ...
            'basic', 'hyperlinks', 'off'));
    end
end

results = table(names, passed, messages, ...
    'VariableNames', {'Check', 'Passed', 'Message'});
disp(results(:, {'Check', 'Passed'}));
fprintf('%d of %d ImageStackIO checks passed.\n', sum(passed), numChecks);
if any(~passed)
    fprintf('\nFailure details:\n');
    for index = find(~passed)'
        fprintf('\n%s\n%s\n', names(index), messages(index));
    end
    error('imagestackio:ValidationFailed', ...
        '%d of %d ImageStackIO checks failed.', sum(~passed), numChecks);
end
end

function [h5Path, tiffPaths] = localFindInputs(testDataRoot)
h5Folder = fullfile(testDataRoot, 'image-stacks', 'hdf5');
tiffFolder = fullfile(testDataRoot, 'image-stacks', 'tiff');
h5Files = dir(fullfile(h5Folder, '*.h5'));
assert(~isempty(h5Files), 'No HDF5 test input was found.');
notCropped = ~contains(lower(string({h5Files.name})), 'cropped');
if any(notCropped)
    h5Files = h5Files(notCropped);
end
[~, largest] = max([h5Files.bytes]);
h5Path = fullfile(h5Folder, h5Files(largest).name);

tiffFiles = dir(fullfile(tiffFolder, 'xyz_chan*.tif'));
assert(numel(tiffFiles) >= 2, ...
    'Expected at least two TIFF inputs matching xyz_chan*.tif.');
[~, order] = sort({tiffFiles.name});
tiffFiles = tiffFiles(order(1:2));
tiffPaths = arrayfun(@(file) fullfile(tiffFolder, file.name), ...
    tiffFiles, 'UniformOutput', false);
end

function localCheckReadTiffs(tiffPaths)
first = imagestackio.readTiff(tiffPaths{1}, struct('SourceAxes', 'YXZ'));
second = imagestackio.readTiff(tiffPaths{2}, struct('SourceAxes', 'YXZ'));
assert(strcmp(first.Axes, 'YXZCT'));
assert(strcmp(second.Axes, 'YXZCT'));
assert(isequal(size(first.Data), size(second.Data)));
assert(all(isfinite(first.Spacing)) && all(first.Spacing > 0));
assert(~isempty(first.SpacingUnit));
assert(~isempty(first.SpacingSource));
end

function localCheckInspectTiff(tiffPath)
info = imagestackio.inspectImage(tiffPath);
assert(strcmp(info.Format, 'TIFF'));
assert(numel(info.Spacing) == 3);
assert(~isempty(info.SpacingUnit));
assert(~isempty(info.SpacingSource));
assert(isfield(info.Metadata, 'Pages'));
assert(isfield(info.Metadata, 'ImageJ'));
end

function localCheckTiffSpacingOverride(tiffPath)
expectedSpacing = [0.21 0.22 0.73];
image = imagestackio.readTiff(tiffPath, struct( ...
    'SourceAxes', 'YXZ', 'Spacing', expectedSpacing, ...
    'SpacingUnit', 'um'));
assert(isequal(image.Spacing, expectedSpacing));
assert(strcmp(image.SpacingUnit, 'um'));
assert(strcmp(image.SpacingSource, 'options'));
end

function localCheckWriteTiffRoundTrip(tiffPath, tempFolder)
source = imagestackio.readTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
expectedSpacing = [0.25 0.30 0.80];
image = struct('Data', reshape(data, [size(data, 1:3) 1 1]), ...
    'Axes', 'YXZCT', 'Spacing', expectedSpacing, 'SpacingUnit', 'um');
outputPath = fullfile(tempFolder, 'writeTiff_roundtrip.tif');
imagestackio.writeTiff(image, outputPath, struct('Compression', 'None'));
loaded = imagestackio.readTiff(outputPath);
assert(isequal(loaded.Data(:, :, :, 1, 1), data));
localAssertClose(loaded.Spacing, expectedSpacing, 1e-6);
assert(strcmp(loaded.SpacingUnit, 'um'));
assert(strcmp(loaded.SpacingSource, 'TIFF/ImageJ metadata'));
end

function localCheckLogicalTiff(tiffPath, tempFolder)
source = imagestackio.readTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
logicalData = data > median(data(:));
outputPath = fullfile(tempFolder, 'logical.tif');
imagestackio.writeTiff(logicalData, outputPath, struct('Compression', 'None'));
loaded = imagestackio.readTiff(outputPath);
assert(isequal(logical(loaded.Data(:, :, :, 1, 1)), logicalData));
assert(isa(loaded.Data, 'uint8'));
end

function localCheckOverwriteProtection(tiffPath, tempFolder)
source = imagestackio.readTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
outputPath = fullfile(tempFolder, 'overwrite.tif');
imagestackio.writeTiff(data, outputPath, struct('Compression', 'None'));
localExpectError(@() imagestackio.writeTiff(data, outputPath), ...
    'imagestackio:OutputExists');
imagestackio.writeTiff(data, outputPath, struct('Overwrite', true));
end

function localCheckHyperstackRoundTrip(tiffPaths, tempFolder)
first = imagestackio.readTiff(tiffPaths{1}, struct('SourceAxes', 'YXZ'));
second = imagestackio.readTiff(tiffPaths{2}, struct('SourceAxes', 'YXZ'));
volume1 = localSmallVolume(first.Data(:, :, :, 1, 1));
volume2 = localSmallVolume(second.Data(:, :, :, 1, 1));
stack = cat(4, volume1, volume2);
expectedSpacing = [0.18 0.18 0.60];
image = struct('Data', reshape(stack, [size(stack, 1:4) 1]), ...
    'Axes', 'YXZCT', 'Spacing', expectedSpacing, 'SpacingUnit', 'um');
outputPath = fullfile(tempFolder, 'hyperstack.tif');
imagestackio.writeImageJHyperstack(image, outputPath, ...
    struct('Compression', 'None'));
loaded = imagestackio.readTiff(outputPath);
assert(isequal(loaded.Data, image.Data));
localAssertClose(loaded.Spacing, expectedSpacing, 1e-6);
assert(strcmp(loaded.SpacingUnit, 'um'));
info = imagestackio.inspectImage(outputPath);
assert(strcmp(info.Axes, 'YXZCT'));
assert(strcmp(info.AxisMetadataSource, 'TIFF MATLAB_AXIS_ORDER metadata'));
end

function localCheckReadH5(h5Path)
image = imagestackio.readH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ'));
assert(strcmp(image.Axes, 'YXZCT'));
assert(size(image.Data, 4) == 3, ...
    'The HDF5 test input was expected to contain three channels.');
assert(strcmp(image.DatasetPath, '/exported_data'));
end

function localCheckH5Channels(h5Path)
allChannels = imagestackio.readH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ'));
selected = imagestackio.readH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ', 'Channels', [1 3]));
assert(size(selected.Data, 4) == 2);
assert(isequal(selected.Data(:, :, :, 1, :), ...
    allChannels.Data(:, :, :, 1, :)));
assert(isequal(selected.Data(:, :, :, 2, :), ...
    allChannels.Data(:, :, :, 3, :)));
end

function localCheckInspectH5(h5Path)
info = imagestackio.inspectImage(h5Path, ...
    struct('DatasetPath', '/exported_data'));
assert(strcmp(info.Format, 'HDF5'));
assert(~isempty(info.Metadata));
assert(isequal(info.Spacing, [1 1 1]));
assert(strcmp(info.SpacingUnit, 'pixel'));
end

function localCheckH5Spacing(h5Path)
defaults = imagestackio.readH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ'));
assert(isequal(defaults.Spacing, [1 1 1]));
assert(strcmp(defaults.SpacingUnit, 'pixel'));
expected = [0.4 0.4 1.2];
calibrated = imagestackio.readH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ', 'Spacing', expected, ...
    'SpacingUnit', 'um'));
assert(isequal(calibrated.Spacing, expected));
assert(strcmp(calibrated.SpacingUnit, 'um'));
end

function localCheckExpectedErrors(tiffPath, h5Path, tempFolder)
localExpectError(@() imagestackio.readTiff(tiffPath, ...
    struct('SourceAxes', 'YXZ', 'Spacing', [1 1])), ...
    'imagestackio:InvalidSpacing');
localExpectError(@() imagestackio.readH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ', 'Channels', 99)), ...
    'imagestackio:ChannelOutOfRange');
localExpectError(@() imagestackio.inspectImage(h5Path), ...
    'imagestackio:MissingDatasetPath');
localExpectError(@() imagestackio.writeTiff(rand(4, 4), ...
    fullfile(tempFolder, 'float.tif')), ...
    'imagestackio:UnsupportedPixelType');
end

function localCheckLegacyLoadH5(h5Path)
data = imagestackio.legacy.loadH5( ...
    h5Path, '/exported_data', 1:3);
assert(~isempty(data));
assert(ndims(data) <= 4);
end

function localCheckLegacyFastWrite(tiffPath, tempFolder)
source = imagestackio.readTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
if ~isa(data, 'uint16')
    data = uint16(data);
end
outputPath = fullfile(tempFolder, 'legacy_fast.tif');
imagestackio.legacy.fastWriteTiff(data, outputPath, 16, 'None');
loaded = imagestackio.readTiff(outputPath, struct('SourceAxes', 'YXZ'));
assert(isequal(loaded.Data(:, :, :, 1, 1), data));
end

function localCheckLegacySave3D(tiffPath, tempFolder)
source = imagestackio.readTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
outputPath = fullfile(tempFolder, 'legacy_3d.tif');
imagestackio.legacy.save3DTiff(data, outputPath);
loaded = imagestackio.readTiff(outputPath, struct('SourceAxes', 'YXZ'));
assert(isequal(loaded.Data(:, :, :, 1, 1), data));
end

function localCheckLegacySaveND(tiffPaths, tempFolder)
stack = localLegacyHyperstackInput(tiffPaths);
outputPath = fullfile(tempFolder, 'legacy_nd.tif');
imagestackio.legacy.saveNDTiffFIJI(stack, outputPath);
assert(isfile(outputPath));
assert(numel(imfinfo(outputPath)) >= size(stack, 3) * size(stack, 4));
end

function localCheckLegacySaveNDVariant(tiffPaths, tempFolder)
stack = localLegacyHyperstackInput(tiffPaths);
outputPath = fullfile(tempFolder, 'legacy_nd_variant.tif');
imagestackio.legacy.variants.saveNDTiffFIJI(stack, outputPath);
assert(isfile(outputPath));
assert(~isempty(imfinfo(outputPath)));
end

function localCheckLegacyRgbTags()
tags = imagestackio.legacy.genTifTagRGB(zeros(7, 9, 3, 'uint8'));
assert(tags.ImageLength == 7);
assert(tags.ImageWidth == 9);
assert(tags.SamplesPerPixel == 3);
assert(tags.BitsPerSample == 8);
end

function localCheckCropAndExtend(tiffPath)
source = imagestackio.readTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
cropSize = max([1 1 1], min(size(data, 1:3), [8 9 2]));
cropped = cropTiffSave(data, [1 1 1], ...
    [cropSize(2) cropSize(1) cropSize(3)], false);
assert(isequal(size(cropped), cropSize));
extended = extend2DTiffAlongZ(data(:, :, 1), 3);
assert(size(extended, 3) == 3);
assert(isequal(extended(:, :, 1), extended(:, :, 3)));
end

function localCheckFileTransforms(tiffPath, tempFolder)
source = imagestackio.readTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
stackPath = fullfile(tempFolder, 'transform_stack_001.tif');
imagestackio.writeTiff(data, stackPath, struct('Compression', 'None'));
layers = getLayersOverTimeFrom3DTif(tempFolder, ...
    'transform_stack_001.tif', [1 size(data, 3)]);
assert(size(layers, 3) == 2);
intensity = getTotIntOver3DTiffs(tempFolder, ...
    'transform_stack_%03i.tif', 1);
assert(intensity == sum(double(data(:))));
slicePattern = fullfile(tempFolder, 'slices', 'slice_%03i.tif');
split3Dto2D(data, slicePattern, 1:min(2, size(data, 3)));
assert(isfile(fullfile(tempFolder, 'slices', 'slice_001.tif')));
end

function stack = localLegacyHyperstackInput(tiffPaths)
first = imagestackio.readTiff(tiffPaths{1}, struct('SourceAxes', 'YXZ'));
second = imagestackio.readTiff(tiffPaths{2}, struct('SourceAxes', 'YXZ'));
volume1 = localSmallVolume(first.Data(:, :, :, 1, 1));
volume2 = localSmallVolume(second.Data(:, :, :, 1, 1));
% Legacy saveNDTiffFIJI expects [Y X C Z T].
stack = permute(cat(4, volume1, volume2), [1 2 4 3]);
stack = reshape(stack, [size(stack, 1:4) 1]);
if ~isa(stack, 'uint16')
    stack = uint16(stack);
end
end

function data = localSmallVolume(data)
limits = min(size(data, 1:3), [32 40 4]);
data = data(1:limits(1), 1:limits(2), 1:limits(3));
end

function localExpectError(functionHandle, expectedIdentifier)
try
    functionHandle();
catch exception
    assert(strcmp(exception.identifier, expectedIdentifier), ...
        'Expected error %s but received %s.', ...
        expectedIdentifier, exception.identifier);
    return
end
error('imagestackio:ExpectedErrorNotThrown', ...
    'Expected error %s was not thrown.', expectedIdentifier);
end

function localAssertClose(actual, expected, tolerance)
assert(isequal(size(actual), size(expected)));
assert(all(abs(double(actual) - double(expected)) <= tolerance));
end

function localRemoveFolder(folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end
