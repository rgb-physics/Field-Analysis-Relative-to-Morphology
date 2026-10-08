% may or may not need to run setup.m in imsane FROM IMSANE DIR (ie cd
% to imsane/ first).
% baseMat = '<redacted original absolute path>';
baseMat = 'Session 28, Exp 6';
% baseSaveMat = '<redacted original absolute path>';
baseSaveMat = 'Session 28, Exp 6';
ilSegDir = fullfile(baseMat,'7 Ilastik Segmentation 2\Split Objects');
ptCloudDir = fullfile(baseSaveMat,'8 Ply Objects');
meshDir = fullfile(baseSaveMat,'9 Split Meshes');
saveDir = fullfile(baseSaveMat,'10 Quantitative Data\Data on Bot');         %*
% PIVDir = '<redacted original absolute path>';
PIVDir = 'Session 28, Exp 6';
subDirs = {''};
% subDirs = {'Bot Layers', 'Top Layers'};
ilSegName = 'SplitRegions_Time%06i.mat';
ptCloudName = 'botskel_vertices_t%03i_AND.ply';                             %*
meshName = 'botskel_vertices_t%03i_AND.ply';                                %*
saveName = 'DataStoreStructT%03i_scatInt_Bot.mat';                          %*
pivName = 't%03i_MTs_pivOUT.mat';
subNames = {''};
structFields = {'BotSheet'};                                              %*
% structFields = {'TopSheet'};                                                %*
% structFields = {'TopSheet','BotSheet'};
segVar = 'regionStruct';

% tifDir = '<redacted original absolute path>';
tifDir = 'Session 28, Exp 6';
tifName = 't%03i_illBleachCorr16bit.tif';

% load metadata from piv (Run3DPIV.m) and segmentation (h5toMesh_homeoAndSplit.m)
load(fullfile(PIVDir,'metadata.mat'));
load(fullfile(ilSegDir,'metadata.mat'));

h5Bool = 0;
chanNum = 2;
threshVal = .6;

maxCuts = [190, 190, 90] ;      % coordinates of segmentation
minCuts = [1 1 1] ;
selectTimes = 150:200;
lapSmooth = 40;
% voxSize = [2.95 2.95 2.95];     % um/pix
% pivVox = voxSize*1000;          % nm/pix
deltaT = 30/60;                    % units of time (min)
vtxNormSign = -1;

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
%% 
strelObj = strel('sphere',1);
for tInd = 1:numel(selectTimes)
    % Load in data
    tic
    currT = selectTimes(tInd);
    % Load intensity data
    currTif = tiffreadVolume(fullfile(tifDir, sprintf(tifName, currT)));
    % Load image segmentation
    if h5Bool == 1
        segData = h5read(fullfile(ilSegDir,sprintf(ilSegName,currT)),'/exported_data');
        selSegs = permute(squeeze(segData(chanNum,:,:,:)),[2 1 3]);
        binSegs = imbinarize(selSegs,threshVal);
    else
        storeStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT)),segVar).(segVar);
        % segSize stored in metadata from segmentations of regionstructs
        binSegs = struct2Mat_sheets(storeStruct,structFields,segSize);      
    end
    % Load segmented mesh (may want to reduce patch in future)
    currMesh = read_ply_mod(fullfile(meshDir, sprintf(meshName,currT)));
    load(fullfile(PIVDir,sprintf(pivName,currT)),'shifts','validCenCoords');
    scaleShifts = shifts.*pivVoxSize/deltaT;        % dist/time; pivVoxSize from PIV metadata
    scaleCenCoords = validCenCoords.*pivVoxSize;    % dist: pivVoxSize from PIV metadata
    
    %load vertices and faces - vertices are in x,y,z order (?)
    Vraw = currMesh.v ; Fraw = currMesh.f;
    %Cut mesh
    [Fcut, Vcut] = meshSideRemove(Fraw, Vraw, minCuts, maxCuts);
    [filtFcut,  unscalefiltVcut] = remove_isolated_mesh_components(Fcut,Vcut);
    filtVcut = unscalefiltVcut.*segVoxSize;     % segVoxSize from mesh generation metadata
    
    %Get barycenter coords in scaled coordinates (um?)
    bcs = barycenter(filtVcut, filtFcut);
    % Get barycenter coords in PIV and original tif coordinates
    bcsPIV = rescaleCoords(bcs,round(segSize.*segVoxSize),pivMatSize);
    bcsIMG = rescaleCoords(bcs,round(segSize.*segVoxSize),imgSize);
    % Compute DiscreteExteriorCalculus of surface
    dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;
    
    % Get surface normals, ensuring to flip sign s.t. normal points toward MTs
    vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % normalized
    if mean(vtxNormals(:,3))*vtxNormSign < 0
        vtxNormals = -vtxNormals;
    end
    [V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut);
    
    % Curvatures - Laplacian points opposite to director
    HV = -sum(vtxNormals .* dec.laplacian(filtVcut), 2) * 0.5 ;
    
    % Velocities on bcs using scattered interpolant
    scinterpx = scatteredInterpolant(scaleCenCoords(:,1),scaleCenCoords(:,2),scaleCenCoords(:,3),scaleShifts(:,1));
    scinterpy = scatteredInterpolant(scaleCenCoords(:,1),scaleCenCoords(:,2),scaleCenCoords(:,3),scaleShifts(:,2));
    scinterpz = scatteredInterpolant(scaleCenCoords(:,1),scaleCenCoords(:,2),scaleCenCoords(:,3),scaleShifts(:,3));
    % scinterpx = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,1));
    % scinterpy = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,2));
    % scinterpz = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,3));
    % query the interp objects at the faces
    vx_faces = scinterpx(bcsPIV(:, 1), bcsPIV(:, 2), bcsPIV(:, 3)) ;
    vy_faces = scinterpy(bcsPIV(:, 1), bcsPIV(:, 2), bcsPIV(:, 3)) ;
    vz_faces = scinterpz(bcsPIV(:, 1), bcsPIV(:, 2), bcsPIV(:, 3)) ;

    % make a #faces x 3 float array of velocities
    vfaces = [vx_faces, vy_faces, vz_faces] ;
    [vF_n, vF_t] = resolveTangentNormalVector(filtFcut, filtVcut, vfaces) ;
    vF_t(isnan(vF_t)) = 0;      % Sloppy fix
    vV_n = F2V * vF_n ; vV_t = F2V * vF_t ;
    
% Intensities from scattered interpolant of subsample of binarized seg.
    % Subsample intensities at selection of sheet indices 
    % (segmentation matrix size)
    sampleNum = round(sum(binSegs==1,'all')/4);
    randVec = randperm(sum(binSegs==1,'all'),sampleNum);   
    binSegInds = find(binSegs == 1);
    randInds = binSegInds(randVec);
    randIndsImg = rescaleCoords_Inds(randInds,segSize,imgSize);
    [randY, randX, randZ] = ind2sub(segSize, randInds);

    % Rescale coordinates to image scale
    img2Seg = imgSize./segSize;
    rsX = randX*img2Seg(2);    rsY = randY*img2Seg(1);    rsZ = randZ*img2Seg(3);
    % rsCoords = rescaleCoords([randX,randY,randZ],segSize,imgSize);
    
    % Intensities on vertices
    scinterpInt = scatteredInterpolant(rsX,rsY,rsZ,double(currTif(randIndsImg)));
    int_faces = scinterpInt(bcsIMG(:,1), bcsIMG(:,2), bcsIMG(:,3));
    int_verts = F2V*int_faces;
    % Intensities on vertices - round barycenters and sample
    % bcsIMGInds  = sub2ind(size(currTif),bcsIMG(:,2), bcsIMG(:,1), bcsIMG(:,3));
    % compare_faces = double(currTif(bcsIMGInds));
    % compare_verts = F2V*compare_faces;

    % Smooth fields (defined on vertices)
    [smoothHV, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',HV,lapSmooth);
    [smoothVVT, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',vV_t,lapSmooth/3);
    [smoothInts, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',int_verts,lapSmooth/3);
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
    currStruct.bcs = bcs;
    currStruct.vn_face = vF_n;
    currStruct.vt_face = vF_t;
    currStruct.hvn_vert = H2vn_onVertices;
    currStruct.divv_vert = divv;
    currStruct.vel_face = vfaces;
    currDEC = dec;
    
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    save(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
%     save(fullfile(saveDir,sprintf(saveName,currT)),'currStruct','currDEC');
toc
end

%% Display on triangulated surface
[test, testa] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',vV_n,50);

%% intensity vs curvature 

[N,Xedges,Yedges] = histcounts2(smoothInts,smoothHV,10:110,-.3:.01:.3);
winSize = 4;
for currI = (winSize+1):(numel(Xedges)-(1+winSize))
    plot(Yedges(1:end-1),sum(N((currI-winSize):(currI+winSize),:),1)/sum(N((currI-winSize):(currI+winSize),:),'all'),'Color',[ currI/numel(Xedges) 0 (1 - currI/numel(Xedges))]);
    hold on
end

set(gca,'FontSize',15)
xlabel('Curvature')
ylabel('Scaled Int. Distribution')
title('Curvature Dist. per Intensity (roll avg. 4)')

% exportgraphics(gca,fullfile(saveDir1,sprintf(saveName1,currT)));
% 
% close all

%% intensity vs curvature over time
% saveDir1 = fullfile('<redacted original absolute path>','Int Dists v Curves Symmetric');
saveDir1 = fullfile('Session 45, Exp 3','Int Dists v Curves Symmetric');
saveName1 = 't%04i.png';

mkdir(saveDir1);
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    load(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
    smoothInts = currStruct.intV;
    smoothHV = currStruct.curvV;
    minInt = prctile(smoothInts,5); maxInt = prctile(smoothInts,95);
    [N,Xedges,Yedges] = histcounts2(smoothInts,smoothHV,minInt:maxInt,-.3:.01:.3);
    winSize = 4;
%     for currI = (winSize+1):(numel(Xedges)-(1+winSize))
%         plot(Yedges(1:end-1),sum(N((currI-winSize):(currI+winSize),:),1)/sum(N((currI-winSize):(currI+winSize),:),'all'),'Color',[ currI/numel(Xedges) 0 (1 - currI/numel(Xedges))]);
%         hold on
%     end
    for currI = (winSize+1):(numel(Xedges)-(1+winSize))
        currDist = N((currI-winSize):(currI+winSize),:);
        plot(flip(Yedges(round(end/2):end-1)),sum(currDist(:,1:round(end/2)),1)/sum(N((currI-winSize):(currI+winSize),:),'all'),...
            'Color',[ currI/numel(Xedges) 0 (1 - currI/numel(Xedges))]);
        hold on
        plot(Yedges(round(end/2):end-1),sum(currDist(:,(round(end/2)+1):end),1)/sum(N((currI-winSize):(currI+winSize),:),'all'),...
            'Color',[ currI/numel(Xedges) 0 (1 - currI/numel(Xedges))]);
    end
    
    set(gca,'FontSize',15)
    xlabel('Curvature')
    ylabel('Scaled Int. Distribution')
    ylim([-.05 .3])
    title('Curvature Dist. per Intensity (roll avg. 4)')
    
    exportgraphics(gca,fullfile(saveDir1,sprintf(saveName1,currT)));
    
    close all
end
%%  Load more data

currT = 10;
load(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
smoothHV = currStruct.curvV;
filtFcut = currStruct.f;
filtVcut= currStruct.v;

%%
figure
% currField = int_verts - compare_verts;
currField = compare_verts;

tri = triangulation(filtFcut,filtVcut);
trisurf(tri, (currField(:)), 'edgecolor','none');
cmax = prctile(abs(currField(:)),95);
% clim([-0.3 0.3]);
clim([6000 16000])
% clim([-cmax cmax]);
axis equal
colorbar
xlabel('X')
ylabel('Y')
zlabel('Z')
set(gca,'FontSize',15)
% title('Curvatures')
hold on
selInds = bcsIMG(:,3) < 27 & bcsIMG(:,3) > 25;
 scatter3(bcsIMG(selInds,1)*ogVoxSize(1), bcsIMG(selInds,2)*ogVoxSize(2), bcsIMG(selInds,3)*ogVoxSize(3),1,'red','filled');
 % scatter3(bcsIMG(selInds,2)*ogVoxSize(2), bcsIMG(selInds,1)*ogVoxSize(1), bcsIMG(selInds,3)*ogVoxSize(3),1,'blue','filled');
 % scatter3(bcsIMG(:,1)*ogVoxSize(1), bcsIMG(:,2)*ogVoxSize(2), bcsIMG(:,3)*ogVoxSize(3),1,'red','filled');
axis equal

manualScale = 10;
selInds2 = scaleCenCoords(:,3) < 45;
quiver3(scaleCenCoords(selInds2,1),scaleCenCoords(selInds2,2),scaleCenCoords(selInds2,3),...
    scaleShifts(selInds2,1)*manualScale,scaleShifts(selInds2,2)*manualScale,scaleShifts(selInds2,3)*manualScale,0,'blue');
% selInds3 = bcsIMG(:,3) < 45;
% selInds3 = selInds3(1:7:end);
selInds3 = selInds;
rsCoords = bcsPIV.*pivVoxSize;
% quiver3(rsCoords(selInds3,1),rsCoords(selInds3,2),rsCoords(selInds3,3),...
%     vfaces(selInds3,1)*manualScale,vfaces(selInds3,2)*manualScale,vfaces(selInds3,3)*manualScale,0,'red');
% axis equal
%% Display quiver plot; validate by sheet
% PIV - validCenCoords
% Seg - binSegs

% Convert PIV coordinates to indices  (x,y) -> (col,row)
pivCenInds = sub2ind(pivMatSize,validCenCoords(:,2),validCenCoords(:,1),validCenCoords(:,3));
% Scale piv coords to seg mat coordinates/size
pivCensInSeg = rescaleCoords_Inds(pivCenInds,pivMatSize,segSize);
% verify
% orthosliceViewer(binSegs + consMatLnB(ones(size(binSegs)),pivCensInSeg));
% Find PIV centers that are in binSegs 
% - can also compare direct to outputStruct.(structFields)
validPIV = ismember(pivCensInSeg,find(binSegs));

% Display
hold on
quiver3(scaleCenCoords(validPIV,1),scaleCenCoords(validPIV,2),scaleCenCoords(validPIV,3),...
    scaleShifts(validPIV,1),scaleShifts(validPIV,2),scaleShifts(validPIV,3),2,'red');


%% Compare lapsmooth steps
currField = HV;
selSteps = 2:4:20;
storeMat = repmat(currField,1,numel(selSteps)+1);
for index = 1:numel(selSteps)
    storeMat(:,index+1) = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',currField,selSteps(index));
end
    % [smoothHV, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',HV,lapSmooth);

%% plot compared lapsmooth
xBnds = [0 100];
yBnds = [0 100];
fieldBnds = [-.2 .2];
dispSteps = [0 selSteps];
figure
for index = 1:size(storeMat,2)
    currField = storeMat(:,index);
    tri = triangulation(filtFcut,filtVcut);
    trisurf(tri, (currField(:)), 'edgecolor','none');
    % cmax = prctile(abs(currField(:)),95);
    % clim([-cmax cmax]);
    clim(fieldBnds);
    axis equal
    colorbar
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    set(gca,'FontSize',15)
    xlim(xBnds); ylim(  yBnds);
    title(sprintf('%i laplacian steps',dispSteps(index)))
    ginput();
end

%% Sample wrt z
zLow = 24;  zHigh = 28+12;
xBnds = [0 100];
yBnds = [0 100];
deadVal = 0;
vertLogic = [find(filtVcut(:,3)<zLow); find(filtVcut(:,3)>zHigh)];
quarterLogic = find( (filtVcut(:,1) > min(xBnds)) & (filtVcut(:,1) < max(xBnds)*1.5) ...
    & (filtVcut(:,2) > min(yBnds)) & (filtVcut(:,2) < max(yBnds)*1.5) );
quartFaceLogic = logical(sum(ismember(filtFcut,quarterLogic),2));
faceLogic = logical(sum(ismember(filtFcut,vertLogic),2));
currField = smoothHV;
dispField = ones(size(currField))*deadVal;
dispField(vertLogic) = smoothHV(vertLogic);

figure
tri = triangulation(filtFcut(quartFaceLogic,:),filtVcut);
trisurf(tri, ones(size(vertLogic)),'FaceColor','black','FaceAlpha',0,'LineWidth',0.25);
hold on
tri = triangulation(filtFcut,filtVcut);
trisurf(tri, ones(size(vertLogic)),'FaceColor','black','FaceAlpha',0.2,'edgecolor','none');
% trisurf(tri, ones(size(vertLogic)),'FaceColor','black','FaceAlpha',0.2,'EdgeColor',[0.5 0.5 0.5]);
tri = triangulation(filtFcut(faceLogic,:),filtVcut);
trisurf(tri, (currField(:)), 'edgecolor','none');
% cmax = prctile(abs(currField(:)),95);
% clim([-cmax cmax]);
clim(fieldBnds);
axis equal
colorbar
xlabel('X')
ylabel('Y')
zlabel('Z')
set(gca,'FontSize',15)
% xlim(xBnds); ylim(  yBnds);
xlim(xBnds*3); ylim(  yBnds*3);

%% Compare scattered interpolation efficiency over varying sample point #
    sampleNums= 100000:100000:2000000;
    storeVec = zeros(2,numel(sampleNums));
    for currNum = 1:numel(sampleNums)
        tic
        currSamp = sampleNums(currNum);
        randVec = randperm(sum(binSegs==1,'all'),currSamp);   
        binSegInds = find(binSegs == 1);
        randInds = binSegInds(randVec);
        [randY, randX, randZ] = ind2sub(size(currTif), randInds);

        scinterIntTemp = scatteredInterpolant(randX,randY,randZ,double(currTif(randInds)));

        int_faces = scinterIntTemp(bcs(:,1), bcs(:,2), bcs(:,3));
        int_verts = F2V*int_faces;

        histogram(int_verts(:),5:100);
        hold on
        storeVec(1,currNum) = toc;
        storeVec(2,currNum) = currSamp;
    end

    validInds = sub2ind(size(currTif),validCenCoords(:,2),validCenCoords(:,1),validCenCoords(:,3));
    scinterInt = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),double(currTif(validInds)));
    scinterInt2 = scatteredInterpolant(shellx,shelly,shellz,double(currTif(segShell)));
    int_faces = scinterInt(bcs(:,1), bcs(:,2), bcs(:,3));
    int_verts = F2V*int_faces;
    int_faces2 = scinterInt2(bcs(:,1), bcs(:,2), bcs(:,3));
    int_verts2 = F2V*int_faces2;

    int_faces = scinterIntTemp(bcs(:,1), bcs(:,2), bcs(:,3));
    int_verts = F2V*int_faces;
%% Load images
% saveDir1 = '<redacted original absolute path>';
saveDir1 = 'Session 45, Exp 3';
saveName1 = '%03i_HVn.png';
selectTimes = 120:170;
mkdir(saveDir1);
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    load(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
%     currN = histcounts2(currStruct.hvn_vert, currStruct.divv_vert, -1:.01:1, -1:.01:1);
%     imagesc(flipud(log(currN))');
%     exportgraphics(gca,fullfile(saveDir1,sprintf(saveName1,currT)));
    
    currField = abs(currStruct.intV);
    currF = currStruct.f;   currV = -currStruct.v;
%     currV(:,3) = -currV(:,3);

%     [~, F2V] = meshAveragingOperators(currF, currV);
%     currField = abs(F2V*currStruct.vn_face);
    tri = triangulation(currF,currV);
    trisurf(tri, (currField(:)), 'edgecolor','none');
%     cmax = prctile(abs(currField(:)),95);
    clim([-.0 85]);
    axis equal
    colorbar
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
%     zlim([0 150])

    zlim([-150 0])
%     set(gca,'FontSize',15)

    exportgraphics(gca,fullfile(saveDir1,sprintf(saveName1,currT)));
end


%% Growth
% saveDir1 = '<redacted original absolute path>';
saveDir1 = 'Session 45, Exp 3';
saveName1 = '%03i_growth.png';
selectTimes = 120:170;
mkdir(saveDir1);
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    load(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
    currN = histcounts2(currStruct.hvn_vert, currStruct.divv_vert, -1:.01:1, -1:.01:1);
    imagesc(flipud(log(currN))');
    clim([0 12])

    exportgraphics(gca,fullfile(saveDir1,sprintf(saveName1,currT)));
    
end




