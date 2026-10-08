%% Compare sparse filament alignment with object surface norms from dense
% Calculates orientation tensor of each filament based on orientation in
% cartesian space and samples gradient at each filament center of mass.
% Creates orientation tensor for gradient field, too. Takes product between
% both tensors over each filament, then averages after selection.
% 2024-10-01 - Rémi Boros

% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 83';
filDataName = 'Concatenated_2D_Info.mat';
% segDir = '<redacted original absolute path>';
segDir = 'Session 83';
segName = 't%03i_illCorr8bit_560_Probabilities Stage 2.h5';

% saveDir = 'Session 56, Exp 1';

timeRange = 1:50;
h5Chans = [1 2 3];
outInOnChans = [1 3 2];
h5thresh = 0.33;
ogPixSize = [.3667 .3667 1.5];      % Pixel size of microscope image;
thetaBinNum = 40;
rBinNum = 100;
deltarBounds = [-80 30];
inOnDist = 1;           % 1 to distinguish drop interiors and boundaries, otherwise combine interiors and boundaries and compare to bg
% Filament filter parameters
minVol = 8;                 % pixels (allVols)
minLength = 2;              % pixels (majAxes)
minAR = 1.5;                % Ratio major/minor axes (aspectRatio)
% selectSetInd = 1;            % Numbered data set (subIndsVec) (relevant when concatenated filaments over multiple directories)
randomCheck = 1;

% Image size
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 83';
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
    currH5 = loadH5(fullfile(segDir,sprintf(segName,currT)),'/exported_data',h5Chans);
    segSize = size(currH5);
    segPixSize = (imgSize./segSize(1:3)).*ogPixSize;
    cubicVoxelsSegSize = round(segSize(1:3).*segPixSize);
    % Separate into ins, outs, ons
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
        imresize3_4mat(currH5, cubicVoxelsSegSize),outInOnChans,h5thresh,1,1);
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

    %% Random checking
    if randomCheck == 1
        % saveDir ='<redacted original absolute path>';
        saveDir ='Session 83';
        saveName = 'Time%06i_Qaligns.png';
        if ~exist(saveDir,'dir')
            mkdir(saveDir);
        end
        alignsField = tensorAligns;
        currSlice = 38;
        % test = allGrads;
        test = imresize3(2*cleanOns + cleanIns,size(rescaledDistMat));
        currDisp = squeeze(test(:,:,currSlice,:));
        tempLogic = newFilt & ismember(sliceInds,(-1:1)+currSlice);
        tempAligns = min(1,max(0,alignsField(tempLogic)));
        imagesc(currDisp);
        colormap('gray')
        hold on
        plot(backboneXs(:,tempLogic),backboneYs(:,tempLogic),'LineWidth',2,'Color','white');
        plot(backboneXs(:,tempLogic),backboneYs(:,tempLogic),'LineWidth',1);
        colororder(([1; 0; 0].*tempAligns)' + ([0; 0; 1].*(1-tempAligns))');
        hold off
        imwrite(getframe(gcf).cdata,fullfile(saveDir,sprintf(saveName,currT)));

    end
    %%


end

%% Save
save(fullfile(filDataDir,'FilamentAlignment_AngleDataREDO.mat'),'allAligns','tensorAligns','gradxs','gradys','gradThetas','allAligns','filDeltaRs','maskedFils','filterStruct','rawDeltaThetas');

%% Load
load(fullfile(filDataDir,'FilamentAlignment_AngleDataREDO.mat'))
load(fullfile(filDataDir,filDataName));
generalFilt = filterStruct.filter;

%% Plot order parameter over time for different delta r bins
timeSpace = 30/60;
timeVec = timeRange*timeSpace;
rBin = [-Inf -8 10 Inf];
storeMat = zeros(numel(rBin)-1,numel(timeVec));
numMat = storeMat;
maskLogic = maskedFils == 0;
legLabels = {'Interior','Surface','Bulk'};
for rInd = 1:(numel(rBin) - 1)

    rEdge1 = rBin(rInd);    rEdge2 = rBin(rInd+1);
    rLogic = (filDeltaRs >= rEdge1) & (filDeltaRs < rEdge2);

    for tInd = 1:numel(timeRange)
        currT = timeRange(tInd);
        tLogic = objInds == currT;
        
        currLogic = generalFilt & tLogic & rLogic & maskLogic;
        currAligns = allAligns(currLogic);
        storeMat(rInd,tInd) = mean(currAligns);
        numMat(rInd,tInd) = sum(currLogic);
    end
end

filtMatLogic = numMat > 100;
filtMat = storeMat; filtMat(~filtMatLogic) = NaN;
% scatter(timeVec,storeMat','filled')
plot(timeVec,filtMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Average Alignment')
legend(legLabels)
set(gca,'FontSize',15)
figure
plot(timeVec,numMat','LineWidth',2)
xlabel('Time (min)')
ylabel('Number of Filaments')
legend(legLabels)
set(gca,'FontSize',15)

%% Plot distribution of alignments for given r bin
colorVec = [1 0 0; 0 0 1; 0 1 0; 0 0 0];
timeColorStamps = [1 10 20 50];     % Session 84 exp 1
timeColorArray = stitchGradients(colorVec,timeColorStamps);

selTimes = 2:3:50;
rEdges = [-10 10];
stepNum = 30;
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
