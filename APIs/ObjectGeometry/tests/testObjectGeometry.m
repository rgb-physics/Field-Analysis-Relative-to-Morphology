function tests=testObjectGeometry
tests=functiontests(localfunctions);
end
function setupOnce(testCase)
folder=fileparts(mfilename('fullpath')); root=fullfile(folder,'..','..','..');
addpath(fullfile(root,'APIs','ObjectGeometry','src'));
addpath(fullfile(root,'APIs','SharedUtilities','src'));
addpath(fullfile(root,'APIs','ImageStackIO','src'));
testCase.TestData.Root=root;
end
function testMaskIdentity(testCase)
mask=false(12); mask(2:4,3:6)=true; mask(9:10,9:10)=true;
[t,o]=objectgeometry.objects.measureObjects(mask,{'Area','Centroid'}, ...
    struct('DatasetID','A','Frame',7));
verifyEqual(testCase,t.Area,[12;4]);
verifyEqual(testCase,t.Centroid,[4.5 3;9.5 9.5]);
verifyEqual(testCase,t.ObjectID,[1;2]); verifyEqual(testCase,t.Frame,[7;7]);
verifyEqual(testCase,o.Grid.Spacing,[1 1 1]);
end
function testDisconnectedLabelsRemainOneIdentity(testCase)
labels=zeros(10,'uint16'); labels(2,2)=12; labels(8,8)=12; labels(2,3)=99;
t=objectgeometry.objects.measureObjects(labels,{'Area','Centroid'});
verifyEqual(testCase,t.ObjectID,[12;99]); verifyEqual(testCase,t.Area,[2;1]);
verifyEqual(testCase,t.Centroid(1,:),[5 5]);
end
function testSuppliedComponentsOrder(testCase)
mask=false(8); mask(2,2)=true; mask(6:7,6:7)=true;
cc=bwconncomp(mask); cc.PixelIdxList=cc.PixelIdxList([2 1]);
t=objectgeometry.objects.measureObjects(cc,{'Area'},struct('ObjectIDs',[90 7]));
verifyEqual(testCase,t.ObjectID,[90;7]); verifyEqual(testCase,t.Area,[4;1]);
end
function testIndexGroups(testCase)
groups={sub2ind([8 9],[2 2],[3 4]),sub2ind([8 9],7,8)};
t=objectgeometry.objects.measureObjects(groups,{'Area','Centroid'}, ...
    struct('ImageSize',[8 9],'ObjectIDs',[50 4]));
verifyEqual(testCase,t.ObjectID,[50;4]); verifyEqual(testCase,t.Area,[2;1]);
verifyEqual(testCase,t.Centroid,[3.5 2;8 7]);
end
function testEmptyForeground(testCase)
t=objectgeometry.objects.measureObjects(false(8,9,4),{'Volume','Centroid'});
verifyEqual(testCase,height(t),0); verifySize(testCase,t.Centroid,[0 3]);
[p,s]=objectgeometry.centerlines.storeFilCCs(false(8,9,4));
verifyEqual(testCase,height(p),0); verifyEmpty(testCase,s);
end
function testNativeAll(testCase)
mask=false(8); mask(3:5,3:6)=true;
t=objectgeometry.objects.measureObjects(mask,'all');
verifyTrue(testCase,all(ismember({'Area','Centroid','PixelIdxList','Orientation'},t.Properties.VariableNames)));
end
function testIntensityAndMismatch(testCase)
mask=false(6); mask(2:3,2:3)=true; field=reshape(1:36,6,6);
t=objectgeometry.objects.measureObjects(mask,{'MeanIntensity'},struct('Intensity',field));
verifyEqual(testCase,t.MeanIntensity,mean(field(mask)));
verifyError(testCase,@() objectgeometry.objects.measureObjects(mask,{'MeanIntensity'}, ...
    struct('Intensity',ones(7))),'objectgeometry:GridMismatch');
end
function testLegacyTwoDimensionalMultipleObjects(testCase)
mask=false(10); mask(2:3,2:4)=true; mask(8,8)=true;
[cc,s]=objectgeometry.objects.blobMat2CCProps(mask,{'Area','Centroid'});
verifyEqual(testCase,cc.NumObjects,2); verifyEqual(testCase,s.Area,[6;1]);
[~,s]=objectgeometry.objects.blobMat2CCProps(mask,{'Area','Centroid'},s);
verifyEqual(testCase,numel(s),2); verifyEqual(testCase,s(2).Centroid,s(1).Centroid);
end
function testThreeDimensionalProperties(testCase)
mask=false(13,17,9); mask(4:6,3:12,3:7)=true;
t=objectgeometry.objects.measureObjects(mask,{'Volume','Centroid','BoundingBox'});
verifyEqual(testCase,t.Volume,150); verifyEqual(testCase,t.Centroid,[7.5 5 5]);
verifyEqual(testCase,t.BoundingBox,[2.5 3.5 2.5 10 3 5]);
end
function testFilamentAxisConvention(testCase)
mask=false(15,25,11); mask(6:8,4:22,5:7)=true;
t=objectgeometry.centerlines.measureFilaments(mask,{'Directors','Lengths','AspectRatios'});
verifyEqual(testCase,abs(t.Directors),[1 0 0],'AbsTol',1e-10);
verifyGreaterThan(testCase,t.AspectRatios,1);
verifyFalse(testCase,ismember('EigenVectors',t.Properties.VariableNames));
end
function testTwoDimensionalFilamentConvention(testCase)
mask=false(21); mask(sub2ind(size(mask),5:17,5:17))=true;
t=objectgeometry.centerlines.measureFilaments(mask,{'Directors'});
verifyEqual(testCase,abs(t.Directors),[1 1]/sqrt(2),'AbsTol',1e-10);
verifyGreaterThan(testCase,prod(t.Directors),0);
end
function testCoordinateScaledPCA(testCase)
mask=false(15,25,11); mask(6:8,4:22,5:7)=true;
t=objectgeometry.centerlines.measureFilaments(mask, ...
    {'ScaledDirectors','ProjectedExtent','ScaledAspectRatios'}, ...
    struct('Identity',struct('Spacing',[0.4 0.2 0.8],'SpacingUnit','um')));
verifyEqual(testCase,abs(t.ScaledDirectors),[1 0 0],'AbsTol',1e-10);
verifyEqual(testCase,t.ProjectedExtent,18*0.2,'AbsTol',1e-10);
verifyEqual(testCase,t.ScaledAspectRatios,3.6/1.6,'AbsTol',1e-10);
verifyEqual(testCase,t.Properties.UserData.ProjectedExtentUnit,"um");
end
function testGradientLinearFieldAndSpacing(testCase)
[y,x,z]=ndgrid(1:9,1:11,1:7); field=2*x+3*y+4*z;
[g,meta,valid]=objectgeometry.objects.distanceGradients(field);
verifyEqual(testCase,g(:,:,:,1),2*ones(size(field)));
verifyEqual(testCase,g(:,:,:,2),3*ones(size(field)));
verifyEqual(testCase,g(:,:,:,3),4*ones(size(field))); verifyTrue(testCase,all(valid,'all'));
verifyEqual(testCase,meta.ComponentAxes,'XYZ');
g=objectgeometry.objects.distanceGradients(field, ...
    struct('Spacing',[3 2 4],'DerivativeUnits','physical','FlipY',true));
verifyEqual(testCase,g(:,:,:,1),ones(size(field)));
verifyEqual(testCase,g(:,:,:,2),-ones(size(field)));
verifyEqual(testCase,g(:,:,:,3),ones(size(field)));
end
function testGradientSmoothingAndZeroVectors(testCase)
[y,x]=ndgrid(1:15,1:17); field=x.^2+y.^2;
g=objectgeometry.objects.distanceGradients(field,struct('Sigma',1));
[gx,gy]=gradient(field);
verifyEqual(testCase,g(:,:,1,1),imgaussfilt(gx,1),'AbsTol',1e-10);
verifyEqual(testCase,g(:,:,1,2),imgaussfilt(gy,1),'AbsTol',1e-10);
g=objectgeometry.objects.distanceGradients(field,struct('Sigma',1,'SmoothingOrder','distance-first'));
[gx,gy]=gradient(imgaussfilt(field,1));
verifyEqual(testCase,g(:,:,1,1),gx,'AbsTol',1e-10);
verifyEqual(testCase,g(:,:,1,2),gy,'AbsTol',1e-10);
[g,~,valid]=objectgeometry.objects.distanceGradients(ones(6),struct('Normalize',true));
verifyFalse(testCase,any(valid,'all')); verifyEqual(testCase,nnz(g),0);
end
function testObjectDistanceDefinitions(testCase)
mask=false(9); mask(3:7,3:7)=true;
[~,signed]=objectgeometry.objects.objectDistanceGradients(mask);
verifyEqual(testCase,signed,sharedutilities.numerics.signedBWDist(mask));
[~,interior]=objectgeometry.objects.objectDistanceGradients(mask,struct('DistanceType','interior'));
verifyEqual(testCase,interior,bwdist(~mask));
[g,~,meta,valid]=objectgeometry.objects.objectDistanceGradients(false(8));
verifyTrue(testCase,all(isnan(g),'all')); verifyFalse(testCase,any(valid,'all'));
verifyFalse(testCase,meta.FiniteDistanceField);
end
function testNematicKnownAnglesAndReversal(testCase)
a=[0;pi/6;pi/4;pi/2]; u=[cos(a) sin(a)];
r=objectgeometry.orientation.nematicAlignment(u,[1 0]);
verifyEqual(testCase,r.Order,[1;0.5;0;-1],'AbsTol',1e-10);
flipped=objectgeometry.orientation.nematicAlignment(-u,[-1 0]);
verifyEqual(testCase,flipped.Order,r.Order,'AbsTol',1e-10);
verifyEqual(testCase,flipped.SignedAngle,r.SignedAngle,'AbsTol',1e-10);
u=[cos(a) sin(a) zeros(4,1)]; r=objectgeometry.orientation.nematicAlignment(u,[1 0 0]);
verifyEqual(testCase,r.Order,[1;0.625;0.25;-0.5],'AbsTol',1e-10);
verifyEqual(testCase,r.UnsignedAngle,a,'AbsTol',1e-10);
verifyTrue(testCase,all(isnan(r.SignedAngle)));
end
function testSignedAngleAndProjectionSelection(testCase)
u=[cosd(80) sind(80);cosd(-80) sind(-80)]; v=[cosd(70) sind(70);cosd(70) sind(70)];
r=objectgeometry.orientation.nematicAlignment(u,v);
verifyEqual(testCase,r.SignedAngle,deg2rad([10;30]),'AbsTol',1e-10);
u=[1 0 0;1 0 10;1 0 -10;0 0 1];
r=objectgeometry.orientation.nematicAlignment(u,[1 0 0],struct('Plane',[1 2],'MaxNormalComponent',0.5));
verifyEqual(testCase,r.Valid,[true;false;false;false]);
verifyTrue(testCase,all(isnan(r.Order(2:4))));
end
function testConcatenationAndShuffledAttachment(testCase)
base=localKeys([10;20;10],[1;1;2],["A";"A";"A"]);
base.Volume=[100;200;300];
combined=objectgeometry.objects.concatenateMeasurements({base(1:2,:),base(3,:)});
extra=base([3 1 2],{'DatasetID','Frame','ObjectID'}); extra.Intensity=[33;11;22];
attached=objectgeometry.objects.attachMeasurements(combined,extra);
verifyEqual(testCase,attached.Intensity,[11;22;33]);
verifyEqual(testCase,attached.ObjectID,base.ObjectID);
filtered=objectgeometry.objects.attachMeasurements(combined([3 1],:),extra);
verifyEqual(testCase,filtered.Intensity,[33;11]);
end
function testAttachmentMissingDuplicateAndOverwrite(testCase)
base=localKeys([1;2],[1;1],["A";"A"]);
extra=base(1,:); extra.Value=uint16(7);
verifyError(testCase,@() objectgeometry.objects.attachMeasurements(base,extra),'objectgeometry:MissingMeasurements');
r=objectgeometry.objects.attachMeasurements(base,extra,struct('MissingPolicy','missing'));
verifyEqual(testCase,r.Value(1),7); verifyTrue(testCase,isnan(r.Value(2)));
verifyError(testCase,@() objectgeometry.objects.attachMeasurements(base,[extra;extra]),'objectgeometry:DuplicateKeys');
verifyError(testCase,@() objectgeometry.objects.attachMeasurements(r,extra,struct('MissingPolicy','missing')),'objectgeometry:ExistingProperty');
end
function testDatasetIsolation(testCase)
base=localKeys([1;1],[1;1],["A";"B"]); extra=base([2 1],:); extra.Signal=[20;10];
r=objectgeometry.objects.attachMeasurements(base,extra);
verifyEqual(testCase,r.Signal,[10;20]);
verifyError(testCase,@() objectgeometry.objects.concatenateMeasurements({base;base}),'objectgeometry:DuplicateKeys');
end
function testShellUsesThreeDimensionalSmoothing(testCase)
mask=false(15,15,11); mask(4:12,4:12,3:9)=true;
d=sharedutilities.numerics.signedBWDist(mask); smooth=imgaussfilt3(d,1);
shell=objectgeometry.objects.returnSmoothBoundsBW(mask,0,1,1);
verifyEqual(testCase,shell,smooth>-1 & smooth<1);
shell2=objectgeometry.objects.returnSmoothBoundsBW(mask(:,:,6),0,1,0);
d2=sharedutilities.numerics.signedBWDist(mask(:,:,6));
verifyEqual(testCase,shell2,d2>-1 & d2<1);
end
function testGeometryDisconnectedComponentsAndIndices(testCase)
labels=zeros(18,18,9,'uint16'); labels(3:7,3:7,3:6)=12; labels(11:15,11:15,3:6)=12;
g=objectgeometry.objects.generateGeometry(labels,'boundary',struct('Sigma',0));
verifyEqual(testCase,numel(g.Records),2);
verifyEqual(testCase,[g.Records.ObjectID],[12 12]);
verifyEqual(testCase,[g.Records.ComponentID],[1 2]);
verifyEqual(testCase,g.Grid.Size,size(labels));
for i=1:numel(g.Records)
    verifyTrue(testCase,all(g.Records(i).Indices>=1 & g.Records(i).Indices<=numel(labels)));
end
end
function testInputValidation(testCase)
verifyError(testCase,@() objectgeometry.objects.prepareObjects(ones(2,2,2,2)), 'objectgeometry:InvalidDimensions');
verifyError(testCase,@() objectgeometry.objects.prepareObjects({[1 2]},struct('ImageSize',[4 4],'ObjectIDs',[1 2])), 'objectgeometry:InvalidObjectIDs');
verifyError(testCase,@() objectgeometry.objects.prepareObjects(ones(4),struct('Unexpected',1)), 'objectgeometry:UnknownOption');
end
function testImageMetadataAndTimeSelection(testCase)
data=zeros(8,9,3,1,2,'uint16'); data(2:3,3:4,2,1,2)=17;
image=struct('Data',data,'Axes','YXZCT','Spacing',[0.2 0.3 0.7],'SpacingUnit','um');
[t,o]=objectgeometry.objects.measureObjects(image,{'Volume'}, ...
    struct('TimeIndex',2,'Frame',9,'DatasetID','movie'));
verifyEqual(testCase,t.ObjectID,17); verifyEqual(testCase,t.Volume,4);
verifyEqual(testCase,o.Grid.Spacing,[0.2 0.3 0.7]); verifyEqual(testCase,t.Frame,9);
end
function t=localKeys(ids,frames,datasets)
t=table(datasets,frames,ids,'VariableNames',{'DatasetID','Frame','ObjectID'});
end
