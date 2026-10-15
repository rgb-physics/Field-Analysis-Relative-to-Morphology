function tests = testSegmentationTools

%TESTSEGMENTATIONTOOLS Synthetic tests for public SegmentationTools functions.
% Active-contour functions are intentionally excluded from this suite.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testsDirectory = fileparts(mfilename('fullpath'));
repositoryRoot = fullfile(testsDirectory, '..', '..', '..');
testCase.TestData.RepositoryRoot = repositoryRoot;
testCase.TestData.SourceRoot = fullfile(repositoryRoot, 'APIs', ...
    'SegmentationTools', 'src');
addpath(testCase.TestData.SourceRoot);
addpath(fullfile(repositoryRoot, 'APIs', 'ImageStackIO', 'src'));
addpath(fullfile(repositoryRoot, 'APIs', 'SharedUtilities', 'src'));
testCase.TestData.WorkDirectory = tempname;
mkdir(testCase.TestData.WorkDirectory);
end

function teardownOnce(testCase)
if isfolder(testCase.TestData.WorkDirectory)
    rmdir(testCase.TestData.WorkDirectory, 's');
end
end

function testCoverageManifest(testCase)
expected = sort({ ...
    'farmClassifyProbabilities.m'; 'farmClassifyProbabilityChannels.m'; ...
    'farmFlatFill3D.m'; 'farmGetCentralSlice.m'; 'farmH5toSmooth3Chans.m'; ...
    'farmImbinarize3_4D.m'; ...
    'farmMakeClasses.m'; 'farmMakeIntensityOptions.m'; 'farmMakeProbabilityOptions.m'; ...
    'farmReadProbabilityTiff.m'; 'farmRemapClassLabels.m'; 'farmRemoveConObjs.m'; ...
    'farmReturnCorrectedBinarizedSurfaceIndices.m'; ...
    'farmReturnSmoothBlobsBW.m'; 'farmReturnSmoothBlobsIDed.m'; ...
    'farmReturnTopBottom2DSheets.m'; ...
    'farmReturnTopBottom2DSheetsConfigurable.m'; ...
    'farmSegmentInOnOutProbabilities.m'; 'farmSegmentIntensity.m'; 'farmSidesHoleFill.m'; ...
    'farmSmoothInOnOutProbabilities.m'; 'farmSmoothNChannelProbabilities.m'; 'farmThresholdProbabilityGroup.m'; ...
    'farmWriteMaskTiff.m'});
entries = dir(fullfile(testCase.TestData.SourceRoot, '**', '*.m'));
paths = arrayfun(@(entry) fullfile(entry.folder, entry.name), entries, ...
    'UniformOutput', false);
activeContour = contains(paths, [filesep 'activeContours' filesep]);
actual = sort({entries(~activeContour).name}.');
verifyEqual(testCase, actual, expected, ...
    ['The coverage manifest must list every SegmentationTools source file ' ...
     'outside activeContours. Add a focused test when adding a function.']);
end

function testIntensityFixedAndCleanup(testCase)
image = zeros(9,9,3,'uint16');
image(2:5,2:5,2) = 1200; image(8,8,2) = 1500; image(1,1,1) = 1000;
r = farmSegmentIntensity(image, ...
    struct('Method','fixed','Threshold',1000,'MinObjectSize',2,'ReturnLabels',true));
verifyEqual(testCase,nnz(r.CandidateMask),17);
verifyEqual(testCase,r.VoxelCount,16);
verifyEqual(testCase,r.ComponentCount,1);
verifyEqual(testCase,r.LabelVolume>0,r.Mask);
dark = farmSegmentIntensity(uint16([100 200 300]), ...
    struct('Method','fixed','Threshold',200,'Foreground','dark'));
verifyEqual(testCase,dark.Mask,logical([1 0 0]));
end

function testIntensityOtsuReferenceAndConstant(testCase)
image = [zeros(4,4) 100*ones(4,4)];
r = farmSegmentIntensity(image);
verifyEqual(testCase,r.Mask,image>50);
scaled = farmSegmentIntensity(uint16(image*10+200));
verifyEqual(testCase,scaled.Mask,r.Mask);
constant = farmSegmentIntensity(ones(4,4)*7);
verifyEqual(testCase,constant.VoxelCount,0);
reference = false(size(image)); reference(:,1:4) = true;
r = farmSegmentIntensity(image,struct('EstimationMask',reference));
verifyTrue(testCase,all(r.Mask(:,5:8),'all')); % reference does not restrict output
end

function testIntensityHolesLargestAndValidation(testCase)
image = zeros(10,10); image(2:6,2:6) = 10; image(4,4) = 0; image(9,9) = 10;
r = farmSegmentIntensity(image, ...
    struct('Method','fixed','Threshold',5,'FillHoles',true,'KeepLargest',1));
verifyEqual(testCase,r.VoxelCount,25);
verifyFalse(testCase,r.CandidateMask(4,4)); verifyTrue(testCase,r.Mask(4,4));
verifyError(testCase,@() farmSegmentIntensity( ...
    zeros(2,2,2,2)),'segmentationtools:InvalidIntensityDimensions');
verifyError(testCase,@() farmSegmentIntensity( ...
    image,struct('Typo',true)),'segmentationtools:UnknownOption');
end

function testNChannelPrecedence(testCase)
p = zeros(2,3,1,4); p(:,:,:,1) = 0.7; p(:,:,:,3) = 0.9; p(:,:,:,4) = 0.5;
[m,info] = farmSmoothNChannelProbabilities( ...
    p,[1 3 4],0.5,struct('OpeningRadius',0,'ReturnOpenedMasks',true));
verifyTrue(testCase,all(m(:,:,:,1),'all')); % priority beats larger score
verifyEqual(testCase,info.VoxelCounts,[6 0 0]);
verifyEqual(testCase,info.OverlapVoxelCountBeforeResolution,6);
verifyFalse(testCase,any(info.OpenedMasks(:,:,:,3),'all')); % exact threshold excluded
[m,info] = farmSmoothNChannelProbabilities( ...
    p,[1 3 4],[0.5 0.5 0.5],struct('OpeningRadius',0,'ChannelPrecedence',[3 4 1]));
verifyTrue(testCase,all(m(:,:,:,2),'all')); % output order unchanged
verifyEqual(testCase,info.VoxelCounts,[0 6 0]);
allMasks = farmSmoothNChannelProbabilities( ...
    p,[],0.5,struct('OpeningRadius',0));
verifySize(testCase,allMasks,[2 3 1 4]);
verifyError(testCase,@() farmSmoothNChannelProbabilities( ...
    p,[1 3],0.5,struct('ChannelPrecedence',[1 2])), ...
    'segmentationtools:InvalidChannelPrecedence');
verifyError(testCase,@() farmSmoothNChannelProbabilities( ...
    p,[1 3],0.5,struct('ChannelPrecedence',[1 1])), ...
    'segmentationtools:InvalidChannelPrecedence');
end

function testNChannelOpeningAndUnclassified(testCase)
p = zeros(11,11,7,2); p(3:9,3:9,2:6,1) = 0.8; p(1,1,1,1) = 0.9;
p(4:8,4:8,3:5,2) = 0.9;
[m,info] = farmSmoothNChannelProbabilities( ...
    p,[2 1],[0.5 0.6],struct('OpeningRadius',1,'ReturnOpenedMasks',true));
kernel = strel('sphere',1);
first = imdilate(imerode(p(:,:,:,2)>0.5,kernel),kernel);
second = imdilate(imerode(p(:,:,:,1)>0.6,kernel),kernel);
verifyEqual(testCase,m(:,:,:,1),first);
verifyEqual(testCase,m(:,:,:,2),second & ~first);
verifyFalse(testCase,m(1,1,1,2));
verifyEqual(testCase,info.UnclassifiedVoxelCount,nnz(~(first|second)));
verifyFalse(testCase,any(sum(m,4)>1,'all'));
end

function testMakeClassConfig(testCase)
options = struct('Names', ["inside" "wall" "outside"], ...
    'CombineMethods', ["sum" "union" "sum"], 'IDs', [10 20 30]);
classes = farmMakeClasses( ...
    {1, [3 4], 2}, {0.2, [0.5 0.6], 0.4}, options);
verifyEqual(testCase, {classes.Name}, {'inside','wall','outside'});
verifyEqual(testCase, classes(2).Channels, [3 4]);
verifyEqual(testCase, classes(2).Thresholds, [0.5 0.6]);
verifyEqual(testCase, [classes.ID], [10 20 30]);

arrayClasses = farmMakeClasses( ...
    [1 3 2], [0.2 0.5 0.5], ...
    struct('Names', ["inside" "wall" "outside"]));
verifyEqual(testCase, [arrayClasses.Channels], [1 3 2]);
verifyEqual(testCase, [arrayClasses.Thresholds], [0.2 0.5 0.5]);
namedClasses = farmMakeClasses([1 2],0.5, ...
    'Names',{'first','second'},'IDs',[4 9]);
verifyEqual(testCase,[namedClasses.ID],[4 9]);
end

function testIntensityOptionsBuilder(testCase)
options = farmMakeIntensityOptions( ...
    'Method','fixed','Threshold',5,'ReturnLabels',true);
image = reshape(uint16(1:9),3,3);
result = farmSegmentIntensity(image,options);
verifyEqual(testCase,result.Mask,image>5);
verifyTrue(testCase,isfield(result,'LabelVolume'));
verifyError(testCase,@()farmMakeIntensityOptions( ...
    'Threshhold',5),'sharedutilities:Config');
end

function testProbabilityOptionsBuilder(testCase)
classes = farmMakeClasses([1 2],0.5);
p = cat(4,0.8*ones(3,4,2),0.2*ones(3,4,2));
options = farmMakeProbabilityOptions('ReturnMasks',true);
result = farmClassifyProbabilities(p,classes,options);
verifyTrue(testCase,all(result.LabelVolume(:)==1));
verifyTrue(testCase,all(result.Masks(:,:,:,1),'all'));
verifyFalse(testCase,any(result.Masks(:,:,:,2),'all'));
verifyError(testCase,@()farmMakeProbabilityOptions( ...
    'EnsureDisjoint',false),'segmentationtools:Config');
end

function testThresholdProbabilityGroup(testCase)
p = zeros(2,2,1,2);
p(:,:,1,1) = [0.2 0.4; 0.6 0.1];
p(:,:,1,2) = [0.3 0.1; 0.2 0.8];
[sumMask, sumInfo] = farmThresholdProbabilityGroup( ...
    p, [1 2], 0.5, struct('CombineMethod','sum','ReturnScore',true));
verifyEqual(testCase, sumMask, (p(:,:,:,1) + p(:,:,:,2)) > 0.5);
verifyEqual(testCase, sumInfo.Score, p(:,:,:,1) + p(:,:,:,2));

unionMask = farmThresholdProbabilityGroup( ...
    p, [1 2], [0.5 0.7], struct('CombineMethod','union'));
expected = p(:,:,:,1) > 0.5 | p(:,:,:,2) > 0.7;
verifyEqual(testCase, unionMask, expected);
verifyFalse(testCase, sumMask(1,1,1)); % strict: 0.2 + 0.3 == 0.5
end

function testClassifyProbabilities(testCase)
p = zeros(1,4,1,2);
p(1,:,1,1) = [0.8 0.7 0.1 0.6];
p(1,:,1,2) = [0.2 0.7 0.1 0.9];
classes = farmMakeClasses( ...
    [1 2], [0.5 0.5], struct('Names',["first" "second"], 'IDs',[4 9]));
options = struct('ReturnLabelVolume',true,'ReturnMasks',true, ...
    'ReturnCandidateMasks',true,'ReturnOverlapMask',true, ...
    'ReturnUnclassifiedMask',true,'ReturnChangedVoxelMask',true, ...
    'CountComponents',true);
result = farmClassifyProbabilities(p,classes,options);
verifyEqual(testCase, squeeze(result.LabelVolume), uint8([4 4 0 9]));
verifyTrue(testCase, result.OverlapMask(1,2,1));
verifyTrue(testCase, result.UnclassifiedMask(1,3,1));
verifyEqual(testCase, sum(result.Masks,4) <= 1, true(size(result.LabelVolume)));

options.AssignUnclassified = true;
exhaustive = farmClassifyProbabilities(p,classes,options);
verifyNotEqual(testCase, exhaustive.LabelVolume(1,3,1), uint8(0));
end

function testClassifyProbabilityChannels(testCase)
p = zeros(2,2,1,3);
p(:,:,:,1) = 0.8; p(:,:,:,2) = 0.2; p(:,:,:,3) = 0.6;
options = struct('Names',["one" "two" "three"], ...
    'IDs',[3 5 7], 'ClassifyOptions',struct('ReturnMasks',true));
result = farmClassifyProbabilityChannels( ...
    p, [], [0.5 0.5 0.5], options);
verifyEqual(testCase, [result.Classes.ID], [3 5 7]);
verifyEqual(testCase, result.VoxelCounts, [4 0 0]);
end

function testInOnOutAndHistoricalWrapper(testCase)
p = localSemanticProbabilities();
classification = struct('ReturnMasks',true,'ReturnLabelVolume',true);
result = farmSegmentInOnOutProbabilities( ...
    p, [1 2 3], [0.5 0.5 0.5], struct('ClassifyOptions',classification));
verifyEqual(testCase, result.SemanticOrder, {'inside','wall','outside'});
verifyEqual(testCase, sum(result.Masks,4) <= 1, true(size(p,1),size(p,2),size(p,3)));

[inside,wall,outside] = ...
    farmSmoothInOnOutProbabilities( ...
    p,[1 2 3],[0.5 0.5 0.5],struct('OpeningRadius',0,'SpanSpace',false));
[legacyInside,legacyOutside,legacyWall] = ...
    farmH5toSmooth3Chans( ...
    p,[3 1 2],[0.5 0.5 0.5],0,false);
verifyEqual(testCase, legacyInside, inside);
verifyEqual(testCase, legacyOutside, outside);
verifyEqual(testCase, legacyWall, wall);
end

function testImbinarize3_4D(testCase)
data = cat(4, [0.2 0.8; 0.5 0.6], [0.7 0.1; 0.4 0.9]);
result = farmImbinarize3_4D(data,[0.5 0.6]);
verifyClass(testCase,result,'logical');
verifyEqual(testCase,result(:,:,:,1),data(:,:,:,1) > 0.5);
verifyEqual(testCase,result(:,:,:,2),data(:,:,:,2) > 0.6);
end

function testRemapClassLabels(testCase)
labels = uint8([0 1 2; 3 2 1]);
mapped = farmRemapClassLabels( ...
    labels,[1 2 3],[85 170 255]);
verifyEqual(testCase,mapped,uint8([0 85 170; 255 170 85]));
end

function testFlatFill3D(testCase)
mask = false(7,7,3);
mask([2 6],2:6,2) = true;
mask(2:6,[2 6],2) = true;
filled = farmFlatFill3D(mask,0);
verifyTrue(testCase,filled(4,4,2));
verifyFalse(testCase,filled(4,4,1));
end

function testRemoveConObjs(testCase)
mask2 = false(12,12);
mask2(2:6,2:6) = true; mask2(10,10) = true;
[largest2,removed2] = farmRemoveConObjs(mask2,1,'large');
verifyEqual(testCase,nnz(largest2),25);
verifyEqual(testCase,numel(removed2),1);

mask3 = false(12,12,4);
mask3(2:5,2:5,2:3) = true; mask3(10,10,2) = true;
components = bwconncomp(mask3);
[kept,removed] = farmRemoveConObjs(mask3,1,'indices');
verifyEqual(testCase,nnz(kept),numel(components.PixelIdxList{1}));
verifyEqual(testCase,numel(removed),numel(components.PixelIdxList{2}));
end

function testSidesHoleFill(testCase)
mask = true(9,9,9);
mask(3:7,3:7,3:7) = false;
filled = farmSidesHoleFill(mask);
verifySize(testCase,filled,size(mask));
verifyTrue(testCase,filled(5,5,5));
end

function testSmoothBlobCleanup(testCase)
mask = false(21,21,9);
mask(6:16,6:16,3:7) = true;
binary = farmReturnSmoothBlobsBW(mask,0,0,0.5);
verifyClass(testCase,binary,'logical');
verifySize(testCase,binary,size(mask));

labels = zeros(size(mask),'uint8');
labels(4:9,4:9,3:6) = 1;
labels(13:18,13:18,3:6) = 2;
fast = farmReturnSmoothBlobsIDed(labels,0,0,0.5,'fast');
slow = farmReturnSmoothBlobsIDed(labels,0,0,0.5,'slow');
verifySize(testCase,fast,size(labels));
verifySize(testCase,slow,size(labels));
verifyTrue(testCase,all(ismember(unique(fast),uint8([0 1 2]))));
verifyTrue(testCase,all(ismember(unique(slow),uint8([0 1 2]))));
end

function testMaskTiffRoundTrips(testCase)
folder = testCase.TestData.WorkDirectory;
single = uint8(reshape(1:60,[4 5 3]));
singlePath = fullfile(folder,'single_mask.tif');
farmWriteMaskTiff(single,singlePath,struct('Overwrite',true));
[singleRead,singleImage] = farmReadProbabilityTiff(singlePath);
verifyEqual(testCase,singleRead,single);
verifyEqual(testCase,singleImage.Axes,'YXZCT');

multi = zeros(4,5,3,2,'uint8');
multi(:,:,:,1) = 11; multi(:,:,:,2) = 22;
multiPath = fullfile(folder,'multi_mask.tif');
farmWriteMaskTiff(multi,multiPath,struct('Overwrite',true));
multiRead = farmReadProbabilityTiff(multiPath);
verifyEqual(testCase,multiRead,multi);
end

function testReadProbabilityTiffTimeHandling(testCase)
data = zeros(3,4,2,1,2,'uint8');
data(:,:,:,:,1) = 7; data(:,:,:,:,2) = 13;
path = fullfile(testCase.TestData.WorkDirectory,'time_stack.tif');
farmWriteImageJHyperstack( ...
    struct('Data',data,'Axes','YXZCT'),path,struct('Overwrite',true));
selected = farmReadProbabilityTiff(path,struct('TimeIndex',2));
verifyEqual(testCase,selected,data(:,:,:,:,2));
asChannels = farmReadProbabilityTiff( ...
    path,struct('TimeAsChannels',true));
verifySize(testCase,asChannels,[3 4 2 2]);
verifyEqual(testCase,asChannels(:,:,:,1),data(:,:,:,:,1));
verifyEqual(testCase,asChannels(:,:,:,2),data(:,:,:,:,2));
end

function testGetCentralSlice(testCase)
mask = localTwoSheetMask();
split = farmGetCentralSlice(mask);
verifyEqual(testCase,split,6);
end

function testCorrectedSurfaceIndices(testCase)
surface = 3*ones(5,5);
surface(3,3) = 0;
[indices,holes] = farmReturnCorrectedBinarizedSurfaceIndices(surface,[5 5 6]);
[~,~,z] = ind2sub([5 5 6],indices);
verifyEqual(testCase,z,3*ones(25,1));
verifyEqual(testCase,nnz(holes),1);
end

function testOriginalTwoSheetWorkflow(testCase)
mask = localTwoSheetMask();
[top,bottom,topZ,bottomZ,removed,removedZ,split] = ...
    farmReturnTopBottom2DSheets(mask);
verifyEqual(testCase,split,6);
verifyTrue(testCase,mean(topZ(top)) < mean(bottomZ(bottom)));
verifyEqual(testCase,nnz(top & bottom),0);
verifyEqual(testCase,nnz(removedZ > 0),nnz(removed));
end

function testConfigurableTwoSheetWorkflow(testCase)
mask = localTwoSheetMask();
options = struct('SplitSlice',6,'GapHalfWidth',1,'Connectivity',26);
[top,bottom,topZ,bottomZ,removed,removedZ,split] = ...
    farmReturnTopBottom2DSheetsConfigurable(mask,options);
verifyEqual(testCase,split,6);
verifyTrue(testCase,mean(topZ(top)) < mean(bottomZ(bottom)));
verifyEqual(testCase,nnz(top & bottom),0);
verifyEqual(testCase,nnz(removedZ > 0),nnz(removed));
end

function probabilities = localSemanticProbabilities()
[y,x,z] = ndgrid(1:21,1:21,1:9);
distance = sqrt((y-11).^2 + (x-11).^2 + (z-5).^2);
inside = double(distance < 5);
wall = double(distance >= 5 & distance < 7);
outside = double(distance >= 7);
probabilities = cat(4,inside,wall,outside);
end

function mask = localTwoSheetMask()
mask = false(20,20,11);
mask(3:18,3:18,2:4) = true;
mask(3:18,3:18,8:10) = true;
mask(9:12,9:12,5) = true;
mask(10,10,6) = true;
mask(9:12,9:12,7) = true;
end
