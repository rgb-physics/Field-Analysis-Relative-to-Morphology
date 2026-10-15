function [ newFace, newVertex, oldVertexIDx, newVertexIDx ] = ...
    farmRemoveFacesVerts_Mesh( face, vertex, rmVIDx )
%FARMREMOVEFACESVERTS_MESH Removes a subset of the vertices and the
%associated faces from a mesh triangulation.
%   INPUT PARAMETERS:
%       - face:         #Fx3 face connectivity list
%       - vertex:       #VxD vertex coordinate list
%       - rmVIDx:       #Nx1 list of vertex IDs to remove
%
%   OUTPUT PARAMETERS:
%       - newFace:      #F'x3 updated face connectivity list
%       - newVertex:    #V'xD updated vertex coordinate list
%       - oldVertexIDx: #V'x1 list of the vertex IDs of the updated
%                       vertices in the old vertex list, so that, for ex,
%                       vn_new = old_mesh.vn(oldVertexIdx, :)
%       - newVertexIDx: #V x1 list of vertex IDs of the old vertices in
%                       the new vertex list, so that
%                       kept_old_vertices = new_mesh.v(newVertexIDx, :)
%
% By Rémi Boros 05-22-2023

% Generate vector of new vertices
newVertex = vertex(~rmVIDx,:);

% Generate cipher to map old vertex indices to new vertex indices
newVertexIDx = zeros(size(vertex,1),1);
if sum(rmVIDx) > 0
    newVertexIDx(rmVIDx) = 0;
    newVertexIDx(~rmVIDx) = 1:size(newVertex,1);
end

% Generate new faces
newFace = newVertexIDx(face);
newFace = newFace(min(newFace,[],2) > 0,:);

% Find the vIDs of the new vertices in the old vertex list
[ ~, oldVertexIDx] = ismember( newVertex, vertex, 'rows' );

end

