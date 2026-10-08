%% Takes in meshes of segmented objects and samples velocities, intensities, and curvatures on faces
% 10/10/2023 - 10/18/2023
%% Directory info
% meshDir = '<redacted original absolute path>';
meshDir = 'Session 45, Exp 3';
meshName = 'Time%03i_pointCloud.ply';
% pivDir = '<redacted original absolute path>';
pivDir = 'Session 45, Exp 3';
pivName = 't%03i_pivOut.mat';
% tifDir = '<redacted original absolute path>';
tifDir = 'Session 45, Exp 3';
tifName = 't%03i_illBleachCorr16bit.tif';
% segDir = '<redacted original absolute path>';
segDir = 'Session 45, Exp 3';
segName = 'PassOne_t%03i_16bitSubSamp_Probabilities.h5';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 45, Exp 3';
saveName = 'Time%03i_fieldStruct.mat';

timeRange = 1:20;
cutOffDist = 1;     % same units as vertices, typically converted to micron
segChans = [2 3];
probThresh = .6;
scaleMat = [.37 .37 1.5];
lapSmooth = 100;
sampleNum = 200000;     % For sub-sampling run-time

%% Load meshes, then sample fields
for tInd = 1:numel(timeRange)
    tic
    % Load in data
    currT = timeRange(tInd);
    % Load intensity data
    currTif = tiffreadVolume(fullfile(tifDir, sprintf(tifName, currT)));
    imgSize = size(currTif);
    % Load image segmentation
    currh5Name = fullfile(segDir,sprintf(segName,currT));
    selSegs = sum(loadH5(currh5Name,'/exported_data',[2 3],1),4);
    binSegs = imbinarize(sum(selSegs,4),probThresh);
    % Load segmented mesh (may want to reduce patch in future)
    if isfile(fullfile(meshDir, sprintf(meshName,currT)))
        currMesh = read_ply_mod(fullfile(meshDir, sprintf(meshName,currT)));
    else
        continue
    end
    load(fullfile(pivDir,sprintf(pivName,currT)),'shifts','validCenCoords');
    
    %load vertices and faces
    Vraw = currMesh.v ; Fraw = currMesh.f;
    %Cut mesh
    [filtFcut, filtVcut] = meshSideRemove(Fraw, Vraw, cutOffDist*[1 1 1] + 1, ...
        [imgSize(2) imgSize(1) imgSize(3)].*scaleMat - cutOffDist);
    % [filtFcut,  filtVcut] = remove_isolated_mesh_components(Fcut,Vcut);
    
    %Get barycenter coords
    scaledbcs = barycenter(filtVcut, filtFcut);     % Used for plotting and storing
    bcs = scaledbcs./scaleMat;                      % Used for interpolation (piv and intensity data is in unscaled units)
    % Compute DiscreteExteriorCalculus of surface
    dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;
    
    % Get surface normals, ensuring to flip sign s.t. normal points toward MTs
    vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % normalized
    [V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut);
    
    % Curvatures
    HV = -sum(vtxNormals .* dec.laplacian(filtVcut), 2) * 0.5 ;
    
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
    vF_t(isnan(vF_t)) = 0;      % Sloppy fix
    vV_n = F2V * vF_n ; vV_t = F2V * vF_t ;
    
    % Intensities from scattered interpolant of subsample of binarized seg.
    randVec = randperm(sum(binSegs==1,'all'),min(sampleNum,sum(binSegs==1,'all')));   
    binSegInds = find(binSegs == 1);
    randInds = binSegInds(randVec);
    [randY, randX, randZ] = ind2sub(size(currTif), randInds);
    % [randY, randX, randZ] = ind2sub(size(currTif), randInds);
    
    % Intensities on vertices
    scinterpInt = scatteredInterpolant(randX,randY,randZ,double(currTif(randInds)));
    int_faces = scinterpInt(bcs(:,1), bcs(:,2), bcs(:,3));
    int_verts = F2V*int_faces;

    % Smooth fields (defined on vertices)
    [smoothHV, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',HV,lapSmooth);
    [smoothVVT, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',vV_t,lapSmooth/3);
    [smoothInts, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',int_verts,lapSmooth/3);
    [smoothLaps, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',dec.laplacian(filtVcut),lapSmooth/3);dec.laplacian(filtVcut);
    smoothVFT = V2F * smoothVVT;
    
    % velocities on Vertices -- normal component: vV_n
    H2vn_onVertices = 2 * smoothHV .* vV_n ;
    divv = dec.divergence(smoothVFT) ;

    % Save in struct
    currStruct = struct();
    currStruct.intF = int_faces;
    currStruct.intV = smoothInts;
    currStruct.curvV = smoothHV;
    currStruct.v = filtVcut;
    currStruct.f = filtFcut;
    currStruct.vn = vtxNormals;
    currStruct.bcs = scaledbcs;
    currStruct.vn_face = vF_n;
    currStruct.vt_face = vF_t;
    currStruct.hvn_vert = H2vn_onVertices;
    currStruct.divv_vert = divv;
    currStruct.v_face = vfaces;
    currStruct.scaleMat = scaleMat;
    currDEC = dec;
    
    save(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
%     save(fullfile(saveDir,sprintf(saveName,currT)),'currStruct','currDEC');
toc
end

%% Display field on surface of your choice
winBounds = [800 800 75].*[.37 .37 1.5];
meshFieldName = 'v_face';
for tInd = 1:numel(timeRange)
% tInd = 10;
    currT = timeRange(tInd);
    if isfile(fullfile(saveDir,sprintf(saveName,currT)))
        load(fullfile(saveDir,sprintf(saveName,currT)));
    else
        continue
    end

    tri = triangulation(currStruct.f,currStruct.v);
    meshField = currStruct.(meshFieldName);
    % figure
    trisurf(tri,meshField(:),'edgecolor','none');
    axis equal
    cmax = prctile(abs(meshField(:)),95);
    clim([-cmax cmax])
    xlim([1 winBounds(1)])
    ylim([1 winBounds(2)])
    zlim([1 winBounds(3)])
    % clim([-.13 13]);
    colorbar
    ginput();
end

%% Curvature on barycenters, flow field at barycenters

winBounds = [800 800 75].*[.37 .37 1.5];
sampFrac = 10;
saveBool = 0;
meshFieldName = 'curvV';
quiverName = 'vn';
magName = 'divv_vert';
% imgSaveDir = '<redacted original absolute path>';
imgSaveDir = 'Session 45, Exp 3';
imgSaveName = 'Frame%03i_quiverunscaled.tif';
if ~isfile(imgSaveDir)
    mkdir(imgSaveDir);
end
for tInd = 1:numel(timeRange)

    currT = timeRange(tInd);
    if isfile(fullfile(saveDir,sprintf(saveName,currT)))
        load(fullfile(saveDir,sprintf(saveName,currT)));
    else
        continue
    end
    meshField = currStruct.(meshFieldName)(:,1);
    quiverField = currStruct.(quiverName);
    quiverMags = currStruct.(magName);  
    quiverField = quiverField.*quiverMags;      
    filtFcut = currStruct.f;    filtVcut = currStruct.v;
    subrand = randperm(size(filtVcut,1),round(size(filtVcut,1)/sampFrac));
    % subrand = randperm(size(filtFcut,1),round(size(filtFcut,1)/sampFrac));
    scaledbcs = currStruct.bcs;

    tri = triangulation(filtFcut,filtVcut);
    trisurf(tri, meshField(:),'edgecolor','none')
    axis equal
    cmax = prctile(abs(meshField(:)),95);
    clim([-.5 .5])
    % clim([-cmax cmax])
    xlim([1 winBounds(1)])
    ylim([1 winBounds(2)])
    zlim([1 winBounds(3)])
    xlabel('this is x')
    colorbar
    hold on
    quiver3(filtVcut(subrand,1),filtVcut(subrand,2),filtVcut(subrand,3),...
        quiverField(subrand,1),quiverField(subrand,2),quiverField(subrand,2),0,'r')
    % quiver3(scaledbcs(subrand,1),scaledbcs(subrand,2),scaledbcs(subrand,3),velFields(subrand,1),velFields(subrand,2),velFields(subrand,2),0,'r')
    set(gcf, 'Position',  [100, 100, 1000, 800])
    title(sprintf('Frame %03i',currT));
    set(gca,'FontSize',15)
    % pause(.1)
    hold off
    
    if saveBool
        exportgraphics(gca,fullfile(imgSaveDir,sprintf(imgSaveName,currT)));
    else
        ginput();
    end

end

%% intensity vs curvature 

[N,Xedges,Yedges] = histcounts2(currStruct.intV,currStruct.curvV,10:110,-.3:.01:.3);
winSize = 4;
for currI = (winSize+1):(numel(Xedges)-(1+winSize))
    plot(Yedges(1:end-1),sum(N((currI-winSize):(currI+winSize),:),1)/sum(N((currI-winSize):(currI+winSize),:),'all'),'Color',[ currI/numel(Xedges) 0 (1 - currI/numel(Xedges))]);
    hold on
end

set(gca,'FontSize',15)
xlabel('Curvature')
ylabel('Scaled Int. Distribution')
title('Curvature Dist. per Intensity (roll avg. 4)')


