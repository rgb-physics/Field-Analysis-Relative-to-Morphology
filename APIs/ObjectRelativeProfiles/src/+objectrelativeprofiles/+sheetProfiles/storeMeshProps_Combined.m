%% Effectively composites three scripts:
% - storeMeshProps_1_IntsCurvesVF.m
% - deltaH_PIV_Sheets.m
% - storeMeshProps_2_AppendPIV_DECVals.m
% 2025-08-01 - Rémi Boros

% Change for top vs. bot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% superString = 'top';
% structFields = {'TopSheet'};                                                
% structFieldsPIV = {'TopSheet','TopRegion'};
% vtxNormSign = 1;

superString = 'bot';
structFields = {'BotSheet'};                                                
structFieldsPIV = {'BotRegion','BotSheet'};
vtxNormSign = -1;

% Directories %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 28, Exp 6';
% baseSaveDir = '<redacted original absolute path>';
baseSaveDir = 'Session 28, Exp 6';

tifDir = fullfile(baseDir,'6 Illumination Bleach Corrected 16bit');
tifName = 't%03i_illBleachCorr16bit.tif';

ilSegDir = fullfile(baseDir,'7 Ilastik Segmentation 2\Split Objects');
ilSegName = 'SplitRegions_Time%06i.mat';

meshDir = fullfile(baseSaveDir,'9 Split Meshes');
meshName = '%sskel_vertices_t%03i_AND.ply';                               

pivDir = fullfile(baseSaveDir,'PIV Height Differences - 2');
pivName = '%s_t%03i_MTs_pivOUT_%s.mat';
if ~exist(pivDir,'dir')
    mkdir(pivDir);
end

structDir = fullfile(baseSaveDir,'10 Data on Meshes');         
structName = 'DataStoreStructT%03i_scatInt_%s.mat';                          
if ~exist(structDir,'dir')
    mkdir(structDir);
end

segVar = 'regionStruct';
structVar = 'currStruct';
% load metadata and segmentation (h5toMesh_homeoAndSplit.m)
load(fullfile(ilSegDir,'metadata.mat'));

selectTimes = 150:283;

% For section 1 - Ints, Curves, Verts, Faces
h5Bool = 0;
chanNum = 2;
threshVal = .6;
maxCuts = [190, 190, 90] ;      % coordinates of segmentation
minCuts = [1 1 1] ;
lapSmooth = 40;                 % Smoothing fields on meshes

% For section 2 - PIV
maskDil = 5;
imgDil = 2;
grdKern = 2;        % Use to remove grid artifacts in method 2
window = 12;
spacing = [8 8 8];
methodNum = 2;      % 0 - from images, 1 - from segmentation, 2 - from mesh
rsFactor = ogVoxSize/ogVoxSize(3)*2;    % set for rescaling base images in method 0; ensure voxels are cubic

% For section 3 - Velocities on mesh
deltaT = 30/60;                    % units of time (min)

%% Section 1 - filter vertices, faces, sample ints
for tInd = 1:numel(selectTimes)
    % Load in data
    currT = selectTimes(tInd);
    % Load intensity data
    currTif = tiffreadVolume(fullfile(tifDir, sprintf(tifName, currT)));
    % Load image segmentation
    if h5Bool == 1
        segData = h5read(fullfile(ilSegDir,sprintf(ilSegName,currT)),'/exported_data');
        selSegs = permute(squeeze(segData(chanNum,:,:,:)),[2 1 3]);
        binSegs = imbinarize(selSegs,threshVal);
    else
        segStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT)),segVar).(segVar);
        % segSize stored in metadata from segmentations of regionstructs
        binSegs = struct2Mat_sheets(segStruct,structFields,segSize);      
    end
    % Load segmented mesh (may want to reduce patch in future)
    currMesh = read_ply_mod(fullfile(meshDir, sprintf(meshName,superString,currT)));

%load vertices and faces - vertices are in x,y,z order (?)
    Vraw = currMesh.v ; Fraw = currMesh.f;
    %Cut mesh
    [Fcut, Vcut] = meshSideRemove(Fraw, Vraw, minCuts, maxCuts);
    [filtFcut,  unscalefiltVcut] = remove_isolated_mesh_components(Fcut,Vcut);
    filtVcut = unscalefiltVcut.*segVoxSize;     % segVoxSize from mesh generation metadata
    
%Get barycenter coords in scaled coordinates (um?)
    bcs = barycenter(filtVcut, filtFcut);
    bcsIMG = rescaleCoords(bcs,round(segSize.*segVoxSize),imgSize);
    
% Get surface normals, ensuring to flip sign s.t. normal points toward MTs
    vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % normalized
    if mean(vtxNormals(:,3))*vtxNormSign < 0
        vtxNormals = -vtxNormals;
    end
    [V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut);
    
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
    
% Intensities on vertices
    scinterpInt = scatteredInterpolant(rsX,rsY,rsZ,double(currTif(randIndsImg)));
    int_faces = scinterpInt(bcsIMG(:,1), bcsIMG(:,2), bcsIMG(:,3));
    int_verts = F2V*int_faces;

% Smooth fields (defined on vertices)
    [smoothInts, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',int_verts,lapSmooth/3);

% Save in struct
    currStruct = struct();
    currStruct.intF = int_faces;
    currStruct.intV = smoothInts;
    currStruct.v = filtVcut;
    currStruct.f = filtFcut;
    currStruct.bcs = bcs;
    currDEC = dec;
    
    if ~exist(structDir,'dir')
        mkdir(structDir);
    end
    save(fullfile(structDir,sprintf(structName,currT,superString)),'currStruct');
%     save(fullfile(saveDir,sprintf(saveName,currT,superString)),'currStruct','currDEC');
end

%% Section 2 - PIV of height differences to approximate change in H surface
dskStrel = strel('disk',grdKern);
maskStrel = strel('sphere',maskDil);
imgStrel = strel('sphere',imgDil);

for tInd = 1:(numel(selectTimes)-1)

    currT = selectTimes(tInd);
    nextT = selectTimes(tInd+1);

    % METHOD 0: Generate fields from tifs
    if methodNum == 0
        % Load images
        if tInd == 1
            img1 = double(tiffreadVolume(fullfile(tifDir,sprintf(tifName,currT))));
        else
            img1 = img2;    
        end
        img2 = double(tiffreadVolume(fullfile(tifDir,sprintf(tifName,nextT))));
        % Load segmentations for masking; preferably binary tifs
        if tInd == 1
            segStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT))).(segVar);
            inds1 = [segStruct.BotSheet; segStruct.TopSheet];
            mask1 = consMatLnB(true(segSize),inds1);
        else
            mask1 = mask2;
        end
        segStruct = load(fullfile(ilSegDir,sprintf(ilSegName,nextT))).(segVar);
        inds2 = [segStruct.BotSheet; segStruct.TopSheet];
        mask2 = consMatLnB(true(segSize),inds2);
        % Define voxel size and matrix size for PIV
        pivVoxSize = ogVoxSize./rsFactor;
        pivMatSize = round(ogVoxSize.*imgSize./pivVoxSize);

    % METHOD 1: Generate fields from segmentation structures
    elseif methodNum == 1
        pivVoxSize = segVoxSize;    pivMatSize = segSize;
        segStruct = load(fullfile(ilSegDir,sprintf(ilSegName,currT)),segVar).(segVar); 
        img1 = struct2Mat_sheets(segStruct,structFieldsPIV,segSize); 
        segStruct = load(fullfile(ilSegDir,sprintf(ilSegName,nextT)),segVar).(segVar); 
        img2 = struct2Mat_sheets(segStruct,structFieldsPIV,segSize); 

    % METHOD 2: Generate fields from mvertices    
    elseif methodNum == 2
        pivVoxSize = [1 1 1];   pivMatSize = round(segVoxSize.*segSize);
        load(fullfile(structDir,sprintf(structName,currT,superString)),'currStruct');
        img1 = rebuildMat(currStruct.v,segVoxSize,segSize,dskStrel,pivMatSize);
        load(fullfile(structDir,sprintf(structName,nextT,superString)),'currStruct');
        img2 = rebuildMat(currStruct.v,segVoxSize,segSize,dskStrel,pivMatSize);
    end

% Mask and image sizes must match: rescale if needed
    if ~isequal(pivMatSize, size(img2))
        if tInd == 1
            img1 = imresize3(img1,pivMatSize);
            mask1 = imresize3(mask1,pivMatSize,'nearest');
        end
        img2 = imresize3(img2,pivMatSize);
        mask2 = imresize3(mask2,pivMatSize,'nearest');
    end

% Dilate masks, if requested
    if maskDil > 0
    % Generate masks for methods 1 or 2
        if sum(ismember(methodNum,[1 2])) > 0 
            mask1 = imdilate(logical(img1+img2),maskStrel);
            mask2 = mask1;
        elseif methodNum == 0
            if tInd == 1
                mask1 = imdilate(mask1,maskStrel);
            end
            mask2 = imdilate(mask2,maskStrel);
        end
    end

% Dilate images before PIV?
    if (imgDil > 0) && (methodNum ~= 0)
        img1 = imdilate(logical(img1),imgStrel);
        img2 = imdilate(logical(img2),imgStrel);
    end
    
% Run PIV on difference of surfaces, using matrices from above    
    [allShifts, cenCoords, shifts, validCenCoords, queryDims] = ...
        calc3DPIV_Sparse(img1, img2, mask1, mask2, spacing, window, 'gaussian');
% Save Data
    save(fullfile(pivDir,sprintf(pivName,superString,currT,superString      )),'allShifts','cenCoords','shifts','validCenCoords','queryDims',"-mat");
    if tInd == 1
        save(fullfile(pivDir,'metadata.mat'),'pivMatSize','pivVoxSize','spacing','window','methodNum')
    end
end

%% Section 3 - growth terms, velocities, 

load(fullfile(pivDir,'metadata.mat'));
for tInd = 1:numel(selectTimes)  
% Load in data
    currT = selectTimes(tInd);
    % Load pre-existing structure
    currStruct = load(fullfile(structDir,sprintf(structName,currT,superString)),structVar).(structVar);
    % Vertices and faces
    filtFcut = currStruct.f;    filtVcut = currStruct.v;
    % Face barycenters in um, PIV dimensions, and image dimensions
    bcs = currStruct.bcs;
    bcsPIV = rescaleCoords(bcs,round(segSize.*segVoxSize),pivMatSize);

% Compute DiscreteExteriorCalculus of surface
    dec = DiscreteExteriorCalculus(filtFcut, filtVcut) ;
    [V2F, F2V] = meshAveragingOperators(filtFcut, filtVcut);

% Get surface normals, ensuring to flip sign s.t. normal points toward MTs
    vtxNormals = per_vertex_normals(filtVcut, filtFcut) ;  % normalized
    if mean(vtxNormals(:,3))*vtxNormSign < 0
        vtxNormals = -vtxNormals;
    end

% Curvatures - Laplacian points opposite to director
    HV = -sum(vtxNormals .* dec.laplacian(filtVcut), 2) * 0.5 ;
    
% Sample PIV results on mesh
    if ~exist(fullfile(pivDir,sprintf(pivName,superString,currT,superString)),'file')
        continue
    end
    load(fullfile(pivDir,sprintf(pivName,superString,currT,superString)),'shifts','validCenCoords');
    scaleShifts = shifts.*pivVoxSize/deltaT;        % dist/time; pivVoxSize from PIV metadata
    scaleCenCoords = validCenCoords.*pivVoxSize;    % dist: pivVoxSize from PIV metadata
    % Velocities on bcs using scattered interpolant
    scinterpx = scatteredInterpolant(scaleCenCoords(:,1),scaleCenCoords(:,2),scaleCenCoords(:,3),scaleShifts(:,1));
    scinterpy = scatteredInterpolant(scaleCenCoords(:,1),scaleCenCoords(:,2),scaleCenCoords(:,3),scaleShifts(:,2));
    scinterpz = scatteredInterpolant(scaleCenCoords(:,1),scaleCenCoords(:,2),scaleCenCoords(:,3),scaleShifts(:,3));
    % query the interp objects at the faces
    vx_faces = scinterpx(bcsPIV(:, 1), bcsPIV(:, 2), bcsPIV(:, 3)) ;
    vy_faces = scinterpy(bcsPIV(:, 1), bcsPIV(:, 2), bcsPIV(:, 3)) ;
    vz_faces = scinterpz(bcsPIV(:, 1), bcsPIV(:, 2), bcsPIV(:, 3)) ;

% make a #faces x 3 float array of velocities
    vfaces = [vx_faces, vy_faces, vz_faces] ;
    [vF_n, vF_t] = resolveTangentNormalVector(filtFcut, filtVcut, vfaces) ;
    vF_t(isnan(vF_t)) = 0;      % Sloppy fix
    vV_n = F2V * vF_n ; vV_t = F2V * vF_t ;

% Smooth fields (defined on vertices)
    [smoothVVT, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',vV_t,lapSmooth/3);
    [smoothHV, ~] = laplacian_smooth(filtVcut,filtFcut,'cotan',[],.1,'implicit',HV,lapSmooth);
    smoothVFT = V2F * real(smoothVVT);
    
% velocities on Vertices -- normal component: vV_n
    H2vn_onVertices = 2 * smoothHV .* vV_n ;
    divv = dec.divergence(smoothVFT) ;

% Save in structs
    currStruct.curvV = smoothHV;
    currStruct.vn_face = vF_n;
    currStruct.vt_face = vF_t;
    currStruct.hvn_vert = H2vn_onVertices;
    currStruct.divv_vert = divv;
    currStruct.vel_face = vfaces;
    % currDEC = dec;
    
    save(fullfile(structDir,sprintf(structName,currT,superString)),'currStruct');
%     save(fullfile(saveDir,sprintf(saveName,currT)),'currStruct','currDEC');

end

