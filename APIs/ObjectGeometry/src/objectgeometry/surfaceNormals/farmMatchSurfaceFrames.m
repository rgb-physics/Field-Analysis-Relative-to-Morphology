function matches = farmMatchSurfaceFrames(current, previous, varargin)
%FARMMATCHSURFACEFRAMES Optional geometric correspondence, without normal edits.
% Physical XYZ arrays; MaxDistance is required. Mutual=true by default.
% Optional Rotation (proper 3-by-3, default eye(3)) and Translation (XYZ row)
% map previous coordinates into current: previous*Rotation.' + Translation.
% Output indices refer to the original input rows. Matching is geometric,
% not a material tracker; nearest points can belong to different folds.
current = farmSurfacePoints(current); previous = farmSurfacePoints(previous);
p = inputParser; addParameter(p,'MaxDistance',[]); addParameter(p,'Mutual',true);
addParameter(p,'Rotation',eye(3)); addParameter(p,'Translation',[0 0 0]);
parse(p,varargin{:}); o = p.Results;
validateattributes(o.MaxDistance,{'numeric'},{'scalar','real','finite','nonnegative'});
validateattributes(o.Mutual,{'logical'},{'scalar'});
validateattributes(o.Rotation,{'numeric'},{'real','finite','size',[3 3]});
validateattributes(o.Translation,{'numeric'},{'real','finite','vector','numel',3});
rotation = double(o.Rotation);
if norm(rotation.'*rotation-eye(3),'fro')>1e-8 || abs(det(rotation)-1)>1e-8
    error('objectgeometry:SurfaceRotation','Rotation must be a proper orthogonal matrix.');
end
placed = previous*rotation.'+double(o.Translation(:).');
ci = zeros(0,1); pi = ci; distances = ci;
if ~isempty(current) && ~isempty(previous)
    [nearest,dist] = farmSurfaceKNN(placed,current,1);
    keep = dist <= o.MaxDistance;
    if o.Mutual
        reverse = farmSurfaceKNN(current,placed,1);
        keep = keep & reverse(nearest) == (1:size(current,1)).';
    end
    ci = find(keep); pi = nearest(keep); distances = dist(keep);
end
matches = struct('CurrentIndices',ci,'PreviousIndices',pi,'Distances',distances, ...
    'Rotation',rotation,'Translation',double(o.Translation(:).'),'Options',o);
end
