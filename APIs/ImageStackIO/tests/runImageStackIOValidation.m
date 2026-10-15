function results = runImageStackIOValidation(throwOnFailure)

%RUNIMAGESTACKIOVALIDATION Exercise ImageStackIO with the bundled data.
%   RESULTS = runImageStackIOValidation() runs independent checks for the
%   public API, spatial calibration, round trips, validation errors,
%   historical HDF5 axis mapping, and retained stack-transform algorithms. All generated files
%   are placed in a temporary subfolder and removed when the run finishes.
%   Pass false to return failed-check rows without throwing at the end.

farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

if nargin<1, throwOnFailure = true; end
validateattributes(throwOnFailure,{'logical'},{'scalar'});

testFolder = fileparts(mfilename('fullpath'));
repositoryRoot = fileparts(fileparts(fileparts(testFolder)));
testSupportFolder = fullfile(repositoryRoot, 'tests');
apiFolder = fullfile(testFolder, '..', 'src');
addpath(testSupportFolder);
addpath(apiFolder);

[h5Path, tiffPaths] = localFindInputs(farmTestDataRoot());
outputRoot = fullfile(repositoryRoot,'test-data','imagestackio-validation');
if ~isfolder(outputRoot), mkdir(outputRoot); end
tempFolder = tempname(outputRoot);
mkdir(tempFolder);
cleanup = onCleanup(@() localRemoveFolder(tempFolder)); %#ok<NASGU>

checks = {
    'readTiff: metadata-free YXZ default and explicit YXT override', ...
        @() localCheckDefaultTiffAxes(tempFolder)
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
    'readH5: preserve historical default CXYZ permutation', ...
        @() localCheckHistoricalH5Axes(h5Path)
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
    if throwOnFailure
        error('imagestackio:ValidationFailed', ...
            '%d of %d ImageStackIO checks failed.', sum(~passed), numChecks);
    end
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
first = farmReadTiff(tiffPaths{1}, struct('SourceAxes', 'YXZ'));
second = farmReadTiff(tiffPaths{2}, struct('SourceAxes', 'YXZ'));
assert(strcmp(first.Axes, 'YXZCT'));
assert(strcmp(second.Axes, 'YXZCT'));
assert(isequal(size(first.Data), size(second.Data)));
assert(all(isfinite(first.Spacing)) && all(first.Spacing > 0));
assert(~isempty(first.SpacingUnit));
assert(~isempty(first.SpacingSource));
end

function localCheckDefaultTiffAxes(folder)
path = fullfile(folder,'metadata-free.tif');
expected = reshape(uint16(1:60),[3 5 4]);
for z = 1:4
    if z==1, imwrite(expected(:,:,z),path,'tif');
    else, imwrite(expected(:,:,z),path,'tif','WriteMode','append'); end
end
image = farmReadTiff(path);
assert(strcmp(image.SourceAxes,'YXZ'));
assert(strcmp(image.SourceAxesSource,'default YXZ page stack'));
assert(isequal(image.Data(:,:,:,1,1),expected));
timeImage = farmReadTiff(path,struct('SourceAxes','YXT'));
assert(strcmp(timeImage.SourceAxes,'YXT'));
assert(strcmp(timeImage.SourceAxesSource,'options.SourceAxes'));
assert(isequal(reshape(timeImage.Data,[3 5 4]),expected));
assert(size(timeImage.Data,3)==1&&size(timeImage.Data,5)==4);
end

function localCheckInspectTiff(tiffPath)
info = farmInspectImage(tiffPath);
assert(strcmp(info.Format, 'TIFF'));
assert(numel(info.Spacing) == 3);
assert(~isempty(info.SpacingUnit));
assert(~isempty(info.SpacingSource));
assert(isfield(info.Metadata, 'Pages'));
assert(isfield(info.Metadata, 'ImageJ'));
end

function localCheckTiffSpacingOverride(tiffPath)
expectedSpacing = [0.21 0.22 0.73];
image = farmReadTiff(tiffPath, struct( ...
    'SourceAxes', 'YXZ', 'Spacing', expectedSpacing, ...
    'SpacingUnit', 'um'));
assert(isequal(image.Spacing, expectedSpacing));
assert(strcmp(image.SpacingUnit, 'um'));
assert(strcmp(image.SpacingSource, 'options'));
end

function localCheckWriteTiffRoundTrip(tiffPath, tempFolder)
source = farmReadTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
expectedSpacing = [0.25 0.30 0.80];
image = struct('Data', reshape(data, [size(data, 1:3) 1 1]), ...
    'Axes', 'YXZCT', 'Spacing', expectedSpacing, 'SpacingUnit', 'um');
outputPath = fullfile(tempFolder, 'writeTiff_roundtrip.tif');
farmWriteTiff(image, outputPath, struct('Compression', 'None'));
loaded = farmReadTiff(outputPath);
assert(isequal(loaded.Data(:, :, :, 1, 1), data));
localAssertClose(loaded.Spacing, expectedSpacing, 1e-6);
assert(strcmp(loaded.SpacingUnit, 'um'));
assert(strcmp(loaded.SpacingSource, 'TIFF/ImageJ metadata'));
end

function localCheckLogicalTiff(tiffPath, tempFolder)
source = farmReadTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
logicalData = data > median(data(:));
outputPath = fullfile(tempFolder, 'logical.tif');
farmWriteTiff(logicalData, outputPath, struct('Compression', 'None'));
loaded = farmReadTiff(outputPath);
assert(isequal(logical(loaded.Data(:, :, :, 1, 1)), logicalData));
assert(isa(loaded.Data, 'uint8'));
end

function localCheckOverwriteProtection(tiffPath, tempFolder)
source = farmReadTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
outputPath = fullfile(tempFolder, 'overwrite.tif');
farmWriteTiff(data, outputPath, struct('Compression', 'None'));
localExpectError(@() farmWriteTiff(data, outputPath), ...
    'imagestackio:OutputExists');
farmWriteTiff(data, outputPath, struct('Overwrite', true));
end

function localCheckHyperstackRoundTrip(tiffPaths, tempFolder)
first = farmReadTiff(tiffPaths{1}, struct('SourceAxes', 'YXZ'));
second = farmReadTiff(tiffPaths{2}, struct('SourceAxes', 'YXZ'));
volume1 = localSmallVolume(first.Data(:, :, :, 1, 1));
volume2 = localSmallVolume(second.Data(:, :, :, 1, 1));
stack = cat(4, volume1, volume2);
expectedSpacing = [0.18 0.18 0.60];
image = struct('Data', reshape(stack, [size(stack, 1:4) 1]), ...
    'Axes', 'YXZCT', 'Spacing', expectedSpacing, 'SpacingUnit', 'um');
outputPath = fullfile(tempFolder, 'hyperstack.tif');
farmWriteImageJHyperstack(image, outputPath, ...
    struct('Compression', 'None'));
loaded = farmReadTiff(outputPath);
assert(isequal(loaded.Data, image.Data));
localAssertClose(loaded.Spacing, expectedSpacing, 1e-6);
assert(strcmp(loaded.SpacingUnit, 'um'));
info = farmInspectImage(outputPath);
assert(strcmp(info.Axes, 'YXZCT'));
assert(strcmp(info.AxisMetadataSource, 'TIFF MATLAB_AXIS_ORDER metadata'));
end

function localCheckReadH5(h5Path)
image = farmReadH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ'));
assert(strcmp(image.Axes, 'YXZCT'));
assert(size(image.Data, 4) == 3, ...
    'The HDF5 test input was expected to contain three channels.');
assert(strcmp(image.DatasetPath, '/exported_data'));
end

function localCheckH5Channels(h5Path)
allChannels = farmReadH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ'));
selected = farmReadH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ', 'Channels', [1 3]));
assert(size(selected.Data, 4) == 2);
assert(isequal(selected.Data(:, :, :, 1, :), ...
    allChannels.Data(:, :, :, 1, :)));
assert(isequal(selected.Data(:, :, :, 2, :), ...
    allChannels.Data(:, :, :, 3, :)));
end

function localCheckInspectH5(h5Path)
info = farmInspectImage(h5Path, ...
    struct('DatasetPath', '/exported_data'));
assert(strcmp(info.Format, 'HDF5'));
assert(~isempty(info.Metadata));
assert(isequal(info.Spacing, [1 1 1]));
assert(strcmp(info.SpacingUnit, 'pixel'));
end

function localCheckH5Spacing(h5Path)
defaults = farmReadH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ'));
assert(isequal(defaults.Spacing, [1 1 1]));
assert(strcmp(defaults.SpacingUnit, 'pixel'));
expected = [0.4 0.4 1.2];
calibrated = farmReadH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ', 'Spacing', expected, ...
    'SpacingUnit', 'um'));
assert(isequal(calibrated.Spacing, expected));
assert(strcmp(calibrated.SpacingUnit, 'um'));
end

function localCheckExpectedErrors(tiffPath, h5Path, tempFolder)
localExpectError(@() farmReadTiff(tiffPath, ...
    struct('SourceAxes', 'YXZ', 'Spacing', [1 1])), ...
    'imagestackio:InvalidSpacing');
localExpectError(@() farmReadH5(h5Path, '/exported_data', ...
    struct('SourceAxes', 'CYXZ', 'Channels', 99)), ...
    'imagestackio:ChannelOutOfRange');
localExpectError(@() farmInspectImage(h5Path), ...
    'imagestackio:MissingDatasetPath');
localExpectError(@() farmWriteTiff(rand(4, 4), ...
    fullfile(tempFolder, 'float.tif')), ...
    'imagestackio:UnsupportedPixelType');
end

function localCheckCropAndExtend(tiffPath)
source = farmReadTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
cropSize = max([1 1 1], min(size(data, 1:3), [8 9 2]));
cropped = farmCropTiffSave(data, [1 1 1], ...
    [cropSize(2) cropSize(1) cropSize(3)], false);
assert(isequal(size(cropped), cropSize));
extended = farmExtend2DTiffAlongZ(data(:, :, 1), 3);
assert(size(extended, 3) == 3);
assert(isequal(extended(:, :, 1), extended(:, :, 3)));
end

function localCheckFileTransforms(tiffPath, tempFolder)
source = farmReadTiff(tiffPath, struct('SourceAxes', 'YXZ'));
data = localSmallVolume(source.Data(:, :, :, 1, 1));
stackPath = fullfile(tempFolder, 'transform_stack_001.tif');
farmWriteTiff(data, stackPath, struct('Compression', 'None'));
layers = farmGetLayersOverTimeFrom3DTif(tempFolder, ...
    'transform_stack_001.tif', [1 size(data, 3)]);
assert(size(layers, 3) == 2);
intensity = farmGetTotIntOver3DTiffs(tempFolder, ...
    'transform_stack_%03i.tif', 1);
assert(intensity == sum(double(data(:))));
slicePattern = fullfile(tempFolder, 'slices', 'slice_%03i.tif');
farmSplit3Dto2D(data, slicePattern, 1:min(2, size(data, 3)));
assert(isfile(fullfile(tempFolder, 'slices', 'slice_001.tif')));
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

function localCheckHistoricalH5Axes(h5Path)
raw = h5read(h5Path, '/exported_data');
selected = farmReadH5(h5Path, '/exported_data', struct('SourceAxes', 'CXYZ', 'Channels', 1:3));
expected = permute(raw(1:3,:,:,:), [3 2 4 1]);
assert(isequal(squeeze(selected.Data), squeeze(expected)));
end
