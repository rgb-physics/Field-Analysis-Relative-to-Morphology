function farmWritePointPly(filename, points, varargin)
%FARMWRITEPOINTPLY Write physical XYZ point rows, with optional unit normals.
% Inputs:
%   filename   Output PLY path; parent directory must already exist.
%   points     N-by-3 finite XYZ coordinates; no faces are reconstructed.
%   Normals    Optional N-by-3 finite nonzero vectors, normalized for export.
% ASCII PLY uses double coordinates (17 significant digits), zero faces,
% and nx/ny/nz properties when supplied. Empty point clouds are supported.
% Retains the vertex-only PLY approach used by farmLogic2Ply, without requiring
% an external plywrite or changing the historical mesh-with-normals writer.
p = inputParser; addParameter(p,'Normals',[]); parse(p,varargin{:});
validateattributes(points,{'numeric'},{'real','finite','2d','ncols',3,'nonsparse'});
normals = p.Results.Normals; withNormals = ~isempty(normals);
if withNormals
    validateattributes(normals,{'numeric'},{'real','finite','size',size(points)});
    lengths = sqrt(sum(double(normals).^2,2));
    if any(lengths==0), error('surfacefieldmapping:Normals','Normal vectors must be nonzero.'); end
    normals = double(normals)./lengths;
end
[fid,message] = fopen(filename,'w');
if fid<0, error('surfacefieldmapping:PLYOpen','Cannot open PLY: %s',message); end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'ply\nformat ascii 1.0\nelement vertex %d\n',size(points,1));
fprintf(fid,'property double x\nproperty double y\nproperty double z\n');
if withNormals
    fprintf(fid,'property double nx\nproperty double ny\nproperty double nz\n');
end
fprintf(fid,'element face 0\nproperty list uchar int vertex_indices\nend_header\n');
% Chunk writes keep temporary transposed arrays bounded on large clouds.
for first = 1:100000:size(points,1)
    rows = first:min(first+99999,size(points,1));
    data = double(points(rows,:));
    if withNormals, data = [data,normals(rows,:)]; end
    format = [repmat('%.17g ',1,size(data,2)-1),'%.17g\n'];
    fprintf(fid,format,data.');
end
[message,number] = ferror(fid);
if number ~= 0, error('surfacefieldmapping:PLYWrite','Writing PLY failed: %s',message); end
end
