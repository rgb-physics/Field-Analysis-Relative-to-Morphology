% Takes in directory of blob objects saved tif per time point. Checks for
% overlaps in object indices between consecutive time points, samples
% object labels of each, then samples unique pairs of labels between the
% two time points. Optionally reconstructs tifs with blobs labeled per
% object ancestry/inherited blob index 
% This script assumes minimal object drift; object overlap between frames
% is assumed enough for inheritence
% Rémi Boros, 2024-06-17; 2024-10-17; 2024-11-06

% The goal: store object IDs using a directed graph. 
allInds = 1:16;
for index = 1:numel(allInds)
expIndex = allInds(index);
% baseDir = fullfile('<redacted original absolute path>',sprintf('%i',expIndex));
baseDir = fullfile('',sprintf('%i',expIndex));
dataDir = fullfile(baseDir,'3Width Convolution - Psqrd and sqrtQ\Filament Clusters');
saveDir = fullfile(baseDir,'Analyzed');
dataName = '2D_T%06i_clusterIDs.tif';
saveName = 'ObjectPointerMatrices.mat';
% Make directory
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

selectTimes = 1:399;
labeledInput = 1;           % If zero, binarize, then bwlabeln to get IDs
tic
%% Iterate over time - update IDs in each frame such that all IDs are unique
% Get [source, target] pairs of IDs to determine object lineage/connections
globalPairs = [];  
for tInd = 1:(numel(selectTimes) - 1)

    % Load data sets
    nextT = selectTimes(tInd+1);
    if ~isfile(fullfile(dataDir,sprintf(dataName,nextT)))
        continue
    end
    frameTwo = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,nextT))));

% Prepare data labels and logical matrices
    % Prepare frame one data
    if tInd == 1
        previousT = selectTimes(1);
        frameOne = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,previousT))));
        if labeledInput == 1
            labeledObjs1 = frameOne;
        else
            labeledObjs1 = bwlabeln(frameOneLogical);
        end
        frameOneLogical = logical(labeledObjs1);
        indVec1 = find(frameOneLogical); 
        nextID = max(labeledObjs1(:));
    end
    [objVols1, objIDs1] = groupcounts(labeledObjs1(labeledObjs1>0));
    if tInd == 1
        local2Global = [objIDs1, objIDs1, repmat(previousT,numel(objIDs1),1)];
    end

    if ~isempty(objIDs1)
        nextID = nextID + numel(objIDs1(:));
    end
    
    % Prepare frame two data
    if labeledInput == 1
        labeledObjs2OG = frameTwo;
    else
        labeledObjs2OG = bwlabeln(frameTwoLogical);
    end
    frameTwoLogical = logical(frameTwo);
    indVec2 = find(frameTwoLogical);   
    [objVols2, ogIDs2] = groupcounts(labeledObjs2OG(labeledObjs2OG>0));
    
    if max(ogIDs2) ~= max(unique(labeledObjs2OG(:)))
        max(ogIDs2);
    end

    % Shift IDs for only unique IDs
    objIDs2 = ogIDs2 + nextID;
    tempIDs2 = [0; objIDs2];
    labeledObjs2 = tempIDs2(1+labeledObjs2OG);
    local2Global = [local2Global; ...
        [ogIDs2, objIDs2, repmat(nextT,numel(objIDs2),1)]];

% First pass of object lineage
    % Get overlapping indices between frames
    overlapInds = indVec1(ismember(indVec1,indVec2));
    % Get object labels at overlapping inds over consecutive time points
    objectLabelPairs = [labeledObjs1(overlapInds),labeledObjs2(overlapInds)];
    uniqueObjectPairs = unique(objectLabelPairs,"rows");
    pairsAndTimes = uniqueObjectPairs; 
    pairsAndTimes(:,3) = previousT; pairsAndTimes(:,4) = nextT;
    globalPairs = [globalPairs; pairsAndTimes];         % [Source IDs, Target IDs, T_i, T_i+1]

% Clean up for next time pair
    frameOneLogical = frameTwoLogical;
    labeledObjs1 = labeledObjs2;
    indVec1 = find(frameOneLogical); 
    previousT = nextT;

end
toc

%% (Di)Graph approach to replacing merge and split event IDs%% (Di)Graph approach to replacing merge and split event IDs
% Make graph object
% testPairs = [1 3 1 2; 2 4 1 2; 3 5 2 3; 3 6 2 3; 4 6 2 3; 5 7 3 4; 6 8 3 4];
% globalPairs = testPairs;
objPairsDG = digraph(globalPairs(:,1),globalPairs(:,2));
% Instantiate new set of pairs with connections
replacePairs = globalPairs;

% Store in and out degree info
inDegsOG = indegree(objPairsDG);
outDegsOG = outdegree(objPairsDG);

% Sever merge events
% indegree > 1 is a merge: IDs become connMap targets, virtuals -> tail
mrgSrcs = find(inDegsOG>1);
mrgTargs = (1:numel(mrgSrcs))' + max(replacePairs(:));
mergeConns = [mrgSrcs, mrgTargs];
% Map merge targets onto global pair sources using mergeConns as a map
[replIDs,~,keptIDs] = mapWrap(replacePairs(:,1),mergeConns(:,1),mergeConns(:,2));
newSources = replIDs + keptIDs;

% Sever split events
% outdegree > 1 is a split: IDs become connMap sources, virtuals -> heads
spltPars = find(outDegsOG>1);
% Map replaceIDs onto splitParents to account for merge severing
spltParsRpl = mapWrap(spltPars, replacePairs(:,1), newSources);
% Make vector of parents repeated equal to outdegree
spltSrcs = genLenVec(outDegsOG(outDegsOG>1),spltParsRpl);
spltTargs = (1:sum(outDegsOG(spltPars)))' + max(mergeConns(:));
splitConns = [spltSrcs, spltTargs];
% Replace node pair sources with splitConn targets; they should be 1-to-1
spltRows = ismember(newSources,spltSrcs);
newSources2 = newSources;
newSources2(spltRows) = spltTargs;

% Concatenate pairs
splitPairsIDs = [newSources2, replacePairs(:,2)];
superPairsIDs = [splitPairsIDs; mergeConns; splitConns];

%% Get [Local, Global, Replace, Time] maps
eventSrcs = [mergeConns(:,1); splitConns(:,1)];
% Clean up: find event sources that are replaced -> map to global
[corrSrcs,~,fineSrcs] = mapWrap(eventSrcs,mergeConns(:,2),mergeConns(:,1));
corrGlobs = corrSrcs + fineSrcs;
% Get [L,T] pairs for connection events
replLocs = mapWrap(corrGlobs,local2Global(:,2),local2Global(:,1));
replTimes = mapWrap(corrGlobs,local2Global(:,2),local2Global(:,3));
% Concatenate individual columns of [L,G,R,T]
locVec = [local2Global(:,1); replLocs];
globVec = [local2Global(:,2); corrGlobs];
replVec = [zeros(size(local2Global,1),1); [mergeConns(:,2); splitConns(:,2)]];
timeVec = [local2Global(:,3); replTimes];
% Stitch everything together, convert to a table
GLRT_Map = [locVec, globVec, replVec, timeVec];
IDConvert = array2table(GLRT_Map, 'VariableNames',{'Local','Global','Replace','Time'});

%% Stitch times to superPairs, then convert superPairs to table
% Map all pairs into global space
[r2g,~,g2g] = mapWrap(superPairsIDs,IDConvert.Replace(:),IDConvert.Global(:));
allGlobPairs = r2g+g2g;
% Get time pairs from IDConvert mapping
timePairs = mapWrap(allGlobPairs,IDConvert.Global(:), IDConvert.Time(:));
superPairs = [superPairsIDs, timePairs];
superPairs = array2table(superPairs,'VariableNames',{'Source','Target','SourceTime','TargetTime'});

%% Save
save(fullfile(saveDir,saveName),'IDConvert','superPairs');
pause(0.01);

end








%% OLD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make graph object
% testPairs = [1 3 1 2; 2 4 1 2; 3 5 2 3; 3 6 2 3; 4 6 2 3; 5 7 3 4; 6 8 3 4];
% ogPairs = testPairs;

objPairsDG = digraph(globalPairs(:,1),globalPairs(:,2));
nodeIDsOg = 1:size(objPairsDG.Nodes,1);
nextID = max(max(globalPairs(:,1:2)));

% Instantiate a set of source-target pairs with replacement IDs
replacementPairs = globalPairs;

% Store in and out degree info
inDegsOG = indegree(objPairsDG);
outDegsOG = outdegree(objPairsDG);

% Get original indices of merge parents and split child
mergeChildren = (inDegsOG > 1);
splitParents = (outDegsOG > 1);

% Locate IDs at merge or split junctions in our "generating" lookup table
IDs2Replace = find(mergeChildren | splitParents);
replaceLogic = ismember(globalPairs(:,1), IDs2Replace);

% Split events are separated into different sub-graphs, one terminating at
% the original split node (unchanged), and a new one starting at each child
% of the split event.
% Merge events are separated at the merge node to form a sub-graph
% terminating at the original merge ID and another beginning at an
% additional map ID
% Redefine all merge/split IDs in the SOURCE column with unique new IDs
newIDs = nextID + (1:sum(replaceLogic(:,1)));
replacementPairs(replaceLogic,1) = newIDs;

% Store the map between global IDs and replacement IDs
global2Replace = [globalPairs(replaceLogic,1), newIDs(:), globalPairs(replaceLogic, 3), globalPairs(replaceLogic, 3)];
% Generate a SUPER graph that includes maps between merges and/or splits
superPairs = [replacementPairs; global2Replace];
superPairs = array2table(superPairs,'VariableNames',{'Source','Target','SourceTime','TargetTime'});

%% Map between local, global, and replacement IDs
% Seperate global indices pre-replacement by unique index
[unqGlobal,unqStarts,unqBinInds] = unique(global2Replace(:,1));
% Find indices of global IDs in local2global map
L2G_Logic = ismember(local2Global(:,2),unqGlobal);
localIDsOg = local2Global(L2G_Logic,1);
localTimesOg = local2Global(L2G_Logic,3);
% Get appropriate replaced IDs, using binInds and localIDs for inds and IDs
localIDs = localIDsOg(unqBinInds);  desTimes = localTimesOg(unqBinInds);
% Concatenate with replacedIDs
G2L2R_map_exist = [localIDs, global2Replace(:,1:2), desTimes];
% Define map for IDs that are not replaced (no merge/split events)
G2L2R_map_noexist = [local2Global(~L2G_Logic,1:2), zeros(sum(~L2G_Logic),1), local2Global(~L2G_Logic,3)];
G2L2LR_map = [G2L2R_map_noexist; G2L2R_map_exist];

% Convert to a table
IDConvert = array2table(G2L2LR_map, 'VariableNames',{'Local','Global','Replace','Time'});

% toc
%%

% connSources = find(outDegsOG);  


% orLogic = (inDegsOG > 1) | (outDegsOG > 1);
% Find IDs of objects in merge/split events
eventIDs = nodeIDsOg(orLogic);
pairsLogic = ismember(globalPairs(:,1:2),eventIDs);
rowsLogic = logical(sum(pairsLogic,2));
eventPairs = globalPairs(rowsLogic,1:2);



%%

% Instantiate a set of source-target pairs with replacement IDs
replacementPairs = globalPairs;


% Get original indices of merge parents and split child
mergeChildren = (inDegsOG > 1);
splitParents = (outDegsOG > 1);

% Locate IDs at merge or split junctions in our "generating" lookup table
IDs2Replace = find(mergeChildren | splitParents);
replaceLogic = ismember(globalPairs(:,1), IDs2Replace);

% Split events are separated into different sub-graphs, one terminating at
% the original split node (unchanged), and a new one starting at each child
% of the split event.
% Merge events are separated at the merge node to form a sub-graph
% terminating at the original merge ID and another beginning at an
% additional map ID
% Redefine all merge/split IDs in the SOURCE column with unique new IDs
newIDs = nextID + (1:sum(replaceLogic(:,1)));
replacementPairs(replaceLogic,1) = newIDs;

% Store the map between global IDs and replacement IDs
global2Replace = [globalPairs(replaceLogic,1), newIDs(:), globalPairs(replaceLogic, 3), globalPairs(replaceLogic, 3)];
% Generate a SUPER graph that includes maps between merges and/or splits
superPairs = [replacementPairs; global2Replace];
superPairs = array2table(superPairs,'VariableNames',{'Source','Target','SourceTime','TargetTime'});

%% Map between local, global, and replacement IDs
% Seperate global indices pre-replacement by unique index
[unqGlobal,unqStarts,unqBinInds] = unique(global2Replace(:,1));
% Find indices of global IDs in local2global map
L2G_Logic = ismember(local2Global(:,2),unqGlobal);
localIDsOg = local2Global(L2G_Logic,1);
localTimesOg = local2Global(L2G_Logic,3);
% Get appropriate replaced IDs, using binInds and localIDs for inds and IDs
localIDs = localIDsOg(unqBinInds);  desTimes = localTimesOg(unqBinInds);
% Concatenate with replacedIDs
G2L2R_map_exist = [localIDs, global2Replace(:,1:2), desTimes];
% Define map for IDs that are not replaced (no merge/split events)
G2L2R_map_noexist = [local2Global(~L2G_Logic,1:2), zeros(sum(~L2G_Logic),1), local2Global(~L2G_Logic,3)];
G2L2LR_map = [G2L2R_map_noexist; G2L2R_map_exist];

% Convert to a table
IDConvert = array2table(G2L2LR_map, 'VariableNames',{'Local','Global','Replace','Time'});

% toc
