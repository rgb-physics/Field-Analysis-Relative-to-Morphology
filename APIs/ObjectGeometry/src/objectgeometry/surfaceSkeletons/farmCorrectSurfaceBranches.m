function [points, info] = farmCorrectSurfaceBranches(inputPoints, sourceMask, options)
%FARMCORRECTSURFACEBRANCHES Query and remove small/redundant surface branches.
% Inputs:
%   inputPoints   N-by-3 unique physical XYZ voxel centers inside sourceMask;
%                 zeros(0,3) is accepted. Point order is preserved.
%   sourceMask    Binary YXZ object volume on an isotropic grid.
%   options       Scalar struct: Method='both'|'extent'|'support';
%                 Spacing=[1 1 1] YXZ; Origin=[1 1 1] XYZ;
%                 Faces=[] or M-by-3 point-row indices;
%                 MaxExtent=10 in physical units;
%                 MaxUniqueSupportFraction=0.05; MaxTotalLossFraction=0.01;
%                 ProtectedPointIndices=[]; Apply=true; Verbose=false.
% Outputs:
%   points        Subset of original points; no fitted plane or moved points.
%   info          Scalar result struct: Patches is a per-patch measurement table;
%                 InputKept maps output rows to input rows; OutputIndices maps
%                 those rows to sourceMask. See glossary Branch correction result.
%
% See also farmPruneSurface, farmMaskToPoints, farmGlossary

if nargin < 3
    options = struct();
end

defaults = struct('Method', 'both', 'Spacing', [1 1 1], 'Origin', [1 1 1], ...
    'Faces', [], 'MaxExtent', 10, 'MaxUniqueSupportFraction', 0.05, ...
    'MaxTotalLossFraction', 0.01, 'ProtectedPointIndices', [], 'Apply', true, 'Verbose', false);
o = farmParseOptions(defaults, options);
o.Method = validatestring(o.Method, {'extent', 'support', 'both'});

% Validate editable options before allocating source-sized distance fields.
validateattributes(o.Spacing, {'numeric'}, {'real', 'finite', 'positive', 'numel', 3});
validateattributes(o.Origin, {'numeric'}, {'real', 'finite', 'numel', 3});
validateattributes(o.MaxExtent, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'});
validateattributes(o.MaxUniqueSupportFraction, {'numeric'}, {'scalar', 'real', 'finite', '>=', 0, '<=', 1});
validateattributes(o.MaxTotalLossFraction, {'numeric'}, {'scalar', 'real', 'finite', '>=', 0, '<=', 1});
validateattributes(o.Apply, {'logical'}, {'scalar'});
validateattributes(o.Verbose, {'logical'}, {'scalar'});
started = tic;

validateattributes(sourceMask, {'logical', 'numeric'}, {'real', 'finite', 'nonempty', 'nonsparse'});
if ndims(sourceMask) ~= 3 || any(sourceMask(:) ~= 0 & sourceMask(:) ~= 1)
    error('objectgeometry:BranchMask', 'Use one binary YXZ source object. See glossary Support.');
end

spacing = double(o.Spacing(:).');
origin = double(o.Origin(:).');
if max(spacing) - min(spacing) > 1e-10 * max(spacing)
    error('objectgeometry:BranchAnisotropy', ...
        'Use an explicitly resampled isotropic object/support. See glossary Grid.');
end

inputPoints = farmSurfacePoints(inputPoints);
n = size(inputPoints, 1);
if ~isempty(o.ProtectedPointIndices)
    validateattributes(o.ProtectedPointIndices, {'numeric'}, {'vector', 'integer', 'positive', '<=', n});
end

% Convert calibrated XYZ points to one-based XYZ voxel coordinates, not YXZ.
voxel = (inputPoints - origin) ./ spacing([2 1 3]) + 1;
xyz = round(voxel);
sz = size(sourceMask);
if any(abs(voxel - xyz) > 1e-6, 'all') || any(xyz < 1 | xyz > sz([2 1 3]), 'all')
    error('objectgeometry:BranchGrid', ...
        'Points must be voxel centers on the supplied source grid. See glossary Grid.');
end

% Convert XYZ coordinate columns to YXZ subscripts for array indexing.
indices = sub2ind(sz, xyz(:, 2), xyz(:, 1), xyz(:, 3));
sourceMask = logical(sourceMask);
if numel(unique(indices)) ~= n || any(~sourceMask(indices))
    error('objectgeometry:BranchPoints', ...
        'Use unique points inside sourceMask. See glossary Point cloud.');
end

% Radii are voxel-center clearances; one padded background layer handles edges.
padded = padarray(sourceMask, [1 1 1], false, 'both');
distance = bwdist(~padded);
distance = distance(2:end - 1, 2:end - 1, 2:end - 1);
radii = double(distance(indices));

faces = o.Faces;
if isempty(faces)
    if o.Verbose
        fprintf('Branch correction: preparing surface connectivity for %d points.\n', n);
    end
    % Shared lattice preparation, also used by the experimental ET operation.
    [faces, preparation] = farmSurfaceVoxelComplex(xyz, sz, radii);
else
    preparation = struct('InputTetrahedronCount', 0, 'CollapsedTetrahedronCount', 0);
end

validateattributes(faces, {'numeric'}, {'real', 'finite', 'integer', 'positive', '2d'});
if size(faces, 2) ~= 3 || any(faces(:) > n)
    error('objectgeometry:BranchFaces', ...
        'Faces must be M-by-3 point-row indices. See glossary Mesh.');
end
faces = unique(sort(double(faces), 2), 'rows');
if o.Verbose
    fprintf('Branch correction: %d faces prepared in %.2f seconds.\n', size(faces, 1), toc(started));
end
if any(diff(faces, 1, 2) == 0, 'all')
    error('objectgeometry:BranchFaces', 'Faces require three distinct point rows.');
end

%% Split surface faces across nonmanifold branch edges
faceCount = size(faces, 1);
allEdges = [faces(:, [1 2]); faces(:, [1 3]); faces(:, [2 3])];
[edges, ~, edgeIds] = unique(allEdges, 'rows');
if isempty(edges)
    edgeDegree = zeros(0, 1);
    edgeFaces = cell(0, 1);
else
    edgeDegree = accumarray(edgeIds, 1, [size(edges, 1), 1]);
    edgeFaces = accumarray(edgeIds, repmat((1:faceCount).', 3, 1), ...
        [size(edges, 1), 1], @(x) {x});
end
seamEdges = edges(edgeDegree > 2, :);
seamVertices = unique(seamEdges(:));
joins = zeros(nnz(edgeDegree == 2), 2);
joinInd = 0;
for edgeInd = find(edgeDegree == 2).'
    joinInd = joinInd + 1;
    joins(joinInd, :) = edgeFaces{edgeInd}.';
end
if faceCount > 0
    facePatch = conncomp(graph(joins(:, 1), joins(:, 2), [], faceCount)).';
    patchCount = max(facePatch);
else
    facePatch = zeros(0, 1);
    patchCount = 0;
end
seamLabels = zeros(n, 1);
if ~isempty(seamEdges)
    [seamNodes, ~, localEdges] = unique(seamEdges(:));
    localEdges = reshape(localEdges, size(seamEdges));
    labels = conncomp(graph(localEdges(:, 1), localEdges(:, 2), [], numel(seamNodes)));
    seamLabels(seamNodes) = labels;
end
freeVertices = unique(edges(edgeDegree == 1, :));
patchVertices = cell(patchCount, 1);
vertexUse = zeros(n, 1);
for patchInd = 1:patchCount
    patchVertices{patchInd} = unique(faces(facePatch == patchInd, :));
    vertexUse(patchVertices{patchInd}) = vertexUse(patchVertices{patchInd}) + 1;
end
if o.Verbose
    fprintf('Branch correction: %d patches and %d seam edges; measuring extent.\n', ...
        patchCount, size(seamEdges, 1));
end
% Shared seam/contact points and points outside the face complex stay fixed.
fixed = vertexUse ~= 1;
fixed(seamVertices) = true;
protected = false(n, 1);
protected(o.ProtectedPointIndices) = true;
pointPatch = zeros(n, 1);
area = zeros(patchCount, 1);
extent = inf(patchCount, 1);
seamCount = zeros(patchCount, 1);
hasBorder = false(patchCount, 1);
isProtected = false(patchCount, 1);
patchSeams = cell(patchCount, 1);
patchInterior = cell(patchCount, 1);
triangleArea = vecnorm(cross(inputPoints(faces(:, 2), :) - inputPoints(faces(:, 1), :), ...
    inputPoints(faces(:, 3), :) - inputPoints(faces(:, 1), :), 2), 2, 2) / 2;
if any(triangleArea == 0)
    error('objectgeometry:BranchFaces', 'Supply nondegenerate surface triangles.');
end
for patchInd = 1:patchCount
    vertices = patchVertices{patchInd};
    patchInterior{patchInd} = vertices(~fixed(vertices));
    pointPatch(patchInterior{patchInd}) = patchInd;
    seeds = intersect(vertices, seamVertices);
    border = intersect(vertices, freeVertices);
    patchSeams{patchInd} = unique(seamLabels(seeds));
    seamCount(patchInd) = numel(patchSeams{patchInd});
    hasBorder(patchInd) = ~isempty(border);
    isProtected(patchInd) = any(protected(vertices));
    area(patchInd) = sum(triangleArea(facePatch == patchInd));
    if ~isempty(seeds) && ~isempty(border)
        selectedFaces = faces(facePatch == patchInd, :);
        patchEdges = unique([selectedFaces(:, [1 2]); selectedFaces(:, [1 3]); ...
            selectedFaces(:, [2 3])], 'rows');
        % Local geodesics: one virtual source connects to every seam vertex.
        [~, localEdges] = ismember(patchEdges, vertices);
        [~, localSeeds] = ismember(seeds, vertices);
        [~, localBorder] = ismember(border, vertices);
        lengths = vecnorm(inputPoints(patchEdges(:, 1), :) - inputPoints(patchEdges(:, 2), :), 2, 2);
        virtual = numel(vertices) + 1;
        g = graph([localEdges(:, 1); repmat(virtual, numel(seeds), 1)], ...
            [localEdges(:, 2); localSeeds], [lengths; zeros(numel(seeds), 1)], virtual);
        geodesic = distances(g, virtual);
        extent(patchInd) = max(geodesic(localBorder));
    end
end

%% Measure actual marginal coverage of the source object by support balls
% Open balls use distance to background voxel centers. Coverage is a discrete
% representation test, not intensity evidence or an exact boundary fit.
coverage = zeros(sz, 'uint32');
fixedCoverage = localCoverage(sz, indices(fixed), radii(fixed), sourceMask);
coverage(fixedCoverage) = 1;
footprints = cell(patchCount, 1);
for patchInd = 1:patchCount
    rows = patchInterior{patchInd};
    if o.Verbose && (patchInd == 1 || mod(patchInd, 100) == 0)
        fprintf('Branch correction: source coverage for patch %d/%d (%.2f seconds elapsed).\n', ...
            patchInd, patchCount, toc(started));
    end
    footprints{patchInd} = localCoverage(sz, indices(rows), radii(rows), sourceMask);
    coverage(footprints{patchInd}) = coverage(footprints{patchInd}) + 1;
end
initialCovered = nnz(coverage);
sourceCount = nnz(sourceMask);
uniqueCount = zeros(patchCount, 1);
supportFraction = zeros(patchCount, 1);
for patchInd = 1:patchCount
    footprint = footprints{patchInd};
    uniqueCount(patchInd) = nnz(coverage(footprint) == 1);
    supportFraction(patchInd) = uniqueCount(patchInd) / max(1, numel(footprint));
end
candidate = seamCount == 1 & hasBorder & ~isProtected;
if any(strcmp(o.Method, {'extent', 'both'}))
    candidate = candidate & extent <= o.MaxExtent;
end
if any(strcmp(o.Method, {'support', 'both'}))
    candidate = candidate & supportFraction <= o.MaxUniqueSupportFraction;
end

%% Apply sequential decisions while retaining two branches at each seam
removed = false(patchCount, 1);
wouldRemove = false(patchCount, 1);
decisionLoss = nan(patchCount, 1);
reason = repmat("not eligible", patchCount, 1);
reason(isProtected) = "protected";
reason(seamCount > 1) = "multiple attachment seams";
reason(seamCount == 0) = "no attachment seam";
lost = 0;
ranking = find(candidate);
if strcmp(o.Method, 'support')
    [~, order] = sortrows([supportFraction(ranking), extent(ranking), area(ranking)]);
else
    [~, order] = sortrows([extent(ranking), supportFraction(ranking), area(ranking)]);
end
ranking = ranking(order);
for patchInd = ranking(:).'
    seam = patchSeams{patchInd};
    incident = cellfun(@(x) any(ismember(x, seam)), patchSeams);
    if nnz(~wouldRemove(incident)) <= 2
        reason(patchInd) = "retain two seam branches";
        continue
    end
    footprint = footprints{patchInd};
    marginal = nnz(coverage(footprint) == 1);
    decisionLoss(patchInd) = marginal;
    fraction = marginal / max(1, numel(footprint));
    if any(strcmp(o.Method, {'support', 'both'})) && fraction > o.MaxUniqueSupportFraction
        reason(patchInd) = "support became unique after earlier removal";
        continue
    end
    if (lost + marginal) / max(1, sourceCount) > o.MaxTotalLossFraction
        reason(patchInd) = "total source loss limit";
        continue
    end
    coverage(footprint) = coverage(footprint) - 1;
    lost = lost + marginal;
    wouldRemove(patchInd) = true;
    reason(patchInd) = "selected";
end
if o.Apply
    removed = wouldRemove;
end
kept = true(n, 1);
for patchInd = find(removed).'
    rows = patchInterior{patchInd};
    kept(rows(~protected(rows))) = false;
end
points = inputPoints(kept, :);
patches = table((1:patchCount).', cellfun(@numel, patchInterior), area, extent, ...
    seamCount, hasBorder, isProtected, cellfun(@numel, footprints), uniqueCount, ...
    supportFraction, candidate, decisionLoss, wouldRemove, removed, reason, ...
    'VariableNames', {'PatchID', 'InteriorPointCount', 'Area', 'Extent', ...
    'AttachmentSeamCount', 'HasFreeBorder', 'Protected', 'CoveredVoxels', ...
    'UniqueSupportVoxels', 'UniqueSupportFraction', 'Candidate', ...
    'DecisionLossVoxels', 'WouldRemove', 'Removed', 'Reason'});
info = struct('Options', o, 'InputKept', kept, 'OutputIndices', indices(kept), ...
    'InputFaces', faces, 'FacePatch', facePatch, 'PointPatch', pointPatch, ...
    'SeamEdges', seamEdges, 'SeamPointIndices', seamVertices, 'Patches', patches, ...
    'MeshPreparation', preparation, 'SourceVoxelCount', sourceCount, ...
    'InitiallyCoveredVoxels', initialCovered, 'InitialCoverageFraction', ...
    initialCovered / max(1, sourceCount), 'ProposedLostVoxels', lost, ...
    'ProposedLossFraction', lost / max(1, sourceCount), ...
    'AppliedLostVoxels', lost * double(o.Apply), 'TopologyPreserved', false);
info.ElapsedSeconds = toc(started);
if o.Verbose
    fprintf('Branch correction complete: %.2f seconds, %d proposed cuts.\n', ...
        info.ElapsedSeconds, nnz(wouldRemove));
end
end

function indices = localCoverage(sz, sites, radii, sourceMask)
%LOCALCOVERAGE Internal raster union of one patch's open support balls.
% sz is YXZ; sites are source linear indices; radii are in voxel units.
% Return unique source indices inside sourceMask, or a 0-by-1 empty vector.
% Crop to the ball bounds and group equal radii to share dilation kernels.
if isempty(sites)
    indices = zeros(0, 1);
    return
end

[y, x, z] = ind2sub(sz, sites);
yxz = [y x z];
reach = ceil(max(radii));
low = max(1, min(yxz, [], 1) - reach);
high = min(sz, max(yxz, [], 1) + reach);
localSize = high - low + 1;
localPoints = yxz - low + 1;
localSites = sub2ind(localSize, localPoints(:, 1), localPoints(:, 2), localPoints(:, 3));

covered = false(localSize);
[levels, ~, groups] = unique(radii);
for radiusInd = 1:numel(levels)
    radius = levels(radiusInd);
    reach = ceil(radius);
    [dy, dx, dz] = ndgrid(-reach:reach, -reach:reach, -reach:reach);
    kernel = dx.^2 + dy.^2 + dz.^2 < radius^2;
    seeds = false(localSize);
    seeds(localSites(groups == radiusInd)) = true;
    covered = covered | imdilate(seeds, kernel);
end

[y, x, z] = ind2sub(localSize, find(covered));
yxz = [y x z] + low - 1;
indices = sub2ind(sz, yxz(:, 1), yxz(:, 2), yxz(:, 3));
indices = indices(sourceMask(indices));
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Application-specific branch heuristics, not a published ET/SAT algorithm.
% Faces with exactly two incident triangles connect patches; edges with more
% than two triangles are seams. Seam edges connected at vertices form one seam.
% Patches touching multiple seams, without free borders, or containing protected
% point rows are not removable. Every affected seam retains at least two patches.
% These restrictions do NOT prove global topology or main-ribbon preservation.
% The two remaining branches are not chosen by a normal-continuation test.
%
% Extent is maximum shortest path along patch edges from any seam point to a
% free-border point. Support is marginal SOURCE voxel coverage by discrete open
% balls centered at original support points, with padded background distances
% as radii. Shared vertices stay fixed. Overlapping patch coverages are counted
% separately; support losses are recomputed after each proposed removal.
% MaxUniqueSupportFraction is relative to each patch's covered source voxels;
% MaxTotalLossFraction is relative to ALL source object voxels and applies to
% every method. Initial missing coverage is reported separately from new loss.
%
% Apply=false returns unchanged points and reports WouldRemove/ProposedLoss.
% Faces=[] uses the same approximate lattice adapter as ET; mesh artifacts can
% create or miss seams. Explicit reviewed connectivity can be supplied instead.
% Points without faces and shared seam points are retained. No global plane,
% height cutoff, normal smoothing, hole filling, or point displacement is used.
%
% Empty input and curve-only supports return unchanged points and an empty
% Patches table. Isolated no-seam surfaces are retained. NaN DecisionLossVoxels
% means marginal loss was not evaluated during selection, not zero loss.
% TopologyPreserved=false records the absence of a topology guarantee; it is
% not a measured topology-change flag. No intensity-field sampling is performed.
%
% EXAMPLES
% -------------------------------------------------------------------------
% Query a calibrated medial support without changing it:
% opts = struct('Spacing', grid.Spacing, 'Origin', grid.Origin, ...
%     'Method', 'both', 'MaxExtent', 12, 'Apply', false);
% [unchanged, preview] = farmCorrectSurfaceBranches(points, objectMask, opts);
% preview.Patches(:, {'PatchID','Extent','UniqueSupportFraction','WouldRemove'})
%
% Apply source-support correction with reviewed mesh connectivity:
% opts = struct('Spacing', grid.Spacing, 'Origin', grid.Origin, ...
%     'Faces', faces, 'Method', 'support', 'MaxUniqueSupportFraction', 0.05, ...
%     'MaxTotalLossFraction', 0.01, 'ProtectedPointIndices', protectedRows);
% [corrected, result] = farmCorrectSurfaceBranches(points, objectMask, opts);
%
% MATCHING RESULTS
% -------------------------------------------------------------------------
% corrected = inputPoints(info.InputKept,:). OutputIndices addresses sourceMask
% in the same output-row order. Faces and SeamEdges always index ORIGINAL point
% rows, even after cuts. PointPatch and FacePatch align with original point rows
% and InputFaces rows, respectively. PatchID is local to one call/mesh, not a
% DatasetID/Frame/ObjectID and not a persistent identity between method runs.
% Fixed/shared/unmeshed points have PointPatch=0. Preserve source object/frame
% identity separately when collecting results across datasets or acquisitions.
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Physical points/origin are XYZ, masks and spacing YXZ. Area uses squared
% physical units; extent uses physical units; coverage uses source voxel counts.
% Origin is the physical XYZ position of voxel CENTER (1,1,1), not a lower edge.
%
% COST AND DEPENDENCIES
% -------------------------------------------------------------------------
% Requires Image Processing Toolbox; graph operations are native MATLAB. Full
% source-sized distance/coverage arrays and a lattice index map are allocated.
% Per-patch footprints can contain overlapping source indices; their total
% storage can exceed nnz(sourceMask). Extent queries build one local graph per
% patch. Support queries run even for Method='extent' to enforce the total-loss
% budget and return comparable measurements. Verbose=true reports phases and
% every 100 coverage queries. ElapsedSeconds is wall time, not peak memory.
% The 105714-point frame-35 preview was interrupted before completion; no full-
% frame performance or real-data acceptance claim is made.
