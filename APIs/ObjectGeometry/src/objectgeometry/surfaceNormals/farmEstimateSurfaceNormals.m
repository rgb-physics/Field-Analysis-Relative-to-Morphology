function [normals, info] = farmEstimateSurfaceNormals(points, queryIndices, varargin)
%FARMESTIMATESURFACENORMALS Fit unsigned PCA normals at selected source points.
% Inputs:
%   points          N-by-3 physical XYZ support, retained at full density.
%   queryIndices    Indices of points receiving normals; [] selects none.
%   Radius          Required positive physical radius; never auto-expanded.
%   MaxNeighbors    KNN cap including the query, default 32.
%   MinNeighbors    Minimum fitting count, default 6 (at least 3).
% Outputs:
%   normals         Q-by-3 unit axes; NaN where support is insufficient or
%                   has no uniquely determined local plane.
%   info            QueryIndices, counts, eigenvalues, Valid and settings.
% Each query uses up to K nearest support points within Radius. No sign,
% curvature, tangent basis, field sampling, or temporal processing is added.
% PCA plane fit: Hoppe et al., SIGGRAPH 1992, pp. 71-78,
% https://doi.org/10.1145/133994.134011
points = farmSurfacePoints(points);
if nargin < 2, queryIndices = (1:size(points,1)).'; end
if ~isempty(queryIndices)
    validateattributes(queryIndices,{'numeric'},{'vector','integer','positive', ...
        'finite','<=',size(points,1)});
end
queryIndices = double(queryIndices(:));
p = inputParser;
addParameter(p,'Radius',[]);
addParameter(p,'MaxNeighbors',32);
addParameter(p,'MinNeighbors',6);
parse(p,varargin{:}); o = p.Results;
validateattributes(o.Radius,{'numeric'},{'real','finite','positive','scalar'});
validateattributes(o.MaxNeighbors,{'numeric'},{'integer','finite','scalar','>=',3});
validateattributes(o.MinNeighbors,{'numeric'},{'integer','finite','scalar','>=',3,'<=',o.MaxNeighbors});
[ids,distances] = farmSurfaceKNN(points,points(queryIndices,:),o.MaxNeighbors);
count = sum(distances <= o.Radius,2);
normals = nan(numel(queryIndices),3); eigenvalues = normals;
for qInd = 1:numel(queryIndices)
    if count(qInd) < o.MinNeighbors, continue; end
    local = points(ids(qInd,distances(qInd,:) <= o.Radius),:);
    local = local - mean(local,1);
    [vectors,values] = eig((local.'*local)/size(local,1),'vector');
    [values,order] = sort(values);
    eigenvalues(qInd,:) = values.';
    % Reject coincident, collinear and isotropic neighborhoods. Threshold is
    % numerical degeneracy protection, not a scientific quality cutoff.
    tol = 1e-10*max(values(3),realmin);
    if values(2) <= tol || values(2)-values(1) <= tol, continue; end
    normals(qInd,:) = vectors(:,order(1)).';
end
info = struct('QueryIndices',queryIndices,'NeighborCount',count, ...
    'Eigenvalues',eigenvalues,'Valid',all(isfinite(normals),2),'Options',o);
end
