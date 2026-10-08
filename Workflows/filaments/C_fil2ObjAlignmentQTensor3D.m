%% Compare sparse filament alignment with object surface norms from dense
% Calculates orientation tensor of each filament based on orientation in
% cartesian space and samples gradient at each filament center of mass.
% Creates orientation tensor for gradient field, too. Takes product between
% both tensors over each filament, then averages after selection.
% NOTE: This implementation takes in Filament Statistics at each time
% point, not a concatenated structure for all times.
% From A_getFilamentStats_2Dand3D.m
% 2025-02-17 - Rémi Boros
% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 83';
filDataName = 'Filament Statistics %03i.mat';
% segDir = '<redacted original absolute path>';
segDir = 'Session 83';
segName = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';
selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 83';

timeRange = 1:90;
segChans = [1 2 3];
outInOnChans = [1 3 2];
segthresh = 0.33;
ogPixSize = [.3667 .3667 1.5];      % Pixel size of microscope image;
inOnDist = 1;           % 1 to distinguish drop interiors and boundaries, otherwise combine interiors and boundaries and compare to bg
% Filament filter parameters
minVol = 0;                 % pixels (allVols)
minLength = 0;              % pixels (majAxes)
minAR = 0;                % Ratio major/minor axes (aspectRatio)
% selectSetInd = 1;            % Numbered data set (subIndsVec) (relevant when concatenated filaments over multiple directories)
randomCheck = 0;

% Save tifs of distance transforms used for gradients?
saveDistMats = 1;
% bwSaveDir = '<redacted original absolute path>';
bwSaveDir = 'Session 83';
bwSaveName = 'T%06i_distanceTransform.mat';

% Image size
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 83';
sampleImg = tiffreadVolume(fullfile(imgDir,'t001_illBleachCorr16bit_560.tif'));
imgSize = size(sampleImg); clear sampleImg


%% Iterate over time
for tInd = 1:numel(timeRange)

currT = timeRange(tInd);
%% Load filament data and instantiate new variables
load(fullfile(filDataDir,sprintf(filDataName,currT)));

%% Define logic to select for specific classes of filaments
allVec = ones(size(rp3D,1),1);            % Baseline logical
sizeFilt = [rp3D.Volume]>=minVol;       % Volume cutoff
arFilt = [rp3D.AspectRatios]>=minAR;    % Fraction from principle axes
lengthFilt = [rp3D.Lengths]>=minLength; % Length cutoff
sliceFilt = allVec;                     % Select zslice (opt.)
% Combine filters to form general filter
generalFilt = sizeFilt & arFilt & sliceFilt & lengthFilt;

if tInd == 1
    % Save metadata
    filterStruct = struct();
    filterStruct.filter = generalFilt;
    filterStruct.minVol = minVol;
    filterStruct.ARCut = arFilt;
    filterStruct.minLen = minLength;
end

%% Load and manipulate .h5
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
        save(fullfile(bwSaveDir,sprintf(bwSaveName,currT)),'distMat');
        if tInd == 1
            save(fullfile(bwSaveDir,'metadata.mat'),'segDir','segChans','segPixSize','ogPixSize')
        end
    end

    %% Rescale distance transform, sample at filament coms (roughly)
    % Resize the distance transform and ignore matrix
    rescaledDistMat = imresize3(distMat,imgSize,'nearest');
    rescaledIgnoreMat = imresize3(~keepMat,imgSize,'nearest');

    % Store matrix indices of CoMs from (x,y,z) centroid coordinates
    rndCoMs = round([rp3D.Centroid]);       % in (x,y,z)/(col, row, page)
    comInds = sub2ind(imgSize,rndCoMs(:,2),rndCoMs(:,1),rndCoMs(:,3));

    % Store deltaR value at each filament CoM; mark if in valid distMat roi
    filDeltaRs = rescaledDistMat(comInds);
    maskedFils = rescaledIgnoreMat(comInds);

    % Redefine filter to ignore filaments in masked areas of distMat
    filterLogic = generalFilt & (maskedFils == 0);

    %% Take the gradient of the distance transform
    [gradx,grady,gradz] = gradient(distMat);
    allGrads = zeros([size(gradx) 3]);
    allGrads(:,:,:,1) = gradx; allGrads(:,:,:,2) = grady; allGrads(:,:,:,3) = gradz;
    % Rescale gradients to img dimensions
    allGrads = imresize3_4mat(allGrads,imgSize);

    %% Sample dist trans gradient at (rough) filament CoMs
    signFlip = [1 1 1];                    % Flip sign of y (img coords)
    bwGradAtCens = zeros(size([rp3D.Directors]));
    for index = 1:size(allGrads,4)
        currGrad = imgaussfilt3(allGrads(:,:,:,index)*signFlip(index),2);
        bwGradAtCens(:,index) = currGrad(comInds);
    end
    % Normalize gradients; remove any zero gradient vectors
    zeroGrads = sum(bwGradAtCens,2) == 0;
    gradMags = sqrt(sum(bwGradAtCens.^2,2));
    normGrads = bwGradAtCens./gradMags;
    normGrads(zeroGrads,:) = 0;

    %% Calc tensor dot prod between filament and local gradient orientations
    filAligns = [rp3D.Directors];
    vDim = 3;
    filAligns3D  = getUnitVecs(filAligns(:,1:vDim));
    grads3D = getUnitVecs(bwGradAtCens(:,1:vDim));

    newFiltInds = find(filterLogic);    
    tensorAligns = zeros(size(zeroGrads));
    vectorAligns = tensorAligns;
    % Iterate over each filament
    for index = 1:sum(filterLogic)
        validInd = newFiltInds(index);
        currFilTensor = filAligns3D(validInd,:) .* filAligns3D(validInd,:)' - eye(3)/3;
        currGrdTensor = grads3D(validInd,:) .* grads3D(validInd,:)' - eye(3)/3;
        tensorAligns(validInd) = vDim*sum(currFilTensor.*currGrdTensor,'all');
        vectorAligns(validInd) = vDim*((sum(filAligns3D(validInd,:).*grads3D(validInd,:))).^2 - 1/vDim);
    end

    % Approximate angles
    angleDiffs3D = acos(sqrt(vectorAligns + 1/3));
    angleDiffs3D = abs(angleDiffs3D);

    % alignAngle = acos(sqrt(2/3*alignParam + 1/3));
    % alignParam = 1/2*(3*dotFN.^2 - 1);
    %% Calc tensor dot prod between filament and local gradient orientations FOR 2D
    % Iterate over each filament
    newFiltInds = find(filterLogic);
    filAligns = [rp3D.Directors];
    vDim = 2;
    filAligns2D = filAligns(:,1:vDim)./vecnorm(filAligns(:,1:vDim)')';
    grads2D = bwGradAtCens(:,1:vDim)./vecnorm(bwGradAtCens(:,1:vDim)')';
    tensorAligns2 = zeros(size(zeroGrads));
    for index = 1:sum(filterLogic)
        validInd = newFiltInds(index);
        currFilTensor = filAligns2D(validInd,:).*filAligns2D(validInd,:)' - eye(vDim)/vDim;
        currGrdTensor = grads2D(validInd,:).*grads2D(validInd,:)' - eye(vDim)/vDim;
        tensorAligns2(validInd) = vDim*sum(currFilTensor.*currGrdTensor,'all');
    end

    %% Save
    save(fullfile(saveDir,sprintf('Time%03i_alignData.mat',currT)),...
        'tensorAligns','vectorAligns','tensorAligns2','angleDiffs3D','bwGradAtCens','filterLogic','signFlip');
end

