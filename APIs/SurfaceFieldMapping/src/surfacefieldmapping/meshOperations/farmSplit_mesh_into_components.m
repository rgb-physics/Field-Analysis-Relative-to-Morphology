function splitMeshes = farmSplit_mesh_into_components( face, vertex, cutoff, saveBool, saveDir, ignoreBounds )
%FARMSPLIT_MESH_INTO_COMPONENTS This function splits a composite mesh into its
% isolated connected components for a multiply connected mesh triangulation
%   INPUT PARAMETERS:
%       - face:         NFx3 mesh connectivity list
%       - vertex:       NVxdim mesh vertex coordinate list
%       - cutoff:       a scalar indicating the minimum number of verts in
%                       a valid mesh object 
%       - saveBool:     Boolean indicating whether or not to save ply
%                       objects
%       - saveDir:      Directory in which to save ply objects
%       - ignoreBounds: Boolean indicating whether to include meshes on 
%
%   OUTPUT PARAMETERS:
%       - components:   #components x 1 cell of structs
%                       components{i} contains faces f and vertices v, as
%                       well as oldVertexIDx and newVertexID, which indexes
%                       into the original (composite) mesh.

%--------------------------------------------------------------------------
% INPUT PROCESSING
%--------------------------------------------------------------------------
% Define cutoff, if necessary
if nargin == 2
    cutoff = 100;
    saveBool = 0;
    saveDir = cd;
elseif nargin == 3
    saveBool = 0;
    saveDir = cd;
elseif nargin == 4
    saveDir = cd;
end

% Get vertex order such that they are grouped by mesh ID
[~,~, vertMeshIDs, sortOrder] = remi_sort_mesh_objects(face,vertex);

%Determine vertices making up meshes with size smaller than cutoff
numVertsinMesh = [numel(find(vertMeshIDs == 1)), diff(find([diff(sort(vertMeshIDs)) 1]==1))];
invalidMeshes = find(numVertsinMesh < cutoff);
validMeshes = find(numVertsinMesh >= cutoff);
vertsToRemove = ismember(vertMeshIDs, invalidMeshes);

%Iterate through validmeshes and generate individual mesh objects of each
splitMeshes = struct();
for currMesh = 1:numel(validMeshes)
    
   [splitMeshes(currMesh).face, splitMeshes(currMesh).vertex] = ...
       farmSplit_single_mesh_object(face, vertex, sortOrder, vertMeshIDs, validMeshes(currMesh), saveBool, saveDir, ignoreBounds);
    
    
end
% 
% %Remove vertices of meshes below cutoff
% filtMesh = struct();
% [ filtMesh.f, filtMesh.v, filtMesh.oldVertexIDx, filtMesh.newVertexIDx ] = ...
%         remove_vertex_from_mesh( face, vertex, vertsToRemove ) ;
% 
% % Now C tells us which component each vertex belongs to. Use this to split
% components = cell(S, 1) ;
% % for each connected component, grab the vertices and faces belonging to it
% % Initialize a submesh structure, which we will populate for each component
% submesh = struct() ;
% for ii = validMeshes
%     rmVIDx = find(C ~= ii) ; 
%     % remove everything not in this component
%     [ submesh.f, submesh.v, submesh.oldVertexIDx, submesh.newVertexIDx ] = ...
%         remove_vertex_from_mesh( face, vertex, rmVIDx ) ;
%     components{ii} = submesh ;
% end

end

