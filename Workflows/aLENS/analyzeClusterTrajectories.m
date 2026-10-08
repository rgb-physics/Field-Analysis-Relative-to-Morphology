% From index pointers (ID [Source, Targets]), coarse-grain and determine
% connectivity of distinct node clusters separated by events. Need
% superPairs table and IDConvert lookup table: 
% [L,G,R,T] corresponds to [Local, Global, Replace, Time] node IDs
% 2024-11-06

% expIndex = 11;
expIndices = 1:16;
for index = 1:numel(expIndices)
% Instantiate load info
expIndex = expIndices(index);
% baseDir = fullfile('<redacted original absolute path>',sprintf('%i',expIndex));
baseDir = fullfile('',sprintf('%i',expIndex));
dataDir = fullfile(baseDir,'Analyzed');
dataName = 'ObjectPointerMatrices.mat';

%% Load data
load(fullfile(dataDir,dataName));
% Load a table of [Sources, Targets, T1, T2] for building a graph
% Load a IDConvert [L,G,R,T] lookup table

%% Split super-connected map into truncations and connectors
g2rLogic = table2array(superPairs(:,3)) == table2array(superPairs(:,4));
connMap = superPairs(g2rLogic,:);
splitTrajs = superPairs(~g2rLogic,:);

%% Make graph of split trajectories
trajDGraph = digraph(splitTrajs.("Source"),splitTrajs.('Target'));

%% Split trajectories into new structure + map trajectory connections
% Get the number of edges connecting in and out of each node
numSources = indegree(trajDGraph); numSinks  = outdegree(trajDGraph);
sepIDs = 1:size(trajDGraph.Nodes,1);
nodePairs = table2array(superPairs(:,1:2));
obj2Traj = [];
% Trajectories start at nodes with no ins; they end at nodes with no outs
trajStarts = sepIDs((numSources == 0) & ~(numSinks == 0));
trajEnds = sepIDs((numSinks == 0) & ~(numSources == 0));

% Index separate connected components of sep-graph
[compInds, compSizes] = conncompDG(trajDGraph);
uniqueTrajs = find(compSizes>0)';
trajStruct = struct();
for trajInd = 1:numel(uniqueTrajs)
    % Get nodes in current trajectory, then store
    currTraj = uniqueTrajs(trajInd);
    currNodes = find(compInds == currTraj);
    edgeLogic = ismember(nodePairs,currNodes); edgeRows = logical(sum(edgeLogic,2));
    currEdges = nodePairs(edgeRows,:);
    trajStruct(trajInd).Nodes = currNodes;
    % Identify starts and endings of this trajectory (count sources/sinks)
    currStarts = trajStarts(ismember(trajStarts,currNodes));
    currEnd = trajEnds(ismember(trajEnds,currNodes));
    % Store trajectory start/end nodes
    trajStruct(trajInd).StartNodes = currStarts;
    trajStruct(trajInd).EndNode = currEnd;

    % Map node ID to trajectory ID; array of [Node, TrajID, trajStruct ind]
    obj2Traj = [obj2Traj; [currNodes(:), repmat(currTraj,numel(currNodes),1), ...
        repmat(trajInd,numel(currNodes),1)]];
end

% Prepare map data
connArray = table2array(connMap(:,1:2));
[~,objOrder] = sort(obj2Traj(:,1));
obj2Traj = obj2Traj(objOrder,:);
% Use connection matrix and object-traj map to define traj connectivity
trajMap = reshape(obj2Traj(connArray,2), size(connArray));
trajMap = array2table(unique(trajMap,'rows'),'VariableNames',{'SourceTraj','TargetTraj'});

save(fullfile(dataDir,'TrajectoryPointerMatrices.mat'), 'trajMap');

end
