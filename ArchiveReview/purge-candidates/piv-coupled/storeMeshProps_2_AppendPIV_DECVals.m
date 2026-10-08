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
structVar = 'currStruct';

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
selectTimes = 204:208;
lapSmooth = 40;
% voxSize = [2.95 2.95 2.95];     % um/pix
% pivVox = voxSize*1000;          % nm/pix
deltaT = 30/60;                    % units of time (min)
vtxNormSign = -1;

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end
%%

for tInd = 1:numel(selectTimes)
    % Load in data
    tic
    currT = selectTimes(tInd);
    % Load pre-existing structure
    currStruct = load(fullfile(saveDir,sprintf(saveName,currT)),structVar).(structVar);
    % Vertices and faces
    filtFcut = currStruct.f;    filtVcut = currStruct.v;
    % Face barycenters in um, PIV dimensions, and image dimensions
    bcs = currStruct.bcs;
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
    
    % Prepare piv units
    load(fullfile(PIVDir,sprintf(pivName,currT)),'shifts','validCenCoords');
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
    smoothVFT = V2F * smoothVVT;
    
    % velocities on Vertices -- normal component: vV_n
    H2vn_onVertices = 2 * smoothHV .* vV_n ;
    divv = dec.divergence(smoothVFT) ;

    % Save in structs
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
