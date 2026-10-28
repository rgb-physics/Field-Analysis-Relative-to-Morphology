function tests = testObjectTracking

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
for api = {'ObjectTracking','ObjectGeometry','ImageStackIO','SharedUtilities'}
    addpath(fullfile(root,'APIs',api{1},'src'));
end
end
function testSplitAndAncestorsExcludeSiblings(testCase)
frames = localBranches(); r = farmTrackOverlaps(1:3,@(t) frames{t});
verifyEqual(testCase,height(r.Detections),7);
seed = struct('ObjectIDs',61,'Frame',3);
s = farmSelectLineage(r,seed);
verifyEqual(testCase,s.Detections.DetectionID,[1;3;7]);
verifyEqual(testCase,s.Detections.ObjectID,[10;22;61]);
verifyEqual(testCase,r.Detections.TrajectoryID(1:3),[1;1;2]);
verifyEqual(testCase,nnz(r.Links.InheritanceChosen),3);
end
function testMergePreservesAllParents(testCase)
frames = localBranches(); frames{3} = 33*ones(4,8);
r = farmTrackOverlaps(1:3,@(t) frames{t});
verifyEqual(testCase,r.Detections.TrajectoryID(end),1);
verifyTrue(testCase,any(r.Events.Type=="merge"));
s = farmSelectLineage(r,struct('ObjectIDs',33,'Frame',3));
verifyEqual(testCase,height(s.Detections),4);
end
function testOverlapVersusVolume(testCase)
a = zeros(4,5); a(1:10) = 7; a(11:13) = 99;
b = zeros(4,5); b(10:13) = 55; frames = {a,b};
r = farmTrackOverlaps(1:2,@(t) frames{t});
verifyEqual(testCase,r.Detections.TrajectoryID(end),2);
r = farmTrackOverlaps(1:2,@(t) frames{t},struct('Ranking','volume'));
verifyEqual(testCase,r.Detections.TrajectoryID(end),1);
end
function testIndependentEventPolicies(testCase)
frames = localBranches();
r = farmTrackOverlaps(1:2,@(t) frames{t},struct('SplitPolicy','new'));
verifyEqual(testCase,r.Detections.TrajectoryID,[1;2;3]); verifyFalse(testCase,any(r.Links.InheritanceChosen));
frames{3} = 33*ones(4,8);
r = farmTrackOverlaps(1:3,@(t) frames{t},struct('MergePolicy','new'));
verifyEqual(testCase,r.Detections.TrajectoryID(end),3);
end
function testManyToManyOneToOneInheritance(testCase)
a = zeros(4); a(1:2,:) = 10; a(3:4,:) = 20;
b = zeros(4); b(:,1:2) = 30; b(:,3:4) = 40;
frames = {a,b}; r = farmTrackOverlaps(1:2,@(t) frames{t});
verifyEqual(testCase,height(r.Links),4); verifyEqual(testCase,nnz(r.Links.InheritanceChosen),2);
verifyEqual(testCase,r.Detections.TrajectoryID,[1;2;1;2]);
verifyEqual(testCase,r.Events.Type,"merge-split");
end
function testEmptyFramesAndIsolatedDetections(testCase)
frames = {zeros(4),zeros(4),zeros(4)}; frames{1}(2,2) = 7; frames{3}(3,3) = 9;
r = farmTrackOverlaps(1:3,@(t) frames{t});
verifyEqual(testCase,height(r.Links),0); verifyEqual(testCase,height(r.Detections),2);
g = farmLineageGraph(r); verifyEqual(testCase,numnodes(g),2);
verifyTrue(testCase,any(r.Events.Type=="appearance")); verifyTrue(testCase,any(r.Events.Type=="disappearance"));
empty = farmTrackOverlaps(1:3,@(t) zeros(4));
verifyEmpty(testCase,empty.Detections); verifyEmpty(testCase,empty.Events);
end
function testFlexibleFramesAndSparseLabels(testCase)
r = farmTrackOverlaps([12 16 17 23 34],@(t) ones(4));
verifyEqual(testCase,r.Detections.Frame,[12;16;17;23;34]);
verifyEqual(testCase,r.Links.SourceFrame,[12;16;17;23]);
verifyEqual(testCase,r.Links.TargetFrame,[16;17;23;34]);
verifyEqual(testCase,r.Detections.TrajectoryID,ones(5,1));
a = zeros(4); a([1 2]) = 1000; b = zeros(4); b([2 3]) = 50000;
source = farmPrepareObjects(a); target = farmPrepareObjects(b);
e = farmOverlapLinks(source,target);
verifyEqual(testCase,e.OverlapCount,1); verifyEqual(testCase,e.SourceObjectID,1000);
verifyEqual(testCase,e.TargetObjectID,50000); verifyEqual(testCase,e.IoU,1/3,'AbsTol',1e-12);
end
function testRepeatedAndReverseFrames(testCase)
loaded = [];
r = farmTrackOverlaps([34 17 34 12 17],@loadFrame);
verifyEqual(testCase,loaded,[34 17 12]);
verifyEqual(testCase,r.Detections.Frame,[34;17;12]);
verifyEqual(testCase,r.Links.SourceFrame,[34;17]);
verifyEqual(testCase,r.Links.TargetFrame,[17;12]);
s = farmSelectLineage(r,struct('ObjectIDs',1,'Frame',12));
verifyEqual(testCase,s.Detections.Frame,[34;17;12]);
    function mask = loadFrame(frame)
        loaded(end+1) = frame;
        mask = ones(4);
    end
end
function testCoordinateBackgroundAndDescendants(testCase)
frames = localBranches(); r = farmTrackOverlaps(1:3,@(t) frames{t});
s = farmSelectLineage(r,struct('CoordinatesYXZ',[1 8 1],'Frame',3), ...
    struct('Loader',@(t) frames{t}));
verifyEqual(testCase,s.Detections.DetectionID,[1;3;7]);
frames{3}(4,8) = 0;
s = farmSelectLineage(r,struct('CoordinatesYXZ',[4 8 1],'Frame',3), ...
    struct('Loader',@(t) frames{t}));
verifyEmpty(testCase,s.Detections); verifyEqual(testCase,s.BackgroundCoordinatesYXZ,[4 8 1]);
s = farmSelectLineage(r,struct('ObjectIDs',22,'Frame',2),struct('Direction','descendants','IncludeSeed',false));
verifyEqual(testCase,s.Detections.ObjectID,[51;61]);
end
function testExplicitTrajectoryRoundTrip(testCase)
input = [1 7 99;2 8 99;1 10 5]; s = farmTot2ts(input,2);
verifyEqual(testCase,s.TrajectoryID,99);
t = farmTs2tot(s); verifyEqual(testCase,t.Trajectory,[99;99]);
verifyEqual(testCase,t.ObjectID,[7;8]);
end
function testPythonImportShuffledAndTwoDimensions(testCase)
t = table(["A";"A";"A"],[2;1;2],[70;99;80],[1 2;3 4;5 6], ...
    'VariableNames',{'DatasetID','Frame','ObjectID','Centroid'});
[matrix,map] = farmExportDetections(t);
verifySize(testCase,matrix,[3 4]);
m = farmImportLinks([3 9;1 4;2 7],map);
verifyEqual(testCase,m.ObjectID,[70;99;80]); verifyEqual(testCase,m.TrajectoryID,[4;7;9]);
m = farmTrackPositions(t,struct('SearchRange',0.5,'Linker',@(data,range,memory) [3 9;1 4;2 7]));
verifyEqual(testCase,m.TrajectoryID,[4;7;9]);
verifyError(testCase,@() farmImportLinks([3 4;1 4;2 7],map),'objecttracking:TrackpyBranch');
end
function testCoordinateHandoffXYAndXYZ(testCase)
% Export preserves coordinate order and origin; imports use explicit RowID.
coordinates = [101.25 7.5 900.75; 12.5 -40.25 30.5; .5 12 9.25];
for dimensions = [2 3]
    source = table(["A";"A";"A"], [8;2;8], [70;99;80], coordinates(:, 1:dimensions), ...
        [13;17;23], 'VariableNames', {'DatasetID','Frame','ObjectID','Centroid','Volume'});
    scale = [2 3 5]; scale = scale(1:dimensions);
    [matrix, map] = farmExportDetections(source, struct('MassProperty', 'Volume', 'CoordinateScale', scale));
    expected = [coordinates(:, 1:dimensions) .* scale, [13;17;23], [8;2;8]];
    verifyEqual(testCase, matrix, expected);
    order = 'XYZ';
    verifyEqual(testCase, map.Properties.UserData.CoordinateOrder, order(1:dimensions));
    membership = farmImportLinks([2 22;3 33;1 11], map);
    verifyEqual(testCase, membership.ObjectID, source.ObjectID);
    verifyEqual(testCase, membership.Frame, source.Frame);
    verifyEqual(testCase, membership.DetectionID, [1;2;3]);
    verifyEqual(testCase, membership.TrajectoryID, [11;22;33]);
end
end

function testRenderingAndMembershipJoin(testCase)
frames = localBranches(); r = farmTrackOverlaps(1:2,@(t) frames{t});
objects = farmPrepareObjects(frames{2},struct('Frame',2));
rows = r.Detections(r.Detections.Frame==2,:);
[labels,map] = farmRenderTrackingFrame(objects,rows);
verifyEqual(testCase,unique(labels),[1;2]); verifyEqual(testCase,map.TrajectoryID,[1;2]);
measurements = farmMeasureObjects(objects,{'Area'});
joined = farmAttachMembership(measurements([2 1],:),rows);
verifyEqual(testCase,joined.TrajectoryID,[2;1]);
end
function testPostTrackingSelectionCountsVersusSpan(testCase)
m = table(["A";"A"],[1;5],[1;2],[1;2],[7;7], ...
    'VariableNames',{'DatasetID','Frame','ObjectID','DetectionID','TrajectoryID'});
[selected,summary] = farmSelectTrajectories(m,struct('MinDetections',3));
verifyEqual(testCase,summary.ObservationCount,2); verifyEqual(testCase,summary.FrameSpan,5);
verifyEmpty(testCase,selected);
end
function frames = localBranches()
a = 10*ones(4,8); b = zeros(4,8); b(:,1:4) = 11; b(:,5:8) = 22;
c = zeros(4,8); c(:,1:2) = 31; c(:,3:4) = 32; c(:,5:6) = 51; c(:,7:8) = 61;
frames = {a,b,c};
end
