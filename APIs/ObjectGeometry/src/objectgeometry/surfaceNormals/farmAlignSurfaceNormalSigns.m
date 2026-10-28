function [aligned, info] = farmAlignSurfaceNormalSigns(normals, previousNormals, groups, matches, varargin)
%FARMALIGNSURFACENORMALSIGNS Flip whole spatial groups using supplied matches.
% Correspondence is computed separately by farmMatchSurfaceFrames or caller.
% groups is the Group output of farmOrientSurfaceNormals (0 means unavailable).
% Optional Weights are per match (default ones); MinAgreement=0.25 is the
% minimum |weighted signed agreement| / weighted absolute agreement.
% MinMatches=3. Weak/insufficient groups retain their input signs and are
% marked unresolved. No smoothing, re-estimation or pointwise flips occur.
% matches.Rotation rotates previous normal rows into the current frame.
validateattributes(normals,{'numeric'},{'real','2d','ncols',3});
validateattributes(previousNormals,{'numeric'},{'real','2d','ncols',3});
validateattributes(groups,{'numeric'},{'integer','finite','nonnegative','column','numel',size(normals,1)});
if ~isstruct(matches)||~isscalar(matches)||~all(isfield(matches,{'CurrentIndices','PreviousIndices'}))
    error('objectgeometry:SurfaceMatches','Provide a scalar correspondence struct.');
end
ci = matches.CurrentIndices(:); pi = matches.PreviousIndices(:);
if numel(ci) ~= numel(pi), error('objectgeometry:SurfaceMatches','Match index counts must agree.'); end
if ~isempty(ci)
    validateattributes(ci,{'numeric'},{'integer','finite','positive','<=',size(normals,1)});
    validateattributes(pi,{'numeric'},{'integer','finite','positive','<=',size(previousNormals,1)});
end
p = inputParser; addParameter(p,'Weights',ones(numel(ci),1));
addParameter(p,'MinAgreement',0.25); addParameter(p,'MinMatches',3);
parse(p,varargin{:}); o = p.Results;
validateattributes(o.Weights,{'numeric'},{'real','finite','nonnegative','numel',numel(ci)});
validateattributes(o.MinAgreement,{'numeric'},{'real','finite','scalar','>=',0,'<=',1});
validateattributes(o.MinMatches,{'numeric'},{'integer','finite','positive','scalar'});
rotation = eye(3);
if isfield(matches,'Rotation'), rotation = matches.Rotation; end
validateattributes(rotation,{'numeric'},{'real','finite','size',[3 3]});
if norm(rotation.'*rotation-eye(3),'fro')>1e-8 || abs(det(rotation)-1)>1e-8
    error('objectgeometry:SurfaceRotation','Match Rotation must be proper orthogonal.');
end
a = double(normals(ci,:)); b = double(previousNormals(pi,:))*rotation.';
la = sqrt(sum(a.^2,2)); lb = sqrt(sum(b.^2,2));
dots = sum(a.*b,2)./(la.*lb); w = o.Weights(:);
valid = isfinite(dots) & abs(dots)>1e-8 & w>0;
ids = unique(groups(groups>0)); aligned = normals;
score = zeros(numel(ids),1); agreement = score; counts = score;
resolved = false(numel(ids),1); flipped = resolved;
for gInd = 1:numel(ids)
    sel = valid & groups(ci) == ids(gInd);
    counts(gInd) = nnz(sel);
    score(gInd) = sum(w(sel).*dots(sel));
    total = sum(w(sel).*abs(dots(sel)));
    if total>0, agreement(gInd) = abs(score(gInd))/total; end
    resolved(gInd) = counts(gInd)>=o.MinMatches && total>0 && ...
        agreement(gInd)>=o.MinAgreement && score(gInd)~=0;
    if resolved(gInd) && score(gInd)<0
        aligned(groups == ids(gInd),:) = -aligned(groups == ids(gInd),:);
        flipped(gInd) = true;
    end
end
info = struct('Group',ids,'MatchCount',counts,'Score',score, ...
    'Agreement',agreement,'Resolved',resolved,'Flipped',flipped,'Options',o);
end
