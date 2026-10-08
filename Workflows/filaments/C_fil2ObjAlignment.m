%% Compare sparse filament alignment with object surface norms from dense
% Takes in collated table of filament properties and .h5s of segmented
% objects. Calculates distance transform of object boundaries, then
% uses gradient of this field as a local director field reference. All
% angles are mapped to [-pi/2, pi/2). Order parameter is calculated over 
% by sampling angle difference at the centroids of select sparse filaments.
% The order parameter itself is defined as cos( angle_diff ),
% where angle_diff is defined as the difference of theta_fil, the
% orientation of a detected filament, and theta_grad, the direction of
% gradient in the distance transform sampled at filament centroids.
% angle_diff is mapped to [-pi/2, pi/2) BEFORE processing with cos, so the
% order parameter is bounded between [0, 1]. 1 corresponds to local
% filament alignment with gradient of the distance transform and 0
% corresponds to an angle difference of 90 degrees, or pi/2. 
% By default, defined for objects segmented with in/out/on channels
% 2024-08-29 - Rémi Boros
% allDirs = {'<redacted original absolute path>',...
allDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 5'};

for index = 1:numel(allDirs)
    baseDir = allDirs{index};
filDataDir = fullfile(baseDir,'6 Filament Data');
filDataName = 'Concatenated_2D_Info.mat';
% segDir = '<redacted original absolute path>';
segDir = 'Session 88';
segName = 't%03i_illCorr8bit_560_E%i_Probabilities Stage 2.h5';
inOnOutDir = fullfile(baseDir,'4 Tracked Blobs','In On Out Segmentation');

if ~exist(inOnOutDir,'dir')
    mkdir(inOnOutDir);
end

% saveDir = 'Session 56, Exp 1';

timeRange = 1:57;
h5Chans = [1 2 3];
outInOnChans = [1 3 2];
h5thresh = 0.33;
ogPixSize = [.55 .55 0.7];      % Pixel size of microscope image;
thetaBinNum = 40;
rBinNum = 100;
deltarBounds = [-30 30];
saveSegs = 1;
inOnDist = 1;           % 1 to distinguish drop interiors and boundaries, otherwise combine interiors and boundaries and compare to bg
% Filament filter parameters
minVol = 8;                 % pixels (allVols)
minLength = 2;              % pixels (majAxes)
minAR = 1.5;                % Ratio major/minor axes (aspectRatio)
% selectSetInd = 1;            % Numbered data set (subIndsVec) (relevant when concatenated filaments over multiple directories)

% Image size
imgDir = fullfile(baseDir,'3 Illumination Bleach Corrected 16bit');
sampleImg = tiffreadVolume(fullfile(imgDir,'t001_illBleachCorr16bit_560.tif'));
imgSize = size(sampleImg); clear sampleImg

%% Load filament data and instantiate new variables
load(fullfile(filDataDir,filDataName));
gradxs = zeros(size(majAxes));
gradys = gradxs; gradThetas = gradxs; allAligns = gradxs;   rawDeltaThetas = gradxs;
tensorAligns = allAligns;
avgAlign = zeros(numel(timeRange),1);   filDeltaRs = gradxs;
maskedFils = logical(gradxs);

%% Define logic to select for specific classes of filaments
allVec = ones(size(allVols));
sizeFilt = allVols > minVol;            % pixels (allVols)
arFilt = majAxes./minAxes > minAR;      % Ratio major/minor axes (aspectRatio)
sliceFilt = allVec;                     % slice index   (sliceInds)
lengthFilt = majAxes > minLength;       % pixels (majAxes)
generalFilt = sizeFilt & arFilt & sliceFilt & lengthFilt;
filterStruct = struct();
filterStruct.filter = generalFilt;
filterStruct.minVol = minVol;
filterStruct.ARCut = arFilt;
filterStruct.minLen = minLength;

%% pick a time: load orientations, perimeters -> distance transform
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    % % Load piv and filament info
    validOris = allOris(objInds == currT);
    % load h5, split into in out on, get gradients from distance transform
    % Consider saving tifs of gradients to avoid having to recalculate from h5s
    % Load the h5
    currH5 = loadH5(fullfile(segDir,sprintf(segName,currT,index)),'/exported_data',h5Chans);
    segSize = size(currH5);
    segPixSize = (imgSize./segSize(1:3)).*ogPixSize;
    cubicVoxelsSegSize = round(segSize(1:3).*segPixSize);
    % Separate into ins, outs, ons
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
        imresize3_4mat(currH5, cubicVoxelsSegSize),outInOnChans,h5thresh,1,1);
    if saveSegs == 1
        if tInd == 1
            save(fullfile(inOnOutDir,'metadata.mat'),'outInOnChans','h5thresh');
        end
        save3DTiff(uint8(cleanIns), fullfile(inOnOutDir,sprintf('CleanIns_T%03i.tif',currT)));
        save3DTiff(uint8(cleanOns), fullfile(inOnOutDir,sprintf('CleanOns_T%03i.tif',currT)));
        save3DTiff(uint8(cleanOuts), fullfile(inOnOutDir,sprintf('CleanOuts_T%03i.tif',currT)));
    end
    % Calculate the distance transform
    if inOnDist == 1
        [distMat,~,~,~,~,keepMat] = distTransFromBoundary(cleanOns, cleanOuts, cleanIns, 1);
    else
        [distMat,~,~,~,~,keepMat] = distTransFromBoundary(cleanOns|cleanIns, cleanOuts, false(size(cleanIns)), 1);
    end
    % Take the gradient, rescale to image size, then return.
    [gradx,grady,gradz] = gradient(distMat);
    allGrads = zeros([size(gradx) 3]);
    allGrads(:,:,:,1) = gradx; allGrads(:,:,:,2) = -grady; allGrads(:,:,:,3) = gradz;
    allGrads = imresize3_4mat(allGrads,imgSize);
    rescaledDistMat = imresize3(distMat,size(allGrads(:,:,:,1)),'nearest');
    rescaledIgnoreMat = imresize3(~keepMat,size(allGrads(:,:,:,1)),'nearest');

    if mod1b(tInd,10) == 1
        fprintf('Currently analyzing Frame %03i...\n',tInd)
    end

    %% Rescale distance transform, sample at filament coms (roughly)
    currFilt = generalFilt & (objInds == currT);
    comInds = sub2ind(size(allGrads(:,:,:,1)),round(CoMs(2,currFilt)),round(CoMs(1,currFilt)),round(sliceInds(currFilt)));
    deltaRFils = rescaledDistMat(comInds);
    ignoreFils = rescaledIgnoreMat(comInds);
    % Store in vectors
    filDeltaRs(currFilt) = deltaRFils;
    maskedFils(currFilt) = ignoreFils;

    % Redefine filter to ignore filaments in masked areas of distMat
    newFilt = currFilt & (maskedFils == 0);

    %% Generate interpolation objects for sampling vels and dist. gradients
    % Fields to sample: x,y velocities, x,y dist transf. gradients
    % Define coordinate matrices over which fields are defined
    fullImgCoords = {1:imgSize(2),1:imgSize(1),1:imgSize(3)};
    bwgradIntObjs = generateFieldInterps(fullImgCoords,...
        mat2cell(allGrads,size(allGrads,1),size(allGrads,2),size(allGrads,3),[1 1 1]));
    % bwIntObj = generateFieldInterps(fullImgCoords,rescaledDistMat);
    % clear allGrads

    %% Calculate orientation field given by gradient of distance transform
    thetasFromGrads = atan2(allGrads(:,:,:,2),allGrads(:,:,:,1));
    bndgradThetas = bndmod(thetasFromGrads,-pi/2,pi/2);
    gradThetaObj = generateFieldInterps(fullImgCoords,bndgradThetas);
    
    %% Collect gradient orientations at filament centers; compare to filament orientations
    gthCoMs = gradThetaObj(CoMs(1,newFilt),CoMs(2,newFilt),sliceInds(newFilt));
    bwgxInterp = bwgradIntObjs{1};   bwgyInterp = bwgradIntObjs{2};
    bwgxAtCens = bwgxInterp(CoMs(1,newFilt),CoMs(2,newFilt),sliceInds(newFilt));
    bwgyAtCens = bwgyInterp(CoMs(1,newFilt),CoMs(2,newFilt),sliceInds(newFilt));
    
    %% Construct tensors from filament and local gradient orientations
    selThetas = allThetas(newFilt);
    filNVecs =  [cos(selThetas); sin(selThetas)];
    bwGradMags = sqrt(bwgxAtCens.^2+bwgyAtCens.^2);
    bwGradMags(bwGradMags == 0) = 1;
    bwGradAtCens = [bwgxAtCens; bwgyAtCens]./bwGradMags;
    % Generate vector to store alignments for current time
    alignVec = 1:sum(newFilt);
    for currInd = 1:sum(newFilt)
        currFilTensor = filNVecs(:,currInd).*filNVecs(:,currInd)' - eye(2)/2;
        currGradTensor = bwGradAtCens(:,currInd).*bwGradAtCens(:,currInd)' - eye(2)/2;
        alignVec(currInd) = sum(currFilTensor(:).*currGradTensor(:)) + 1/2;
    end

    %% Calculate alignment between filaments and gradient of distMat
    alignments = cos(bndmod(gthCoMs - allThetas(newFilt),-pi/2,pi/2));
    
    %% Store values in appropriate indices
    gradxs(newFilt) = bwgxAtCens;  gradys(newFilt) = bwgyAtCens;
    gradThetas(newFilt) = gthCoMs;
    rawDeltaThetas(newFilt) = gthCoMs - allThetas(newFilt);
    allAligns(newFilt) = alignments;
    tensorAligns(newFilt) = alignVec;
    % avgAlign(tInd) = mean(allAligns(currFilt));

end

%% Save
save(fullfile(filDataDir,'FilamentAlignment_3SegDataOG.mat'),'allAligns','tensorAligns','gradxs','gradys','gradThetas','allAligns','filDeltaRs','maskedFils','filterStruct','rawDeltaThetas');

end 


%% Load
load(fullfile(filDataDir,'FilamentAlignment_3SegDataOG.mat'))
load(fullfile(filDataDir,filDataName));
generalFilt = filterStruct.filter;

%% Plot order parameter over time for different delta r bins
timeSpace = 30;
timeVec = timeRange*timeSpace;
rBin = [-20:10:20];
storeMat = zeros(numel(rBin)-1,numel(timeVec));
numMat = storeMat;
maskLogic = maskedFils == 0;
currField = allAligns;
% currField = tensorAligns;
for rInd = 1:(numel(rBin) - 1)

    rEdge1 = rBin(rInd);    rEdge2 = rBin(rInd+1);
    rLogic = (filDeltaRs >= rEdge1) & (filDeltaRs < rEdge2);

    for tInd = 1:numel(timeRange)
        currT = timeRange(tInd);
        tLogic = objInds == currT;
        
        currLogic = generalFilt & tLogic & rLogic & maskLogic;
        currAligns = currField(currLogic);
        storeMat(rInd,tInd) = mean(currAligns);
        numMat(rInd,tInd) = sum(currLogic);
    end
end

filtMatLogic = numMat > 100;
filtMat = storeMat; filtMat(~filtMatLogic) = NaN;
% scatter(timeVec,storeMat','filled')
plot(timeVec,filtMat','LineWidth',2)
xlabel('Time (sec)')
ylabel('Average Alignment')
legend('-20um','-10um','0um','10um')
figure
plot(timeVec,numMat','LineWidth',2)
xlabel('Time (sec)')
ylabel('Number of Filaments')
legend('-20um','-10um','0um','10um')

%% Plot distribution of alignments for given r bin
colorVec = [1 0 0; 0 0 1; 0 1 0; 0 0 0];
timeColorStamps = [1 10 20 50];     % Session 84 exp 1
timeColorArray = stitchGradients(colorVec,timeColorStamps);

selTimes = 16;
rEdges = [-10 10];
stepNum = 20;
spacing = pi/stepNum;
binEdges = -pi/2:spacing:(pi/2);

maskLogic = maskedFils == 0;
rLogic = (filDeltaRs >= rEdges(1)) & (filDeltaRs <= rEdges(2));
figure
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    tLogic = objInds == currT;
    currFilt = generalFilt & tLogic & maskLogic & rLogic; 
    fieldVals = bndmod(rawDeltaThetas(currFilt),-pi/2, pi/2);
    a = histcounts(fieldVals,binEdges);
    plot(binEdges(1:end-1)+spacing/2,a./sum(a),'LineWidth',2)
    % plot(binEdges(1:end-1)+spacing/2,a./sum(a) + .02*tInd,'LineWidth',2)
    hold on
   
end

colororder(timeColorArray(selTimes,:))
xlim([-pi/2 pi/2])
set(gca, 'FontSize',15)
xlabel('Angle Difference of Alignment')
ylabel('Filament Fraction')
title('Alignment on Surfaces')

cbh = colorbar;
colormap(timeColorArray(selTimes,:));
cbh.Ticks = (selTimes - min(selTimes))/(max(selTimes)- min(selTimes)) ; %Create 8 ticks from zero to 1
cbh.TickLabels = num2cell(selTimes*30) ;  

%% Overlay filaments on segmentation
randomCheck = 1;
% saveDir ='<redacted original absolute path>';
saveDir ='Session 83';
saveName = 'Time%06i_Filaments.png';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 83';
imgName = 't%03i_illBleachCorr16bit_560.tif';

currSlice = 39;
alignsField = tensorAligns;
fieldBounds = [6000 21000];
timeRange = [10 12 16];
% figure
for tInd = 1:numel(timeRange)
    
    currT = timeRange(tInd);
    newFilt = generalFilt & (objInds == currT);

    if randomCheck == 1
        if ~exist(saveDir,'dir')
            mkdir(saveDir);
        end
        test = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        currDisp = squeeze(test(:,:,currSlice,:));
        tempLogic = newFilt & ismember(sliceInds,(-1:1)+currSlice);
        tempAligns = min(1,max(0,alignsField(tempLogic)));
        imagesc(currDisp);
        clim(fieldBounds)
        colormap(flipud(gray))
        hold on
        plot(backboneXs(:,tempLogic),backboneYs(:,tempLogic),'LineWidth',3,'Color','cyan');
        plot(backboneXs(:,tempLogic),backboneYs(:,tempLogic),'LineWidth',1,'Color','black');
        % colororder(([1; 0; 0].*tempAligns)' + ([0; 0; 1].*(1-tempAligns))');
        hold off
        xlim([100 450])
        ylim([100 450])
        % imwrite(getframe(gcf).cdata,fullfile(saveDir,sprintf(saveName,currT)));
    end
end