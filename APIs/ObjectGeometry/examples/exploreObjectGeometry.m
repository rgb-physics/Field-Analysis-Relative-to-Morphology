%% Real-data object measurements, shells and distance gradients
% Edit the semantic channel order to match the HDF5 fixture; no files in
% tests/data are changed. Outputs are created in a fresh temporary directory.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this saved script.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

semanticChannels = [1 3 2]; % [inside wall outside], confirm by eye
thresholds = [0.2 0.5 0.5];
shellMean = 0; shellWidth = 1; sigma = 1;
folder = fileparts(mfilename('fullpath')); root = fullfile(folder,'..','..','..');
for api = {'ObjectGeometry','SegmentationTools','ImageStackIO','SharedUtilities'}
    addpath(fullfile(root,'APIs',api{1},'src'));
end
addpath(fullfile(root,'tests'));
path = fullfile(farmTestDataRoot(),'image-stacks','hdf5', ...
    'inOnOut_3ChannelSegmentation_cropped.h5');
image = farmReadH5(path,'/exported_data',struct('SourceAxes','CYXZ'));
segmented = farmSegmentInOnOutProbabilities( ...
    image.Data(:,:,:,:,1),semanticChannels,thresholds, ...
    struct('ClassifyOptions',struct('ReturnMasks',true)));
mask = segmented.Masks(:,:,:,1);
[properties,objects] = farmMeasureObjects(mask, ...
    {'Volume','Centroid','BoundingBox','PrincipalAxisLength'}, ...
    struct('DatasetID','h5-fixture','Frame',1,'Spacing',image.Spacing, ...
    'SpacingUnit',image.SpacingUnit));
shells = farmGenerateGeometry(objects,'boundary', ...
    struct('LayerMean',shellMean,'LayerWidth',shellWidth,'Sigma',sigma));
shellMask = false(size(mask));
for i = 1:numel(shells.Records), shellMask(shells.Records(i).Indices) = true; end
[gradients,distanceField,gradientMetadata,valid] = farmObjectDistanceGradients( ...
    mask,struct('Sigma',sigma,'Spacing',image.Spacing,'SpacingUnit',image.SpacingUnit));
outputDirectory = tempname; mkdir(outputDirectory);
save(fullfile(outputDirectory,'measurements_and_geometry.mat'), ...
    'properties','objects','shells','gradientMetadata');
farmWriteMaskTiff(cat(4,mask,shellMask),fullfile(outputDirectory,'inside_and_shell.tif'));
% Float fields belong in MAT rather than integer mask TIFF output. Slice
% figures preserve gradient signs and use colorbars for interpretation.
z = round(size(mask,3)/2);
figure('Name','ObjectGeometry real-data preview');
subplot(2,3,1); imagesc(mask(:,:,z)); axis image; title('Inside mask');
subplot(2,3,2); imagesc(shellMask(:,:,z)); axis image; title('Shell');
subplot(2,3,3); imagesc(distanceField(:,:,z)); axis image; colorbar; title('Signed distance');
for i = 1:3
    subplot(2,3,3+i); imagesc(gradients(:,:,z,i)); axis image; colorbar;
    title(sprintf('Gradient component %d (XYZ)',i));
end
save(fullfile(outputDirectory,'distance_and_gradient_fields.mat'),'distanceField','gradients','valid');
disp(properties); fprintf('Visual outputs: %s\n',outputDirectory);
