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

function testGlossaryCoversWrittenEntries(t)
folder = fileparts(mfilename('fullpath'));
root = fullfile(folder, '..', '..', '..');
document = fileread(fullfile(root, 'GLOSSARY-CAPABILITIES-MOCKUP.md'));
headings = regexp(document, '(?m)^\*\*(.+?)\*\*\s+\[(.*)\][^\S\r\n]*\r?$', 'tokens');
expected = strings(numel(headings), 1);
types = expected;
for k = 1:numel(headings)
    expected(k) = string(headings{k}{1});
    types(k) = string(headings{k}{2});
end
entries = sharedutilities.documentation.glossaryEntries();
verifyGreaterThan(t, height(entries), 90);
verifyEqual(t, entries.Term, expected);
verifyEqual(t, entries.DataType, types);
verifyTrue(t, all(strlength(entries.Definition) > 0));
verifyTrue(t, all(strlength(entries.Section) > 0));
% Every documented layout must parse, including placeholder field names.
for k = 1:height(entries)
    fields = sharedutilities.documentation.getGlossaryInputOptions(entries.Term(k));
    if entries.Inputs(k) == "Inputs: {''}"
        verifyEqual(t, height(fields), 0);
    else
        verifyEqual(t, height(fields), count(entries.Inputs(k), '='));
    end
end
end

function testGlossaryTypesInputsAndRequiredFields(t)
verifyEqual(t, sharedutilities.documentation.getGlossaryDataType("Experiment"), "scalar struct");
verifyEqual(t, sharedutilities.documentation.getGlossaryDataType('GRID'), ...
    "scalar struct with Size, Axes, Spacing and SpacingUnit");
inputs = sharedutilities.documentation.getGlossaryInputs("Experiment");
verifyTrue(t, contains(inputs, 'DatasetID* = text'));
verifyFalse(t, contains(inputs, '`'));
fields = sharedutilities.documentation.getGlossaryInputOptions("Experiment");
verifyEqual(t, fields.Name, ["DatasetID"; "Frames"; "Sources"; "TimeStep"; "TimeUnit"]);
verifyEqual(t, fields.Required, [true; true; true; false; false]);
verifyTrue(t, contains(fields.Type(4), 'default 1'));
verifyTrue(t, contains(fields.Type(5), "default 'frame'"));
source = sharedutilities.documentation.getGlossaryInputOptions("Data source");
verifyEqual(t, source.Type(source.Name == "Folder"), "text (file source)");
entry = sharedutilities.documentation.getGlossaryEntry("Data source");
verifyTrue(t, contains(entry.Notes, 'depend on Format'));
end

function testGlossaryAbsentInputsAndScopedNames(t)
verifyEqual(t, sharedutilities.documentation.getGlossaryInputs("Matrix"), "Inputs: {''}");
fields = sharedutilities.documentation.getGlossaryInputOptions("Matrix");
verifySize(t, fields, [0 3]);
verifyClass(t, fields.Name, 'string');
verifyClass(t, fields.Required, 'logical');
feature = sharedutilities.documentation.getGlossaryEntry("Geometry");
variable = sharedutilities.documentation.getGlossaryEntry("geometry");
verifyNotEqual(t, feature.Definition, variable.Definition);
verifyNotEqual(t, feature.Group, variable.Group);
verifyError(t, @() sharedutilities.documentation.getGlossaryEntry("GEOMETRY"), ...
    'sharedutilities:AmbiguousGlossaryTerm');
verifyError(t, @() sharedutilities.documentation.getGlossaryInputs("Not a glossary term"), ...
    'sharedutilities:UnknownGlossaryTerm');
verifyError(t, @() sharedutilities.documentation.getGlossaryEntry(["Grid", "Matrix"]), ...
    'sharedutilities:GlossaryTerm');
end

function testGlossarySearchAndGeneratedLayoutNotes(t)
matches = sharedutilities.documentation.searchGlossary("DISTANCE");
verifyTrue(t, ismember("Distance-defined neighborhood", matches.Term));
fieldMatches = sharedutilities.documentation.searchGlossary("ExcludedCounts");
verifyTrue(t, ismember("Conditional profile", fieldMatches.Term));
verifyEqual(t, height(sharedutilities.documentation.searchGlossary("zzzz_no_matching_entry_zzzz")), 0);
entry = sharedutilities.documentation.getGlossaryEntry("Axial alignment");
verifyTrue(t, contains(entry.Notes, 'not options supplied'));
verifyFalse(t, contains(entry.Notes, 'Tracking and field analysis'));
verifyError(t, @() sharedutilities.documentation.searchGlossary(""), ...
    'sharedutilities:GlossarySearch');
end

function testGlossaryRootEntryPoint(t)
folder = fileparts(mfilename('fullpath'));
root = fullfile(folder, '..', '..', '..');
previous = path;
cleanup = onCleanup(@() path(previous)); %#ok<NASGU>
addpath(root);
entries = glossary();
verifyEqual(t, glossary("list"), entries.Term);
verifyEqual(t, glossary("Experiment", "DataType"), "scalar struct");
verifyEqual(t, glossary("Matrix", "Inputs"), "Inputs: {''}");
verifyEqual(t, glossary("Grid", "InputOptions"), ...
    sharedutilities.documentation.getGlossaryInputOptions("Grid"));
verifyEqual(t, glossary("search", "distance"), sharedutilities.documentation.searchGlossary("distance"));
entry = glossary("Experiment");
verifyEqual(t, entry.Term, "Experiment");
output = evalc('glossary("Matrix");');
verifyTrue(t, contains(output, "Inputs: {''}"));
verifyError(t, @() glossary("Experiment", "NoSuchProperty"), 'sharedutilities:GlossaryProperty');
end

function testGlossaryOptionalSectionAndMultiFieldSearch(t)
allEntries = sharedutilities.documentation.glossaryEntries();
dictionary = sharedutilities.documentation.glossaryEntries('Section', "DataDictionary");
concepts = sharedutilities.documentation.glossaryEntries('Section', "Glossary");
verifyEqual(t, height(dictionary), 10);
verifyEqual(t, height(allEntries), height(dictionary) + height(concepts));
verifyEqual(t, sharedutilities.documentation.glossaryEntries( ...
    'Section', ["Glossary", "DataDictionary"]), allEntries);
verifyEqual(t, sharedutilities.documentation.glossaryEntries('Section', "Data Dictionary"), dictionary);
verifyTrue(t, all(dictionary.Group == "Sampling diagnostics"));
matches = sharedutilities.documentation.searchGlossary("geometry", ...
    'SearchIn', ["Term", "Definition"]);
expected = contains(allEntries.Term, "geometry", 'IgnoreCase', true) | ...
    contains(allEntries.Definition, "geometry", 'IgnoreCase', true);
verifyEqual(t, matches, allEntries(expected, :));
verifyEqual(t, matches, sharedutilities.documentation.searchGlossary("Geometry", ...
    'SearchIn', ["Term", "Definition"]));
matches = sharedutilities.documentation.searchGlossary("dictionary", 'SearchIn', "Section");
verifyEqual(t, matches, dictionary);
verifyEqual(t, height(sharedutilities.documentation.searchGlossary("Geometry", ...
    'SearchIn', "Section")), 0);
matches = sharedutilities.documentation.searchGlossary("sampling", ...
    'SearchIn', "Group", 'Section', "DataDictionary");
verifyEqual(t, matches, dictionary);
entry = sharedutilities.documentation.getGlossaryEntry("SelectionEmpty", 'Section', "DataDictionary");
verifyEqual(t, entry.DataType, "logical scalar per row; table column across rows");
verifyEqual(t, sharedutilities.documentation.getGlossaryInputs("SelectedCount", ...
    'Section', "DataDictionary"), "Inputs: {''}");
verifyError(t, @() sharedutilities.documentation.getGlossaryEntry("SelectedCount", 'Section', "Glossary"), ...
    'sharedutilities:UnknownGlossaryTerm');
verifyError(t, @() sharedutilities.documentation.searchGlossary("geometry", 'SearchIn', "NotAColumn"), ...
    'sharedutilities:GlossarySearchIn');
verifyError(t, @() sharedutilities.documentation.searchGlossary("geometry", 'Section', "NotASection"), ...
    'sharedutilities:GlossarySection');
end

function testGlossaryDictionaryFormattingAndRootFilters(t)
folder = fileparts(mfilename('fullpath'));
previous = path;
cleanup = onCleanup(@() path(previous)); %#ok<NASGU>
addpath(fullfile(folder, '..', '..', '..'));
entry = glossary("diagnostics");
verifyTrue(t, contains(entry.Definition, "flags:" + string(newline) + "[SelectedCount,FiniteCount,"));
selected = glossary("SelectedCount", "Section", "DataDictionary");
verifyEqual(t, selected.Section, "DataDictionary");
verifyEqual(t, glossary("SelectedCount", "Section"), "DataDictionary");
verifyEqual(t, glossary("SelectedCount", "Section", "Section", "DataDictionary"), "DataDictionary");
catalog = glossary("catalog", "Section", "DataDictionary");
verifyEqual(t, glossary("list", "Section", "DataDictionary"), catalog.Term);
verifyEqual(t, glossary("SelectedCount", "DataType", "Section", "DataDictionary"), ...
    sharedutilities.documentation.getGlossaryDataType("SelectedCount", 'Section', "DataDictionary"));
verifyEqual(t, glossary("search", "count", "SearchIn", ["Term", "Definition"], ...
    "Section", ["Glossary", "DataDictionary"]), ...
    sharedutilities.documentation.searchGlossary("count", 'SearchIn', ["Term", "Definition"]));
end
function t=localTable(DatasetID,Frame,ObjectID)
t=table(DatasetID,Frame,ObjectID);
end
