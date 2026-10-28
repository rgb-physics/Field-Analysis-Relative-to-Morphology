function [points, info] = farmPruneSurface(inputPoints, sourceMask, options)
%FARMPRUNESURFACE Experimental ET filtering or rasterized scale-axis processing.
% Inputs:
%   inputPoints   N-by-3 physical XYZ voxel centers of the selected support.
%   sourceMask    Binary YXZ object volume containing that support.
%   options       Scalar struct: Method='ET'|'SAT'; Spacing=[1 1 1] YXZ;
%                 Origin=[1 1 1] physical XYZ of voxel (1,1,1);
%                 ETThreshold=0 in physical units; Faces=[] or M-by-3 rows
%                 indexing inputPoints; ETSubdivisions=0;
%                 Scale=1.2; MaxVoxels=5e7; ReturnReconstruction=false.
% Outputs:
%   points        ET: subset of inputPoints. SAT: newly calculated centers.
%   info          Method, approximation, calibration and correspondence details.
%
% See also farmMedialSurface, farmMaskToPoints, farmSkel3Dfrom2D

if nargin < 3
    options = struct();
end

defaults = struct('Method', 'ET', 'Spacing', [1 1 1], 'Origin', [1 1 1], ...
    'ETThreshold', 0, 'Faces', [], 'ETSubdivisions', 0, 'Scale', 1.2, ...
    'MaxVoxels', 5e7, 'ReturnReconstruction', false);
o = farmParseOptions(defaults, options);
o.Method = validatestring(o.Method, {'ET', 'SAT'});
validateattributes(o.Spacing, {'numeric'}, {'real', 'finite', 'positive', 'numel', 3});
validateattributes(o.Origin, {'numeric'}, {'real', 'finite', 'numel', 3});
validateattributes(o.ETThreshold, {'numeric'}, {'real', 'finite', 'scalar', 'nonnegative'});
validateattributes(o.ETSubdivisions, {'numeric'}, {'scalar', 'integer', '>=', 0, '<=', 3});
validateattributes(o.Scale, {'numeric'}, {'real', 'finite', 'scalar', '>=', 1});
validateattributes(o.MaxVoxels, {'numeric'}, {'real', 'finite', 'integer', 'positive', 'scalar'});
validateattributes(o.ReturnReconstruction, {'logical'}, {'scalar'});
validateattributes(sourceMask, {'logical', 'numeric'}, {'real', 'finite', 'nonempty', 'nonsparse'});
if ndims(sourceMask) ~= 3 || any(sourceMask(:) ~= 0 & sourceMask(:) ~= 1)
    error('objectgeometry:PruningMask', 'Source mask must be one binary YXZ volume.');
end

spacing = double(o.Spacing(:).');
origin = double(o.Origin(:).');
if max(spacing) - min(spacing) > 1e-10 * max(spacing)
    error('objectgeometry:PruningAnisotropy', ...
        'Explicitly resample the object and support onto an isotropic grid before pruning.');
end

inputPoints = farmSurfacePoints(inputPoints);
sourceMask = logical(sourceMask);
voxel = (inputPoints - origin) ./ spacing([2 1 3]) + 1;
rounded = round(voxel);
sz = size(sourceMask);
if any(abs(voxel(:) - rounded(:)) > 1e-6) || ...
        any(rounded < 1 | rounded > sz([2 1 3]), 'all')
    error('objectgeometry:PruningGrid', ...
        'Input points must be voxel centers inside sourceMask on the supplied Grid calibration.');
end
indices = sub2ind(sz, rounded(:, 2), rounded(:, 1), rounded(:, 3));
if any(~sourceMask(indices)) || numel(unique(indices)) ~= numel(indices)
    error('objectgeometry:PruningSupport', ...
        'Use unique points inside the source object; preserve point/face row correspondence.');
end

info = struct('Method', o.Method, 'Options', o, 'Spacing', spacing, ...
    'Origin', origin, 'InputIndices', indices, 'InputPointCount', numel(indices), ...
    'TopologyPreserved', false, 'InputKept', false(numel(indices), 1));
if isempty(indices)
    points = inputPoints;
    info.OutputPointCount = 0;
    return
end

% Native distance calculation: pad with background, including at image edges.
% Radii measure distance to background voxel CENTERS, not a fitted interface.
radiusTimer = tic;
radiusField = localRadius(sourceMask) * spacing(1);
radii = double(radiusField(indices));
info.SourceRadiusSeconds = toc(radiusTimer);
switch o.Method
    case 'ET'
        faces = o.Faces;
        if isempty(faces)
            % Local representation step: use only Freudenthal lattice triangles.
            [faces, preparation] = farmSurfaceVoxelComplex(rounded, sz, radii);
            meshSource = 'Freudenthal complex with tetrahedron/free-face collapses';
        else
            meshSource = 'supplied triangle complex';
            preparation = struct('InputTetrahedronCount', 0, ...
                'CollapsedTetrahedronCount', 0, 'LowerDimensionalPointCount', 0);
        end
        faces = localValidateFaces(inputPoints, faces, isempty(o.Faces));
        info.InputFaces = faces;
        info.MeshPreparation = preparation;
        samplePoints = inputPoints;
        sampleRadii = radii;
        for subdivisionInd = 1:o.ETSubdivisions
            [samplePoints, sampleRadii, faces] = localSubdivide(samplePoints, sampleRadii, faces);
        end

        % ET: graph-restricted sector burning, following Yan et al. Figure 8.
        [burnTime, sectorCount] = localBurn(samplePoints, sampleRadii, faces);
        et = burnTime(1:size(inputPoints, 1)) - radii;
        kept = et >= o.ETThreshold;
        points = inputPoints(kept, :);
        info.InputKept = kept;
        info.OutputIndices = indices(kept);
        info.Radii = radii;
        info.BurnTime = burnTime(1:size(inputPoints, 1));
        info.ErosionThickness = et;
        info.MeshSource = meshSource;
        info.FaceCount = size(faces, 1);
        info.SamplePointCount = size(samplePoints, 1);
        info.SectorCount = sectorCount;
        info.Approximation = ['ET on the supplied/generated triangle-edge graph; ' ...
            'not the continuous ET or the paper''s full Steiner graph. ' ...
            'Thresholding alone does not preserve topology or tubular branches.'];
    case 'SAT'
        if ~isempty(o.Faces) || o.ETSubdivisions ~= defaults.ETSubdivisions || o.ETThreshold ~= 0
            error('objectgeometry:PruningOptions', 'Faces and ET settings apply only to Method=ET.');
        end
        if o.Scale == 1
            points = inputPoints;
            info.InputKept(:) = true;
            info.OutputIndices = indices;
            info.Radii = radii;
            info.ScaleOneIdentity = true;
        else
            % Native raster SAT: grow support balls with a sufficient halo.
            halo = ceil(o.Scale * max(radii) / spacing(1)) + 2;
            workSize = sz + 2 * halo;
            if prod(double(workSize)) > o.MaxVoxels
                error('objectgeometry:PruningMemory', ...
                    'SAT needs a %s raster. Increase MaxVoxels or use a coarser grid.', mat2str(workSize));
            end
            shifted = rounded(:, [2 1 3]) + halo;
            sites = sub2ind(workSize, shifted(:, 1), shifted(:, 2), shifted(:, 3));
            growthTimer = tic;
            grown = localBalls(workSize, sites, o.Scale * radii / spacing(1));
            info.GrowthSeconds = toc(growthTimer);

            % FARM geometry: recompute the grown volume's medial surface.
            thinningTimer = tic;
            [newSurface, thinningInfo] = farmMedialSurface(grown, 'Spacing', spacing);
            info.ThinningSeconds = toc(thinningTimer);
            assert(thinningInfo.Converged, 'SAT medial thinning did not converge.');
            outputOrigin = origin - halo * spacing([2 1 3]);

            % FARM point preparation: preserve the halo's physical translation.
            preparationTimer = tic;
            [points, newIndices, newGrid] = farmMaskToPoints(newSurface, ...
                'Spacing', spacing, 'Origin', outputOrigin);
            grownRadius = localRadius(grown);
            % SAT shrink stage changes radii, not the recomputed ball centers.
            info.Radii = double(grownRadius(newIndices)) * spacing(1) / o.Scale;
            info.OutputPreparationSeconds = toc(preparationTimer);
            info.WorkingSize = workSize;
            info.OutputIndices = newIndices;
            info.OutputGrid = newGrid;
            info.InputKept = [];
            info.ThinningInfo = thinningInfo;
            info.GrownVoxelCount = nnz(grown);
            if o.ReturnReconstruction
                info.Reconstruction = localBalls(workSize, newIndices, info.Radii / spacing(1));
            end
        end
        info.Approximation = ['Rasterized SAT of balls at the selected support: grow, ' ...
            'recompute with FARM surface thinning, shrink new radii. Neither the ' ...
            'input nor recomputed support is an exact maximal-ball medial axis. ' ...
            'Output centers can move; no nearest-point filtering is substituted.'];
end

info.OutputPointCount = size(points, 1);
end

function radii = localRadius(mask)
padded = padarray(mask, [1 1 1], false, 'both');
distance = bwdist(~padded);
radii = distance(2:end - 1, 2:end - 1, 2:end - 1);
end

function mask = localBalls(sz, indices, radii)
% Group equal radii to avoid a separate full-volume dilation for every point.
mask = false(sz);
[levels, ~, groups] = unique(radii);
for radiusInd = 1:numel(levels)
    radius = levels(radiusInd);
    reach = ceil(radius);
    [y, x, z] = ndgrid(-reach:reach, -reach:reach, -reach:reach);
    % Open balls cannot include their defining nearest background centers.
    kernel = x.^2 + y.^2 + z.^2 < radius^2;
    centers = false(sz);
    centers(indices(groups == radiusInd)) = true;
    mask = mask | imdilate(centers, kernel);
end
end

function faces = localValidateFaces(points, faces, allowLowerDimensional)
validateattributes(faces, {'numeric'}, {'2d', 'real', 'finite', 'integer', 'positive'});
if size(faces, 2) ~= 3 || (~allowLowerDimensional && isempty(faces)) || any(faces(:) > size(points, 1))
    error('objectgeometry:PruningFaces', 'Faces must be a nonempty M-by-3 array indexing inputPoints.');
end
faces = unique(sort(double(faces), 2), 'rows');
if any(diff(faces, 1, 2) == 0, 'all')
    error('objectgeometry:PruningFaces', 'Each face must reference three distinct vertices.');
end
area = vecnorm(cross(points(faces(:, 2), :) - points(faces(:, 1), :), ...
    points(faces(:, 3), :) - points(faces(:, 1), :), 2), 2, 2);
if any(area == 0) || (~allowLowerDimensional && numel(unique(faces(:))) ~= size(points, 1))
    error('objectgeometry:PruningFaces', 'Use nondegenerate faces covering every input point.');
end
end

function [points, radii, faces] = localSubdivide(points, radii, faces)
edges = [faces(:, [1 2]); faces(:, [2 3]); faces(:, [1 3])];
[edges, ~, ids] = unique(sort(edges, 2), 'rows');
mid = reshape(ids, size(faces, 1), 3) + size(points, 1);
points = [points; (points(edges(:, 1), :) + points(edges(:, 2), :)) / 2];
radii = [radii; (radii(edges(:, 1)) + radii(edges(:, 2))) / 2];
faces = [faces(:, 1), mid(:, 1), mid(:, 3); ...
    mid(:, 1), faces(:, 2), mid(:, 2); ...
    mid(:, 3), mid(:, 2), faces(:, 3); mid];
end

function [burnTime, totalSectors] = localBurn(points, radii, faces)
% Each vertex link is a graph. Link paths between non-degree-two vertices,
% and closed link cycles, are sectors. An unburned sector is exposed exactly
% when it participates in no cycle of the remaining link graph (a bridge).
n = size(points, 1);
if isempty(faces)
    burnTime = radii;
    totalSectors = 0;
    return
end
incidence = accumarray(faces(:), repmat((1:size(faces, 1)).', 3, 1), [n 1], @(x) {x});
faceSector = zeros(size(faces));
sectorOwner = zeros(0, 1);
sectorEnds = cell(n, 1);
vertexSectors = cell(n, 1);
totalSectors = 0;
for vertexInd = 1:n
    faceIds = incidence{vertexInd};
    if isempty(faceIds)
        % ET measures sheet significance. Original points belonging only to
        % edges/vertices have zero sheet ET, rather than fabricated faces.
        vertexSectors{vertexInd} = zeros(1, 0);
        sectorEnds{vertexInd} = zeros(0, 2);
        continue
    end
    localFaces = faces(faceIds, :);
    % Build the opposite edge per face; preserve face row correspondence.
    link = zeros(numel(faceIds), 2);
    for faceInd = 1:numel(faceIds)
        link(faceInd, :) = localFaces(faceInd, localFaces(faceInd, :) ~= vertexInd);
    end
    [nodes, ~, linkIds] = unique(link(:));
    linkIds = reshape(linkIds, size(link));
    degree = accumarray(linkIds(:), 1, [numel(nodes), 1]);
    joins = zeros(0, 2);
    for nodeInd = find(degree == 2).'
        touching = find(any(linkIds == nodeInd, 2));
        joins(end + 1, :) = touching.'; %#ok<AGROW>
    end
    faceGroups = conncomp(graph(joins(:, 1), joins(:, 2), [], numel(faceIds)));
    count = max(faceGroups);
    ids = totalSectors + (1:count);
    vertexSectors{vertexInd} = ids;
    ends = zeros(count, 2);
    for sectorInd = 1:count
        selected = faceGroups == sectorInd;
        endpoints = linkIds(selected, :);
        occurrences = accumarray(endpoints(:), 1, [numel(nodes), 1]);
        tips = find(occurrences == 1);
        if isempty(tips)
            ends(sectorInd, :) = [0 0]; % A closed link cycle.
        elseif numel(tips) == 2
            ends(sectorInd, :) = tips.';
        else
            error('objectgeometry:PruningSectors', 'Invalid link sector at point %d.', vertexInd);
        end
        rows = faceIds(selected);
        for rowInd = rows(:).'
            faceSector(rowInd, faces(rowInd, :) == vertexInd) = ids(sectorInd);
        end
    end
    sectorEnds{vertexInd} = ends;
    sectorOwner(ids, 1) = vertexInd;
    totalSectors = totalSectors + count;
end

% A shared seam edge keeps a distinct arc for each pair of incident sectors.
arcS = [faceSector(:, 1); faceSector(:, 2); faceSector(:, 1)];
arcT = [faceSector(:, 2); faceSector(:, 3); faceSector(:, 3)];
arcs = unique([arcS arcT; arcT arcS], 'rows');
from = sectorOwner(arcs(:, 1));
to = sectorOwner(arcs(:, 2));
lengths = vecnorm(points(from, :) - points(to, :), 2, 2);
outgoing = accumarray(from, (1:numel(from)).', [n 1], @(x) {x});
sectorTime = inf(totalSectors, 1);
sectorBurned = false(totalSectors, 1);
burnTime = inf(n, 1);
nodeKey = inf(n, 1);
nodeBurned = false(n, 1);
queue = farmSurfacePriorityQueue();
for vertexInd = 1:n
    exposed = localExposed(sectorEnds{vertexInd}, false(numel(vertexSectors{vertexInd}), 1));
    if all(exposed)
        nodeKey(vertexInd) = radii(vertexInd);
        queue.Push(vertexInd, nodeKey(vertexInd));
    end
end

while ~queue.IsEmpty()
    [v, time] = queue.Pop();
    if nodeBurned(v) || time ~= nodeKey(v)
        continue
    end
    sectors = vertexSectors{v};
    active = sectors(~sectorBurned(sectors));
    [arrival, primary] = min(sectorTime(active));
    if isfinite(arrival)
        sectorBurned(active(primary)) = true;
    end
    exposed = localExposed(sectorEnds{v}, sectorBurned(sectors));
    sectorBurned(sectors(exposed)) = true;
    active = sectors(~sectorBurned(sectors));
    if isempty(active)
        nodeBurned(v) = true;
        burnTime(v) = time;
        for arcInd = outgoing{v}(:).'
            targetSector = arcs(arcInd, 2);
            u = sectorOwner(targetSector);
            if nodeBurned(u) || sectorBurned(targetSector)
                continue
            end
            h = time + lengths(arcInd);
            if h < sectorTime(targetSector)
                sectorTime(targetSector) = h;
                if h < nodeKey(u)
                    nodeKey(u) = h;
                    queue.Push(u, h);
                end
            end
        end
    else
        nodeKey(v) = min(sectorTime(active));
        if isfinite(nodeKey(v))
            queue.Push(v, nodeKey(v));
        end
    end
end
end

function exposed = localExposed(ends, burned)
% Compress each link sector to an edge. Parallel edges form a cycle, whereas
% an isolated closed link sector is a self-loop and cannot expose itself.
exposed = false(size(burned));
active = find(~burned);
for sectorInd = active(:).'
    a = ends(sectorInd, 1);
    b = ends(sectorInd, 2);
    if a == 0
        continue
    end
    other = active(active ~= sectorInd);
    edges = ends(other, :);
    edges = edges(all(edges > 0, 2), :);
    nodeCount = max(ends(:));
    labels = conncomp(graph(edges(:, 1), edges(:, 2), [], nodeCount));
    exposed(sectorInd) = labels(a) ~= labels(b);
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Experimental discrete implementations; no equivalence to an exact continuous
% medial axis is claimed. ET follows the sector-burning logic in Figure 8 of
% Yan et al., Erosion Thickness on Medial Axes of 3D Shapes (2016),
% https://www.cs.wustl.edu/~taoju/research/et.pdf . ETThreshold filters ET values;
% the paper's medial-curve augmentation/topology-preserving contraction is NOT
% implemented. Closed surface cores have infinite ET and are retained.
% Faces supplies meaningful surface connectivity. Automatic preparation uses
% farmSurfaceVoxelComplex, shared with branch correction, and collapses occupied
% tetrahedra with free faces. Lower-dimensional rows have zero sheet ET.
% The adapter can still produce nonmanifold/infinite-ET cores or reject a
% remaining uncollapsible complex; it is not a guaranteed medial-sheet mesh.
% ETSubdivisions refines triangles and interpolates radii; zero uses original
% triangle edges. The paper's Steiner-graph accuracy bound is not claimed.
%
% SAT follows the grow/recompute/shrink construction in Miklos et al. (2010),
% https://www.cs.jhu.edu/~misha/ReadingSeminar/Papers/Miklos10.pdf , rasterized
% using balls at the selected support and FARM thinning as a medial estimator.
% This is an approximation, not a CGAL/exact union-of-balls implementation.
% Scale=1 explicitly preserves the input. Larger scales can alter topology.
% InputKept=[] for nontrivial SAT because output points can move. OutputIndices
% then addresses OutputGrid, not sourceMask. ReturnReconstruction optionally
% returns the shrunk-ball union on that padded grid; this can be memory-heavy.
%
% UNITS AND COORDINATES
% -------------------------------------------------------------------------
% Points and Origin use XYZ; arrays and Spacing use YXZ. All distances use the
% physical unit of Spacing. SourceMask exterior is background. Cropped sheet
% edges are therefore treated as physical boundaries by the radius estimator.
