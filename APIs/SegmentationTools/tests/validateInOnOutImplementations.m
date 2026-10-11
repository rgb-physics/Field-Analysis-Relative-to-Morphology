function report = validateInOnOutImplementations(options)
%VALIDATEINONOUTIMPLEMENTATIONS Compare current and historical methods.
%   REPORT = VALIDATEINONOUTIMPLEMENTATIONS() creates synthetic [Y X Z C]
%   probability data in semantic channel order [inside wall outside], runs
%   the generalized classifier and historical opening implementation, and
%   writes inspectable ImageJ TIFFs to a temporary output directory.
%
%   OPTIONS fields:
%     InputFile       optional TIFF/HDF5 probability stack
%     DatasetPath     HDF5 dataset; default /exported_data
%     ReadOptions     options for ImageStackIO or readProbabilityTiff
%     Channels        semantic [inside wall outside]; default [1 2 3]
%     Thresholds      default [0.5 0.5 0.5]
%     OutputDirectory default tempdir/FARM-SegmentationTools-in-on-out
%     OpeningRadius   historical opening radius; default 1 voxel
%     SaveDiagnostics default true
%
%   HDF5 data must be read into [Y X Z C T] by ImageStackIO; this script
%   evaluates its first time point. TIFF metadata is honored. For YXZT data
%   that actually stores classes, set ReadOptions.TimeAsChannels=true.

if nargin < 1 || isempty(options)
    options = struct();
end
thisDirectory = fileparts(mfilename('fullpath'));
repositoryRoot = fullfile(thisDirectory, '..', '..', '..');
addpath(fullfile(repositoryRoot, 'APIs', 'SegmentationTools', 'src'));
addpath(fullfile(repositoryRoot, 'APIs', 'ImageStackIO', 'src'));
addpath(fullfile(repositoryRoot, 'APIs', 'SharedUtilities', 'src'));

channels = localOption(options, 'Channels', [1 2 3]);
thresholds = localOption(options, 'Thresholds', [0.5 0.5 0.5]);
openingRadius = localOption(options, 'OpeningRadius', 1);
saveDiagnostics = localOption(options, 'SaveDiagnostics', true);
outputDirectory = localOption(options, 'OutputDirectory', ...
    fullfile(tempdir, 'FARM-SegmentationTools-in-on-out'));

if isfield(options, 'InputFile') && ~isempty(options.InputFile)
    probabilities = localReadProbabilities(options);
    source = char(string(options.InputFile));
else
    probabilities = localSyntheticProbabilities();
    source = 'synthetic closed-wall volumes';
end
if size(probabilities,4) < max(channels)
    error('segmentationtools:ValidationChannelOutOfRange', ...
        'The selected validation channel exceeds the input channel count.');
end

classifyOptions = struct('ReturnLabelVolume', true, ...
    'ReturnMasks', true, 'ReturnCandidateMasks', true, ...
    'ReturnOverlapMask', true, 'ReturnUnclassifiedMask', true, ...
    'ReturnChangedVoxelMask', true, 'CountComponents', true);
newOptions = struct('CombineMethods', repmat("sum",1,3), ...
    'ClassifyOptions', classifyOptions);
generalized = segmentationtools.binarization.segmentInOnOutProbabilities( ...
    probabilities, channels, thresholds, newOptions);

historicalOptions = struct('OpeningRadius', openingRadius, ...
    'SpanSpace', false);
[historicalInside, historicalWall, historicalOutside, historicalInfo] = ...
    segmentationtools.binarization.smoothInOnOutProbabilities( ...
    probabilities, channels, thresholds, historicalOptions);
historicalMasks = cat(4, historicalInside, historicalWall, historicalOutside);

assert(~any(sum(generalized.Masks,4) > 1, 'all'), ...
    'Generalized default output must be disjoint.');
expectedSpatialSize = [size(probabilities,1), size(probabilities,2), ...
    size(probabilities,3)];
assert(isequal(size(generalized.LabelVolume), expectedSpatialSize), ...
    'Generalized label output must retain the spatial dimensions.');

report = struct();
report.Source = source;
report.SemanticOrder = {'inside','wall','outside'};
report.Channels = channels;
report.Thresholds = thresholds;
report.GeneralizedVoxelCounts = generalized.VoxelCounts;
report.GeneralizedComponentCounts = generalized.ComponentCounts;
report.GeneralizedOverlapCandidates = generalized.OverlapVoxelCount;
report.GeneralizedUnclassified = ...
    generalized.UnclassifiedVoxelCountBeforeResolution;
report.HistoricalVoxelCounts = reshape(sum(historicalMasks,[1 2 3]),1,[]);
report.HistoricalOverlapVoxels = nnz(sum(historicalMasks,4) > 1);
report.HistoricalInfo = historicalInfo;
report.OutputDirectory = '';

if saveDiagnostics
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end
    writeOptions = struct('Overwrite', true);
    probabilityPreview = uint16(max(0,min(1,probabilities))*65535);
    segmentationtools.io.writeMaskTiff(probabilityPreview, ...
        fullfile(outputDirectory,'input_probabilities_YXZC.tif'),writeOptions);
    segmentationtools.io.writeMaskTiff(generalized.LabelVolume, ...
        fullfile(outputDirectory,'generalized_class_labels.tif'),writeOptions);
    segmentationtools.io.writeMaskTiff(generalized.Masks, ...
        fullfile(outputDirectory,'generalized_masks_YXZC.tif'),writeOptions);
    segmentationtools.io.writeMaskTiff(historicalMasks, ...
        fullfile(outputDirectory,'historical_masks_YXZC.tif'),writeOptions);
    diagnostics = cat(4, generalized.OverlapMask, ...
        generalized.UnclassifiedMask, generalized.ChangedVoxelMask);
    segmentationtools.io.writeMaskTiff(diagnostics, ...
        fullfile(outputDirectory,'diagnostics_overlap_unclassified_changed.tif'), ...
        writeOptions);
    report.OutputDirectory = outputDirectory;
    fprintf('Inspectable validation TIFFs written to:\n%s\n',outputDirectory);
end

disp(report)
end

function probabilities = localReadProbabilities(options)
[~,~,extension] = fileparts(options.InputFile);
readOptions = localOption(options, 'ReadOptions', struct());
if any(strcmpi(extension,{'.tif','.tiff'}))
    probabilities = segmentationtools.io.readProbabilityTiff( ...
        options.InputFile,readOptions);
elseif any(strcmpi(extension,{'.h5','.hdf5'}))
    datasetPath = localOption(options,'DatasetPath','/exported_data');
    image = imagestackio.readH5(options.InputFile,datasetPath,readOptions);
    if size(image.Data,5) > 1
        warning('segmentationtools:ValidationFirstTimeOnly', ...
            'Validation uses the first HDF5 time point.');
    end
    probabilities = image.Data(:,:,:,:,1);
else
    error('segmentationtools:UnsupportedValidationInput', ...
        'InputFile must be TIFF or HDF5.');
end
end

function probabilities = localSyntheticProbabilities()
volumeSize = [96 96 48];
[y,x,z] = ndgrid(1:volumeSize(1),1:volumeSize(2),1:volumeSize(3));
centers = [34 39 24; 66 61 25];
radii = [18 14];
insideScore = zeros(volumeSize);
wallScore = zeros(volumeSize);
for index = 1:size(centers,1)
    distance = sqrt((y-centers(index,1)).^2 + ...
        (x-centers(index,2)).^2 + (z-centers(index,3)).^2);
    insideScore = max(insideScore, 1./(1+exp((distance-radii(index))/1.5)));
    wallScore = max(wallScore, exp(-((distance-radii(index))/1.8).^2));
end
outsideScore = max(0,1-insideScore-wallScore*0.65);
probabilities = cat(4,insideScore,wallScore,outsideScore);
probabilities = probabilities./max(sum(probabilities,4),eps);
end

function value = localOption(options,name,defaultValue)
if isfield(options,name)
    value = options.(name);
else
    value = defaultValue;
end
end
