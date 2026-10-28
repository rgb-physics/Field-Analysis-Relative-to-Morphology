function points = farmSurfacePoints(points)
%FARMSURFACEPOINTS Validate physical XYZ rows shared by surface operations.
validateattributes(points,{'numeric'},{'real','finite','2d','nonsparse'});
if size(points,2) ~= 3
    error('objectgeometry:SurfacePoints','Points must be N-by-3 physical XYZ.');
end
points = double(points);
end
