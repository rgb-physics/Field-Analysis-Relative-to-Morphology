%% Analysis for comparing orientation fields, velocities, and other quants
% This code assumes that PIV data has been saved in the form [x,y,z] rather
% than [row,col,depth]/[y,x,z]. This important is carried out through PIV
% calculation and griddedinterpolant object instantiation. 
% 2023-11-28
% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 56, Exp 1';
filDataName = 'Concatenated_2D_Info.mat';
% segDir = '<redacted original absolute path>';
segDir = 'Session 56, Exp 1';
segName = 'PassOne_t%03i_16bitSubSamp_Probabilities Stage 2.h5';
% pivDir = '<redacted original absolute path>';
pivDir = 'Session 56, Exp 1';
pivNameForm = 't%03i_pivOUT.mat';
% perimDir = '<redacted original absolute path>';
perimDir = 'Session 56, Exp 1';
perimTifs = 'inOnPerim_t%03i.tif';

% imgSaveDir = '<redacted original absolute path>';
imgSaveDir = 'Session 56, Exp 1';

timeRange = 40;
h5chans = [1 2 3];
outInOnChans = [1 2 3];
h5thresh = 0.33;
imgScaling = [1 1 4]/2;
thetaBinNum = 40;
rBinNum = 100;
deltarBounds = [-80 30];

desColorMap = [250 131 13; 0 0 0; 13 242 250; 255 255 255; 250 131 13]/255;

% Image size
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 56, Exp 1';
sampleImg = tiffreadVolume(fullfile(imgDir,'t003_illBleachCorr16bit.tif'));
imgSize = size(sampleImg); clear sampleImg

%% Load filament data and instantiate new variables
load(fullfile(filDataDir,filDataName));
gradxs = zeros(size(majAxes));
gradys = gradxs; gradThetas = gradxs; allAligns = gradxs;

%% Define logic to select for specific classes of filaments
allVec = ones(size(allVols));
sizeFilt = allVols > 8;         % pixels (allVols)
arFilt = majAxes./minAxes > 1;       % Ratio major/minor axes (aspectRatio)
sliceFilt = allVec;             % slice index   (sliceInds)
lengthFilt = majAxes > 2;       % pixels (majAxes)
generalFilt = sizeFilt & arFilt & sliceFilt & lengthFilt;

%% pick a time: load piv, orientations, perimeters -> distance transform
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    % % Load piv and filament info
    % load(fullfile(pivDir,sprintf(pivNameForm,currT)),'allShifts','cenCoords');
    validOris = allOris(objInds == currT);
    % load h5, split into in out on, get gradients from distance transform
    % Consider saving tifs of gradients to avoid having to recalculate from h5s
    [allGrads,distMat] = getDistGrads(fullfile(segDir,sprintf(segName,currT)),h5chans,outInOnChans,h5thresh,imgSize,imgScaling,0);
    
    if tInd == 1
        scaleDiff = imgSize./size(distMat);
    end

    if mod1b(tInd,10) == 1
        fprintf('Currently analyzing Frame %03i...\n',tInd)
    end
    %% Generate interpolation objects for sampling vels and dist. gradients
    % Fields to sample: x,y velocities, x,y dist transf. gradients
    % Define coordinate matrices over which fields are defined
    % velIntObjs = generateVelocityInterpolants(cenCoords,allShifts);
    % velIntObjs = generateVelocityInterpolants(cenCoords,allShifts);
    fullImgCoords = {1:imgSize(2),1:imgSize(1),1:imgSize(3)};
    bwgradIntObjs = generateFieldInterps(fullImgCoords,...
        mat2cell(allGrads,size(allGrads,1),size(allGrads,2),size(allGrads,3),[1 1 1]));
    bwIntObj = generateFieldInterps(fullImgCoords,imresize3(distMat,size(allGrads(:,:,:,1))));
    % clear allGrads
    
    %% Select z slice and prepare data
    currFilt = generalFilt & (objInds == currT);
    thetasFromGrads = atan2(allGrads(:,:,:,2),allGrads(:,:,:,1));
    bndgradThetas = bndmod(thetasFromGrads,-pi/2,pi/2);
    
    %% Collect gradient orientations at filament centers; compare to filament orientations
    gradThetaObj = generateFieldInterps(fullImgCoords,bndgradThetas);
    gthCoMs = gradThetaObj(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
    bwgxInterp = bwgradIntObjs{1};   bwgyInterp = bwgradIntObjs{2};
    bwgxAtCens = bwgxInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
    bwgyAtCens = bwgyInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
    
    %% Calculate alignment
    alignments = cos(bndmod(gthCoMs - allThetas(currFilt),-pi/2,pi/2));
    
    %% Store values in appropriate indices
    gradxs(currFilt) = bwgxAtCens;  gradys(currFilt) = bwgyAtCens;
    gradThetas(currFilt) = gthCoMs;
    allAligns(currFilt) = alignments;
end
save(fullfile(filDataDir,'FilamentAlignment_AngleData.mat'),'allAligns','gradxs','gradys','gradThetas');

%% Plot different alignment histograms over time
histBins = 0:.05:1;
allBins = zeros(numel(timeRange),numel(histBins)-1);
figure
hold on
for tInd = 1:numel(timeRange)
    currFilt = generalFilt & (objInds == tInd);
    allBins(tInd,:) = histcounts(allAligns(currFilt),histBins);
    plot( (histBins(1:end-1) + histBins(2:end))/2, allBins(tInd,:)./sum(allBins(tInd,:)), 'Color', [tInd/numel(timeRange) 0 (1 - tInd/numel(timeRange))])
end
xlabel('Degree of alignment')
ylabel('Fraction of filaments')
title('Distribution of Filament Alignments Over Time')
set(gca, 'FontSize',20)

%% Mean alignment w/ errorbars per delta r over time
deltarBins = -60:2:30;
meanStore = zeros(numel(deltarBins),numel(timeRange));
stdStore = meanStore;
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    timeFilt = generalFilt & (objInds == currT);
    currAligns = allAligns(timeFilt);
    
    [currBins,~,currInds] = histcounts(currAligns,deltarBins);
    for rInd = 1:numel(deltarBins)
        currSel = currAligns(currInds == deltarBins(rInd));
        if numel(currSel) > 0
            meanStore(rInd,currT) = mean(currAligns(currInds == deltarBins(rInd)));
            stdStore(rInd,currT) = std(currAligns(currInds == deltarBins(rInd)));
        end
    end
end

%% Calculate distribution in alignments for different separation dists
% [~,~,rBins] = histcounts(bwIntObj(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt)),rBinNum);

%% Plot filaments, color by theta (-pi/2 to pi/2)
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    currFilt = generalFilt & (objInds == currT);
    zInd = 20;
    
    [~,distMat] = getDistGrads(fullfile(segDir,sprintf(segName,currT)),h5chans,outInOnChans,h5thresh,imgSize,imgScaling,0);
    
    zFilt = (sliceInds >= zInd - 2) & (sliceInds <= zInd + 2);
    imgSaveName = 'Slice %03i at Time %03i - Filament Orientation 5 Proj';
    distMatSlice = distMat(:,:,zInd);
    dispSlice = imresize(distMatSlice, imgSize(1:2));
    % dispSlice = bndgradThetas(:,:,zInd);
    currThetas = allThetas(currFilt & zFilt);
    % Indices of object perimeters
    [zeroy,zerox] = ind2sub(size(distMatSlice),find(distMatSlice==0));
    zerox = zerox*scaleDiff(1); zeroy = zeroy*scaleDiff(2);
    
    % Binning
    % Generate a colormap based on dot product value
    [~,~,binInds] = histcounts(currThetas,thetaBinNum);
    colorVec = meldNcolors(desColorMap,round(thetaBinNum/(size(desColorMap,1)-1)));
    colorarray = colorVec(binInds,:);
    
    % Plot all filaments and color code using colorarray
    figure
    sfh1 = subplot(1,2,1);
    imagesc(dispSlice);
    colormap(gray)
    hold on
    title(sprintf(imgSaveName,zInd,currT))
    plot(backboneXs(:,currFilt & zFilt),backboneYs(:,currFilt & zFilt),'LineWidth',2);
    colororder(colorarray);
    scatter(zerox,zeroy,6,'r','filled');
    xlim([0 750]); ylim([0 740]); zlim([0 75]);
    
    sfh2 = subplot(1,2,2);
    imagesc(reshape(colorVec(end:-1:1,:),[numel(colorVec)/3,1,3]))
    
    sfh2.Position = [0.9 sfh2.Position(2) 0.05 sfh2.Position(4)];
    sfh2.YAxisLocation = 'right';
    sfh1.Position = [sfh1.Position(1) sfh1.Position(2) 0.7 sfh1.Position(4)];
    set(gcf,'Position',[100 100 900 800])
    
    exportgraphics(gcf,fullfile(imgSaveDir,[sprintf(imgSaveName,zInd,currT) '.png']));
    close();
end

%% Plot filaments, color by alignment with gradient (projected two z slices above and below)
% NOTE: alignment is calculated in the slice that the filament is observed
% in and does NOT use the gradient of the current z slice as reference
desColorMap = [1 .8 0; 0 .2 1];
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    currFilt = generalFilt & (objInds == currT);
    zInd = 20;
    
    [~,distMat] = getDistGrads(fullfile(segDir,sprintf(segName,currT)),h5chans,outInOnChans,h5thresh,imgSize,imgScaling,0);
    
    zFilt = (sliceInds >= zInd - 2) & (sliceInds <= zInd + 2);
    imgSaveName = 'Slice %03i at Time %03i - Filament Alignment 5 Proj';
    distMatSlice = distMat(:,:,zInd);
    dispSlice = imresize(distMatSlice, imgSize(1:2));
    % dispSlice = bndgradThetas(:,:,zInd);
    currAligns = allAligns(currFilt & zFilt);
    % Indices of object perimeters
    [zeroy,zerox] = ind2sub(size(distMatSlice),find(distMatSlice==0));
    zerox = zerox*scaleDiff(1); zeroy = zeroy*scaleDiff(2);
    
    % Binning
    % Generate a colormap based on dot product value
    [~,~,binInds] = histcounts(currAligns,thetaBinNum);
    colorVec = meldNcolors(desColorMap,round(thetaBinNum/(size(desColorMap,1)-1)));
    colorarray = colorVec(binInds,:);
    
    % Plot all filaments and color code using colorarray
    figure
    sfh1 = subplot(1,2,1);
    imagesc(dispSlice);
    colormap(gray)
    hold on
    title(sprintf(imgSaveName,zInd,currT))
    plot(backboneXs(:,currFilt & zFilt),backboneYs(:,currFilt & zFilt),'LineWidth',2);
    colororder(colorarray);
    scatter(zerox,zeroy,6,'r','filled');
    xlim([0 750]); ylim([0 740]); zlim([0 75]);
    
    sfh2 = subplot(1,2,2);
    imagesc(reshape(colorVec(end:-1:1,:),[numel(colorVec)/3,1,3]))
    
    sfh2.Position = [0.9 sfh2.Position(2) 0.05 sfh2.Position(4)];
    sfh2.YAxisLocation = 'right';
    sfh1.Position = [sfh1.Position(1) sfh1.Position(2) 0.7 sfh1.Position(4)];
    set(gcf,'Position',[100 100 900 800])
    
    exportgraphics(gcf,fullfile(imgSaveDir,[sprintf(imgSaveName,zInd,currT) '.png']));
    close();
end

%% Plot filaments, color by alignment with gradient (projected two z slices above and below)
% Overlap over original tif dense phase
% NOTE: alignment is calculated in the slice that the filament is observed
% in and does NOT use the gradient of the current z slice as reference
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 56, Exp 1';
imgName = 't%03i_illBleachCorr16bit.tif';
desColorMap = [1 .8 0; 1 0 0;0 .2 1];
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    currFilt = generalFilt & (objInds == currT);
    zInd = 20;
    
    distMatSlice = tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT)),"PixelRegion",{[1 1 inf], [1 1 inf], [zInd zInd]});
    
    zFilt = (sliceInds >= zInd - 2) & (sliceInds <= zInd + 2);
    imgSaveName = 'Slice %03i at Time %03i - Filament Alignment 5 Proj Over Tif';
    dispSlice = imresize(distMatSlice, imgSize(1:2));
    % dispSlice = (dispSlice - min(dispSlice(:)))/(max(dispSlice(:)) - min(dispSlice(:)))*2^16;
    % dispSlice = bndgradThetas(:,:,zInd);
    currAligns = allAligns(currFilt & zFilt);
    % Indices of object perimeters
    [zeroy,zerox] = ind2sub(size(distMatSlice),find(distMatSlice==0));
    zerox = zerox*scaleDiff(1); zeroy = zeroy*scaleDiff(2);
    
    % Binning
    % Generate a colormap based on dot product value
    [~,~,binInds] = histcounts(currAligns,thetaBinNum);
    colorVec = meldNcolors(desColorMap,round(thetaBinNum/(size(desColorMap,1)-1)));
    colorarray = colorVec(binInds,:);
    
    % Plot all filaments and color code using colorarray
    figure
    sfh1 = subplot(1,2,1);
    imagesc(dispSlice);
    colormap(gray)
    clim([0.4 2]*10^4)
    hold on
    title(sprintf(imgSaveName,zInd,currT))
    plot(backboneXs(:,currFilt & zFilt),backboneYs(:,currFilt & zFilt),'LineWidth',2);
    colororder(colorarray);
    scatter(zerox,zeroy,6,'r','filled');
    xlim([0 750]); ylim([0 740]); zlim([0 75]);
    
    sfh2 = subplot(1,2,2);
    imagesc(reshape(colorVec(end:-1:1,:),[numel(colorVec)/3,1,3]))
    
    sfh2.Position = [0.9 sfh2.Position(2) 0.05 sfh2.Position(4)];
    sfh2.YAxisLocation = 'right';
    sfh1.Position = [sfh1.Position(1) sfh1.Position(2) 0.7 sfh1.Position(4)];
    set(gcf,'Position',[100 100 900 800])
    
    exportgraphics(gcf,fullfile(imgSaveDir,[sprintf(imgSaveName,zInd,currT) '.png']));
    close();
end

%% Degree of alignment - Filament orientation vs. distance transform grad
imgSaveName = 'Slice %03i at Time %03i - Field Alignment';
% Binning
thetaBinNum = 40;
corrBound = 1.5;
% Sample gradients at CoMs of interest
bwgxInterp = bwgradIntObjs{1};   bwgyInterp = bwgradIntObjs{2};
bwgxAtCens = bwgxInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
bwgyAtCens = bwgyInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
bwgThetas = atan2(bwgyAtCens,bwgxAtCens);
nematicBWG = bndmod(bwgThetas,-pi/2,pi/2);

% Dot product
dotProd = cos(nematicBWG - allThetas(currFilt));

% Generate a colormap based on dot product value
[~,~,binInds] = histcounts(dotProd,thetaBinNum);
colorVec = meldNcolors([0 131 13; 0 0 0; 255 242 0; 255 255 255; 0 131 13]/255,round(thetaBinNum/4));
colorarray = colorVec(binInds,:);

% Plot all filaments and color code using colorarray
figure
sfh1 = subplot(1,2,1);
imagesc(dispSlice);
colormap(gray)
hold on
title(sprintf(imgSaveName,zInd,currT))
% plot3(backboneXs(:,currFilt),backboneYs(:,currFilt),[sliceInds(:,currFilt);sliceInds(:,currFilt)]);
plot(backboneXs(:,currFilt),backboneYs(:,currFilt),'LineWidth',2);
colororder(colorarray);
xlim([0 750])
ylim([0 740])
zlim([0 75])
sfh2 = subplot(1,2,2);
imagesc(reshape(colorVec(end:-1:1,:),[numel(colorVec)/3,1,3]))

sfh2.Position = [0.9 sfh2.Position(2) 0.05 sfh2.Position(4)];
sfh2.YAxisLocation = 'right';
sfh1.Position = [sfh1.Position(1) sfh1.Position(2) 0.7 sfh1.Position(4)];
set(gcf,'Position',[100 100 900 800])

% exportgraphics(gcf,fullfile(imgSaveDir,[sprintf(imgName,zInd,currT) '.png']));
% close();

%% Plot filaments over orientation field from gradients
gradThetas = atan2(-allGrads(:,:,:,2),allGrads(:,:,:,1));
bndgradThetas = bndmod(gradThetas,-pi/2,pi/2);
dispSlice = bndgradThetas(:,:,zInd);
currThetas = allThetas(currFilt);



% make scattered interpolant of bounded thetas from gradient fields, sample
% at filament centers, compare to filament orientations
bndThetaObj = generateFieldInterps(fullImgCoords,bndgradThetas);
bndThetaCoMs = bndThetaObj(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));

% Generate a colormap based on dot product value
[~,~,binInds] = histcounts(currThetas,thetaBinNum);
colorVec = meldNcolors([0 131 13; 0 0 0; 255 242 0; 255 255 255; 0 131 13]/255,round(thetaBinNum/4));
colorarray = colorVec(binInds,:);

% Plot all filaments and color code using colorarray
figure
sfh1 = subplot(1,2,1);
imagesc(dispSlice);
colormap(colorVec)
hold on
title(sprintf(imgSaveName,zInd,currT))
% plot3(backboneXs(:,currFilt),backboneYs(:,currFilt),[sliceInds(:,currFilt);sliceInds(:,currFilt)]);
plot(backboneXs(:,currFilt),backboneYs(:,currFilt),'LineWidth',2);
colororder(colorarray);
xlim([0 750])
ylim([0 740])
zlim([0 75])

sfh2 = subplot(1,2,2);
imagesc(reshape(colorVec,[numel(colorVec)/3,1,3]))

sfh2.Position = [0.9 sfh2.Position(2) 0.05 sfh2.Position(4)];
sfh2.YAxisLocation = 'right';
sfh1.Position = [sfh1.Position(1) sfh1.Position(2) 0.7 sfh1.Position(4)];
set(gcf,'Position',[100 100 900 800])

%% Plot filaments, color by binned distribution of a field
% corrBound = 1.5;
thetaBinNum = 100;
% Generate a colormap based on dot product value
[binN,binEdges,binInds] = histcounts(signedDot,thetaBinNum);
colorVec = meldNcolors([1 0 0; 0 1 0; 0 0 1],round(thetaBinNum/2));
colorarray = colorVec(binInds,:);

% Plot all filaments and color code using colorarray
figure
plot3(backboneXs(:,currFilt),backboneYs(:,currFilt),[sliceInds(:,currFilt);sliceInds(:,currFilt)]);
% plot(backboneXs(:,currFilt),backboneYs(:,currFilt));
colororder(colorarray);
xlim([0 750])
ylim([0 740])
zlim([0 75])

%% Sample gradients at centroid locations, then dot
corrBound = 1.5;
thetaBinNum = 100;
bwgxInterp = bwgradIntObjs{1};   bwgyInterp = bwgradIntObjs{2};
currFilt = generalFilt & (objInds == currT);
bwgxAtCens = bwgxInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
bwgyAtCens = bwgyInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
bwAtCens = bwIntObj(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));

% Need sign combo of x and y components for nematic symmetry
gradDegSigns = (sign(bwgxAtCens) + (bwgxAtCens == 0)).*(sign(bwgyAtCens) + (bwgyAtCens == 0));

% Calculate signed dot product
currThetas = allThetas(currFilt);
signedDot = min(max(gradDegSigns.*(cos(currThetas).*bwgxAtCens + sin(currThetas).*bwgyAtCens),-corrBound),corrBound);

%% Look at filaments, colored by degree of orientation 
% Generate a colormap based on dot product value
[binN,binEdges,binInds] = histcounts(signedDot,thetaBinNum);
colorVec = meldNcolors([1 0 0; 0 1 0; 0 0 1],round(thetaBinNum/2));
colorarray = colorVec(binInds,:);

% Plot all filaments and color code using colorarray
figure
plot3(backboneXs(:,currFilt),backboneYs(:,currFilt),[sliceInds(:,currFilt);sliceInds(:,currFilt)]);
% plot(backboneXs(:,currFilt),backboneYs(:,currFilt));
colororder(colorarray);
xlim([0 750])
ylim([0 740])
zlim([0 75])

%% Sample fields at filament centers of mass

%% Single z slice for image test
selSlice = 30;
currFilt = generalFilt & (objInds == currT) & (sliceInds == selSlice);
bwgxInterp = bwgradIntObjs{1};   bwgyInterp = bwgradIntObjs{2};
bwgxAtCens = bwgxInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
bwgyAtCens = bwgyInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));

% numerically compare to rounded coordinate values
roundCoMs = round(CoMs);
checkInds = sub2ind(size(allGrads),roundCoMs(2,currFilt),roundCoMs(1,currFilt),selSlice*ones(1,sum(currFilt)),1*ones(1,sum(currFilt)));
compareValsx = allGrads(checkInds);
mean(compareValsx - bwgxAtCens); std(compareValsx - bwgxAtCens);

figure
% imshow(allGrads(:,:,selSlice,1))
imagesc(allGrads(:,:,selSlice,1))
hold on
plot(backboneXs(:,currFilt),backboneYs(:,currFilt),'LineWidth',2,'Color','r');
% scatter(CoMs(1,currFilt),CoMs(2,currFilt)); 



%% Compare cos(2*thetas)
% Calculate angles of gradients at filament centers
bwgxInterp = bwgradIntObjs{1};   bwgyInterp = bwgradIntObjs{2};
currFilt = generalFilt & (objInds == currT);
bwgxAtCens = bwgxInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
bwgyAtCens = bwgyInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
gradThetas = atan2(bwgyAtCens,bwgxAtCens);
cos2gThetas = cos(2*gradThetas);

figure
histogram(cos2gThetas.*cos(2*allThetas(currFilt)));

%% Generate scattered interpolant for filament orientation field
scAngInt = scatteredInterpolant(CoMs(1,currFilt)',CoMs(2,currFilt)',cos(2*allThetas(currFilt))');
test = scAngInt({1:100,1:100,1:100});

%% Work towards Q-tensor: nn
% Interpolate gradients at filament centers
bwgxInterp = bwgradIntObjs{1};   bwgyInterp = bwgradIntObjs{2};
currFilt = generalFilt & (objInds == currT);
bwgxAtCens = bwgxInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
bwgyAtCens = bwgyInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
% Define indices to efficiently calculate outer products
interbwgs = zeros(1,2*numel(bwgxAtCens));
interbwgs(1:2:end) = bwgxAtCens;    interbwgs(2:2:end) = bwgyAtCens;
allInds = repmat(1:numel(interbwgs),2,1);  rowInds = allInds(:)';
colInds = rowInds;  
colInds(2:4:end) = colInds(2:4:end) + 1; colInds(3:4:end) = colInds(3:4:end) - 1;
% Calculate outer products
nn2D = reshape(interbwgs(rowInds).*interbwgs(colInds),[2 2 numel(bwgyAtCens)]);
