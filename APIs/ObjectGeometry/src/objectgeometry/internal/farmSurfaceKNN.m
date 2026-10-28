function [ids, distances] = farmSurfaceKNN(points, queries, count)
%FARMSURFACEKNN Capped Euclidean KNN, using a KD tree; no full distance matrix.
% Statistics and Machine Learning Toolbox is required. Duplicate coordinates
% are allowed; callers must not assume the query itself is the first result.
if isempty(points) || isempty(queries)
    ids = zeros(size(queries,1),0); distances = ids; return
end
if exist('KDTreeSearcher','class') ~= 8
    error('objectgeometry:KNNDependency', ...
        'Surface KNN requires Statistics and Machine Learning Toolbox.');
end
tree = KDTreeSearcher(points);
[ids,distances] = knnsearch(tree,queries,'K',min(count,size(points,1)));
end
