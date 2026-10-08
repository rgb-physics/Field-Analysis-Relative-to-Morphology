function [cInds, cSizes, outGraph] = conncompDG(inDGraph)
%CONNCOMPDG Calculates the connectivity of a digraph as though it were an
%undirected graph.
% Rémi Boros - 2024-11-14

% Construct graph from sum of digraph adjacency with its transpose
outGraph = dg2g(inDGraph);
[cInds, cSizes] = conncomp(outGraph);

end

