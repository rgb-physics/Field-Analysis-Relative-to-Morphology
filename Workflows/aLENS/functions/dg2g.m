function [outGraph] = dg2g(inDigraph)
%DG2G One line conversion of a digraph to a graph
% Rémi Boros 2024-11-14

outGraph = graph(adjacency(inDigraph) + adjacency(inDigraph)');

end

