% Takes in tifs of blob objects with pixel intensities denoting object ID.
% The script expects blob-labeling between consecutive frames to be
% consistent. Labeled blob tifs are expected to contain cubic voxels
% (equal dimension scaling along each axis)
% overlapBlobTracking.m can produce these, if needed.
% The script tracks the properties of blobs over time and stores them in
% associated trajectories. Optionally, tracks radii at blob skeletons.
% Optionally, saves .tifs of blob skeletons.

% Rémi Boros, 2024-06-18

%% Data directories
% baseDirs = {'<redacted original absolute path>',...
baseDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 5'};
lNames = {'E1_T%03i_trajIDs.tif',...
    'E2_T%03i_trajIDs.tif',...
    'E3_T%03i_trajIDs.tif',...
    'E4_T%03i_trajIDs.tif',...
    'E5_T%03i_trajIDs.tif'};

% iterate over multiple directories
for dirInd = 1:numel(baseDirs)
    
baseDir = baseDirs{dirInd};
labeledName = lNames{dirInd};
labeledDir = fullfile(baseDir,'4 Tracked Blobs');      %phi 0
imgDir = fullfile(baseDir,'3 Illumination Bleach Corrected 16bit');
imgName = 't%03i_illBleachCorr16bit_560.tif';

selectTimes = 30;
imgVoxSize = [.55 .55 .7];         % in um/pix
timeStep = 30/60;                          % Sec/frame
forceScale = 1;

% r_eff method 1: for each blob, r_eff is the max of the distance transform
% r_eff method 2: for each blob, subsample EDT along an eroded skeleton
rMethod = 2;    gradCut = .5;   sigma = 2;  hBool = 0;
saveSkel = 1;

% Morphological erosion or dilation? ONLY SUPPORTS EROSION NOW
morphKern = 2;
skelCO = 10000;     % Max number of indices per skeleton (for computation)
nRad = 18;  nSigma = nRad/6;

%% Iterate over times
storageStruct = struct();
if rMethod == 2
    rminSaveDir = fullfile(labeledDir,'RMinStats');
    mkdir(rminSaveDir);
    rMinStats = struct();   timeShft = 0;
end
for tInd = 1:numel(selectTimes)
    tic
    currT = selectTimes(tInd);
    if ~exist(fullfile(labeledDir,sprintf(labeledName,currT)),'file')
        continue
    end
% Load tifs
    ogLabels = (tiffreadVolume(fullfile(labeledDir,sprintf(labeledName,currT))));
    loadImg = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)));
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
% Rescale labels, then calculate distance transform (first time)
    rsLabels = imresize3(ogLabels,round(labelDims*logicRescale),'nearest');
    rsExtend = imdilate(rsLabels,morphObj); % used to sample blob surroundings
    % Get distance transform
    distLabs = bwdist(~logical(rsLabels));
% Erode or dilate to smooth boundaries, if requested
    morphMat = imgaussfilt3(distLabs,abs(morphKernSc));     % blur distance transform
    loadLabels = consMatLnB(rsExtend,morphMat > morphKernSc/2);    % threshold blurred EDT

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

    % Take distance transform of binarized labels
    distLabs = bwdist(loadLabels == 0);
    % Instantiate storage vectors
    objInts = objVols;  objMinAx = objVols;
    % Generate blob skeletons, if rMethod 2 is requested
    if rMethod == 2
        [~,skelMat] = skel3DBlobs(loadLabels,gradCut,sigma,hBool);
        if saveSkel == 1
            save3DTiff(uint16(consMatLnB(loadLabels,skelMat)),...
                fullfile(rminSaveDir,sprintf('T%03i_IDedSkelMat.tif',currT)));
        end
    end

    for currInd = 1:numel(uniqueLabels)
        % Get object intensities of each object
        currID = uniqueLabels(currInd);
        currLogic = (rescaledLabels == currID);
        objInts(currInd) = sum(loadImg(currLogic));
        % Store minor axis as max value of distance transform in each obj.
        currLogic = (loadLabels == currID);
        % "Simple" max r_min method
        if rMethod == 1
            objMinAx(currInd) = max(distLabs(currLogic),[],'all')*distScale;
        % Skeletonization statistics method for r_min
        elseif rMethod == 2
            statsInd = currInd + timeShft;
            if sum(currLogic & skelMat,'all') > 0
                objMinAx(currInd) = median(distLabs(currLogic & skelMat),'all')*distScale;
                rMinStats(statsInd).MinAxStats = distLabs(currLogic & skelMat)*distScale;
            else
                % If no skeleton in blob core, use "simple" method
                objMinAx(currInd) = max(distLabs(currLogic),[],'all')*distScale;
                % Store stats
                rMinStats(statsInd).MinAxStats = max(distLabs(currLogic),[],'all')*distScale;
            end
        else
            objMinAx(currInd) = [];
        end
    end
    % Generate vector of frames
    frameVec = repmat(currT,numel(objVols),1);
    % Store data
    storageStruct(tInd).Frames = frameVec;
    storageStruct(tInd).ObjLabels = double(uniqueLabels);
    storageStruct(tInd).Ints = objInts';
    storageStruct(tInd).Volumes = objVols'*prod(imgVoxSize);    %in um^3
    storageStruct(tInd).MinAx = objMinAx';                      %in um
    % Store r_min stats, if rMethod = 2
    if rMethod == 2
        if ~exist(rminSaveDir,'dir')
            mkdir(rminSaveDir);
        end
        timeShft = numel(rMinStats);
    end

toc
pause(.01)
end

% Concatenate all blob values 
allFrames = vertcat(storageStruct(:).Frames);
storeMat = zeros(numel(allFrames),4);
storeMat(:,2) = allFrames;
storeMat(:,3) = vertcat(storageStruct(:).Volumes);  %in units of image voxels (mult. by imgVoxVol to convert to um)
storeMat(:,4) = vertcat(storageStruct(:).Ints);
storeMat(:,5) = vertcat(storageStruct(:).MinAx);
storeMat(:,1) = vertcat(storageStruct(:).ObjLabels);
% Sort data by trajectory
[~,labelOrder] = sort(storeMat(:,1));
sortedMat = storeMat(labelOrder,:);
rMinStats = rMinStats(labelOrder);
% Save data
save(fullfile(labeledDir,'sortedTraj_IntsVolsMinRs_ErodedScaled2.mat'),'sortedMat', 'imgDims', 'imgVoxSize', 'timeStep', "labelDims", 'labelVoxSize'  );
save(fullfile(labeledDir,'sorted_RMinStatistics.mat'),'rMinStats');
end




