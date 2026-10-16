function tests = testObjectGeometry

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
folder = fileparts(mfilename('fullpath')); root = fullfile(folder,'..','..','..');
addpath(fullfile(root,'APIs','ObjectGeometry','src'));
addpath(fullfile(root,'APIs','SharedUtilities','src'));
addpath(fullfile(root,'APIs','ImageStackIO','src'));
testCase.TestData.Root = root;
addpath(fullfile(root,'tests'));
end

function testFieldOnObjectsSelectionAndOverlap(testCase)
selected = logical([1 1 0; 1 0 1]);
indices = [1; 2; 4; 6];
[values, returnedIndices, returnedSelection] = ...
    farmFieldOnObjs([10; 20], [2 3], indices, selected);
verifyEqual(testCase, values, [10 0 0; 20 10 20]);
verifyClass(testCase, values, 'double');
verifyEqual(testCase, returnedIndices, indices);
verifyEqual(testCase, returnedSelection, selected);

overlap = farmFieldOnObjs([10; 20], [2 3 2], [1; 1], true(2, 1));
expected = zeros(2, 3, 2);
expected(1) = 20;
verifyEqual(testCase, overlap, expected);

empty = farmFieldOnObjs([], [2 3], [], false(0, 0));
verifyEqual(testCase, empty, zeros(2, 3));
end

function testEndpointRasterizerUsesIncludedAssignment(testCase)
% Historical sampling uses round(length) points, including both endpoints.
filaments = array2table([0 0 0 1 2 2 4 2 2]);
[labels, indices, selected] = farmCoords2Mat_2DFils(filaments, [5 5 5], 5);
expected = zeros(5, 5, 5);
expected([1 3 4], 2, 2) = 1;
verifyEqual(testCase, labels, expected);
verifyEqual(testCase, indices, sub2ind([5 5 5], [1; 3; 4], 2*ones(3,1), 2*ones(3,1)));
verifyEqual(testCase, selected, true(1, 3));
end

function testSkeletonCleanupPreservesInputGrid(testCase)
% A 20-voxel component exceeds median size + one standard deviation;
% three separated singletons do not. Distance cutoff 1 adds no neighbors.
input = false(60, 60, 10);
input(5:24, 5, 5) = true;
input(40, 40, 5) = true;
input(50, 40, 5) = true;
input(40, 50, 5) = true;

expected = zeros(size(input));
expected(5:24, 5, 5) = 1;
actual = farmSkel3DClean(input, 1);

verifyEqual(testCase, actual, expected);
verifyClass(testCase, actual, 'double');
verifySize(testCase, actual, size(input));
end

function testMaskIdentity(testCase)
mask = false(12); mask(2:4,3:6) = true; mask(9:10,9:10) = true;
[t,o] = farmMeasureObjects(mask,{'Area','Centroid'}, ...
    struct('DatasetID','A','Frame',7));
verifyEqual(testCase,t.Area,[12;4]);
verifyEqual(testCase,t.Centroid,[4.5 3;9.5 9.5]);
verifyEqual(testCase,t.ObjectID,[1;2]); verifyEqual(testCase,t.Frame,[7;7]);
verifyEqual(testCase,o.Grid.Spacing,[1 1 1]);
end
function testDisconnectedLabelsRemainOneIdentity(testCase)
labels = zeros(10,'uint16'); labels(2,2) = 12; labels(8,8) = 12; labels(2,3) = 99;
t = farmMeasureObjects(labels,{'Area','Centroid'});
verifyEqual(testCase,t.ObjectID,[12;99]); verifyEqual(testCase,t.Area,[2;1]);
verifyEqual(testCase,t.Centroid(1,:),[5 5]);
end
function testSuppliedComponentsOrder(testCase)
mask = false(8); mask(2,2) = true; mask(6:7,6:7) = true;
cc = bwconncomp(mask); cc.PixelIdxList = cc.PixelIdxList([2 1]);
t = farmMeasureObjects(cc,{'Area'},struct('ObjectIDs',[90 7]));
verifyEqual(testCase,t.ObjectID,[90;7]); verifyEqual(testCase,t.Area,[4;1]);
end
function testIndexGroups(testCase)
groups = {sub2ind([8 9],[2 2],[3 4]),sub2ind([8 9],7,8)};
t = farmMeasureObjects(groups,{'Area','Centroid'}, ...
    struct('ImageSize',[8 9],'ObjectIDs',[50 4]));
verifyEqual(testCase,t.ObjectID,[50;4]); verifyEqual(testCase,t.Area,[2;1]);
verifyEqual(testCase,t.Centroid,[3.5 2;8 7]);
end
function testEmptyForeground(testCase)
t = farmMeasureObjects(false(8,9,4),{'Volume','Centroid'});
verifyEqual(testCase,height(t),0); verifySize(testCase,t.Centroid,[0 3]);
[p,s] = farmStoreFilCCs(false(8,9,4));
verifyEqual(testCase,height(p),0); verifyEmpty(testCase,s);
verifySize(testCase,p.ExtentInVoxels,[0 1]);
verifySize(testCase,p.PrincipalAxisLength,[0 3]);
verifySize(testCase,p.Directors,[0 3]);
flat = farmMeasureObjects(false(8,9),{'Centroid','BoundingBox','Area'});
verifySize(testCase,flat.Centroid,[0 2]);
verifySize(testCase,flat.BoundingBox,[0 4]);
verifySize(testCase,flat.Area,[0 1]);
end
function testNativeAll(testCase)
mask = false(8); mask(3:5,3:6) = true;
t = farmMeasureObjects(mask,'all');
verifyTrue(testCase,all(ismember({'Area','Centroid','PixelIdxList','Orientation'},t.Properties.VariableNames)));
explicit = farmMeasureObjects(mask,{'Area','Centroid'});
verifyEqual(testCase,t.Area,explicit.Area);
verifyEqual(testCase,t.Centroid,explicit.Centroid);
volume = false(8,9,5); volume(3:5,3:6,2:4) = true;
all3D = farmMeasureObjects(volume,"all");
verifyEqual(testCase,all3D.Volume,36);
verifyTrue(testCase,ismember('EigenVectors',all3D.Properties.VariableNames));
emptyAll = farmMeasureObjects(false(size(volume)),{'all'});
verifyEqual(testCase,height(emptyAll),0);
verifySize(testCase,emptyAll.Centroid,[0 3]);
filaments = farmMeasureFilaments(volume,{'all','Directors'});
verifyEqual(testCase,height(filaments),1);
verifyTrue(testCase,ismember('Directors',filaments.Properties.VariableNames));
end
function testIntensityAndMismatch(testCase)
mask = false(6); mask(2:3,2:3) = true; field = reshape(1:36,6,6);
t = farmMeasureObjects(mask,{'MeanIntensity'},struct('Intensity',field));
verifyEqual(testCase,t.MeanIntensity,mean(field(mask)));
verifyError(testCase,@() farmMeasureObjects(mask,{'MeanIntensity'}, ...
    struct('Intensity',ones(7))),'objectgeometry:GridMismatch');
end
function testLegacyTwoDimensionalMultipleObjects(testCase)
mask = false(10); mask(2:3,2:4) = true; mask(8,8) = true;
[cc,s] = farmBlobMat2CCProps(mask,{'Area','Centroid'});
verifyEqual(testCase,cc.NumObjects,2); verifyEqual(testCase,s.Area,[6;1]);
[~,s] = farmBlobMat2CCProps(mask,{'Area','Centroid'},s);
verifyEqual(testCase,numel(s),2); verifyEqual(testCase,s(2).Centroid,s(1).Centroid);
end
function testThreeDimensionalProperties(testCase)
mask = false(13,17,9); mask(4:6,3:12,3:7) = true;
t = farmMeasureObjects(mask,{'Volume','Centroid','BoundingBox'});
verifyEqual(testCase,t.Volume,150); verifyEqual(testCase,t.Centroid,[7.5 5 5]);
verifyEqual(testCase,t.BoundingBox,[2.5 3.5 2.5 10 3 5]);
end
function testFilamentAxisConvention(testCase)
mask = false(15,25,11); mask(6:8,4:22,5:7) = true;
t = farmMeasureFilaments(mask,{'Directors','ExtentInVoxels','AspectRatios'});
verifyEqual(testCase,abs(t.Directors),[1 0 0],'AbsTol',1e-10);
verifyGreaterThan(testCase,t.AspectRatios,1);
verifyFalse(testCase,ismember('EigenVectors',t.Properties.VariableNames));
end
function testTwoDimensionalFilamentConvention(testCase)
mask = false(21); mask(sub2ind(size(mask),5:17,5:17)) = true;
t = farmMeasureFilaments(mask,{'Directors'});
verifyEqual(testCase,abs(t.Directors),[1 1]/sqrt(2),'AbsTol',1e-10);
verifyGreaterThan(testCase,prod(t.Directors),0);
end
function testCoordinateScaledPCA(testCase)
mask = false(15,25,11); mask(6:8,4:22,5:7) = true;
t = farmMeasureFilaments(mask, ...
    {'ScaledDirectors','ProjectedExtent','ScaledAspectRatios'}, ...
    struct('Identity',struct('Spacing',[0.4 0.2 0.8],'SpacingUnit','um')));
verifyEqual(testCase,abs(t.ScaledDirectors),[1 0 0],'AbsTol',1e-10);
verifyEqual(testCase,t.ProjectedExtent,18*0.2,'AbsTol',1e-10);
verifyEqual(testCase,t.ScaledAspectRatios,3.6/1.6,'AbsTol',1e-10);
verifyEqual(testCase,t.Properties.UserData.ProjectedExtentUnit,"um");
end
function testProjectedExtentSmallerZSpacing(testCase)
expectedLengthUm = 40;
report = farmTestFilamentExtentAngleSweep(.25,expectedLengthUm);
localVerifyExtentSweep(testCase,report);
end
function testProjectedExtentLargerZSpacing(testCase)
expectedLengthUm = 40;
report = farmTestFilamentExtentAngleSweep(2,expectedLengthUm);
localVerifyExtentSweep(testCase,report);
end
function localVerifyExtentSweep(testCase,report)
verifyEqual(testCase,height(report),21);
verifyEqual(testCase,report.ComponentCount,ones(height(report),1));
verifyTrue(testCase,all(isfinite(report.ProjectedExtentUm)));
verifyTrue(testCase,all(abs(report.ErrorUm)<=report.LengthToleranceUm), ...
    'Physical extent differs from the configured centerline beyond the raster allowance.');
verifyTrue(testCase,all(report.DirectorErrorDegrees<=report.DirectorToleranceDegrees));
% Axis-aligned spans equal the distance between the rounded voxel centers,
% even when the requested length is not a multiple of voxel spacing.
axisAligned = report.ElevationDegrees==90 | ...
    (report.ElevationDegrees==0 & ismember(report.AzimuthDegrees,[0 90]));
verifyEqual(testCase,report.ProjectedExtentUm(axisAligned), ...
    report.RoundedEndpointSpanUm(axisAligned),'AbsTol',1e-10);
end
function testProjectedExtentConfigurableLength(testCase)
expectedLengthUm = 24.5;
report = farmTestFilamentExtentAngleSweep(2,expectedLengthUm);
verifyEqual(testCase,report.ExpectedLengthUm,repmat(expectedLengthUm,height(report),1));
verifyEqual(testCase,report.ErrorUm,report.ProjectedExtentUm-expectedLengthUm);
localVerifyExtentSweep(testCase,report);
end
function testGradientLinearFieldAndSpacing(testCase)
[y,x,z] = ndgrid(1:9,1:11,1:7); field = 2*x+3*y+4*z;
[g,meta,valid] = farmDistanceGradients(field);
verifyEqual(testCase,g(:,:,:,1),2*ones(size(field)));
verifyEqual(testCase,g(:,:,:,2),3*ones(size(field)));
verifyEqual(testCase,g(:,:,:,3),4*ones(size(field))); verifyTrue(testCase,all(valid,'all'));
verifyEqual(testCase,meta.ComponentAxes,'XYZ');
g = farmDistanceGradients(field, ...
    struct('Spacing',[3 2 4],'DerivativeUnits','physical','FlipY',true));
verifyEqual(testCase,g(:,:,:,1),ones(size(field)));
verifyEqual(testCase,g(:,:,:,2),-ones(size(field)));
verifyEqual(testCase,g(:,:,:,3),ones(size(field)));
end
function testGradientSmoothingAndZeroVectors(testCase)
[y,x] = ndgrid(1:15,1:17); field = x.^2+y.^2;
g = farmDistanceGradients(field,struct('Sigma',1));
[gx,gy] = gradient(field);
verifyEqual(testCase,g(:,:,1,1),imgaussfilt(gx,1),'AbsTol',1e-10);
verifyEqual(testCase,g(:,:,1,2),imgaussfilt(gy,1),'AbsTol',1e-10);
g = farmDistanceGradients(field,struct('Sigma',1,'SmoothingOrder','distance-first'));
[gx,gy] = gradient(imgaussfilt(field,1));
verifyEqual(testCase,g(:,:,1,1),gx,'AbsTol',1e-10);
verifyEqual(testCase,g(:,:,1,2),gy,'AbsTol',1e-10);
[g,~,valid] = farmDistanceGradients(ones(6),struct('Normalize',true));
verifyFalse(testCase,any(valid,'all')); verifyEqual(testCase,nnz(g),0);
end
function testObjectDistanceDefinitions(testCase)
mask = false(9); mask(3:7,3:7) = true;
[~,signed] = farmObjectDistanceGradients(mask);
verifyEqual(testCase,signed,farmSignedBWDist(mask));
[~,interior] = farmObjectDistanceGradients(mask,struct('DistanceType','interior'));
verifyEqual(testCase,interior,bwdist(~mask));
[g,~,meta,valid] = farmObjectDistanceGradients(false(8));
verifyTrue(testCase,all(isnan(g),'all')); verifyFalse(testCase,any(valid,'all'));
verifyFalse(testCase,meta.FiniteDistanceField);
end
function testNematicKnownAnglesAndReversal(testCase)
a = [0;pi/6;pi/4;pi/2]; u = [cos(a) sin(a)];
r = farmNematicAlignment(u,[1 0]);
verifyEqual(testCase,r.Order,[1;0.5;0;-1],'AbsTol',1e-10);
flipped = farmNematicAlignment(-u,[-1 0]);
verifyEqual(testCase,flipped.Order,r.Order,'AbsTol',1e-10);
verifyEqual(testCase,flipped.SignedAngle,r.SignedAngle,'AbsTol',1e-10);
u = [cos(a) sin(a) zeros(4,1)]; r = farmNematicAlignment(u,[1 0 0]);
verifyEqual(testCase,r.Order,[1;0.625;0.25;-0.5],'AbsTol',1e-10);
verifyEqual(testCase,r.UnsignedAngle,a,'AbsTol',1e-10);
verifyTrue(testCase,all(isnan(r.SignedAngle)));
end
function testSignedAngleAndProjectionSelection(testCase)
u = [cosd(80) sind(80);cosd(-80) sind(-80)]; v = [cosd(70) sind(70);cosd(70) sind(70)];
r = farmNematicAlignment(u,v);
verifyEqual(testCase,r.SignedAngle,deg2rad([10;30]),'AbsTol',1e-10);
u = [1 0 0;1 0 10;1 0 -10;0 0 1];
r = farmNematicAlignment(u,[1 0 0],struct('Plane',[1 2],'MaxNormalComponent',0.5));
verifyEqual(testCase,r.Valid,[true;false;false;false]);
verifyTrue(testCase,all(isnan(r.Order(2:4))));
end
function testConcatenationAndShuffledAttachment(testCase)
base = localKeys([10;20;10],[1;1;2],["A";"A";"A"]);
base.Volume = [100;200;300];
combined = farmConcatenateMeasurements({base(1:2,:),base(3,:)});
extra = base([3 1 2],{'DatasetID','Frame','ObjectID'}); extra.Intensity = [33;11;22];
attached = farmAttachMeasurements(combined,extra);
verifyEqual(testCase,attached.Intensity,[11;22;33]);
verifyEqual(testCase,attached.ObjectID,base.ObjectID);
filtered = farmAttachMeasurements(combined([3 1],:),extra);
verifyEqual(testCase,filtered.Intensity,[33;11]);
end
function testAttachmentMissingDuplicateAndOverwrite(testCase)
base = localKeys([1;2],[1;1],["A";"A"]);
extra = base(1,:); extra.Value = uint16(7);
verifyError(testCase,@() farmAttachMeasurements(base,extra),'objectgeometry:MissingMeasurements');
r = farmAttachMeasurements(base,extra,struct('MissingPolicy','missing'));
verifyEqual(testCase,r.Value(1),7); verifyTrue(testCase,isnan(r.Value(2)));
verifyError(testCase,@() farmAttachMeasurements(base,[extra;extra]),'objectgeometry:DuplicateKeys');
verifyError(testCase,@() farmAttachMeasurements(r,extra,struct('MissingPolicy','missing')),'objectgeometry:ExistingProperty');
end
function testDatasetIsolation(testCase)
base = localKeys([1;1],[1;1],["A";"B"]); extra = base([2 1],:); extra.Signal = [20;10];
r = farmAttachMeasurements(base,extra);
verifyEqual(testCase,r.Signal,[10;20]);
verifyError(testCase,@() farmConcatenateMeasurements({base;base}),'objectgeometry:DuplicateKeys');
end
function testShellUsesThreeDimensionalSmoothing(testCase)
mask = false(15,15,11); mask(4:12,4:12,3:9) = true;
d = farmSignedBWDist(mask); smooth = imgaussfilt3(d,1);
shell = farmReturnSmoothBoundsBW(mask,0,1,1);
verifyEqual(testCase,shell,smooth>-1 & smooth<1);
shell2 = farmReturnSmoothBoundsBW(mask(:,:,6),0,1,0);
d2 = farmSignedBWDist(mask(:,:,6));
verifyEqual(testCase,shell2,d2>-1 & d2<1);
end
function testGeometryDisconnectedComponentsAndIndices(testCase)
labels = zeros(18,18,9,'uint16'); labels(3:7,3:7,3:6) = 12; labels(11:15,11:15,3:6) = 12;
g = farmGenerateGeometry(labels,'boundary',struct('Sigma',0));
verifyEqual(testCase,numel(g.Records),2);
verifyEqual(testCase,[g.Records.ObjectID],[12 12]);
verifyEqual(testCase,[g.Records.ComponentID],[1 2]);
verifyEqual(testCase,g.Grid.Size,size(labels));
for i = 1:numel(g.Records)
    verifyTrue(testCase,all(g.Records(i).Indices>=1 & g.Records(i).Indices<=numel(labels)));
end
end
function testInputValidation(testCase)
verifyError(testCase,@() farmPrepareObjects(ones(2,2,2,2)), 'objectgeometry:InvalidDimensions');
verifyError(testCase,@() farmPrepareObjects({[1 2]},struct('ImageSize',[4 4],'ObjectIDs',[1 2])), 'objectgeometry:InvalidObjectIDs');
verifyError(testCase,@() farmPrepareObjects(ones(4),struct('Unexpected',1)), 'objectgeometry:UnknownOption');
end
function testImageMetadataAndTimeSelection(testCase)
data = zeros(8,9,3,1,2,'uint16'); data(2:3,3:4,2,1,2) = 17;
image = struct('Data',data,'Axes','YXZCT','Spacing',[0.2 0.3 0.7],'SpacingUnit','um');
[t,o] = farmMeasureObjects(image,{'Volume'}, ...
    struct('TimeIndex',2,'Frame',9,'DatasetID','movie'));
verifyEqual(testCase,t.ObjectID,17); verifyEqual(testCase,t.Volume,4);
verifyEqual(testCase,o.Grid.Spacing,[0.2 0.3 0.7]); verifyEqual(testCase,t.Frame,9);
end
function t = localKeys(ids,frames,datasets)
t = table(datasets,frames,ids,'VariableNames',{'DatasetID','Frame','ObjectID'});
end

function testGeometryMatrixIdentityAndSelection(t)
labels = zeros(5,6,3); labels(2,3,1) = 7; labels(4,5,3) = 7; labels(3,2,2) = 42;
objects = farmPrepareObjects(labels, ...
    struct('InputType','labels','Spacing',[.2 .3 .7],'SpacingUnit','um'));
[mask,grid] = farmGeometryToMatrix(objects);
verifyEqual(t,mask,labels>0); verifyEqual(t,grid,objects.Grid);
mapped = farmGeometryToMatrix(objects,'OutputType','labels');
verifyEqual(t,mapped,labels);
selected = farmGeometryToMatrix(objects,'ObjectIDs',7);
verifyEqual(t,selected,labels==7);
empty = farmGeometryToMatrix(objects,'ObjectIDs',99);
verifyFalse(t,any(empty(:)));
objects = farmPrepareObjects(false(5,6,3));
empty = farmGeometryToMatrix(objects);
verifySize(t,empty,[5 6 3]); verifyFalse(t,any(empty(:)));
end
function testGeometryMatrixOverlapPolicy(t)
grid = struct('Size',[4 5]);
records = struct('ObjectID',{7,42},'Indices',{[1;2],[2;3]});
geometry = struct('Type','boundary','Grid',grid,'Records',records);
mask = farmGeometryToMatrix(geometry);
verifyEqual(t,find(mask),[1;2;3]);
verifyError(t,@()farmGeometryToMatrix(geometry, ...
    'OutputType','labels'),'objectgeometry:GeometryOverlap');
first = farmGeometryToMatrix(geometry, ...
    'OutputType','labels','OverlapPolicy','first');
last = farmGeometryToMatrix(geometry, ...
    'OutputType','labels','OverlapPolicy','last');
verifyEqual(t,first(1:3),[7 7 42]); verifyEqual(t,last(1:3),[7 42 42]);
end
function testGeometryMatrixFallbackAndMidplane(t)
grid = struct('Size',[4 5 3],'Spacing',[1 2 3],'SpacingUnit','um');
record = struct('ObjectID',8,'Indices',[],'Fallback',struct('Centroid',[3 2 2]));
geometry = struct('Type','skeleton','Method','sheet','Grid',grid,'Records',record);
mask = farmGeometryToMatrix(geometry);
verifyFalse(t,any(mask(:)));
[mask,~,info] = farmGeometryToMatrix(geometry,'IncludeFallback',true);
verifyTrue(t,mask(2,3,2)); verifyEqual(t,nnz(mask),1);
verifyEqual(t,info.IncludedFallbackCount,1);
geometry.Records.Indices = [1;5]; % stored sheet point indices use same converter
mask = farmGeometryToMatrix(geometry);
verifyEqual(t,find(mask),[1;5]);
end
function testPointsCoordinateOrderBoundsAndEmpty(t)
grid = struct('Size',[5 7 3]);
mask = farmPointsToMatrix([4 2 3;4 2 3],grid);
verifyTrue(t,mask(2,4,3)); verifyEqual(t,nnz(mask),1);
yxz = farmPointsToMatrix([2 4 3],grid,'CoordinateOrder','YXZ');
verifyEqual(t,mask,yxz);
rounded = farmPointsToMatrix([3.8 2.2 2.7],grid);
verifyEqual(t,mask,rounded);
verifyError(t,@()farmPointsToMatrix([8 2 1],grid), ...
    'objectgeometry:RepresentationBounds');
[clipped,~,info] = farmPointsToMatrix([8 2 1],grid,'BoundsPolicy','omit');
verifyFalse(t,any(clipped(:))); verifyEqual(t,info.OmittedPointCount,1);
empty = farmPointsToMatrix(zeros(0,3),grid);
verifySize(t,empty,[5 7 3]); verifyFalse(t,any(empty(:)));
end
function testGaussianOccupancyAndThreshold(t)
grid = struct('Size',[15 15]);
[field,~,info] = farmPointsToMatrix([8 8],grid,'Sigma',1);
verifyClass(t,field,'double'); verifyEqual(t,sum(field(:)),1,'AbsTol',1e-12);
verifyGreaterThan(t,field(8,8),field(8,9)); verifyGreaterThan(t,field(8,9),0);
mask = farmPointsToMatrix([8 8],grid,'Sigma',1,'Threshold',.05);
verifyEqual(t,mask,field>.05); verifyClass(t,mask,'logical');
verifyEqual(t,info.Options.Sigma,1);
anisotropic = farmPointsToMatrix([8 8],grid,'Sigma',[1 0]);
verifyEqual(t,nnz(anisotropic(:,[1:7 9:15])),0);
verifyGreaterThan(t,nnz(anisotropic(:,8)),1);
verifyError(t,@()farmPointsToMatrix([8 8],grid,'Sigma',[1 1 1]), ...
    'objectgeometry:SigmaDimensions');
end
function testSingletonAxisGaussian(t)
grid = struct('Size',[9 9 1]);
field = farmPointsToMatrix([5 5 1],grid,'Sigma',[0 0 1]);
verifyGreaterThan(t,field(5,5),0); verifyLessThan(t,field(5,5),1);
verifyEqual(t,nnz(field),1);
end
function testSegmentsEndpointsReversalAndWidth(t)
grid = struct('Size',[9 10]);
mask = farmSegmentsToMatrix([2 4],[7 4],grid);
expected = false(9,10); expected(4,2:7) = true;
verifyEqual(t,mask,expected);
reverse = farmSegmentsToMatrix([7 4],[2 4],grid);
verifyEqual(t,reverse,mask);
point = farmSegmentsToMatrix([2 4],[2 4],grid);
verifyEqual(t,nnz(point),1); verifyTrue(t,point(4,2));
field = farmSegmentsToMatrix([2 4],[7 4],grid,'Sigma',1);
wide = farmSegmentsToMatrix([2 4],[7 4],grid,'Sigma',1,'Threshold',.1);
verifyEqual(t,wide,field>.1); verifyTrue(t,any(wide(3,:)));
empty = farmSegmentsToMatrix(zeros(0,2),zeros(0,2),grid);
verifyEqual(t,empty,false(9,10));
end
function testSegments3DAndClipping(t)
grid = struct('Size',[5 6 4]);
mask = farmSegmentsToMatrix([2 3 1],[2 3 4],grid);
expected = false(5,6,4); expected(3,2,:) = true;
verifyEqual(t,mask,expected);
verifyError(t,@()farmSegmentsToMatrix([0 3 1],[2 3 1],grid), ...
    'objectgeometry:RepresentationBounds');
clipped = farmSegmentsToMatrix([0 3 1],[2 3 1],grid,'BoundsPolicy','omit');
verifyTrue(t,clipped(3,1,1)); verifyTrue(t,clipped(3,2,1));
end

function testPointExtentFallback(testCase)
for dims = [2 3]
    if dims==3, mask = false(7,8,5); mask(3,4,2) = true;
    else, mask = false(7,8); mask(3,4) = true; end
    for spacing = {[.3 .3 .3],[.4 .2 .8]}
        identity = struct('Spacing',spacing{1},'SpacingUnit','um');
        t = farmMeasureFilaments(mask, ...
            {'ExtentInVoxels','Directors','ProjectedExtent','ScaledDirectors'}, ...
            struct('Identity',identity));
        xyz = spacing{1}([2 1 3]); xyz = xyz(1:dims);
        expected = t.ExtentInVoxels*norm(t.Directors.*xyz);
        verifyTrue(testCase,isfinite(t.ProjectedExtent));
        verifyEqual(testCase,t.ProjectedExtent,expected,'AbsTol',1e-12);
        verifyTrue(testCase,all(isnan(t.ScaledDirectors),'all'));
        verifyEqual(testCase,t.Properties.UserData.PointExtentFallbackObjectIDs,t.ObjectID);
        only = farmMeasureFilaments(mask,{'ProjectedExtent'},struct('Identity',identity));
        verifyEqual(testCase,only.ProjectedExtent,expected,'AbsTol',1e-12);
        verifyFalse(testCase,ismember('ExtentInVoxels',only.Properties.VariableNames));
    end
end
end
function testExtendedDegenerateExtentNotPointFallback(testCase)
mask = false(7,8,5); mask(2:4,3:5,2:4) = true;
t = farmMeasureFilaments(mask,{'ProjectedExtent','ScaledDirectors'});
verifyEmpty(testCase,t.Properties.UserData.PointExtentFallbackObjectIDs);
verifyTrue(testCase,all(isnan(t.ScaledDirectors),'all'));
verifyEqual(testCase,t.ProjectedExtent,2,'AbsTol',1e-12);
end
