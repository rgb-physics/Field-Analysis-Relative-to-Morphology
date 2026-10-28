function [surface, info] = farmMedialSurface(mask, varargin)
%FARMMEDIALSURFACE Parallel six-direction surface thinning on a cubic lattice.
% Inputs:
%   mask           One binary YXZ volume, including one-voxel-thick layers.
%   MaxIterations  Maximum complete six-direction cycles; default Inf.
%   Spacing        [dY dX dZ], default [1 1 1]; must be isotropic.
% Outputs:
%   surface        Logical surface skeleton, subset of mask on the SAME grid.
%   info           Method/provenance, iterations, convergence and voxel counts.
% Exterior is background (one padded voxel). Image-edge material can thin.
% No patching, pruning, mesh construction, or distance cutoff is applied.
% This is a digital approximation, not an exact Euclidean medial axis.
%
% Implements P-6-SI-2, NOT Palagyi's 2002 three-subiteration algorithm.
% Palagyi, Nemeth, Kardos (2015), Equivalent Sequential and Parallel
% Subiteration-Based Surface-Thinning Algorithms, IWCIA, LNCS 9448, 31-45.
% https://doi.org/10.1007/978-3-319-26145-4_3
% Verified transcription source: Palagyi (2019), Topology Preservation and
% Thinning, section 3.3, Definition 3.3.2, Algorithm 11, Figure 3.9.
% https://www.inf.u-szeged.hu/~palagyi/PK_MTAdissertation.pdf
% Each subiteration protects voxels with an opposite pair of white face
% neighbors. Template d requires a white d-neighbor and black opposite
% neighbor in the constraint set, plus the v/w and v/x/y implications below.
% The opposite neighbor is constrained because its d-neighbor is p (black).
% Candidates are tested against an unchanged subiteration snapshot; deletion
% is simultaneous. Array operations are vectorized; no Parallel Toolbox needed.
p = inputParser; addParameter(p,'MaxIterations',Inf);
addParameter(p,'Spacing',[1 1 1]); parse(p,varargin{:}); o = p.Results;
validateattributes(mask,{'logical','numeric'},{'real','finite','nonsparse'});
if ndims(mask)>3 || any(mask(:)~=0 & mask(:)~=1)
    error('objectgeometry:InvalidMask','Provide one binary YXZ volume.');
end
validateattributes(o.MaxIterations,{'numeric'},{'real','scalar','positive'});
if ~(isinf(o.MaxIterations) || (isfinite(o.MaxIterations) && fix(o.MaxIterations)==o.MaxIterations))
    error('objectgeometry:SurfaceIterations','MaxIterations must be a positive integer or Inf.');
end
spacing = double(o.Spacing(:).');
validateattributes(spacing,{'numeric'},{'real','finite','positive','numel',3});
if max(spacing)-min(spacing) > 1e-10*max(spacing)
    error('objectgeometry:SurfaceAnisotropy', ...
        ['This lattice-thinning method requires isotropic voxels. Explicitly ' ...
         'resample upstream and preserve the grid transform; scaling output ' ...
         'coordinates alone does not correct anisotropic thinning.']);
end
work = padarray(logical(mask),[1 1 1],false,'both');
strides = [1,size(work,1),size(work,1)*size(work,2)];
% U,D,N,E,S,W, expressed in array YXZ coordinates (U is increasing Z).
directions = [3 1;3 -1;1 -1;2 1;1 1;2 -1];
active = find(work); originalCount = numel(active); iteration = 0;
removed = zeros(0,1); converged = isempty(active);
while ~converged && iteration < o.MaxIterations
    iteration = iteration+1; deleted = 0;
    for dInd = 1:6
        axisDim = directions(dInd,1); step = directions(dInd,2)*strides(axisDim);
        candidates = active(~work(active+step) & work(active-step));
        if isempty(candidates), continue; end
        % Type-2 surface endpoints: preserve any opposing white face pair.
        protected = false(size(candidates));
        for dimInd = 1:3
            s = strides(dimInd);
            protected = protected | (~work(candidates+s) & ~work(candidates-s));
        end
        candidates = candidates(~protected);
        if isempty(candidates), continue; end
        tangential = setdiff(1:3,axisDim,'stable');
        a = strides(tangential(1)); b = strides(tangential(2));
        % Four face positions v, cyclically arranged in p's tangent plane.
        % x(k+1) is the corner between v(k) and v(k+1).
        v = [a,b,-a,-b]; next = [2 3 4 1];
        deletable = true(size(candidates));
        for k = 1:4
            vBlack = work(candidates+v(k));
            wBlack = work(candidates+v(k)+step);
            deletable = deletable & (vBlack | ~wBlack);
            corner = v(k)+v(next(k));
            tripleWhite = ~vBlack & ~work(candidates+corner) & ...
                ~work(candidates+v(next(k)));
            deletable = deletable & (~tripleWhite | ~work(candidates+corner+step));
        end
        drop = candidates(deletable);
        work(drop) = false; deleted = deleted+numel(drop);
        active = active(work(active));
    end
    removed(iteration,1) = deleted;
    converged = deleted == 0;
end
surface = work(2:end-1,2:end-1,2:end-1);
info = struct('Method','P-6-SI-2','ReferenceDOI','10.1007/978-3-319-26145-4_3', ...
    'Iterations',iteration,'Converged',converged,'DeletedPerIteration',removed, ...
    'InputVoxelCount',originalCount,'OutputVoxelCount',nnz(surface), ...
    'Spacing',spacing,'Exterior','background');
end
