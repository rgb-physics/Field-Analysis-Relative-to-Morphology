function result = exampleSurfaceSkeleton(outputFile)
%EXAMPLESURFACESKELETON Folded surface skeleton and optional oriented PLY.
% Requires Image Processing and Statistics and Machine Learning Toolboxes.
% With no outputFile, computes/returns results without writing any file.
% Measurements can sample the original field using SourceIndices. MeshLab
% reconstruction, curvature, DEC, patching and pruning are outside this example.
if nargin<1, outputFile=''; end
[y,x,z]=ndgrid(1:35,1:45,1:45);
rad=sqrt((x-23).^2+(z-23).^2);
mask=rad>=12 & rad<=16 & y>=5 & y<=31;
[surface,surfaceInfo]=farmMedialSurface(mask,'Spacing',[1 1 1]);
[points,sourceIndices,grid]=farmMaskToPoints(surface);
% Select normal queries while retaining the denser skeleton as fit support.
queryIndices=(1:2:size(points,1)).';
[normals,normalInfo]=farmEstimateSurfaceNormals(points,queryIndices, ...
    'Radius',3,'MaxNeighbors',32,'MinNeighbors',6);
% Unavailable fits are excluded from the oriented export explicitly.
valid=normalInfo.Valid; exportIndices=queryIndices(valid);
[normals,orientationInfo]=farmOrientSurfaceNormals(points(exportIndices,:), ...
    normals(valid,:),'Radius',3,'MaxNeighbors',12, ...
    'SourceMask',mask,'SourceIndices',sourceIndices(exportIndices));
if strlength(string(outputFile))>0
    farmWritePointPly(outputFile,points(exportIndices,:),'Normals',normals);
end
result=struct('Mask',mask,'Surface',surface,'SurfaceInfo',surfaceInfo, ...
    'Points',points,'SourceIndices',sourceIndices,'Grid',grid, ...
    'QueryIndices',queryIndices,'NormalInfo',normalInfo,'ExportIndices',exportIndices, ...
    'Normals',normals,'OrientationInfo',orientationInfo);
end
