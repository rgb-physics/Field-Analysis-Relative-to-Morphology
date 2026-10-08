% Filament Detection
% ideally, loads .h5s directly, applies threshold, returns binarized
% objects. Then the script will do statistics
% This script takes in directory/directories containing .tifs of segmented
% filaments from .h5s. It measures the statistics of said filaments without
% considering statistics from the 3rd dimension
% 2023-11-13 Rémi Boros
% Adapted 2026-08-05 to run from binarized .tifs of filaments rather than
% from  .h5s to detect filaments
% Attempted on 2026/08/05: Looks good....

expDirs = {'Exp 1','Exp 2','Exp 3','Exp 4 - Rmin Redo','Exp 5'};

for dirInd = 1:numel(expDirs)


% baseDir = fullfile('<redacted original absolute path>',expDirs{dirInd});
baseDir = fullfile('Session 88',expDirs{dirInd});
filDir = fullfile(baseDir,'6 Filament Data');
filName = 'Time%06i_threshFils.tif';

segDirSuper = baseDir;
saveDirSuper = fullfile(filDir,'AlignmentData - Fils2Aligns_TIFS');
filSaveName = 'Filament Statistics %03i.mat';

binarizeBool = 1; 
scaleFacts = [1 1];
selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation'};
selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};

% Filament Alignment 
% Compare sparse filament alignment with object surface norms from dense
% Calculates orientation tensor of each filament based on orientation in
% cartesian space and samples gradient at each filament center of mass.
% Creates orientation tensor for gradient field, too. Takes product between
% both tensors over each filament, then averages after selection.
% NOTE: This implementation takes in Filament Statistics at each time
% point, not a concatenated structure for all times.
% From A_getFilamentStats_2Dand3D.m
% 2025-02-17 - Rémi Boros
filDataDir = saveDirSuper;
filDataName = filSaveName;
% In/on/out segmentations (converted to .tifs already)
iooSegDir = fullfile(baseDir, '4 Tracked Blobs\In On Out Segmentation');
iooSegName = 'T%03i_CleanInOnOut.tif';
saveDir = fullfile(filDir,'Filament Alignment Statistics');

timeRange =  40;
segthresh = 0.33;
ogVoxSize = [.55 .55 0.7];      % Pixel size of microscope image;
inOnDist = 1;           % 1 to distinguish drop interiors and boundaries, otherwise combine interiors and boundaries and compare to bg

% Save tifs of distance transforms used for gradients?
saveDistMats = 0;
bwSaveDir = fullfile(filDir,'Boundary Distance Transforms');
bwSaveName = 'T%06i_distanceTransform.mat';

segChans = [1 2 3];
binVals = [0 100 200 300];  
inOnOutBins = [3 2 1];

if ~exist(saveDirSuper,'dir')
    mkdir(saveDirSuper);
end

%% PART A - get filament statistics in 2D and 3D %%%%%%%%%%%%%%%%%%%%%%%%%%
% Load .tifs of binarized filaments
for tInd = 1:numel(timeRange)
    newBool = 1;        % Used to define new storage struct in cases where no objects are observed in first z slice
    currT = timeRange(tInd);
    currMat = logical(tiffreadVolume(fullfile(filDir,sprintf(filName,currT))));
    if tInd == 1
        imgSize = size(currMat);
    end

    % Get regionprops for 3D, store in .mat file
    bwObjs = logical(currMat);
    % If voxels are anisotropic, regionprops3 will not work
    % Must run regionprops3 on rescaled indices
    rp3D = regionprops3(bwObjs, selFields3D);
    % Make filament properties calculated from regionprops
    catEVecs = [rp3D.EigenVectors{:}];
    % EVecs are returned in (row,col,page) form; swap x,y
    % Isolate every third column. Each evec is a column. 1st col is dir.
    catEVecs1 = catEVecs([2 1 3],1:3:end); 
    filDirs = catEVecs1';                   % Convert to rows
    filLens = [rp3D.PrincipalAxisLength(:,1)];
    filOffLens = [rp3D.PrincipalAxisLength(:,2:3)];
    filARs = filLens./filOffLens(:,1);
    % Append properties
    rp3D.('Directors') = filDirs;
    rp3D.('Lengths') = filLens;     % stored in voxels
    rp3D.('AspectRatios') = filARs;

% Calculate eigenvectors from voxels of the current filament
    aniFilDirs = filDirs;   aniLens = filLens;  aniARs = filARs;
    stats = regionprops3(bwObjs, "VoxelList");
    for filInd = 1:numel(stats)
        currFilRS = stats.VoxelList{filInd}.*ogVoxSize;
        filRSSize = currFilRS - mean(currFilRS,1);
        covRS = (filRSSize'*filRSSize)/max((size(filRSSize,1)-1),1);
        [eVecs,eVals] = eig(covRS);
        % Project all voxels along the eVec with largest eVal
        [~,eigOrder] = sort(sum(eVals,1),'descend');
        aniFilDir = eVecs(:,eigOrder(1));
        projVoxels = filRSSize*aniFilDir;
        aniFilLen = max(projVoxels) - min(projVoxels);
        % Calculate anisotropic aspect ratio
        projSecond = filRSSize*eVecs(:,eigOrder(2));
        secondLen = max(projSecond) - min(projSecond);
        aniAR = aniFilLen/max(1,secondLen);
% Store filament properties accounting for anisotropic voxels
        aniFilDirs(filInd,:) = aniFilDir(:);
        aniLens(filInd) = aniFilLen;
        aniARs(filInd) = aniAR;
    end
    rp3D.('AniDirectors') = aniFilDirs;
    rp3D.('AniLengths') = aniLens;     % stored in ums
    rp3D.('AniAspectRatios') = aniARs;
    save(fullfile(saveDirSuper,sprintf(filSaveName, currT)),'rp3D','scaleFacts');
end
save(fullfile(saveDirSuper,'FilamentDetect_metadata.mat'),"ogVoxSize",'imgSize')

%% PART B - Filament Alignments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load(fullfile(saveDirSuper,'FilamentDetect_metadata.mat'),'imgSize')
% Iterate over time
for tInd = 1:numel(timeRange)

    % Load filament data
    currT = timeRange(tInd);
    load(fullfile(filDataDir,sprintf(filDataName,currT)),'rp3D');
% Load .h5 and calculate perimeter, distance transform, etc.
    % load h5, split into in out on, get gradients from distance transform
    % Consider saving tifs of gradients to avoid having to recalculate from h5s
    % Load the h5
    inOnOutMat = tiffreadVolume(fullfile(iooSegDir,sprintf(iooSegName,currT)));
    segSize = size(inOnOutMat);
    segPixSize = (imgSize./segSize(1:3)).*ogVoxSize;
    cubicVoxelsSegSize = round(segSize(1:3).*segPixSize);
    % Separate into ins, outs, ons
    scaledSegs = imresize3(inOnOutMat,cubicVoxelsSegSize,'nearest');
    [~,~,binInds] = histcounts(scaledSegs,binVals);
    cleanIns = binInds == inOnOutBins(1);
    cleanOns = binInds == inOnOutBins(2);
    cleanOuts = binInds == inOnOutBins(3);
    % Calculate the distance transform
    if inOnDist == 1
        [distMat,~,~,~,~,keepMat] = distTransFromBoundary(cleanOns, cleanOuts, cleanIns, 1);
    else
        [distMat,~,~,~,~,keepMat] = distTransFromBoundary(cleanOns|cleanIns, cleanOuts, false(size(cleanIns)), 1);
    end
    % Save, if requested
    if saveDistMats == 1
        if ~exist(bwSaveDir,'dir')
            mkdir(bwSaveDir)
        end
        save(fullfile(bwSaveDir,sprintf(bwSaveName,currT)),'distMat');
        if tInd == 1
            save(fullfile(bwSaveDir,'metadata.mat'),'iooSegDir','segChans','segPixSize','ogVoxSize')
        end
    end

    % Resize the distance transform and ignore matrix
    rescaledDistMat = imresize3(distMat,imgSize,'nearest');
    rescaledIgnoreMat = imresize3(~keepMat,imgSize,'nearest');
    rescaledIOOMat = imresize3(inOnOutMat,imgSize,'nearest');

    % Store matrix indices of CoMs from (x,y,z) centroid coordinates
    rndCoMs = round([rp3D.Centroid]);       % in (x,y,z)/(col, row, page)
    comInds = sub2ind(imgSize,rndCoMs(:,2),rndCoMs(:,1),rndCoMs(:,3));

    % Store deltaR value at each filament CoM; mark if in valid distMat roi
    filDeltaRs = rescaledDistMat(comInds);
    maskedFils = rescaledIgnoreMat(comInds);
    iooInds = rescaledIOOMat(comInds);

% Get surface gradients, surface normals, sample at filament CoMs
    % Take the gradient of the distance transform
    [gradx,grady,gradz] = gradient(distMat);
    allGrads = zeros([size(gradx) 3]);
    allGrads(:,:,:,1) = gradx; allGrads(:,:,:,2) = grady; allGrads(:,:,:,3) = gradz;
    % Rescale gradients to image dimensions!
    allGrads = imresize3_4mat(allGrads,imgSize);
    % Sample dist trans gradient at (rough) filament CoMs (image coords)
    signFlip = [1 1 1];                    % Flip sign of y (img coords)
    bwGradAtCens = zeros(size([rp3D.Directors]));
    for index = 1:size(allGrads,4)
        currGrad = imgaussfilt3(allGrads(:,:,:,index)*signFlip(index),2);
        bwGradAtCens(:,index) = currGrad(comInds);
    end

% Calc dot prod between filament and local gradient orientations
    % Load filament alignment vectors
    filDirs = [rp3D.Directors];
    aniFilDirs = [rp3D.AniDirectors];

    % Define dot-product and get angle difference in 3D   
    vDim = 3;
    filAligns3D  = getUnitVecs(filDirs(:,1:vDim));
    aniFilAligns3D = getUnitVecs(aniFilDirs(:,1:vDim));
    grads3D = getUnitVecs(bwGradAtCens(:,1:vDim)); 
    dotFN3D = dot(filAligns3D,grads3D,2);
    thetaFN3D = bndmod(acos(dotFN3D),-pi/2,pi/2);
    aniDotFN3D = dot(aniFilAligns3D,grads3D,2);
    aniThetaFN3D = bndmod(acos(aniDotFN3D),-pi/2,pi/2);

    % Store quantities in rp3D structure
    rp3D.('CoMInds') = comInds;
    rp3D.('DeltaR') = filDeltaRs;
    rp3D.('inOnOutInd') = iooInds;
    rp3D.('distGrads') = bwGradAtCens;
    rp3D.('theta3D') = thetaFN3D;
    rp3D.('dot3D') = dotFN3D;
    rp3D.('theta3DAni') = aniThetaFN3D;
    rp3D.('dot3DAni') = aniDotFN3D;

% Save
      save(fullfile(filDataDir,sprintf(filDataName,currT)),'rp3D');
end

end
