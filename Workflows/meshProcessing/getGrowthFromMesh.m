function [growth,divvt,H2vn_onVertices, HV, vF_t, vF_n] = getGrowthFromMesh(mesh, PIVData, imageVol, parameters)
%GETGROWTHFROMMESH Returns the growth and terms composing it as defined by
%the expression: gamma = div(v_tan) - 2*H*v_norm
%The function relies on the DEC library made by Dillon Cislo and Noah
%Mitchell: https://github.com/DillonCislo/DEC.git
%MESH is a .ply object containing vertex and face information outlining the
%object in question, PIV is a 4D matrix containing Vx, Vy, and Vz, IMAGEVOL
%is a scaled version of the .tif from which PIV data was used (used for
%scales and sizes), and PARAMETERS is a vector containing scalar values of:
%  - The Target Edge Length of edges defining the mesh after rescaling
%  - The number of iterations/attempts to rescale the mesh
%  - Scalar length in pixels between defined PIV data points (isotropic)

%% Unload Parameters
EdgeLength = parameters(1);
% targetEdgeLength = parameters(2);
% numIterations = parameters(3);

%% Split velocity matrices
VX = PIVData(:,:,:,1);
VY = PIVData(:,:,:,2);
VZ = PIVData(:,:,:,3);

%% Optional: Downsample the mesh to make this more tractable (isotropic_remeshing function must be compiled; use meshlab and skip this otherwise)
% if targetEdgeLength ~= 1
%     [Fnew, Vnew, ~, ~] = ...
%            isotropic_remeshing(mesh.f, mesh.v, targetEdgeLength, numIterations) ;
% else
%     Fnew = mesh.f ;
%     Vnew = mesh.v ;
% end

Fnew = mesh.f; Vnew = mesh.v;
%% Query 3d velocities on barycenters
bcs = barycenter(Vnew, Fnew) ;
% make interpolation object of the velocities
[rowMat,colMat,depthMat] = ndgrid(EdgeLength/2:EdgeLength:size(imageVol,1)-EdgeLength/2, ...
    EdgeLength/2:EdgeLength:size(imageVol,2)-EdgeLength/2, ...
    EdgeLength/2:EdgeLength/1:size(imageVol,3)-EdgeLength/2); 
ginterpx = griddedInterpolant(rowMat, colMat, depthMat, permute(VX, [2 1 3])) ;
ginterpy = griddedInterpolant(rowMat, colMat, depthMat, permute(VY, [2 1 3])) ;
ginterpz = griddedInterpolant(rowMat, colMat, depthMat, permute(VZ, [2 1 3])) ;
% query the interp objects at the faces
vx_faces = ginterpx(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;
vy_faces = ginterpy(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;
vz_faces = ginterpz(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;

% make a #faces x 3 float array of velocities
vfaces = [vx_faces, vy_faces, vz_faces] ;

%% Take tangential and normal components
% Note: DEC should be able to handle this projection "on the fly" but in 
% my hands it is more accurate to do this manually. The projection method
% in DEC is a bit different than this more robust version (something I'll
% fix soon). 
% velocities on Faces -- tangential / normal components
[vF_n, vF_t] = resolveTangentNormalVector(Fnew, Vnew, vfaces) ;

%% Compute DiscreteExteriorCalculus of velocities
dec = DiscreteExteriorCalculus(Fnew, Vnew) ;

%% by default, divv will be #verts x 1 scalar field on mesh
divvt = dec.divergence(vF_t) ;

%% Compare to bending: 2H*vn
vtxNormals = per_vertex_normals(Vnew, Fnew) ;
% mean curvature is the laplacian dotted with the normal
% this is mean curvature on VERTICES
HV = sum(vtxNormals .* dec.laplacian(mesh.v), 2) * 0.5 ;

% push the normal component of the velocities to vertices
[~, F2V] = meshAveragingOperators(Fnew, Vnew) ;
% velocities on Vertices -- normal component: vV_n
vV_n = F2V * vF_n ;

H2vn_onVertices = 2 * HV .* vV_n ;

%% What is the Tr[gdot g^{-1}] == "metric growth"
growth = divvt - H2vn_onVertices ;

end

