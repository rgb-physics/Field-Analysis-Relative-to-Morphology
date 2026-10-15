function [validFaces, validVerts] = farmSplit_single_mesh_object(face, vertex, sortOrder, vertMeshIDs, meshID, saveBool, saveDir, ignoreBounds)
%FARMSPLIT_SINGLE_MESH_OBJECT Takes in FACE and VERTEX information and returns
%all faces and vertices making up the isolated mesh labeled by MESHID. The
%function can optionally save the new mesh object.
%   INPUT VARIABLES:
%           - face:         NFx3 array of pointers corresponding to verts
%           - vertex:       NVx3 array of vertex coordinates
%           - sortOrder:    Vector of sorted vertex IDs for selection
%           - vertMeshIDs:  Vector assigning vertices to mesh IDs
%           - meshID:       Scalar ID of mesh to isolate
%           - saveBool:     Boolean indicating whether or not to save files
%           - saveDir:      Directory to save .ply objects toboundaries

% Isolate vertices in desired mesh
indsOfInterest = (vertMeshIDs == meshID);
validVertInds = sortOrder(indsOfInterest);
validVerts = vertex(validVertInds,:);

% Isolate faces in desired mesh
meshFaceInds = sum(ismember(face, validVertInds),2) > 0;
validFaces = face(meshFaceInds,:);

%Map face pointers to new vertex indices
uniqPointers = unique(validFaces);
[~, validFaces] = ismember(validFaces, uniqPointers);

%Save data
if saveBool
    if ~exist(saveDir, 'dir')
        mkdir(saveDir)
    end
    
    if ignoreBounds
       [~, checkVal] = isManifoldMesh(validVerts, validFaces); 
       if checkVal           
          return 
       end    
    end
    
    plywrite(fullfile(saveDir, sprintf('Mesh%0.6i.ply',meshID)), validFaces, validVerts);
    
end

end

