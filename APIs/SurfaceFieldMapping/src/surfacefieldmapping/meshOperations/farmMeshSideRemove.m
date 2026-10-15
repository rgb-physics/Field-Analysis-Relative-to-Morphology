function [Fcut,Vcut] = farmMeshSideRemove(Fraw,Vraw, minCuts, maxCuts)
%FARMMESHSIDEREMOVE Takes in as arguments the original array of vertex pointers
%FRAW and array of vertex coordinates VRAW that define a mesh object. Also
%takes in boundary values to shave off. The function uses
%remove_vertex_from_mesh, a function in gut_matlab: https://github.com/npmitchell/gut_matlab.git
%and returns the faces and vertices defining a shaved down mesh.
%MINCUTS and MAXCUTS are 1x3 vectors in the same units as the coordinates
%in VRAW

% Get vertices outside of desired boundaries
badVertices = logical( (Vraw(:, 1) < minCuts(1)) +  (Vraw(:, 1) > maxCuts(1)) ...
    + (Vraw(:, 2) < minCuts(2)) +  (Vraw(:, 2) > maxCuts(2)) ...
    + (Vraw(:, 3) < minCuts(3)) +  (Vraw(:, 3) > maxCuts(3)) );

% Remove vertices above and faces encompassing said vertices
if sum(badVertices) > 0
    [ Fcut, Vcut] = ...
         farmRemoveFacesVerts_Mesh(Fraw, Vraw, badVertices) ;
else
    Fcut = Fraw;    Vcut = Vraw;
end

% Remove faces with vertices that have zeros
for dimInd = 1:size(Fcut,2)
    Fcut = Fcut( logical(Fcut(:,dimInd)),:);
end

end

