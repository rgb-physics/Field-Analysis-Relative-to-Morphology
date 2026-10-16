function tests = testFieldSampling

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
function setupOnce(~)
folder = fileparts(mfilename('fullpath')); root = fullfile(folder,'..','..','..');
for api = {'ObjectRelativeProfiles','ObjectGeometry','ImageStackIO','SharedUtilities'}
    addpath(fullfile(root,'APIs',api{1},'src'));
end
end
function testIndicesDeduplicateAndRetainZero(testCase)
field = reshape(0:23,[3 4 2]);
t = farmQueryField(field,[1 1 2 3],{'Mean','Count','Sum'});
verifyEqual(testCase,t.Field_SelectedCount,3); verifyEqual(testCase,t.Field_Count,3);
verifyEqual(testCase,t.Field_Mean,1); verifyEqual(testCase,t.Field_Sum,3);
end
function testMaskEqualsIndices(testCase)
field = reshape(1:24,[3 4 2]); mask = false(size(field)); mask([2 5 8]) = true;
a = farmQueryField(field,mask,{'Mean','Variance'});
b = farmQueryField(field,find(mask),{'Mean','Variance'});
verifyEqual(testCase,a.Field_Mean,b.Field_Mean); verifyEqual(testCase,a.Field_Variance,b.Field_Variance);
end
function testNonfiniteCountsAndFiniteSummaries(testCase)
field = [0 2 NaN Inf -Inf];
t = farmQueryField(field,1:5,{'Mean','Variance','Count'});
verifyEqual(testCase,t.Field_SelectedCount,5); verifyEqual(testCase,t.Field_FiniteCount,2);
verifyEqual(testCase,t.Field_NaNCount,1); verifyEqual(testCase,t.Field_PositiveInfCount,1);
verifyEqual(testCase,t.Field_NegativeInfCount,1); verifyEqual(testCase,t.Field_Mean,1);
verifyEqual(testCase,t.Field_Variance,2);
end
function testEmptyAndAllInvalidDiffer(testCase)
field = [NaN Inf];
a = farmQueryField(field,[],{'Mean','Count','Sum'});
b = farmQueryField(field,[1 2],{'Mean','Count','Sum'});
verifyTrue(testCase,a.Field_SelectionEmpty); verifyFalse(testCase,b.Field_SelectionEmpty);
verifyEqual(testCase,a.Field_Count,0); verifyEqual(testCase,b.Field_Count,0);
verifyTrue(testCase,isnan(a.Field_Mean)); verifyTrue(testCase,isnan(b.Field_Mean));
verifyEqual(testCase,a.Field_Sum,0); verifyEqual(testCase,b.Field_PositiveInfCount,1);
end
function testLabelGroupingAndOverlappingGroups(testCase)
field = reshape(1:12,[3 4]); labels = zeros(size(field)); labels([1 12]) = 7; labels([2 3]) = 99;
t = farmQueryField(field,labels,{'Mean','Count'});
verifyEqual(testCase,t.ObjectID,[7;99]); verifyEqual(testCase,t.Field_Mean,[6.5;2.5]);
t = farmQueryField(field,{[1 2],[2 3]},{'Sum'}, ...
    struct('Support',struct('ObjectIDs',[8 4])));
verifyEqual(testCase,t.ObjectID,[8;4]); verifyEqual(testCase,t.Field_Sum,[3;5]);
end
function testPreparedObjectsAndMetadata(testCase)
labels = zeros(4,5,3); labels([2 5]) = 12;
objects = farmPrepareObjects(labels,struct('Frame',9,'DatasetID','A','Spacing',[1 2 3]));
field = struct('Data',ones(size(labels)),'Grid',struct('Size',size(labels),'Spacing',[4 5 6]));
t = farmQueryField(field,objects,{'Mean'});
verifyEqual(testCase,t.Frame,9); verifyEqual(testCase,t.ObjectID,12);
verifyTrue(testCase,isfield(t.Properties.UserData.MetadataDifferences.value,'Spacing'));
end
function testSkeletonFallbackAndParentGrouping(testCase)
record = struct('ObjectID',12,'ComponentID',1,'Indices',[],'Status','empty', ...
    'Fallback',struct('Centroid',[2 3 2]));
second = record; second.ComponentID = 2; second.Indices = 1; second.Status = 'computed'; second.Fallback = [];
geometry = struct('Type','skeleton','DatasetID',"A",'Frame',3, ...
    'Grid',struct('Size',[4 5 3]),'Records',[record second]);
field = reshape(1:60,[4 5 3]); index = sub2ind([4 5 3],3,2,2);
t = farmQueryField(field,geometry,{'Mean','Count'});
verifyEqual(testCase,height(t),1); verifyEqual(testCase,t.Field_Count,2);
verifyTrue(testCase,t.Field_UsedFallback); verifyFalse(testCase,t.Field_GeometryEmpty);
verifyEqual(testCase,t.Field_EmptyGeometryCount,1); verifyEqual(testCase,t.Field_Mean,(index+1)/2);
t = farmQueryField(field,geometry,{'Count'}, ...
    struct('Support',struct('ComponentResults',true,'CentroidFallback',false)));
verifyEqual(testCase,t.ComponentID,[1;2]); verifyEqual(testCase,t.Field_Count,[0;1]);
verifyEqual(testCase,t.Field_GeometryEmpty,[true;false]);
end
function testHistogramsQuantilesAndCustomOperations(testCase)
field = 0:9;
t = farmQueryField(field,1:10, ...
    {'Histogram','Quantiles','Std'},struct('BinEdges',[0 5 10],'Quantiles',[0 .5 1], ...
    'CustomOperations',struct('AboveFour',@(v) nnz(v>4))));
verifyEqual(testCase,t.Field_Histogram{1}.Counts,[5 5]);
verifyEqual(testCase,t.Field_Quantiles,[0 4.5 9]); verifyEqual(testCase,t.Field_AboveFour{1},5);
verifyEqual(testCase,t.Field_Std,std(field));
end
function testSameFrameSampleCombination(testCase)
fields = struct('A',reshape(1:12,[3 4]),'B',ones(3,4));
t = farmQueryField(fields,[1 3 5],{'Mean'}, ...
    struct('FieldName','Difference','SampleOperation',@(f) f.A-f.B));
verifyEqual(testCase,t.Difference_Mean,2);
verifyError(testCase,@() farmQueryField(fields,[1 3],{'Mean'}, ...
    struct('SampleOperation',@(f) sum(f.A))),'objectrelativeprofiles:SampleShape');
end
function testIdentityAttachmentAfterSorting(testCase)
labels = [1 2;1 2]; field = [10 20;30 40];
t = farmQueryField(field,labels,{'Mean'},struct('FieldName','I'));
extra = farmQueryField(2*field,labels,{'Mean'},struct('FieldName','D'));
joined = farmAttachResults(t([2 1],:),extra);
verifyEqual(testCase,joined.ObjectID,[2;1]); verifyEqual(testCase,joined.D_Mean,[60;40]);
verifyError(testCase,@() farmAttachResults(t,[extra;extra]),'objectrelativeprofiles:DuplicateKeys');
end
function testQueryFrameAndFrameStreaming(testCase)
folder = tempname; mkdir(folder); cleanup = onCleanup(@() rmdir(folder,'s'));
specs(1) = struct('Name','I','Loader',@(frame) frame*ones(3,4,2));
specs(2) = struct('Name','D','Loader',@(frame) (frame+1)*ones(3,4,2));
q(1) = struct('Name','I_Object','Support','objects','Statistics',{{'Mean'}}, ...
    'Field','I','Operation',[],'Mode','','Fields',{{}},'Options',struct());
q(2) = q(1); q(2).Name = 'Product_Object'; q(2).Field = '';
q(2).Operation = @(f) f.I.*f.D; q(2).Mode = 'samples';
loader = @(frame,fields) struct('objects',true(size(fields.I)));
manifest = farmRunFieldBatch([2 7],specs,loader,q, ...
    struct('OutputDirectory',folder,'DatasetID','A','RetainTables',true));
verifyEqual(testCase,manifest.Tables{1}.I_Object_Mean,2);
verifyEqual(testCase,manifest.Tables{2}.Product_Object_Mean,56);
verifyEqual(testCase,manifest.Tables{2}.Frame,7);
verifyTrue(testCase,all(isfile(manifest.Files)));
combined = farmConcatenateResults(manifest.Tables);
verifyEqual(testCase,combined.Frame,[2;7]);
end
function testMismatchesAndStacksOfStacks(testCase)
verifyError(testCase,@() farmQueryField(ones(3,4),true(4,4),{'Mean'}),'objectrelativeprofiles:GridMismatch');
verifyError(testCase,@() farmQueryField(ones(3,4,2,3),1,{'Mean'}),'objectrelativeprofiles:InvalidDimensions');
verifyError(testCase,@() farmQueryField(ones(3,4),13,{'Mean'}),'objectrelativeprofiles:IndexOutOfBounds');
end

function testVerboseBatchPreservesSavedResults(testCase)
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));

specs = struct('Name', 'Intensity', 'Loader', @(frame) frame * ones(3, 4, 2));
loader = @(frame, fields) struct('objects', true(size(fields.Intensity)));
query = farmMakeQuery('Name', 'Intensity', 'Support', 'objects', ...
    'Field', 'Intensity', 'Statistics', {'Mean', 'Sum'});
options = struct('OutputDirectory', folder, 'DatasetID', 'example', ...
    'Verbose', true);

text = evalc('manifest = farmRunFieldBatch([7 2], specs, loader, query, options);');
verifyTrue(testCase, contains(text, 'Processing frame 7 (1 of 2)'));
verifyTrue(testCase, contains(text, 'Completed frame 2 (2 of 2)'));
verifyEmpty(testCase, manifest.Tables);
verifyEqual(testCase, manifest.Frames, [7; 2]);

saved = load(manifest.Files(1));
verifyEqual(testCase, saved.results.Intensity_Mean, 7);
verifyEqual(testCase, saved.results.Intensity_Sum, 168);
verifyEqual(testCase, saved.results.Frame, 7);
verifyEqual(testCase, saved.results.DatasetID, "example");

verifyError(testCase, ...
    @() farmRunFieldBatch([7 2], specs, loader, query, options), ...
    'objectrelativeprofiles:ExistingOutput');
savedAgain = load(manifest.Files(1));
verifyEqual(testCase, savedAgain.results, saved.results);
end
