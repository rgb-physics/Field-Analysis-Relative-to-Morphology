function [shiftGraph,cutDownGraph] = rmNodeStatic(inGraph,nodes2rmv)
%RMNODESTATIC Given a graph object, removes all edges that incorporate
%requested nodes for removal. Useful for maintaining static mapping between
%nodes before and after removal.
% Rémi Boros - 2024-11-18

% Collect node IDs
ogNodeIDs = 1:size(inGraph.Nodes);
% Select nodes to remove
rmvdLogic = ismember(ogNodeIDs,nodes2rmv);
% Remove nodes from graph, get new edges and nodes
cutDownGraph = rmnode(inGraph,nodes2rmv);
cdEdges = table2array(cutDownGraph.Edges);
% Map cut-down graph nodes to the original node values; then remap edges
shiftedNodes = ogNodeIDs(~rmvdLogic);
shiftedEdges = shiftedNodes(cdEdges);
shiftGraph = digraph(shiftedEdges(:,1),shiftedEdges(:,2));

end

