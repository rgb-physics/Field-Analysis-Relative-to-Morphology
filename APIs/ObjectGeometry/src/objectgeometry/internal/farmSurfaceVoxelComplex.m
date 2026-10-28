function [faces, preparation] = farmSurfaceVoxelComplex(xyz, sz, radii)
%FARMSURFACEVOXELCOMPLEX Internal shared voxel-center surface adapter.
% Inputs (validated by callers): xyz is N-by-3 unique one-based integer XYZ;
% sz is the three-element YXZ source size; radii is an N-by-1 finite nonnegative
% priority vector in consistent units. Radii only order free-face collapses.
% Outputs: faces is M-by-3 ORIGINAL xyz row indices; preparation records input
% and collapsed tetrahedron counts and points with no remaining incident face.
% Induced Freudenthal complex is collapsed from dimension three to at most two.
% A tetrahedron/free-face removal preserves homotopy of THIS lattice complex,
% not necessarily the caller's digital connectivity. No vertices are displaced.
% Remaining faces need not form a manifold, unique medial sheet, or mesh that
% covers all points. Empty/curve-only input can produce zeros(0,3) faces.
% Axis/face ordering breaks radius ties; rotation invariance is not claimed.
% No PCA projection, XY height field, Delaunay hull or cross-gap KNN edges.
% Allocates a uint32 index map of size sz plus face/tetrahedron incidence lists.

% Convert XYZ coordinate columns to YXZ for array indexing, without resampling.
yxz = xyz(:, [2 1 3]);
map = zeros(sz, 'uint32');
sites = sub2ind(sz, yxz(:, 1), yxz(:, 2), yxz(:, 3));
map(sites) = uint32(1:size(xyz, 1));
offsets = dec2bin(1:7, 3) - '0';

faces = zeros(0, 3);
for firstInd = 1:7
    for secondInd = 1:7
        a = offsets(firstInd, :);
        b = offsets(secondInd, :);
        if ~all(a <= b) || isequal(a, b)
            continue
        end
        inside = all(yxz + b <= sz, 2);
        starts = find(inside);
        pa = yxz(inside, :) + a;
        pb = yxz(inside, :) + b;
        ia = double(map(sub2ind(sz, pa(:, 1), pa(:, 2), pa(:, 3))));
        ib = double(map(sub2ind(sz, pb(:, 1), pb(:, 2), pb(:, 3))));
        valid = ia > 0 & ib > 0;
        faces = [faces; starts(valid), ia(valid), ib(valid)]; %#ok<AGROW>
    end
end

% Retain occupied tetrahedra explicitly. Simply taking their boundary faces
% would create false closed ET cores. Collapse a tetrahedron with a free face
% instead; each pair removal preserves the lattice complex's homotopy type.
tetrahedra = zeros(0, 4);
for permutation = perms(1:3).'
    a = zeros(1, 3);
    a(permutation(1)) = 1;
    b = a;
    b(permutation(2)) = 1;
    c = [1 1 1];
    inside = all(yxz + c <= sz, 2);
    starts = find(inside);
    p = yxz(inside, :);
    pa = p + a;
    pb = p + b;
    pc = p + c;
    ia = double(map(sub2ind(sz, pa(:, 1), pa(:, 2), pa(:, 3))));
    ib = double(map(sub2ind(sz, pb(:, 1), pb(:, 2), pb(:, 3))));
    ic = double(map(sub2ind(sz, pc(:, 1), pc(:, 2), pc(:, 3))));
    valid = ia > 0 & ib > 0 & ic > 0;
    tetrahedra = [tetrahedra; starts(valid), ia(valid), ib(valid), ic(valid)]; %#ok<AGROW>
end

faces = unique(sort(faces, 2), 'rows');
tetrahedra = sort(tetrahedra, 2);
count = size(tetrahedra, 1);
if count > 0
    faces = localCollapseTetrahedra(faces, tetrahedra, radii);
end

preparation = struct('InputTetrahedronCount', count, ...
    'CollapsedTetrahedronCount', count, ...
    'LowerDimensionalPointCount', size(xyz, 1) - numel(unique(faces(:))));
end

function faces = localCollapseTetrahedra(faces, tetrahedra, radii)
%LOCALCOLLAPSETETRAHEDRA Internal sequential tetrahedron/free-face collapse.
% Lower-radius free faces are removed first, favoring more central surfaces.
% Tie order follows lattice face order. This is a mesh preparation choice,
% not a claim of geometrically unique or rotation-invariant reconstruction.

n = size(tetrahedra, 1);
allFaces = [tetrahedra(:, [1 2 3]); tetrahedra(:, [1 2 4]); ...
    tetrahedra(:, [1 3 4]); tetrahedra(:, [2 3 4])];
[found, faceIds] = ismember(allFaces, faces, 'rows');
assert(all(found), 'Lattice tetrahedron faces must belong to the complex.');
tetraFaces = reshape(faceIds, n, 4);
incidence = accumarray(faceIds, repmat((1:n).', 4, 1), ...
    [size(faces, 1), 1], @(x) {x});
degree = accumarray(faceIds, 1, [size(faces, 1), 1]);
priority = mean(radii(faces), 2);

active = true(n, 1);
keepFace = true(size(faces, 1), 1);
queue = farmSurfacePriorityQueue();
for faceInd = find(degree == 1).'
    queue.Push(faceInd, priority(faceInd));
end

while ~queue.IsEmpty()
    [faceInd, ~] = queue.Pop();
    if degree(faceInd) ~= 1 || ~keepFace(faceInd)
        continue
    end
    owners = incidence{faceInd};
    owner = owners(active(owners));
    assert(isscalar(owner), 'A free face must belong to exactly one active tetrahedron.');
    active(owner) = false;
    keepFace(faceInd) = false;
    adjacent = tetraFaces(owner, :);
    degree(adjacent) = degree(adjacent) - 1;
    for nextFace = adjacent
        if degree(nextFace) == 1 && keepFace(nextFace)
            queue.Push(nextFace, priority(nextFace));
        end
    end
end

if any(active)
    error('objectgeometry:PruningSurfaceComplex', ...
        'Lattice complex retains uncollapsible tetrahedra. Supply explicit surface Faces.');
end

faces = faces(keepFace, :);
end
