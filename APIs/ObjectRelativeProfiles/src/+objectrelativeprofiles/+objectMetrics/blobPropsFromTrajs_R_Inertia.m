% Takes in tifs of blob objects with pixel intensities denoting object ID.
% The script expects blob-labeling between consecutive frames to be
% consistent. Labeled blob tifs are expected to contain cubic voxels
% (equal dimension scaling along each axis)
% overlapBlobTracking.m can produce these, if needed.
% The script tracks the properties of blobs over time and stores them in
% associated trajectories. Optionally, tracks radii at blob skeletons.
% Optionally, saves .tifs of blob skeletons.
% volumes are saved in um^3

% Rémi Boros, 2024-06-18

%% Data directories
% baseDirs = {'Session 88, Exp 1',...
%     'Session 88, Exp 2',...
%     'Session 88, Exp 3',...
%     'Session 88, Exp 4',...
%     'Session 88, Exp 5'};
% lNames = {'E1_T%03i_trajIDs.tif',...
%     'E2_T%03i_trajIDs.tif',...
%     'E3_T%03i_trajIDs.tif',...
%     'E4_T%03i_trajIDs.tif',...
%     'E5_T%03i_trajIDs.tif'};
lNames = {'T%03i_trajIDs.tif'};
% baseDirs = {'<redacted original absolute path>'};
baseDirs = {'Session 81, Exp 2'};

% iterate over multiple directories
for dirInd = 1:numel(baseDirs)
    
baseDir = baseDirs{dirInd};
labeledName = lNames{dirInd};
labeledDir = fullfile(baseDir,'5 Segmented Blobs','Tracked Blobs');      %phi 100
imgDir = fullfile(baseDir,'3 Illumination Bleach Corrected 16bit');
imgName = 't%03i_illBleachCorr16bit_560.tif';

selectTimes = 1:60;
imgVoxSize = [1.1 1.1 1.5];                 % in um/pix
timeStep = 30/60;                           % Sec/frame
forceScale = 1;

% r_eff method 1: for each blob, r_eff is the max of the distance transform
% r_eff method 2: for each blob, subsample EDT along an eroded skeleton
rMethod = 2; layerMean = -1;  layerWidth = -1; gKern = 2;
% rMethod = 2;    gradCut = .5;   sigma = 2;  hBool = 0;
saveSkel = 1;

% Morphological erosion or dilation? ONLY SUPPORTS EROSION NOW
morphKern = 2;
skelCO = 10000;     % Max number of indices per skeleton (for computation)
nRad = 18;  nSigma = nRad/6;

%% Iterate over times
storageStruct = struct();
if rMethod == 2
    rminSaveDir = fullfile(labeledDir,'Skels Dir');
    mkdir(rminSaveDir);
    statStruct = struct();   timeShft = 0;
end
for tInd = 1:numel(selectTimes)
    
    currT = selectTimes(tInd);
    if ~exist(fullfile(labeledDir,sprintf(labeledName,currT)),'file')
        continue
    end
tic
% Load tifs
    ogLabels = (tiffreadVolume(fullfile(labeledDir,sprintf(labeledName,currT))));
    loadImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
% Define conversion factors and voxel scale from labels and images
    if tInd == 1
        imgDims = size(loadImg);    labelDims = size(ogLabels);
        scaleFact = imgDims./labelDims;
        labelVoxSize = scaleFact.*imgVoxSize;
        logicRescale = min(scaleFact)*forceScale;
        morphKernSc = round(morphKern*logicRescale);
        distScale = mean(labelVoxSize)/logicRescale;
        if abs(morphKern) > 0
            morphObj = strel('sphere',abs(morphKernSc));
        end
    end
% Rescale labels, then smooth boundaries
    rsLabels = imresize3(ogLabels,round(labelDims*logicRescale),'nearest');
    % Get distance transform
    distLabs = bwdist(~logical(rsLabels));

%     rsExtend = imdilate(rsLabels,morphObj); % used to sample blob surroundings
% % Erode or dilate to smooth boundaries, if requested
%     morphMat = imgaussfilt3(distLabs,abs(morphKernSc));     % blur distance transform
%     loadLabels = consMatLnB(rsExtend,morphMat > morphKernSc/2);    % threshold blurred EDT

    % Smooth labels
    loadLabels = returnSmoothBlobsIDed(rsLabels,-1,-1,2,'fast');

% Get unique labels and their indices
    labelsVec = loadLabels(loadLabels>0);
    uniqueLabels = unique(labelsVec);
    indsVec = find(loadLabels>0);
% Rescale tifs of IDs to og. image size, then bin with histcounts
    if ~isempty(uniqueLabels)
        [objVols,temp,resizedLabelInds] = ...
            histcounts(imresize3(loadLabels,size(loadImg),'nearest'),[uniqueLabels; inf]);
        uniqueLabels0 = [0; uniqueLabels];  % List of all unique object labels and 0 (background) as a map vector   
        rescaledLabels = uniqueLabels0(resizedLabelInds + 1);   % remap resized label matrix using map vector above     
    else                                                        % ^(prevents ID swaps when rescaling)^
        continue
    end
    % Instantiate storage vectors
    objInts = objVols;  stdInts = objVols;
    % objMinAx = objVols; objFAs = objVols;   objSphs = objVols;

% Take distance transform of binarized labels
    distLabs = bwdist(loadLabels == 0);
% Generate blob skeletons, if rMethod 2 is requested
    if rMethod == 2
        [~,skelLogic] = skel3DBlobs(loadLabels,gradCut,sigma,hBool);
        skelMat = consMatLnB(loadLabels,skelLogic);
        if saveSkel == 1
            save3DTiff(uint16(skelMat),...
                fullfile(rminSaveDir,sprintf('T%03i_IDedSkelMat.tif',currT)));
        end
    end

% Instantiation for local inertia tensor calculations
    % Pad arrays - reflect blobs, 0-pad skeletons
    padBlobs = padarray(loadLabels,[nRad nRad nRad],'symmetric');
    padSkels = padarray(skelMat,[nRad nRad nRad]);
    padDist = padarray(distLabs,[nRad nRad nRad]);      % for blobs w/o skels
    % Instantiate matrices to calculate inertia tensor indices 
        if tInd == 1
            [rowMat, colMat, depMat] = ndgrid(-nRad:nRad,-nRad:nRad,-nRad:nRad); 
            % Generate tensor indices using 0-centered matrices
            ind11 = colMat.^2 + depMat.^2;
            ind22 = rowMat.^2 + depMat.^2;
            ind33 = colMat.^2 + rowMat.^2;
            ind12 = -rowMat.*colMat;
            ind23 = -depMat.*colMat;
            ind13 = -rowMat.*depMat;
        end     
    % Gauss blur 
    gBlurBlobs = imgaussfilt3(double(logical(padBlobs)),nSigma);

% Statistics for each blob calculated below
    for currInd = 1:numel(uniqueLabels)
    % Get object intensities of each object
        currID = uniqueLabels(currInd);     % currBlob
        currLogic = (rescaledLabels == currID);
        objInts(currInd) = sum(loadImg(currLogic));
        stdInts(currInd) = std(loadImg(currLogic));
    % Store minor axis of each blob via selected method
        currLogic = (loadLabels == currID);
        % "Simple" max r_min method
        statsInd = currInd + timeShft;
        if rMethod == 1
            % objMinAx(currInd) = max(distLabs(currLogic),[],'all')*distScale;
        % Skeletonization statistics method for r_min
        elseif rMethod == 2
            if sum(currLogic & skelLogic,'all') > 0
                % objMinAx(currInd) = median(distLabs(currLogic & skelLogic),'all')*distScale;
                statStruct(statsInd).MinAxStats = distLabs(currLogic & skelLogic)*distScale;
            else
                rEffMaxes = max(distLabs(currLogic),[],'all');
                % If no skeleton in blob core, use "simple" method
                % objMinAx(currInd) = rEffMaxes*distScale;
                % Store stats
                statStruct(statsInd).MinAxStats = rEffMaxes*distScale;
            end
        else
            % objMinAx(currInd) = [];
        end

% Calculate local inertia tensor for all indices in each skeleton, up to CO
        % Identify the current skeleton
        currSkel = padSkels == currID;
        currBlob = padBlobs == currID;
        skelInds = find(currSkel);
        % Reapproximate skeleton if no skeleton exists for current blob
        if numel(skelInds) == 0
            skelInds = find(consMatLnB(padDist == rEffMaxes,currBlob));
            rOnSkels = padDist(skelInds)';
            statStruct(statsInd).MinAxStats = rOnSkels(:)*distScale;
        end
        % Select subset of skeleton if indices exceed cutoff
        if numel(skelInds) > skelCO
            subSkel = randsample(skelInds,skelCO);
        else
            subSkel = skelInds;
        end
        subSkelInds = find(ismember(skelInds,subSkel)); % which of the skeleteon indices are used in subskeleton?
    % Store which indices are being subsampled for calculating anisotropy
        statStruct(statsInd).skelInds = skelInds;
        statStruct(statsInd).skelSubInds = subSkelInds;

 % Iterate through all skeleton indices in current blob, up to cutoff
        eigStore = zeros(numel(subSkel),3);
        FAStore = zeros(numel(subSkel),1);  SphStore = FAStore;
        for index = 1:numel(subSkel)
        % Convert current index to coordinate in matrix
            skInd = subSkel(index);
            [row0,col0,dep0] = ind2sub(size(padBlobs),skInd);
        % add Xo-coord to each matrix
            shftRows = rowMat + row0;
            shftCols = colMat + col0;
            shftDeps = depMat + dep0;
        % Subsample gauss-blurred image at current X0
            sampInds = sub2ind(size(padBlobs),shftRows,shftCols,shftDeps);
            gBlrSub = gBlurBlobs(sampInds);
        % Construct second moment (local inertia moment)
            m11 = sum(ind11.*gBlrSub,'all');   m22 = sum(ind22.*gBlrSub,'all');   m33 = sum(ind33.*gBlrSub,'all');
            m12 = sum(ind12.*gBlrSub,'all');   m23 = sum(ind23.*gBlrSub,'all');   m13 = sum(ind13.*gBlrSub,'all');
            scndM = [m11 m12 m13; ...
                     m12 m22 m23;...
                     m13 m23 m33];
        % Get eigenvalues
            [eVecs,eVals] = eig(scndM);
            eVals = sum(eVals,2);   maxInd = find(max(eVals));
            eigStore(index,:) = eVals;
        % fractional anisotropy and eccentricity scalar
            eMean = sum(eVals)/3;
            FAStore(index) = sqrt(3/2) * sqrt(sum((eVals - eMean).^2)) ./ sqrt(sum(eVals.^2));
            SphStore(index) = min(abs(eVals))/max(abs(eVals));
        end   
        % Store eccentricities and eVals
        statStruct(statsInd).EigVals = eigStore;
        statStruct(statsInd).FAs = FAStore;
        statStruct(statsInd).Sphs = SphStore;
        % Store current time and object
        statStruct(statsInd).BlobID = currID;
        statStruct(statsInd).Frame = currT;
        % WTF????
        if size(statStruct(statsInd).MinAxStats,2) > size(statStruct(statsInd).MinAxStats,1)
            statStruct(statsInd).MinAxStats
        end
    end

% Concatenate average/median values into single structure
    % Generate vector of frames
    frameVec = repmat(currT,numel(objVols),1);
    % Store data
    storageStruct(tInd).Frames = frameVec;
    storageStruct(tInd).ObjLabels = double(uniqueLabels);
    storageStruct(tInd).Ints = objInts';
    storageStruct(tInd).IntsSTD = stdInts';
    storageStruct(tInd).NumVox = objVols';
    storageStruct(tInd).Volumes = objVols'*prod(imgVoxSize);    %in um^3
    % storageStruct(tInd).MinAx = objMinAx';                      %in um
    % storageStruct(tInd).MedFA = objMinAx';                      
    % storageStruct(tInd).medSph = objMinAx';                     
    % Store r_min stats, if rMethod = 2
    if ~exist(rminSaveDir,'dir')
        mkdir(rminSaveDir);
    end
    timeShft = numel(statStruct);
if mod1b(tInd,5) == 1
    fprintf('Finished analyzing Frame %i \n',currT);
    toc
    tic
    pause(.01)
end
end

% Concatenate all blob values 
allFrames = vertcat(storageStruct(:).Frames);
storeMat = zeros(numel(allFrames),4);
storeMat(:,2) = allFrames;
storeMat(:,3) = vertcat(storageStruct(:).Volumes);  %in units of image voxels (mult. by imgVoxVol to convert to um)
storeMat(:,4) = vertcat(storageStruct(:).Ints);
storeMat(:,5) = vertcat(storageStruct(:).IntsSTD);     % standard deviations of intensities
storeMat(:,6) = vertcat(storageStruct(:).NumVox);     % Number of voxels sampled
% storeMat(:,5) = vertcat(storageStruct(:).MinAx);
storeMat(:,1) = vertcat(storageStruct(:).ObjLabels);
% Sort data by trajectory
[~,labelOrder] = sort(storeMat(:,1));
sortedMat = storeMat(labelOrder,:);
statStruct = statStruct(labelOrder);
colStr = {'Object ID','Frame','Volume','Intensity','Intensity STD','Number of Voxels'};
% Save data
save(fullfile(labeledDir,'metadata.mat'),'layerMean','layerWidth','gKern',...
    'selectTimes','imgDims','imgVoxSize','colStr','timeStep',"labelDims","labelVoxSize");
save(fullfile(labeledDir,'trajSorted_BlobVolsInts'),'sortedMat'  );
save(fullfile(labeledDir,'trajSorted_RMin_Anisotropy.mat'),'statStruct');
end
