% may or may not need to run setup.m in imsane FROM IMSANE DIR (ie cd
% to imsane/ first).
%% Script expects meshes generated in meshlab and calculates/saves DEC
% This script is a mess. Section one is for variables, section two is where
% DEC is calculated, along with various fields mesh vertices and faces
% meshDir = '<redacted original absolute path>';
meshDir = 'Session 45, Exp 3';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 45, Exp 3';
% PIVDir = '<redacted original absolute path>';
PIVDir = 'Session 45, Exp 3';
subDirs = {''};
% subDirs = {'Bot Layers', 'Top Layers'};
meshName = 'Rescaled%sskel_vertices_t%03i.ply';
saveName = '%sDataStoreStructT%03i.mat';
pivName = 't%03i_pivOUT.mat';
subNames = {''};

% tifDir = '<redacted original absolute path>';
tifDir = 'Session 45, Exp 3';
tifName = 't%03i_illCorr8bit.tif';

maxCuts = [385, 392, 150] ;
minCuts = [0, 0, 0] ;
selectTimes = 120:170;

mkdir(saveDir);

%% Iterate through time: accumulate all curvatures (compare top v. bot)
for tInd = 1:numel(selectTimes)

    %Load current data
    currT = selectTimes(tInd);
    if mod(tInd,10) == 1
        fprintf('Currently analyzing frame %i...\n',currT)
    end
    currTif = tiffreadVolume(fullfile(tifDir, sprintf(tifName, currT)));
    load(fullfile(PIVDir,sprintf(pivName,currT)),'shifts','validCenCoords');

    % Iterate through different sub directories
    for layerInd = 1:numel(subDirs)

        currMesh = read_ply_mod(fullfile(meshDir, subDirs{layerInd}, sprintf(meshName,subNames{layerInd},currT)));
        
        %load vertices and faces
        Vraw = currMesh.v ; Fraw = currMesh.f;
    
        %Cut mesh
        [Fcut, Vcut] = meshSideRemove(Fraw, Vraw, minCuts, maxCuts);
        [filtFcut,  filtVcut] = remove_isolated_mesh_components(Fcut,Vcut);
    
        %Get barycenter coords
        bcs = barycenter(filtVcut, filtFcut);
        % Compute DiscreteExteriorCalculus of surface
        dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;
    
        % Get surface normals, ensuring to flip sign s.t. normal points toward MTs
        vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % note that we add a negative sign to force normals to be inward facing
        [~, F2V] = meshAveragingOperators(filtFcut, filtVcut);
%         if median(vtxNormals(:,3)) < 0
%             vtxNormals = -vtxNormals;       %For layer at higher z
%         end
    
        % Curvatures on vertices
        HV = sum(vtxNormals .* dec.laplacian(filtVcut), 2) * 0.5 ;

        % Velocities on bcs using scattered interpolant
        scinterpx = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,1));
        scinterpy = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,2));
        scinterpz = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,3));
        % query the interp objects at the faces
        vx_faces = scinterpx(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;
        vy_faces = scinterpy(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;
        vz_faces = scinterpz(bcs(:, 1), bcs(:, 2), bcs(:, 3)) ;
        % make a #faces x 3 float array of velocities
        vfaces = [vx_faces, vy_faces, vz_faces] ;
        [vF_n, vF_t] = resolveTangentNormalVector(filtFcut, filtVcut, vfaces) ;

        % velocities on Vertices -- normal component: vV_n
        vV_n = F2V * vF_n ;
        H2vn_onVertices = 2 * HV .* vV_n ;
        divv = dec.divergence(vF_t) ;

        % Intensities on vertices
        [rowMat,colMat,depthMat] = ndgrid(1:size(currTif,1), 1:size(currTif,2), 1:size(currTif,3));
        ginterpInt = griddedInterpolant(rowMat, colMat, depthMat, double(currTif));
        int_faces = ginterpInt(bcs(:,1), bcs(:,2), bcs(:,3));
        int_verts = F2V*int_faces;
    
        currStruct = struct();
        currStruct.intF = int_faces;
        currStruct.intV = int_verts;
        currStruct.curvV = HV;
        currStruct.v = filtVcut;
        currStruct.f = filtFcut;
        currStruct.bcs = bcs;
        currDEC = dec;
    
        save(fullfile(saveDir, subDirs{layerInd}, sprintf(saveName,subNames{layerInd},currT)),"currStruct", "currDEC","-mat");
    end

end

%% 

%% Read in a mesh
currMesh = read_ply_mod(fullfile(botDir, sprintf(meshName,'botLayer',selectTimes(1))));
Vraw = currMesh.v ; Fraw = currMesh.f;

currTif = tiffreadVolume(fullfile(tifDir, sprintf(tifName, selectTimes(1))));

%% cut mesh
maxCuts = [387, 381, 180] ;
minCuts = [3, 3, 0] ;

[Fcut, Vcut] = meshSideRemove(Fraw,Vraw, minCuts, maxCuts);
[filtFcut,  filtVcut, ~,objNum] = remove_isolated_mesh_components(Fcut,Vcut);

%% Query intensities on barycenters
bcs = barycenter(filtVcut, filtFcut) ;

% make interpolation object of the intensities
[rowMat,colMat,depthMat] = ndgrid(1:size(currTif,1), 1:size(currTif,2), 1:size(currTif,3));
ginterpInt = griddedInterpolant(rowMat, colMat, depthMat, double(currTif));
int_faces = ginterpInt(bcs(:,1), bcs(:,2), bcs(:,3));

%% Triangulate and display intensities on surface
tri = triangulation(filtFcut, filtVcut) ;
trisurf(tri, int_faces, 'edgecolor', 'none')

axis equal
cmax = prctile(abs(int_faces(:)), 95) ;
caxis([cmax/4, cmax])

%% Compute DiscreteExteriorCalculus of surface
dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;

%% Get surface normals, ensuring to flip sign s.t. normal points toward MTs
vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % note that we add a negative sign to force normals to be inward facing
if median(vtxNormals(:,3)) < 0
    vtxNormals = -vtxNormals;       %For layer at higher z
end

%% Curvatures on vertices
% mean curvature is the laplacian dotted with the normal
% this is mean curvature on VERTICES
HV = sum(vtxNormals .* dec.laplacian(filtVcut), 2) * 0.5 ;

trisurf(tri, HV, 'edgecolor', 'none') ;

axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])

figure
histogram(HV(:),-2.5:.01:2.5)

%% intensity vs curvature - push intensity back to vertices
[V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut) ;
int_verts = F2V*int_faces;

trisurf(tri, int_verts, 'edgecolor', 'none')

axis equal
cmax = prctile(abs(int_faces(:)), 95) ;
caxis([cmax/4, cmax])

figure

histogram2(HV(:),int_verts(:),-2:.01:2, 0:160); %high intensities correlate with near zeros curvature -> flattening; increased population of positive curvatures

%% 
% push the normal component of the velocities to vertices
[V2F, F2V] = meshAveragingOperators(Fnew, Vnew) ;
% velocities on Vertices -- normal component: vV_n
vV_n = F2V * vF_n ;

H2vn_onVertices = 2 * HV .* vV_n ;

%% cut mesh

maxCuts = [387, 381, 180] ;
minCuts = [3, 3, 0] ;

[Fcut, Vcut] = meshSideRemove(Fraw,Vraw, minCuts, maxCuts);
[filtFcut,  filtVcut, ~,objNum] = remove_isolated_mesh_components(Fcut,Vcut);

%% Parameters
downsample = false;
targetEdgeLength = 2 ;  % larger than current average edge length
numIterations = 50 ;    % 50-100 should be plenty
scaling = 1;
totChannels = 2;
channelNum = 1;
EdgeLength = 4;

%% Define boundary cutoffs

%% Load in image (tif), piv file, and mesh
imageVol = imresize(tiffreadVolume(fullfile(dataDir, firstImg)),scaling,'bicubic');
imageVol = imageVol(:,:,channelNum:totChannels:end);
load(fullfile(pivDir, firstPIV));
currMesh = read_ply_mod(fullfile(meshDir, firstMesh)) ;
% rawMesh = read_ply_mod(fullfile(meshDir, rawMeshFn)) ;

%% Consider: remaking the smooth meshes after removing the walls 
% rm vertices on the "boundary" of the fudicial volume from rawMesh and
% then make a coarsened mesh from that 
Vraw = currMesh.v ; Fraw = currMesh.f;
[Fcut, Vcut] = meshSideRemove(Fraw,Vraw, minCuts, maxCuts);
[filtFcut,  filtVcut, ~,objNum] = remove_isolated_mesh_components(Fcut,Vcut);
plywrite(fullfile(meshDir,['EdgeCut_' firstMesh]),filtFcut,filtVcut);

%%

 % Then you can smooth these meshes and downsample them
 [Frecut, Vrecut] = isotropic_remeshinging() ;
 bndVtx = freeBoundary(triangulation(Frecut, Vrecut)) ;
VrecutSmoothed = laplacian_smooth(Vrecut, Frecut, 'cotan', bndVtx, lambda, 'implicit', Vrecut, 1000)

 plywrite(filename,faces,verts)

%(keep the old ones though they are ok!)
% use isotropic_remesh() in CGAL to downsample the vertices -- this is in
% imsane/external/CGALcodes/.cpp
% and use 
% laplacian_smooth() in gptoolbox to smooth the mesh. 
% Then use plywrite() to save it.
% if you want normals, per_vertex_normals()

%% Optional: Downsample the mesh to make this more tractable
if downsample 
    [Fnew, Vnew, Fnnew, Vnnew] = ...
           isotropic_remeshing(currMesh.f, currMesh.v, targetEdgeLength, numIterations) ;
else
    Fnew = currMesh.f ;
    Vnew = currMesh.v ;
end

%% MAKE SURE NORMALS ARE INWARD
% by hook or crook. Here we know they start out outward
Fnew = [Fnew(:, 2), Fnew(:, 1), Fnew(:, 3)] ;

%% Remove walls
minCuts = [328, 330, 110] ; %[331, 332, 110] ;
maxCuts = [2, 2, 0] ;
badVertices  = find(Vnew(:, 1) < maxCuts(1) | Vnew(:, 1) > minCuts(1) | ...
    Vnew(:, 2) < maxCuts(2) | Vnew(:, 2) > minCuts(2) | ...
    Vnew(:, 3) < maxCuts(3) | Vnew(:, 3) > minCuts(3)) ;
    
[ Fnew, Vnew]  = ...
     remove_vertex_from_mesh(Fnew, Vnew, badVertices) ;

%% Query 3d velocities on barycenters
bcs = barycenter(Vnew, Fnew) ;
% make interpolation object of the velocities
[rowMat,colMat,depthMat] = ndgrid(EdgeLength/2:EdgeLength:size(imageVol,1)-EdgeLength/2, ...
    EdgeLength/2:EdgeLength:size(imageVol,2)-EdgeLength/2, ...
    EdgeLength/2:EdgeLength/1:size(imageVol,3)-EdgeLength/2); 
% CHECK THIS WITH ASSYMETRIC MATRICES
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
divv = dec.divergence(vF_t) ;

%% Compare to bending: 2H*vn
vtxNormals = per_vertex_normals(Vnew, Fnew) ;  % note that we add a negative sign to force normals to be inward facing
% mean curvature is the laplacian dotted with the normal
% this is mean curvature on VERTICES
HV = sum(vtxNormals .* dec.laplacian(Vnew), 2) * 0.5 ;

% push the normal component of the velocities to vertices
[V2F, F2V] = meshAveragingOperators(Fnew, Vnew) ;
% velocities on Vertices -- normal component: vV_n
vV_n = F2V * vF_n ;

H2vn_onVertices = 2 * HV .* vV_n ;

%% Check orientation of mesh
tri = triangulation(Fnew, Vnew) ;
clf
trisurf(tri, vtxNormals(:, 1), 'edgecolor', 'none')
axis equal
xlabel('x')
title('x component of vertex normals -- check that they are inward!!')

%% Alternatively, for comparison, we can compute 2Hvn on faces
HF = V2F * HV ;
H2vn_onFaces = 2 * HF .* vF_n ;

%% What is the Tr[gdot g^{-1}] == "metric growth"
growth = divv - H2vn_onVertices ;

%% Plot the two
clf
scatter(divv(:), H2vn_onVertices(:)) ; hold on;
plot([-1,1], [-1, 1], 'k--')

% fit to 
keepVtx = ~isnan(HV(:)) ;
pp = polyfit(divv(keepVtx), H2vn_onVertices(keepVtx), 1) ;
ylabel('$2H v_n$', 'interpreter', 'latex')
xlabel('$\nabla \cdot v_t$', 'interpreter', 'latex')
titleString = ['$\nabla \cdot v_t = ', sprintf('%0.2f H v_n + %0.2f$ ', 2*pp(1), pp(2))] ;
title(titleString, 'interpreter', 'latex')
axis equal

%% Check smoothness of fields
trisurf(tri, HV, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$H$', 'interpreter', 'latex')
sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;

saveas(gcf, fullfile(outDir, sprintf('meanCurvature_T%03d.png', tidx)))


%% Check smoothness of fields
clf
tri = triangulation(Fnew, Vnew) ;
trisurf(tri, HV, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$v_n$', 'interpreter', 'latex')
sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;

saveas(gcf, fullfile(outDir, sprintf('meanCurvature_T%03d.png', tidx)))

%% Check smoothness of fields
clf
trisurf(tri, vV_n, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(vV_n(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$2Hv_n$', 'interpreter', 'latex')
sgtitle(sprintf('$2Hv_n$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
saveas(gcf, fullfile(outDir, sprintf('vn_T%03d.png', tidx)))


%% Check smoothness of fields
clf
trisurf(tri, H2vn_onVertices, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(H2vn_onVertices(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$2Hv_n$', 'interpreter', 'latex')
sgtitle(sprintf('$2Hv_n$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
saveas(gcf, fullfile(outDir, sprintf('H2vn_T%03d.png', tidx)))


%% Correlate this to other observables
plot(HV(:), growth(:), '.')
ylabel('growth')
xlabel('mean curvature')

%% Is there a correlation with something else that makes physical sense?


%% Wait which way is the normal???
subplot(3, 1, 1)
trisurf(tri, vtxNormals(:, 1),'edgecolor','none') ;
subplot(3, 1, 2)
trisurf(triangulation(Fnew, Vnew), vtxNormals(:, 2),'edgecolor','none') ;
subplot(3, 1, 3)
trisurf(triangulation(Fnew, Vnew), vtxNormals(:, 3),'edgecolor','none') ;

% If there is bad orientation issues
Fnew = reorient_facets(Vnew, Fnew) ;




%% Could point match to get time info (rough but good method since it is parameter-free!)
% [] = pointMatch(V_t0, V_t1)



