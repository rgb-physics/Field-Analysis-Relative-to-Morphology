% After constructing trajectory super-graph and accessing cluster data
% (like volumes and centroids), correlate data over trajectories
% 1) From splitDGraph connectivity, get unique trajectories
% 2) Get trajectory connectivity
% 3) Measure trajectory properties, get trajectory heads and tail
% 4) From traj properties, define cost function
% 5) Isolate traj-pairs that are close/low cost function values
% 6) Get connectivity of isolated trajectories
% 7) Within each connected trajectory group, collate pairs of 
% [tailIDs of TrajSources, headIDs of TrajTargets]
% 8) Collate head-tail ID pairs with all [S,T] ID pairs of connected trajs
% 9) Treat each collated set as a new trajectory
% Ideally, cost-function should be selected s.t. new collated trajectories
% are visibly a single trajectory

%% 0) Define dataset info, load data
% Define directory info
expIndex = 2;
% baseDir = fullfile('<redacted original absolute path>', sprintf('%i',expIndex));
baseDir = fullfile('', sprintf('%i',expIndex));
propsDir = fullfile(baseDir,'3Width Convolution - Psqrd and sqrtQ');
trajDir = fullfile(baseDir,'Analyzed');
objsName = 'ObjectPointerMatrices.mat';
trajName = 'TrajectoryPointerMatrices.mat';
clustersName = 'T%06i_clusterProps.mat';
selTimes = 1:399;
difCutOff = 10;
matrixDims = [800 800 52];
% Load cluster and trajectory data
load(fullfile(trajDir,trajName));
load(fullfile(trajDir,objsName));

%% 1) From superPairs, generate superGraph, splitTrajs, and map IDs to trajs
% Split super-graph pairs into split-traj pairs and connection pairs
g2rLogic = table2array(superPairs(:,3)) == table2array(superPairs(:,4));
connMap = superPairs(g2rLogic,:);
splitTrajs = superPairs(~g2rLogic,:);
% Generate digraphs
superDGraph = digraph(superPairs.Source, superPairs.Target);  
splitDGraph = digraph(splitTrajs.Source, splitTrajs.Target); 

%% 1.5) Concatenate cluster properties from selected times (ideally done earlier)
allIDProps = [];
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    if ~isfile(fullfile(propsDir,sprintf(clustersName,currT)))
        continue
    end
    % Load object properties; skip if empty
    load(fullfile(propsDir,sprintf(clustersName,currT)));
    if isempty(clusterProps)
        continue
    end
    % Add vector of times
    numObjs = size(clusterProps,1);
    timeVec = repmat(currT,numObjs,1);
    clusterProps.Time(1:numObjs) = timeVec;
    % Add vector of local IDs
    clusterProps.Local(1:numObjs) = 1:numObjs;
    % Concatenate to prior data
    if isempty(allIDProps)
        allIDProps = clusterProps;
    else
        allIDProps = [allIDProps; clusterProps];
    end
end
allIDProps.NumFils(:) = cellIndSizes(allIDProps.FilIDs);
save(fullfile(propsDir,'ALL_clusterProps.mat'),'allIDProps');

%% 2) Get trajectory connectivity from ID connection pairs
% Map each object ID (index) to traj it's in (trajInds(index))
[ID2Traj, trajLens] = conncompDG(splitDGraph);  
% Map IDs in connection pairs to associated trajectories
connIDs = [connMap.Source(:), connMap.Target(:)];
connTrajs = ID2Traj(connIDs);   connIDsAndTrajs = [connIDs, connTrajs];
[trajST,uniqueInds,uniqueOrder] = (unique(connTrajs,'rows'));
IDofTrajST = connIDs(uniqueInds,:);
missingIDST = connIDs(~ismember(connIDs,IDofTrajST,'rows'),:);
% Make digraph of TRAJECTORY connections
trajDGraph = digraph(trajST(:,1),trajST(:,2));
[trajConn, connSize] = conncompDG(trajDGraph);

%% 4) Define cost function
% filNumPairs = meanFilNum(trajST);
% filNumDifs = abs(diff(filNumPairs,1,2));
% costLogic = filNumDifs < difCutOff;

allPropsKey = [allIDProps.Local(:)  allIDProps.Time(:)];
splitEdges = splitDGraph.Edges.EndNodes;
allCens =  reshape(allIDProps.Centroid(:),size(allIDProps,1),3);

% Compare connMap sources to predecessors
    % Find connection ID sources in splitGraph Edge Targets
    predsLogic = ismember(splitEdges(:,2),connIDs(:,1));
    predSrcPairs = splitEdges(predsLogic,1:2);
    % Calculate cost [Source, Predecessors]
    filPairsSP = getPairsFieldVals(predSrcPairs,IDConvert,allPropsKey,allIDProps.NumFils(:));

    % censSP = [getPairsFieldVals(predSrcPairs,IDConvert,allPropsKey,allCens(:,1)); ...
    %     getPairsFieldVals(predSrcPairs,IDConvert,allPropsKey,allCens(:,2)); ...
    %     getPairsFieldVals(predSrcPairs,IDConvert,allPropsKey,allCens(:,3))];
    % censSP = reshape(censSP,size(predSrcPairs,1),size(predSrcPairs,2),3);
    
% Compare connMap targets to successors
    % Find connection ID targets in splitGraph Edge sources
    sucsLogic = ismember(splitEdges(:,1),connIDs(:,2));
    trgSucPairs = splitEdges(sucsLogic,1:2);
    % Calculate cost [Target, Sucessors]
    filPairsTS = getPairsFieldVals(trgSucPairs,IDConvert,allPropsKey,allIDProps.NumFils(:));


% Make some cost functions
    % Define number of filaments over time
    filDifsSP = diff(filPairsSP,1,2);
    numFilAvgSP = sum(filPairsSP,2)/2;
    nfFracSP = abs(filDifsSP)./max(filPairsSP,[],2);

    % Define number of filaments over time
    filDifsTS = diff(filPairsTS,1,2);
    numFilAvgTS = sum(filPairsTS,2)/2;
    nfFracTS = abs(filDifsTS)./max(filPairsTS,[],2);


%% Select cost function
% Map cost function associated with each source onto connIDs
% spCosts = mapWrap(connMap.Source(:),predSrcPairs(:,2),nfFracSP);
% tsCosts = mapWrap(connMap.Target(:),trgSucPairs(:,1),nfFracTS);
spCosts = mapWrap(connMap.Source(:),predSrcPairs(:,2),filDifsSP);
tsCosts = mapWrap(connMap.Target(:),trgSucPairs(:,1),filDifsTS);
pairsCost = max(abs(spCosts),abs(tsCosts));
test = [connIDs, connTrajs, spCosts, tsCosts, pairsCost];

%%
% pairsCost = abs(spCosts + tsCosts);

% Define cutoff and apply
cutOff = 5;
costLogic = pairsCost < cutOff;
% Clean-up edges; make new digraph
% Remove edges of connMap that fall within cutoff
smallEdges = [connMap.Source(costLogic), connMap.Target(costLogic)];
largeEdges = [connMap.Source(~costLogic), connMap.Target(~costLogic)];
% Remove small edges and anneal nodes
[cleanGraph,newEdges] = rmedgeAnneal(superDGraph,smallEdges);
% Remove large connection edges, but don't anneal
cleanGraph = rmedge(cleanGraph,largeEdges(:,1),largeEdges(:,2));
% plot(cleanGraph)

%% Plot property vs time, coloring based on trajectory ID
% Generate ID to Traj structures splitGraph and revisitedGraph
% Iterate through each unique traj value
currDG = cleanGraph;
[currID2Traj,trajSizes] = conncompDG(currDG);
figure
% xlim([0 300])
% ylim([0 200])
hold on
% figure(2)
% hold on
for index = 1:numel(trajSizes)
    % Find IDs in the current trajectory
    trajLogic = currID2Traj == index;
    if sum(trajLogic) < 3
        continue
    end
    % Find [Local, Time] pairs of all selected IDs
    selIDs = find(trajLogic);
    [LTPairs,a,b] = globRepl2LT(IDConvert,selIDs);
    % Get cluster properties of selected IDs
    IDLogic = ismember(allPropsKey,LTPairs,'rows');
    numFils = allIDProps.NumFils(IDLogic);
    currVols = allIDProps.Volume(IDLogic);
    % plot
    % scatter(allIDProps.Time(IDLogic),numFils,10,[index/numel(trajSizes) 0 (1 - (index/numel(trajSizes)))],'filled')
    [sortT, sorder] = sort(allIDProps.Time(IDLogic));
    % plot(sortT,numFils(sorder));
    scatter(allIDProps.Time(IDLogic),numFils,'filled')
    % scatter(mean(allIDProps.Time(IDLogic)),mean(numFils),'filled')

    % Look for current IDs in remaining connectors
    % areConns = ismember(remainingConns,selIDs);
    % areConns = logical(sum(areConns,2));
    % if sum(areConns,'all') > 0
    %     checkIDs = remainingConns(areConns,:);
    %     checkLTs = globRepl2LT(IDConvert,checkIDs);
    %     % propsIDs = ismember(allPropsKey,checkLTs,'rows');
    % 
    %     if size(checkLTs,1) > numel(unique(checkIDs(:,1)))
    % 
    %         find(checkLTs)
    %     end
    % 
    %     % sum(areConns)
    % end

end

%% Reconstruct stack from IDs
% Generate ID to Traj structures splitGraph and revisitedGraph
% Iterate through each unique traj value
currDG = cleanGraph;
currDG = splitDGraph;
[currID2Traj,trajSizes] = conncompDG(currDG);
% selTrajs = 1:numel(trajSizes);
selTrajs = 1000:1505;

for index = selTrajs

    % Find IDs in the current trajectory
    trajLogic = currID2Traj == index;
    if sum(trajLogic) < 10
        continue
    end
    %%
    % Find [Local, Time] pairs of all selected IDs
    selIDs = find(trajLogic);
    [LTPairs,a,b] = globRepl2LT(IDConvert,selIDs);
    % Get cluster properties of selected IDs
    IDLogic = ismember(allPropsKey,LTPairs,'rows');
    numFils = allIDProps.NumFils(IDLogic);
    currVols = allIDProps.Volume(IDLogic);
    currCens = allIDProps.Centroid(IDLogic,:);
    currInds = allIDProps.VoxelIdxList(IDLogic);
    [sortT, sorder] = sort(allIDProps.Time(IDLogic));
    currLTs = [allIDProps.Local(IDLogic) allIDProps.Time(IDLogic)];
    unqTs = unique(sortT);

    matStore = zeros(matrixDims(1),matrixDims(2),numel(unqTs));
    for tInd = 1:numel(unqTs)
        tempMat = zeros(matrixDims);
        currT = unqTs(tInd);
        tLogic = sortT == currT;
        if sum(tLogic) > 1
            % sum(tLogic)
        end
        censInT = round(currCens(tLogic,:));
        indsInT = vertcat(currInds{tLogic});
        tempMat(indsInT) = index;
        tempMat2D = nzFlat(tempMat);
        cenInds = sub2ind(size(tempMat2D),censInT(:,2),censInT(:,1));
        tempMat2D(cenInds) = 1.5*index;
        matStore(:,:,tInd) = tempMat2D;
    end

    testDir = fullfile(baseDir,'Analyzed','Test Trajs');
    if ~exist(testDir,'dir')
        mkdir(testDir)
    end
    %%
    save3DTiff(uint16(matStore),fullfile(testDir,sprintf('traj%06i.tif',index)));

    % plot
    % scatter(allIDProps.Time(IDLogic),numFils,10,[index/numel(trajSizes) 0 (1 - (index/numel(trajSizes)))],'filled')
    % plot(sortT,numFils(sorder));

end

%% Test navigation of split events
currDG = splitDGraph;
[currID2Traj,trajSizes] = conncompDG(currDG);

splitSource = 2829;
pairsLogic = (connIDs(:,1) == splitSource);
splitIDs = connIDs(pairsLogic,:);
splitTrajs = connTrajs(pairsLogic,:);
uTrajs = unique(splitTrajs);
allLTs = [];    allIDs = [];
for index = 1:numel(uTrajs)
    trajLogic = currID2Traj == uTrajs(index);
    selIDs = find(trajLogic);
    tempLTs = globRepl2LT(IDConvert,selIDs);
    allLTs = [allLTs; tempLTs];
    allIDs = [allIDs; selIDs'];
    
end
allAll = [allIDs, allLTs];


%% 5) Isolate trajectory pairs that fall within cutoff
% Isolate in trajectory space
keptConns = trajST;
keptConns(~costLogic,:) = 0;
% Move to ID space: traj space is compact since many ID heads is possible
% Rebuild degenerate pairs; 
degenKeptConns = keptConns(uniqueOrder,:);
% Find zero-valued rows; used to reconstruct non-degen IDs
zeroRows = degenKeptTrajs(:,1) == 0;
% Rebuild IDs (non-degenerate) and trajs (degenerate)
rmvIDs = connIDs(zeroRows,:);
remainingConns = connIDs(~zeroRows,:);

%% 6) Remove IDs from trajs that fall within cutoff
revisitedGraph = rmedge(superDGraph,rmvIDs(:,1),rmvIDs(:,2));
% close all
% plot(revisitedGraph)
% hold on
% plot(superDGraph);

%% Plot property vs time, coloring based on trajectory ID
% Generate ID to Traj structures splitGraph and revisitedGraph
% Iterate through each unique traj value

% currDG = splitDGraph;
currDG = cleanGraph;
[currID2Traj,trajSizes] = conncompDG(currDG);

figure
% xlim([0 300])
% ylim([0 200])
hold on
% figure(2)
% hold on
for index = 1:numel(trajSizes)
    % Find IDs in the current trajectory
    trajLogic = currID2Traj == index;
    % Find [Local, Time] pairs of all selected IDs
    selIDs = find(trajLogic);
    LTPairs = globRepl2LT(IDConvert,selIDs);
    % Get cluster properties of selected IDs
    IDLogic = ismember(allPropsKey,LTPairs,'rows');
    numFils = allIDProps.NumFils(IDLogic);
    currVols = allIDProps.Volume(IDLogic);
    % plot
    % scatter(allIDProps.Time(IDLogic),numFils,'filled')
    % scatter(mean(allIDProps.Time(IDLogic)),mean(numFils),'filled')

    % Look for current IDs in remaining connectors
    areConns = ismember(remainingConns,selIDs);
    areConns = logical(sum(areConns,2));
    if sum(areConns,'all') > 0
        checkIDs = remainingConns(areConns,:);
        checkLTs = globRepl2LT(IDConvert,checkIDs);
        % propsIDs = ismember(allPropsKey,checkLTs,'rows');
        
        if size(checkLTs,1) > numel(unique(checkIDs(:,1)))

            find(checkLTs)
        end
        
        % sum(areConns)
    end

end

%% Original implementation
%       Find rows in allIDProps corresponding to relevant [Local, Time]s
%       Scatter property vs. time, color by trajectory
allTrajs = currProps.TrajID(:);
unqTrajs = unique(allTrajs);
figure
for index = 1:numel(unqTrajs)
    currTraj = unqTrajs(index);
    trajLogic = allTrajs == currTraj;
    numFils = currProps.NumFils(trajLogic);
    currVols = currProps.Volume(trajLogic);
    scatter(currProps.Time(trajLogic),numFils,'filled')
    % scatter(currProps.Time(trajLogic),currProps.Volume(trajLogic),10,...
        % [index/numel(uTrajs) 0 (1 - index/numel(uTrajs))],'filled')
    hold on
end




%% Sanity check stuff
% Sanity check - indicate which [S,T] have [pred,succ]
hasPred = mapWrap(connMap.Source(:),predSrcPairs(:,2),predSrcPairs(:,1));
hasSucc = mapWrap(connMap.Target(:),trgSucPairs(:,1),trgSucPairs(:,2));

test3 = [hasPred, connMap.Source(:), connMap.Target(:), hasSucc];
allPairs = [testStack(1:(end-1)), testStack(2:end)];
realPairs = allPairs((1:3)' + (0:4:floor(size(allPairs,1)/4)),:)+1;
temp = digraph(realPairs(:,1), realPairs(:,2));
temp2 = rmnode(temp,1);

% test3 = [connMap.Source(:), connMap.Target(:), test, test2];

%% 3) Measure trajectory properties (split), get heads and tails
% Get the number of edges connecting in and out of each node
sepIDs = 1:size(splitDGraph.Nodes,1);
numSources = indegree(splitDGraph); numSinks  = outdegree(splitDGraph);
% Trajectories start at nodes with no ins; they end at nodes with no outs
trajStarts = sepIDs((numSources == 0) & ~(numSinks == 0));
trajEnds = sepIDs((numSinks == 0) & ~(numSources == 0));
trajExtrema = struct();

% List all non-trivial trajectory IDs
unqSplitTrajs = unique(trajST(:));
% unqSplitTrajs = find(trajLens > 1)';
% Iterate through all non-trivial trajectories; calculate/store properties
meanFilNum = zeros(numel(trajLens),1); meanTime = meanFilNum;
for index = 1:numel(unqSplitTrajs)
    currTraj = unqSplitTrajs(index);
    [currProps, selIDs] = Traj2Props(currTraj,ID2Traj,IDConvert,allIDProps);
    trajExtrema(index).Heads = trajStarts(ismember(trajStarts,selIDs));
    trajExtrema(index).Tail = trajEnds(ismember(trajEnds,selIDs));
    trajExtrema(index).Index = currTraj;
    meanFilNum(currTraj) = mean(currProps.NumFils(:));
    meanTime(currTraj) = mean(currProps.Time(:));
end

%% 
% Apply uniqueInds(~costLogic) to unique [S,T], then extend to og. size
% using uniqueOrder; Finally, keep all [S,T] IDs that are non-zero and rmv
% remaining edges from superGraph
keptConns(uniqueInds(~costLogic),:) = 0;
% Extend back up to full dimensions

grpIDsTrajs = connIDsAndTrajs(uniqueInds(costLogic),:);
% Get collection of IDs 

%% 6) Generate graph; find connectivity of isolated trajectories
selTrajGraph = digraph(grpIDsTrajs(:,3),grpIDsTrajs(:,4));
[grpTrajConn, grpTrajSizes] = conncompDG(selTrajGraph);

%% 7) Collate connector ID pairs to all IDs in connected trajectories
largrGrpIDs = find(grpTrajSizes>1); 

for index = 1:numel(largrGrpIDs)

    currGrp = largrGrpIDs(index);
    % Get trajectories in current connected cluster from 
    currTrajs = find(grpTrajConn == currGrp);
    % Get IDs in selected trajectories from ID2Traj
    currIDs = find(ismember(ID2Traj, currTrajs));
    % Get ID [S,T] that generate current traj selection
    revisitedGraph = ismember([splitTrajs.Source(:),splitTrajs.Target(:)],currIDs);
    keepLogic = revisitedGraph(:,1) & revisitedGraph(:,2);
    currIDST = [splitTrajs.Source(keepLogic),splitTrajs.Target(keepLogic)];



    connIDs = [connMap.Source(:), connMap.Target(:)];
    trajST = (unique(ID2Traj(connIDs),'rows'));


    testGraph = digraph(currIDST(:,1),currIDST(:,2));
    plot(testGraph)


end








%% 
% Get properties and IDs of objects in selected trajectories
[currProps, selIDs] = IDs2Props(selTraj,ID2Traj,IDConvert,allIDProps);
currHeads = trajStarts(ismember(trajStarts,selIDs));
currTail = trajEnds(ismember(trajEnds,selIDs));

%% Average quantities over each trajectory
meanFilNum = zeros(numel(ancList),1);
meanTime = meanFilNum;
for index = 1:numel(ancList)
    selTraj = ancList(index);
    [currProps, selIDs] = IDs2Props(selTraj,ID2Traj,IDConvert,allIDProps);
    meanFilNum(index) = mean(currProps.NumFils(:));
    meanTime(index) = mean(currProps.Time(:));
end

%% Iterate through each unique pair, compare difference in fil num
filNumDif = zeros(size(unqTrajPairs,1),1);
for index = 1:size(unqTrajPairs,1)
    currPair = unqTrajPairs(index,:);
    currLogic = ismember(ancList,currPair);
    currFN = meanFilNum(currLogic);
    filNumDif(index) = abs(diff(currFN));
end

%% Get trajectories corresponding to each row of currProp
% Isolate (Local, Time) pairs from cluster properties and IDLUT
allLTs = [allIDProps.Local(:), allIDProps.Time(:)];
LUTLTs = [IDConvert.Local(:), IDConvert.Time(:)];
% Get trajectories associated with each global ID
allGlobals = unique(IDConvert.Global(:));
selTrajs = ID2Traj(allGlobals);
% Assign trajectory ID to cluster properties, 
allIDProps.TrajID(:) = selTrajs;
% allPropsKey = [allIDProps.Local(:) allIDProps.Time(:) allIDProps.TrajID(:)];

%% Given a trajectory, propagate "up" and find ancestors
maxLen = max(trajLens); maxInd = find(trajLens == maxLen);
selTraj = maxInd;

currHeads = selTraj;
trajMat = table2array(trajMap);
ancList = currHeads;
currPairs = [];
loopFlag = true;
while loopFlag
    currTargetLogic = ismember(trajMat(:,2), currHeads);
    % indList = [indList; find(currTargetLogic)];
    if sum(currTargetLogic) == 0
        loopFlag = false;
    else
        currPairs = [currPairs; trajMat(currTargetLogic,1:2)];
        % Be sure not to double count paths that have already been navigated 
        currHeads = unique(trajMat(currTargetLogic,1));
        currHeads = currHeads(~ismember(currHeads,ancList));
    end
    ancList = [ancList; currHeads(:)];   
end
ancList = unique(ancList);
unqTrajPairs = unique(currPairs,'rows');
uniqueGraph = digraph(unqTrajPairs(:,1),unqTrajPairs(:,2));

%% Get collection of all split traj heads and tails
% Get the number of edges connecting in and out of each node
numSources = indegree(splitDGraph);
numSinks  = outdegree(splitDGraph);
sepIDs = 1:size(splitDGraph.Nodes,1);
obj2Traj = [];
% Trajectories start at nodes with no ins; they end at nodes with no outs
trajStarts = sepIDs((numSources == 0) & ~(numSinks == 0));
trajEnds = sepIDs((numSinks == 0) & ~(numSources == 0));

%% Given a trajectory, isolate properties, then find starts and end IDs
% Select a trajectory
maxLen = max(trajLens); maxInd = find(trajLens == maxLen);
selTraj = maxInd;

% Get properties and IDs of objects in selected trajectories
[currProps, selIDs] = IDs2Props(selTraj,ID2Traj,IDConvert,allIDProps);
currHeads = trajStarts(ismember(trajStarts,selIDs));
currTail = trajEnds(ismember(trajEnds,selIDs));

%% Average quantities over each trajectory
meanFilNum = zeros(numel(ancList),1);
meanTime = meanFilNum;
for index = 1:numel(ancList)
    selTraj = ancList(index);
    [currProps, selIDs] = IDs2Props(selTraj,ID2Traj,IDConvert,allIDProps);
    meanFilNum(index) = mean(currProps.NumFils(:));
    meanTime(index) = mean(currProps.Time(:));
end

%% Iterate through each unique pair, compare difference in fil num
filNumDif = zeros(size(unqTrajPairs,1),1);
for index = 1:size(unqTrajPairs,1)
    currPair = unqTrajPairs(index,:);
    currLogic = ismember(ancList,currPair);
    currFN = meanFilNum(currLogic);
    filNumDif(index) = abs(diff(currFN));
end

%% Given nodes under cutoff, remove them
% testPairs = [1 3 1 2; 2 4 1 2; 3 5 2 3; 3 6 2 3; 4 6 2 3; 5 7 3 4; 6 8 3 4] + 1;
% testPairs = [testPairs; testPairs + max(testPairs) - 1 - 1];
% ogGraph  = digraph(testPairs(:,1),testPairs(:,2));
% rmvNodes = [ 7 9];
cutOff = 10;
ogGraph  = digraph(unqTrajPairs(:,1),unqTrajPairs(:,2));
ogNodeIDs = 1:size(ogGraph.Nodes);
% Select nodes to remove
rmvLogic = filNumDif < cutOff;
rmvNodes = unique(unqTrajPairs(rmvLogic,:));
rmvdAncLogic = ismember(ogNodeIDs,rmvNodes);
% Remove nodes from graph, get new edges and nodes
cutDownGraph = rmnode(ogGraph,rmvNodes);
cdEdges = table2array(cutDownGraph.Edges);
cutNodeIDs = 1:size(cutDownGraph.Nodes);
% Map cut-down graph nodes to the original node values; then map edges
shiftedNodes = ogNodeIDs(~rmvdAncLogic);
shiftedEdges = shiftedNodes(cdEdges);
shiftGraph = digraph(shiftedEdges(:,1),shiftedEdges(:,2));

% Display the graphs
figure
plot(ogGraph)
figure
plot(cutDownGraph)
figure
plot(shiftGraph)

%% Plot property vs time, coloring based on trajectory ID
allTrajs = currProps.TrajID(:);
unqTrajs = unique(allTrajs);
figure
for index = 1:numel(unqTrajs)
    currTraj = unqTrajs(index);
    trajLogic = allTrajs == currTraj;
    numFils = currProps.NumFils(trajLogic);
    currVols = currProps.Volume(trajLogic);
    scatter(currProps.Time(trajLogic),numFils,'filled')
    % scatter(currProps.Time(trajLogic),currProps.Volume(trajLogic),10,...
        % [index/numel(uTrajs) 0 (1 - index/numel(uTrajs))],'filled')
    hold on
end

%% Plot mean filament number vs. time
[sortedTrajs,trajOrder] = sort(ancList);

[sortedTime,sortOrder] = sort(meanTime);
chronoFN = meanFilNum(sortOrder);
figure
plot()

%% Plot property vs time, coloring based on trajectory ID
allTrajs = currProps.TrajID(:);
unqTrajs = unique(allTrajs);
figure
for index = 1:numel(unqTrajs)

    currTraj = unqTrajs(index);
    trajLogic = allTrajs == currTraj;
    numFils = currProps.NumFils(trajLogic);
    currVols = currProps.Volume(trajLogic);
    scatter(currProps.Time(trajLogic),numFils,'filled')
    % scatter(currProps.Time(trajLogic),currProps.Volume(trajLogic),10,...
        % [index/numel(uTrajs) 0 (1 - index/numel(uTrajs))],'filled')
    hold on

end
%
%% 
% From global/replace ID, get local ID and time (Make this into a function)
headsLTPairs = globRepl2LT(IDConvert,currHeads);
tailLTPairs = globRepl2LT(IDConvert,tailLogic);
















% Get numfils for all IDs in current trajectory

allTrajs = currProps.TrajID(:);
unqTrajs = unique(allTrajs);

    currTraj = unqTrajs(index);
    trajLogic = allTrajs == currTraj;
    numFils = currProps.NumFils(trajLogic);

%% Get endIDs and startIDs from sourceTraj and targTraj, respectively


% Find rows of ID-Lookup that contain the selected indices (global/replace)
IDLogic = ismember(table2array(IDConvert(:,2:3)),selIDs);
IDRows = logical(sum(IDLogic,2));
% Define Time and Local IDs of the selectedIDs
currKey = [table2array(IDConvert(IDRows,[4 1]))];

% Get properties for current objects
allPropsKey = [allIDProps.Time(:)  allIDProps.Local(:)];
IDLU_Inds = find(ismember(allPropsKey,currKey,'rows'));
currProps = allIDProps(IDLU_Inds,:);

%% Get info for all trajs here

% Given (ancestral) trajectory indices, map of IDs to trajs, and IDLookup,
% find all object properties for objects in selected trajectory/(ies)

% trajInds: trajectoryID that each unique ID (global/replace) belongs to
selIDs = find(ismember(ID2Traj,ancList));

% Find rows where IDs live
IDLogic = ismember(table2array(IDConvert(:,2:3)),selIDs);
IDRows = logical(sum(IDLogic,2));

% Get properties for current objects: compare local ID + times to identify
% which rows of allProps to query/access

allPropsKey = [allIDProps.Local(:)  allIDProps.Time(:)];
currKey = table2array(IDConvert(IDRows,[1 4]));
IDLUTKey = table2array(IDConvert(:,[1 4]));

IDLU_Inds = find(ismember(allPropsKey,currKey,'rows'));      
currProps = allIDProps(IDLU_Inds,:);
currProps.NumFils(:) = cellIndSizes(currProps.FilIDs);

%% Get trajectories corresponding to each row of currProps
allLTs = [allIDProps.Time(IDLU_Inds), allIDProps.Local(IDLU_Inds)];
checkTimesLocals = [IDConvert.Time(:), IDConvert.Local(:)];
% Look for global IDs from properties in ID lookup table; get assoc. trajs
lutInds = ismember(checkTimesLocals,allLTs,'rows');
selGlobal = unique(IDConvert(lutInds,'Global'));
selTrajs = ID2Traj(selGlobal.Global(:));
% get relevant index order of select IDs in currProps
propsInds = find(ismember(allLTs,checkTimesLocals,'rows'));
currProps.TrajID(propsInds) = selTrajs;



%% Plot volumes vs time, coloring based on trajectory ID
allTrajs = currProps.TrajID(:);
unqTrajs = unique(allTrajs);
figure
xlim([0 250])
ylim([0 160])
    hold on
for index = 1:numel(unqTrajs)

    currTraj = unqTrajs(index);
    trajLogic = allTrajs == currTraj;
    numFils = currProps.NumFils(trajLogic);
    currVols = currProps.Volume(trajLogic);
    scatter(currProps.Time(trajLogic),numFils,'filled')
    % scatter(currProps.Time(trajLogic),currProps.Volume(trajLogic),10,...
        % [index/numel(uTrajs) 0 (1 - index/numel(uTrajs))],'filled')

end


%% over time, scatter centers of mass
[subTimes,~,binInds] = unique(currProps.Time(:));

for tInd = 1:numel(subTimes)

    currT = subTimes(tInd);
    currLogic = currProps.Time(:) == currT;


end





