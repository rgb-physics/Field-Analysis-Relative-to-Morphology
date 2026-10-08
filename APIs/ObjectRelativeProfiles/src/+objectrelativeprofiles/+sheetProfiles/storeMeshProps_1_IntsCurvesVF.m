% Get intensities, curvatures, clean up faces and verts from meshes.
% Basically, everything other than PIV
% 2025-08-01 - Rémi  Boros
% baseMat = '<redacted original absolute path>';
baseMat = 'Session 28, Exp 6';
% baseSaveMat = '<redacted original absolute path>';
baseSaveMat = 'Session 28, Exp 6';
ilSegDir = fullfile(baseMat,'7 Ilastik Segmentation 2\Split Objects');
ptCloudDir = fullfile(baseSaveMat,'8 Ply Objects');
meshDir = fullfile(baseSaveMat,'9 Split Meshes');
saveDir = fullfile(baseSaveMat,'10 Quantitative Data\Data on Top');         %*
subDirs = {''};
% subDirs = {'Bot Layers', 'Top Layers'};
ilSegName = 'SplitRegions_Time%06i.mat';
ptCloudName = 'topskel_vertices_t%03i_AND.ply';                             %*
meshName = 'toptskel_vertices_t%03i_AND.ply';                                %*
saveName = 'DataStoreStructT%03i_scatInt_Top.mat';                          %*
subNames = {''};
% structFields = {'BotSheet'};                                                    %*
structFields = {'TopSheet'};                                                %*
% structFields = {'TopSheet','BotSheet'};
segVar = 'regionStruct';

% tifDir = '<redacted original absolute path>';
tifDir = 'Session 28, Exp 6';
tifName = 't%03i_illBleachCorr16bit.tif';

% load metadata from segmentation (h5toMesh_homeoAndSplit.m)
load(fullfile(ilSegDir,'metadata.mat'));

h5Bool = 0;
chanNum = 2;
threshVal = .6;

maxCuts = [190, 190, 90] ;      % coordinates of segmentation
minCuts = [1 1 1] ;
selectTimes = 199:283;
lapSmooth = 40;
% voxSize = [2.95 2.95 2.95];     % um/pix
% pivVox = voxSize*1000;          % nm/pix
deltaT = 30/60;                    % units of time (min)
vtxNormSign = -1;

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
%% Iterate over time, sample values, store
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

    %load vertices and faces - vertices are in x,y,z order (?)
    Vraw = currMesh.v ; Fraw = currMesh.f;
    %Cut mesh
    [Fcut, Vcut] = meshSideRemove(Fraw, Vraw, minCuts, maxCuts);
    [filtFcut,  unscalefiltVcut] = remove_isolated_mesh_components(Fcut,Vcut);
    filtVcut = unscalefiltVcut.*segVoxSize;     % segVoxSize from mesh generation metadata
    
    %Get barycenter coords in scaled coordinates (um?)
    bcs = barycenter(filtVcut, filtFcut);
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
    [smoothInts, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',int_verts,lapSmooth/3);

    % Save in struct
    currStruct = struct();
    currStruct.intF = int_faces;
    currStruct.intV = smoothInts;
    currStruct.curvV = smoothHV;
    currStruct.v = filtVcut;
    currStruct.f = filtFcut;
    currStruct.bcs = bcs;
    currDEC = dec;
    
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    save(fullfile(saveDir,sprintf(saveName,currT)),'currStruct');
%     save(fullfile(saveDir,sprintf(saveName,currT)),'currStruct','currDEC');
toc
end



