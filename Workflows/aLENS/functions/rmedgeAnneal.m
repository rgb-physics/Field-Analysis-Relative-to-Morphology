function [cleanGraph,newEdges] = rmedgeAnneal(inGraph,rmEdges)
%RMEDGEANNEAL Removes edges from graph but anneals predecessors and
%succesors of the removed nodes, retaining connectivity of all other nodes
% Rémi Boros - 2024-11-18

% Begin by removing edges from the input graph
tempGraph = rmedge(inGraph,rmEdges(:,1),rmEdges(:,2));
% Get the edges of the paired-down graph
clEdgeST = tempGraph.Edges.EndNodes;
% Map all instances of rmEdge targets (deleted) in the new graph sources to
% the appropriate rmEdge sources. i.e. we remove edge target nodes, connect
% remove edge source nodes to anything remove edge target nodes was
% connecting to.
stitchedEdgeST = mapWrap(clEdgeST,rmEdges(:,2),rmEdges(:,1));
newEdges = stitchedEdgeST + consMatLnB(clEdgeST,~logical(stitchedEdgeST));
% Redefine graph with small connection nodes removed
cleanGraph = digraph(newEdges(:,1),newEdges(:,2));

end

