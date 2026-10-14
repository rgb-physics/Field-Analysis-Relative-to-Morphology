function tests=testSharedUtilities
tests=functiontests(localfunctions);
end
function testKeyedPermutationAndDatasetIsolation(t)
base=localTable(["A";"B";"A"],[2;2;3],[7;7;7]);
extra=base([3 1 2],:); extra.Signal=[30;10;20];
out=sharedutilities.structsAndTables.attachByKeys(base,extra,localKeys);
verifyEqual(t,out.Signal,[10;20;30]);
for name=localKeys
    verifyEqual(t,out.(name{1}),base.(name{1}));
end
verifyEqual(t,out.Properties.UserData.Base,base.Properties.UserData);
verifyEqual(t,out.Properties.UserData.Added,extra.Properties.UserData);
end
function testMissingZeroAndTypedValues(t)
base=localTable(["A";"A"],[1;1],[7;42]);
extra=base(1,:); extra.Count=uint16(0); extra.Text="present";
extra.Time=datetime(2026,10,13); extra.Class=categorical("sample");
extra.Cells={17};
out=sharedutilities.structsAndTables.attachByKeys(base,extra,localKeys,struct('MissingPolicy','missing'));
verifyEqual(t,out.Count(1),0); verifyTrue(t,isnan(out.Count(2)));
verifyTrue(t,ismissing(out.Text(2))); verifyTrue(t,isnat(out.Time(2)));
verifyTrue(t,isundefined(out.Class(2))); verifyEmpty(t,out.Cells{2});
verifyError(t,@()sharedutilities.structsAndTables.attachByKeys(base,extra,localKeys),'sharedutilities:MissingMatches');
end
function testDuplicateOverwriteAndExplicitColumns(t)
a=localTable("A",1,7); a.Value=10;
b=a; b.Value=20; b.Other=30;
verifyError(t,@()sharedutilities.structsAndTables.attachByKeys(a,[b;b],localKeys),'sharedutilities:DuplicateKeys');
verifyError(t,@()sharedutilities.structsAndTables.attachByKeys(a,b,localKeys),'sharedutilities:ExistingColumn');
out=sharedutilities.structsAndTables.attachByKeys(a,b,localKeys,struct('Overwrite',true,'Columns',{{'Value'}}));
verifyEqual(t,out.Value,20); verifyFalse(t,ismember('Other',out.Properties.VariableNames));
end
function testConcatenationAndMetadata(t)
a=localTable("A",1,7); a.Properties.UserData=struct('Spacing',[1 2 3]);
b=localTable("A",2,7); b.Properties.UserData=struct('Spacing',[2 2 3]);
r=sharedutilities.structsAndTables.concatenateByKeys({a,b},localKeys);
verifyEqual(t,r.Frame,[1;2]);
verifyEqual(t,r.Properties.UserData.FrameMetadata{2}.Spacing,[2 2 3]);
verifyError(t,@()sharedutilities.structsAndTables.concatenateByKeys({a,a},localKeys),'sharedutilities:DuplicateKeys');
end
function testInvalidKeysAndEmptyTables(t)
a=localTable("A",1,7); a.Frame=[1 2];
verifyError(t,@()sharedutilities.structsAndTables.validateTableKeys(a,localKeys),'sharedutilities:InvalidKeys');
a=localTable("A",1,7); a.DatasetID=missing;
verifyError(t,@()sharedutilities.structsAndTables.validateTableKeys(a,localKeys),'sharedutilities:InvalidKeys');
a=localTable("A",1,7); empty=a([],:); empty.Value=zeros(0,1);
r=sharedutilities.structsAndTables.attachByKeys(a([],:),empty,localKeys);
verifySize(t,r.Value,[0 1]);
end
function testComponentKeysAndTrackingReplication(t)
base=localTable(["A";"A"],[1;1],[7;7]); base.ComponentID=[2;1];
extra=base([2 1],:); extra.Value=[10;20];
r=objectrelativeprofiles.fieldSampling.attachResults(base,extra);
verifyEqual(t,r.Value,[20;10]);
membership=localTable("A",1,7); membership.DetectionID=9; membership.TrajectoryID=42;
r=objecttracking.attachMembership(base,membership);
verifyEqual(t,r.TrajectoryID,[42;42]); verifyEqual(t,r.ComponentID,[2;1]);
end
function testDomainWrapperErrorCompatibility(t)
base=localTable(["A";"A"],[1;2],[7;7]); extra=base(1,:); extra.Value=10;
verifyError(t,@()objectgeometry.objects.attachMeasurements(base,extra),'objectgeometry:MissingMeasurements');
verifyError(t,@()objectrelativeprofiles.fieldSampling.attachResults(base,[extra;extra]),'objectrelativeprofiles:DuplicateKeys');
r=objectgeometry.objects.attachMeasurements(base,extra,struct('MissingPolicy','missing'));
verifyEqual(t,r.Value(1),10); verifyTrue(t,isnan(r.Value(2)));
end
function testTrajectoriesAreAttachedNotKeyed(t)
base=localTable("A",1,7); base.TrajectoryID=3;
extra=localTable("A",1,7); extra.TrajectoryID=99;
r=sharedutilities.structsAndTables.attachByKeys(base,extra,localKeys,struct('Overwrite',true));
verifyEqual(t,r.TrajectoryID,99);
end
function testSelectedStructIndicesNumericAndCell(t)
s=repmat(struct('A',0,'B',""),1,3);
r=sharedutilities.structsAndTables.addFieldsStruct(s,{'A','B'},{[10 20 30],{"x","y","z"}},[3 1]);
verifyEqual(t,[r.A],[10 0 30]); verifyEqual(t,[r.B],["x" "" "z"]);
r=sharedutilities.structsAndTables.addFieldsStruct(s,{'A'},{[1 2 3]});
verifyEqual(t,[r.A],[1 2 3]);
end
function testPixelCenterMappingAndIndexShape(t)
r=sharedutilities.arrays.rescaleCoords([1 1;10 8],[8 10],[2 3]);
verifyEqual(t,r,[1 1;3 2]);
indices=[1 80];
row=sharedutilities.coordinates.rescaleCoords_Inds(indices,[8 10],[2 3]);
column=sharedutilities.coordinates.rescaleCoords_Inds(indices',[8 10],[2 3]);
verifyEqual(t,row,[1 6]); verifyEqual(t,column,[1;6]);
verifyEmpty(t,sharedutilities.coordinates.rescaleCoords_Inds([],[8 10],[2 3]));
verifyError(t,@()sharedutilities.arrays.rescaleCoords([0 1],[8 10],[2 3]),'sharedutilities:Coordinates');
end
function testInterpolationRampAndConstant(t)
a=single([1 2;3 4]);
r=sharedutilities.numerics.fastLinIntNDScale2(a);
verifyEqual(t,r,single([1 1.5 2 2;2 2.5 3 3;3 3.5 4 4;3 3.5 4 4]));
a=ones(2,3,4);
r=sharedutilities.numerics.fastLinIntNDScale2(a);
verifySize(t,r,[4 6 8]); verifyEqual(t,r,ones(4,6,8,'single'));
end
function testUnitVectorsAndNaNRepair(t)
r=sharedutilities.coordinates.getUnitVecs([3 4;0 0;Inf 1]);
verifyEqual(t,r(1,:),[.6 .8],'AbsTol',1e-12);
verifyTrue(t,all(isnan(r(2:3,:)),'all'));
r=sharedutilities.numerics.noNan(single([NaN Inf 0]),5);
verifyClass(t,r,'single'); verifyEqual(t,r,single([5 Inf 0]));
end
function testLogBaseAndPairedBins(t)
verifyEqual(t,sharedutilities.plotting.logAB(2,8),3,'AbsTol',1e-12);
[x,y]=sharedutilities.plotting.loglogBin([1 2 4 8],[1 4 16 64],20);
verifyEqual(t,y,2*x,'AbsTol',1e-12);
end
function testQualifiedHelperCalls(t)
cc=struct('PixelIdxList',{{[1 2],[7 8 9]}});
[n,v,id]=sharedutilities.coordinates.getCCVectors(cc);
verifyEqual(t,n,[2 3]); verifyEqual(t,v,[1;2;7;8;9]); verifyEqual(t,id,[1;1;2;2;2]);
verifyEqual(t,sharedutilities.miscellaneous.genericLenVec([2 1]),[2;2;1]);
s=struct('Data',{[1 2],3});
verifyEqual(t,sharedutilities.structsAndTables.structLenVec(s,'Data'),[1;1;2]);
end
function testMaskedArrayPreservesClassAndZeros(t)
a=uint16([0 7;8 9]);
r=sharedutilities.arrays.consMatLnB(a,[1 4]);
verifyClass(t,r,'uint16'); verifyEqual(t,r,uint16([0 0;0 9]));
r=sharedutilities.arrays.consMatLnB(single(a),logical([1 0;0 1]));
verifyClass(t,r,'single'); verifyEqual(t,r,single([0 0;0 9]));
end
function testCellMetadataStaysScalar(t)
a=localTable("A",1,7); a.Properties.UserData={1,2};
b=a; b.Value=3; b.Properties.UserData={"field","units"};
r=sharedutilities.structsAndTables.attachByKeys(a,b,localKeys);
verifyTrue(t,isscalar(r.Properties.UserData));
verifyEqual(t,r.Properties.UserData.Base,{1,2});
end
function keys=localKeys
keys={'DatasetID','Frame','ObjectID'};
end
function t=localTable(DatasetID,Frame,ObjectID)
t=table(DatasetID,Frame,ObjectID);
end
