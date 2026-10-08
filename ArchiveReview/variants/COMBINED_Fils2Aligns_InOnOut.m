% Filament Detection
% ideally, loads .h5s directly, applies threshold, returns binarized
% objects. Then the script will do statistics
% This script takes in directory/directories containing .tifs of segmented
% filaments from .h5s. It measures the statistics of said filaments without
% considering statistics from the 3rd dimension
% 2023-11-13 Rémi Boros
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 88, Exp 4';
segDirSuper = baseDir;
saveDirSuper = fullfile(baseDir,'Analyzed Filament Data');
saveDirLabel = '%s';
h5Query = '*_Probabilities.h5';  h5String = '/exported_data';

h5Chans = 2; h5Thresh = 0.6;
binarizeBool = 1; saveBool = 0;
scaleFacts = [1 1]; pixSize = 11*2/60;
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
filDataName = 'Filament Statistics %03i.mat';
% segDir = '<redacted original absolute path>';
segDir = 'Session 83';
segName = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';
saveDir = fullfile(baseDir,'\Filament Alignment Statistics');

timeRange = 1:50;
segChans = [1 2 3];
outInOnChans = [1 3 2];
segthresh = 0.33;
ogPixSize = [.3667 .3667 1.5];      % Pixel size of microscope image;
inOnDist = 1;           % 1 to distinguish drop interiors and boundaries, otherwise combine interiors and boundaries and compare to bg

% Save tifs of distance transforms used for gradients?
saveDistMats = 1;
bwSaveDir = fullfile(baseDir,'Boundary Distance Transforms');
bwSaveName = 'T%06i_distanceTransform.mat';

% Filament filtering: get indices of filaments in certain domains and based
% on certain characteristics
% Filament filter parameters
minVol = 0;                 % pixels (allVols)
minLength = 0;              % pixels (majAxes)
minAR = 0;                  % Ratio major/minor axes (aspectRatio)
strLabels = {'Out','In','On'};
% inOnOutDir = '<redacted original absolute path>';
inOnOutDir = 'Session 83';
inOnOutName = 'Time%06i_Probabilities_smoothbin.tif';
statsSaveDir = fullfile(baseDir,'Filament Alignment Statistics');
statsSaveName = 'OutInOn_BinnedStats.mat';
outInOn = [1 2 3];
binVals = [0 100 200 300];
numBins = numel(binVals) - 1;

%% PART A - get filament statistics in 2D and 3D %%%%%%%%%%%%%%%%%%%%%%%%%%
% Iterate through h5 directories, convert contents
fileNames = dir(fullfile(segDirSuper,h5Query));
% Iterate through each file in the current directory; load and convert
% to binarized matrix; save, if requested
for fileInd = 1:numel(fileNames)
    newBool = 1;        % Used to define new storage struct in cases where no objects are observed in first z slice
    [~,currFileName,fileExt] = fileparts(fileNames(fileInd).name);
    currSeg = loadH5(fullfile(segDirSuper,[currFileName fileExt]),h5String,h5Chans);
    currMat = h5toTif(currSeg,scaleFacts,binarizeBool,h5Thresh,0);
    if exist(saveDirSuper,'dir') == 0
        mkdir(saveDirSuper);
    end
    % Save tif of the .h5, if requested
    if saveBool == 1        
        tifDir = fullfile(saveDirSuper,'Thresholded Filament Tifs');
        if exist(tifDir,'dir') == 0
            mkdir(tifDir);
        end
        save3DTiff(currMat, fullfile(tifDir,[currFileName '.tif']));
        fprintf('Saving file %06i...\n',fileInd)
    end

    % Get regionprops for 3D, store in .mat file
    bwObjs = logical(currMat);
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
    rp3D.('Lengths') = filLens;
    rp3D.('AspectRatios') = filARs;

    % Get regionprops for 2D, store in .mat file
    % Iterate through each Z slice, get 2D stats, store
    for zInd = 1:size(bwObjs,3)
        curr2D = regionprops(bwObjs(:,:,zInd),selFields2D);
        IndVecCol = repmat(zInd, size(curr2D,1), 1);
        curr2D = addFieldStruct(curr2D,'Slice_Index',IndVecCol);
        if (newBool == 1) && ~isempty(curr2D)
            rp2D = curr2D;
            newBool = 0;
        elseif (newBool == 0) && ~isempty(curr2D)
            rp2D = vertcat(rp2D,curr2D);
        end
    end
    save(fullfile(saveDirSuper,[currFileName '.mat']),"rp2D",'rp3D','scaleFacts');
    % save(fullfile(saveDirSuper,sprintf('Filament Statistics %03i',fileInd)),"rp2D",'rp3D','scaleFacts');
end
imgSize = size(currMat);
save(fullfile(saveDirSuper,'FilamentDetect_metadata.mat'),"pixSize","h5Chans","h5Thresh",'imgSize')

%% PART B - Filament Alignmnets %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    currH5 = loadH5(fullfile(segDir,sprintf(segName,currT)),'/exported_data',segChans);
    segSize = size(currH5);
    segPixSize = (imgSize./segSize(1:3)).*ogPixSize;
    cubicVoxelsSegSize = round(segSize(1:3).*segPixSize);
    % Separate into ins, outs, ons
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
        imresize3_4mat(currH5, cubicVoxelsSegSize),outInOnChans,segthresh,1,1);
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
            save(fullfile(bwSaveDir,'metadata.mat'),'segDir','segChans','segPixSize','ogPixSize')
        end
    end

    % Resize the distance transform and ignore matrix
    rescaledDistMat = imresize3(distMat,imgSize,'nearest');
    rescaledIgnoreMat = imresize3(~keepMat,imgSize,'nearest');

    % Store matrix indices of CoMs from (x,y,z) centroid coordinates
    rndCoMs = round([rp3D.Centroid]);       % in (x,y,z)/(col, row, page)
    comInds = sub2ind(imgSize,rndCoMs(:,2),rndCoMs(:,1),rndCoMs(:,3));

    % Store deltaR value at each filament CoM; mark if in valid distMat roi
    filDeltaRs = rescaledDistMat(comInds);
    maskedFils = rescaledIgnoreMat(comInds);

    % Add index and filter data to rp3D
    rp3D.('CoMInds') = comInds;
    rp3D.('MaskedInds') = maskedFils;
    rp3D.('DeltaR') = filDeltaRs;

% Get surface gradients, surface normals, sample at filament CoMs
    % Take the gradient of the distance transform
    [gradx,grady,gradz] = gradient(distMat);
    allGrads = zeros([size(gradx) 3]);
    allGrads(:,:,:,1) = gradx; allGrads(:,:,:,2) = grady; allGrads(:,:,:,3) = gradz;
    % Rescale gradients to img dimensions
    allGrads = imresize3_4mat(allGrads,imgSize);
    % Sample dist trans gradient at (rough) filament CoMs
    signFlip = [1 1 1];                    % Flip sign of y (img coords)
    bwGradAtCens = zeros(size([rp3D.Directors]));
    for index = 1:size(allGrads,4)
        currGrad = imgaussfilt3(allGrads(:,:,:,index)*signFlip(index),2);
        bwGradAtCens(:,index) = currGrad(comInds);
    end

% Calc dot prod between filament and local gradient orientations
    % Load filament alignment vectors
    filDirs = [rp3D.Directors];

    % Define dot-product and get angle difference in 3D   
    vDim = 3;
    filAligns3D  = getUnitVecs(filDirs(:,1:vDim));
    grads3D = getUnitVecs(bwGradAtCens(:,1:vDim)); 
    dotFN3D = dot(filAligns3D,grads3D,2);
    dotFN3D = sqrt(dotFN3D.^2);
    thetaFN3D = acos(dotFN3D);

    % Define dot-product and get angle difference in 2D   
    vDim = 2;
    filAligns2D  = getUnitVecs(filDirs(:,1:vDim));
    grads2D = getUnitVecs(bwGradAtCens(:,1:vDim));
    dotFN2D = dot(filAligns2D,grads2D,2);
    dotFN2D = sqrt(dotFN2D.^2);
    thetaFN2D = acos(dotFN2D);

    % Order parameters: cos^2(theta) - 0.5
    order3D = dotFN3D.^2 - 0.5;
    order2D = dotFN2D.^2 - 0.5;

% Save
    save(fullfile(saveDir,sprintf('Time%03i_alignData.mat',currT)),...
        'dotFN3D','thetaFN3D','dotFN2D','thetaFN2D','bwGradAtCens','filDirs','signFlip','order3D','order2D');
    save(fullfile(filDataDir,sprintf(filDataName,currT)),'rp3D','-append');
end

%% PART C - Filter filaments and bin %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load(fullfile(saveDirSuper,'FilamentDetect_metadata.mat'),'imgSize')
selTimes = 2:40;
% Iterate through time, calculate things at each frame
outInOnIndices = struct(); 
filterStruct = struct();
for tInd = 1:numel(selTimes)
    % Load filament info and segmentation
    currT = selTimes(tInd);
    currFile = fullfile(filDataDir,sprintf(filDataName,currT));
    segFile = fullfile(inOnOutDir,sprintf(inOnOutName,currT));
    if exist(segFile,'file') == 0
        continue
    end
    load(currFile,'rp3D');
    currSegs = tiffreadVolume(segFile);
    currSegs = imresize3(currSegs,imgSize,'nearest');

% Bin segmentations, then map indices to match outInOn order
    [~,~,binInds] = histcounts(currSegs,binVals);
    mapVec = [0 outInOn];
    binInds = mapVec(binInds+1);

% Define logic to select for specific classes of filaments
    sizeFilt = [rp3D.Volume]>=minVol;       % Volume cutoff
    arFilt = [rp3D.AspectRatios]>=minAR;    % Fraction from principle axes
    lengthFilt = [rp3D.Lengths]>=minLength; % Length cutoff
    % Combine filters to form general filter
    generalFilt = sizeFilt & arFilt & lengthFilt;
    
    % Save metadata
    filterStruct = struct();
    filterStruct.minVol = minVol;
    filterStruct.ARCut = arFilt;
    filterStruct.minLen = minLength;

    % Redefine filter to ignore filaments in masked areas of distMat
    maskedFils = [rp3D.MaskedInds];
    filterLogic = generalFilt & (maskedFils == 0);

% Iterate through each bin, get order parameter statistics
    comInds = [rp3D.CoMInds];
    for index = 1:numBins
        currROI = find(binInds == index);
        domainLogic = ismember(comInds,currROI) & filterLogic;
        outInOnIndices(tInd).(strLabels{index}) = find(domainLogic);
    end
    outInOnIndices(tInd).Filter = filterLogic;
end
outInOnIndices = addFieldsStruct(outInOnIndices,{'Frame'},mat2cell(selTimes,1,numel(selTimes)));
if ~exist(statsSaveDir,'dir')
    mkdir(statsSaveDir);
end
save(fullfile(statsSaveDir,statsSaveName),'outInOnIndices','selTimes')


