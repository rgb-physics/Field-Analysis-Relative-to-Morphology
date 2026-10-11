%% Stitch two XYZ TIFF stacks into one Y-X-Z-C stack
% Channel convention used here:
%   channel 1 = 560 nm
%   channel 2 = 647 nm

testFolder = fileparts(mfilename('fullpath'));
repositoryRoot = fileparts(fileparts(fileparts(testFolder)));
testSupportFolder = fullfile(repositoryRoot, 'tests');
sourceFolder = fullfile(testFolder, '..', 'src');
addpath(testSupportFolder);
addpath(sourceFolder);

channel1Name = 'xyz_chan1.tif';
channel2Name = 'xyz_chan2.tif';
outputName = 'xyzcStack.tif';

tiffFolder = fullfile(memotest.dataRoot(), 'image-stacks', 'tiff');
channel1Path = fullfile(tiffFolder, channel1Name);
channel2Path = fullfile(tiffFolder, channel2Name);
outputPath = fullfile(tiffFolder, outputName);

% These are ordinary grayscale XYZ page stacks, so state their source axes
% explicitly rather than relying on TIFF page metadata.
readOptions = struct('SourceAxes', 'YXZ');
image560 = imagestackio.readTiff(channel1Path, readOptions);
image647 = imagestackio.readTiff(channel2Path, readOptions);

volume560 = image560.Data(:, :, :, 1, 1);
volume647 = image647.Data(:, :, :, 1, 1);
assert(isequal(size(volume560), size(volume647)), ...
    'The 560 nm and 647 nm TIFF stacks must have the same Y-X-Z size.');

% The requested four-dimensional matrix follows [Y X Z C].
stitchedStackYXZC = cat(4, volume560, volume647);

% ImageStackIO writers accept the canonical [Y X Z C T] representation.
stitchedImage = struct();
stitchedImage.Data = reshape(stitchedStackYXZC, ...
    [size(stitchedStackYXZC, 1), size(stitchedStackYXZC, 2), ...
     size(stitchedStackYXZC, 3), size(stitchedStackYXZC, 4), 1]);
stitchedImage.Axes = 'YXZCT';
stitchedImage.Spacing = image560.Spacing;
stitchedImage.SpacingUnit = image560.SpacingUnit;

writeOptions = struct('Overwrite', true, 'Compression', 'LZW');
imagestackio.writeImageJHyperstack(stitchedImage, outputPath, writeOptions);

fprintf('Stitched size [Y X Z C]: %s\n', mat2str(size(stitchedStackYXZC)));
fprintf('Channel 1: 560 nm; channel 2: 647 nm\n');
fprintf('Saved ImageJ hyperstack: %s\n', outputPath);

