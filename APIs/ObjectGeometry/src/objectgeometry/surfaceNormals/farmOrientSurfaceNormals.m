function [oriented, info] = farmOrientSurfaceNormals(points, normals, varargin)
%FARMORIENTSURFACENORMALS Spatial sign propagation on a guarded KNN forest.
% Inputs:
%   points               N-by-3 physical XYZ query/export points.
%   normals              N-by-3 axes; NaN rows are retained as unavailable.
%   Radius               Required physical maximum graph edge length.
%   MaxNeighbors         Maximum non-self neighbors, default 12.
%   MinAbsDot            Minimum normal-axis agreement, default 0.25.
%   MaxNormalOffset      Max |dot(edgeDirection,normal)| at either end, 0.65.
%   ReferenceDirections  N-by-3 center-to-boundary vectors or [], default [].
%   SourceMask           Optional binary source volume for default boundary
%                        references; requires N source linear SourceIndices.
%   Spacing              YXZ spacing for SourceMask, default [1 1 1].
%   SeedIndices          Preferred roots in this point array, default [].
% Outputs:
%   oriented             Unit normals with signs propagated within groups.
%   info                 Group IDs (0 for invalid axes), seed IDs, whether
%                        referenced, sign flips, accepted edge count/settings.
% References choose a group's initial sign only. Without a usable reference,
% the root's largest-magnitude component is made positive (arbitrary sign).
% Neighbor graph and forest orient an assumed orientable surface; there is
% no guarantee of correct connectivity at unresolved folds or contacts.
% Method: Hoppe et al., Surface Reconstruction from Unorganized Points,
% SIGGRAPH 1992, https://doi.org/10.1145/133994.134011 ; tangent-offset guards
% and component seed selection are FARM additions, not the original method.
points = farmSurfacePoints(points);
validateattributes(normals,{'numeric'},{'real','2d','size',size(points)});
p = inputParser;
addParameter(p,'Radius',[]); addParameter(p,'MaxNeighbors',12);
addParameter(p,'MinAbsDot',0.25); addParameter(p,'MaxNormalOffset',0.65);
addParameter(p,'ReferenceDirections',[]); addParameter(p,'SeedIndices',[]);
addParameter(p,'SourceMask',[]); addParameter(p,'SourceIndices',[]);
addParameter(p,'Spacing',[1 1 1]);
parse(p,varargin{:}); o = p.Results;
validateattributes(o.Radius,{'numeric'},{'real','finite','scalar','positive'});
validateattributes(o.MaxNeighbors,{'numeric'},{'integer','finite','scalar','positive'});
validateattributes(o.MinAbsDot,{'numeric'},{'real','finite','scalar','>=',0,'<=',1});
validateattributes(o.MaxNormalOffset,{'numeric'},{'real','finite','scalar','>=',0,'<=',1});
n = size(points,1); refs = o.ReferenceDirections;
if isempty(refs) && ~isempty(o.SourceMask)
    if numel(o.SourceIndices) ~= n
        error('objectgeometry:SurfaceIndices','Supply one SourceIndices entry per point.');
    end
    refs = farmSurfaceBoundaryDirections(o.SourceMask,o.SourceIndices,'Spacing',o.Spacing);
end
if isempty(refs), refs = nan(n,3); end
validateattributes(refs,{'numeric'},{'real','size',[n,3]});
seeds = o.SeedIndices(:);
if ~isempty(seeds)
    validateattributes(seeds,{'numeric'},{'integer','finite','positive','<=',n});
end
lengths = sqrt(sum(double(normals).^2,2));
valid = all(isfinite(normals),2) & lengths > 0;
oriented = nan(n,3); oriented(valid,:) = double(normals(valid,:))./lengths(valid);
validIDs = find(valid); m = numel(validIDs); local = oriented(valid,:);
group = zeros(n,1); rootIDs = zeros(0,1); referenced = false(0,1);
edgeCount = 0;
if m > 0
    [ids,dist] = farmSurfaceKNN(points(valid,:),points(valid,:),o.MaxNeighbors+1);
    a = repmat((1:m).',1,size(ids,2)); b = ids;
    keep = a ~= b & dist > 0 & dist <= o.Radius;
    a = a(keep); b = b(keep); d = dist(keep);
    delta = (points(validIDs(b),:) - points(validIDs(a),:))./d;
    agreement = abs(sum(local(a,:).*local(b,:),2));
    offset = max(abs(sum(delta.*local(a,:),2)),abs(sum(delta.*local(b,:),2)));
    keep = agreement >= o.MinAbsDot & offset <= o.MaxNormalOffset;
    pairs = sort([a(keep),b(keep)],2);
    [pairs,first] = unique(pairs,'rows');
    costs = 1-agreement(keep)+offset(keep)+eps;
    costs = costs(first); edgeCount = size(pairs,1);
    g = graph(pairs(:,1),pairs(:,2),costs,m);
    forest = minspantree(g,'Type','forest');
    groups = conncomp(forest).'; group(validIDs) = groups;
    links = adjacency(forest) ~= 0;
    seen = false(m,1);
    for gInd = 1:max(groups)
        members = find(groups == gInd);
        preferred = seeds(ismember(seeds,validIDs(members)));
        if ~isempty(preferred)
            root = find(validIDs == preferred(1),1);
        else
            r = refs(validIDs(members),:);
            mag = sqrt(sum(r.^2,2));
            score = abs(sum(local(members,:).*r,2))./mag;
            score(~isfinite(score)) = -1;
            [~,best] = max(score); root = members(best);
        end
        rootIDs(gInd,1) = validIDs(root);
        ref = refs(validIDs(root),:); agreement = dot(local(root,:),ref);
        referenced(gInd,1) = all(isfinite(ref)) && norm(ref)>0 && abs(agreement)>1e-8*norm(ref);
        if referenced(gInd)
            if agreement < 0, local(root,:) = -local(root,:); end
        else
            [~,axisInd] = max(abs(local(root,:)));
            if local(root,axisInd)<0, local(root,:) = -local(root,:); end
        end
        queue = zeros(numel(members),1); queue(1) = root;
        seen(root) = true; head = 1; tail = 1;
        while head <= tail
            parent = queue(head); head = head+1;
            children = find(links(:,parent)); children = children(~seen(children));
            flip = local(children,:)*local(parent,:).' < 0;
            local(children(flip),:) = -local(children(flip),:);
            seen(children) = true;
            queue(tail+(1:numel(children))) = children; tail = tail+numel(children);
        end
    end
    oriented(valid,:) = local;
end
flipped = false(n,1); flipped(valid) = sum(oriented(valid,:).*normals(valid,:),2)<0;
% Do not retain another source-volume reference in returned options.
o = rmfield(o,{'SourceMask','SourceIndices'});
info = struct('Group',group,'SeedIndices',rootIDs,'Referenced',referenced, ...
    'Flipped',flipped,'Valid',valid,'AcceptedEdgeCount',edgeCount,'Options',o);
end
