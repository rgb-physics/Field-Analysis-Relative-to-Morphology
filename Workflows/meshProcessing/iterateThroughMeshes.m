%% Directories and files of interest
% meshDir = '<redacted original absolute path>';
meshDir = '';
% pivDir = '<redacted original absolute path>';
pivDir = '';
% dataDir = '<redacted original absolute path>';
dataDir = '';
saveDir = fullfile(meshDir, 'PIV Settings 25 70 4 1 1 0 0 0 MT Channel');
meshName = 'Rescaledmesh_ms_%0.6i.ply'; pivName  = 'vel_%0.3i.mat'; imgName  = 'Tiny_T%i.tif';

imgData = dir(fullfile(dataDir,'*.tif'));
%% Parameters
% downsample = false;
% targetEdgeLength = 1 ;  % larger than current average edge length for scaled down remeshing
% numIterations = 1 ;    % 50-100 should be plenty
scaling = 1;
totChannels = 2;
channelNum = 1;
EdgeLength = 4;
cutEdges = 1;
maxCuts = [329, 330, 109] ;
minCuts = [3, 3, 0] ;
selectedTimes = 70:95;

% parameters = [targetEdgeLength, numIterations, EdgeLength];
parameters = EdgeLength;

%% Iterate through time points and cut edges, if desired
edgeCutPrefix = 'EdgeCut_';
if cutEdges == 1
    for currT = 1:numel(selectedTimes)
        
        currMeshName = fullfile(meshDir, sprintf(meshName, selectedTimes(currT)));
        mesh = read_ply_mod(currMeshName);
        [Fcut, Vcut] = meshSideRemove(mesh.f,mesh.v, minCuts, maxCuts);
        [filtFcut,  filtVcut, ~,objNum] = remove_isolated_mesh_components(Fcut,Vcut);
        plywrite(fullfile(meshDir,[edgeCutPrefix sprintf(meshName, selectedTimes(currT))]),filtFcut,filtVcut);
        
    end
end

meshName = [edgeCutPrefix 'Rescaledmesh_ms_%0.6i.ply'];

%% Iterate through time points and store growth, divvt, and 2Hvn

storageStruct = struct();
for currT = 1:numel(selectedTimes)
    
    currMeshName = fullfile(meshDir, sprintf(meshName, selectedTimes(currT)));
    currPIVName  = fullfile(pivDir,  sprintf(pivName,  selectedTimes(currT)));
    currImgName  = fullfile(dataDir, sprintf(imgName,  selectedTimes(currT)));

    currImg = imresize(tiffreadVolume(currImgName),scaling,'bicubic');
    currImg = currImg(:,:,channelNum:totChannels:end);
    load(currPIVName);
    PIVTot(:,:,:,1) = VX; PIVTot(:,:,:,2) = VY; PIVTot(:,:,:,3) = VZ;
    mesh = read_ply_mod(currMeshName) ;
    
    [growth,divvt,H2vn, HV, vF_t, vF_n] = getGrowthFromMesh(mesh, PIVTot, currImg, parameters);
    storageStruct(currT).growth = growth;
    storageStruct(currT).divvt = divvt;
    storageStruct(currT).H2vn = H2vn;
    storageStruct(currT).HV = HV;
    storageStruct(currT).vF_t = vF_t;
    storageStruct(currT).vF_n = vF_n;
    storageStruct(currT).meshName = currMeshName;
    
end


%% Save
save(fullfile(saveDir,'storageStruct.mat'),'storageStruct')

%%END EXTRACTION%%%%%%%%%%%%%%%%%%



%% 
for currT = 1:numel(selectedTimes)
    
    % Load mesh elements
    currMeshName = storageStruct(currT).meshName;
    currMesh = read_ply_mod(currMeshName) ;
    currV = currMesh.v; currF = currMesh.f;
    currTri = triangulation(currF, currV);
    
    % Load face facets
    currHV = storageStruct(currT).HV;
    currGrowth = storageStruct(currT).growth;

    trisurf(currTri, currHV, 'edgecolor', 'none') ;
    axis equal
    cmax = prctile(abs(currHV(:)), 90) ;
    caxis([-.3, .3])
    colormap bone
    cb = colorbar ;
%     ylabel(cb, '$H$', 'interpreter', 'latex')
    % sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
    xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
    ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
    zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
    curvDir = fullfile(saveDir, 'Curvature Images');
    
    exportgraphics(gcf, fullfile(curvDir,sprintf('%03i.png',currT)), 'Resolution', 200)

    trisurf(currTri, currGrowth, 'edgecolor', 'none') ;
    axis equal
    cmax = prctile(abs(currGrowth(:)), 90) ;
    caxis([-.5, .5])
    colormap bluewhitered
    cb = colorbar ;
%     ylabel(cb, '$H$', 'interpreter', 'latex')
    % sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
    xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
    ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
    zlabel('z [$\mu$m]', 'interpreter', 'latex') ;
    growthDir = fullfile(saveDir, 'Growth Images');
    
    exportgraphics(gcf, fullfile(growthDir,sprintf('%03i.png',currT)), 'Resolution', 200)

end

%% Open a mesh

meshName = 'Rescaledmesh_ms_000063.ply';
mesh = read_ply_mod(fullfile(meshDir, meshName));
vStuff = mesh.v; fStuff = mesh.f;
cutName = 'EdgeCut_Rescaledmesh_ms_000063.ply';

%% plot
tri = triangulation(fStuff,vStuff);
HV = storageStruct(13).HV;

trisurf(tri, -HV, 'edgecolor', 'none') ;
axis equal
cmax = prctile(abs(HV(:)), 90) ;
caxis([-cmax, cmax])
colormap bluewhitered
cb = colorbar ;
ylabel(cb, '$H$', 'interpreter', 'latex')
% sgtitle(sprintf('$H$, $t=%03d$', tidx), 'interpreter', 'latex')
xlabel('x [$\mu$m]', 'interpreter', 'latex') ;
ylabel('y [$\mu$m]', 'interpreter', 'latex') ;
zlabel('z [$\mu$m]', 'interpreter', 'latex') ;

%%

for index = 1:2:26
        currH = storageStruct(index).HV;
        [a,b] = histcounts(abs(currH));
        scatter(b(1:20),log(a(1:20)),30,[index/26, 0, (26-index)/26],'filled')
        pause(.5)
        hold on
end

        xlabel('Curvature (1/pix)')
        ylabel('Log(Bin Counts)')
        set(gca,'FontSize',15);