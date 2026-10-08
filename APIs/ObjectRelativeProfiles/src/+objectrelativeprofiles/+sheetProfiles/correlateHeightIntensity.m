%% This function takes in the height and intensity profiles of layers and correlates them
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 25, Exp 5';
heightDir = 'Surface Heights';
intDir = 'Surface Max Projections';
ringBin = 100;
pixelScale = 11*4/60;

%% Load data
hMat = double(tiffreadVolume(fullfile(dataDir, heightDir, 'BotSurface_heightInfo_redo.tif')));
iMat = tiffreadVolume(fullfile(dataDir, intDir, 'BotSurface_maxProjection_redo.tif'));

%% Get mean heights per time
meanHeights = mean(mean(hMat,1),2);
shiftedHeights = double(hMat) - repmat(meanHeights, [size(hMat,1), size(hMat,2) 1]);
dhMat = diff(hMat,1,3);

% 
% timeIndH = uint16(reshape(hMat, size(hMat,1), size(hMat,2)*size(hMat,3)));
% timeIndI = reshape(iMat, size(iMat,1), size(iMat,2)*size(iMat,3));

%% Bin dhMat to iMat
intsLeadTimes = iMat(:,:,1:end-1);
[N,dhEdges,iEdges,bindH,binI] = histcounts2(dhMat(:),intsLeadTimes(:),90);
[dhBinMat,iBinMat] = ndgrid(dhEdges(2:end), iEdges(2:end));
logN = log(N);
scatter3(dhBinMat(:), iBinMat(:), logN(:),'filled');
% imagesc(logN)

%% Bin dhMat to iMat over time
for currT = 1:size(dhMat,3)
    intsLeadTimes = iMat(:,:,1:end-1);
    [N,dhEdges,iEdges,bindH,binI] = histcounts2(dhMat(:),intsLeadTimes(:),90);
    [dhBinMat,iBinMat] = ndgrid(dhEdges(2:end), iEdges(2:end));
    logN = log(N);
    % scatter3(dhBinMat(:), iBinMat(:), logN(:),'filled');
    imagesc(logN)
end

%% Correlate
corrMat = zeros(size(hMat,1)+size(iMat,1)-1, size(hMat,2) + size(iMat,2) - 1, size(hMat,3));
hcorrMat = corrMat;
icorrMat = corrMat;
for currT = 1:size(hMat,3)

    corrMat(:,:,currT) = normxcorr2(hMat(:,:,currT), iMat(:,:,currT));
    hcorrMat(:,:,currT) = normxcorr2(hMat(:,:,currT), hMat(:,:,currT));
    icorrMat(:,:,currT) = normxcorr2(iMat(:,:,currT), iMat(:,:,currT));
%     corrMat(:,:,currT) = xcorr2(hMat(:,:,currT), iMat(:,:,currT));

end

%% Radial averaging
[rowInds, colInds] = ndgrid(-floor(size(corrMat,1)/2):floor(size(corrMat,1)/2),-floor(size(corrMat,2)/2):floor(size(corrMat,2)/2));
ringIndMat = zeros(size(rowInds));
maxRad = ceil(min(size(hMat,1)/2,size(hMat,2)/2)); radVals = 0:maxRad/ringBin:maxRad;

%Generate matrix of indices of rings to average over
for currRing = 2:numel(radVals)
    ringIndMat( (rowInds.^2 + colInds.^2) > radVals(currRing-1)^2 & (rowInds.^2 + colInds.^2) <= radVals(currRing)^2) = currRing - 1;
end

%% Store binned correlations
%For multiple 2D curves
corrsOverT = zeros(size(corrMat,3), ringBin);
for currT = 1:size(corrMat,3)
    
    for currBin = 1:ringBin
        
        [rows2D, cols2D] = ind2sub(size(rowInds), find(ringIndMat == currBin));
        inds3D = sub2ind(size(corrMat), rows2D, cols2D, currT*ones(size(rows2D)));
        corrsOverT(currT, currBin) = mean(corrMat(inds3D));

    end


end

%% Spatial autocorrelation of height and intensity
plot(mean(corrsOverT,1),'LineWidth',5,'Color','y')
hold on
for index = 1:100
    plot(corrsOverT(index,:), 'Color', [index/100 0 (1 - index/100)])
    
end

%% Store binned correlations
%For multiple 2D curves
hcorrsOverT = zeros(size(hcorrMat,3), ringBin);
for currT = 1:size(hcorrMat,3)
    
    for currBin = 1:ringBin
        
        [rows2D, cols2D] = ind2sub(size(rowInds), find(ringIndMat == currBin));
        inds3D = sub2ind(size(hcorrMat), rows2D, cols2D, currT*ones(size(rows2D)));
        hcorrsOverT(currT, currBin) = mean(hcorrMat(inds3D));

    end


end

%% Temporal autocorrelation of height and intensity
figure
hold on
for index = 1:100
    plot(radVals(2:end)*pixelScale,hcorrsOverT(index,:), 'Color', [index/100 0 (1 - index/100)])
    
end

plot(radVals(2:end)*pixelScale, mean(hcorrsOverT,1),'LineWidth',3,'Color','g')

%% Get length scale
xValAtZero = 27.2;
numPointsPreZero = numel(find(radVals*pixelScale < xValAtZero));
lengthScales = sum(pixelScale*radVals(2:numPointsPreZero).*hcorrsOverT(:,2:numPointsPreZero),2);


radialValidInds = ringIndMat > 0 & ringIndMat <xValAtZero;
radial3D = repmat(ringIndMat,[1 1 size(hcorrMat,3)]);
% selectedHInds = radial3D > 
lengthScale = sum(radVals(2:numPointsPreZero).*mean(hcorrsOverT(radialValidInds)),1)./sum(radVals(2:numPointsPreZero));

%% Plot height vs mean intensity averaged over all times
figure
[heightBins, heightVals] = discretize(double(hMat(:)),50);
for index = 1:numel(heightVals)-1
    scatter(heightVals(index), mean( iMat(heightBins == index)),20,[index/numel(heightVals) 0 index/numel(heightVals)], 'filled');
    hold on
end

%% Plot height vs mean intensity for each time point
figure
currVec = zeros(1,50);
for currT = 1:size(hMat,3)
    currHMat = double(hMat(:,:,currT));
    currIMat = double(iMat(:,:,currT));
    [heightBins, heightVals] = discretize(currHMat,50);
    for index = 1:numel(heightVals)-1
        currVec(index) = mean( currIMat(heightBins == index));
%         scatter(heightVals(index), ,8, [0 currT/size(hMat,3) (1-currT/size(hMat,3))], 'filled');
    end
    scatter(heightVals(2:end), currVec, 8, [0 currT/size(hMat,3) (1-currT/size(hMat,3))], 'filled');
    hold on
end

%% Generate convolution scaling matrix for autocorrelation
dim1Vec = genReflVec(size(hMat,1));
dim2Vec = genReflVec(size(hMat,2));
dim3Vec = genReflVec(size(hMat,3));
%Generate scaling matrix
[scaleMatX, scaleMatY, scaleMatT] = ndgrid(dim1Vec,dim2Vec, dim3Vec);
scaleMat2D = scaleMatX(:,:,1).*scaleMatY(:,:,1);
scaleMat3D = scaleMatX.*scaleMatY.*scaleMatT;

%% Get mean heights at each time
meanHeights = mean(mean(hMat,1),2);
[~,~,meanShiftMat] = ndgrid(dim1Vec, dim2Vec, meanHeights);
shiftedH = double(hMat) - meanShiftMat;

%% Get autocorrelation of matrix heights
% convMat = convn(hMat,hMat,'same');
storeMat = zeros(size(hMat));
repScaleMat2D = repmat(scaleMat2D,[1,1,100]);
for index = 1:100
    test = shiftedH(:,:,index);
%     convVec = conv2(test, flip(flip(test,1),2),'same');
%     imagesc(log(shiftConvVec./scaleMat2D))
%     clim([-2 8])
%     pause(.2)
    storeMat(:,:,index) = conv2(test, flip(flip(test,1),2),'same');
%     storeMat(:,:,index) = conv2(test, flip(test,1),'same');
end
[~,~,shiftMatStorage] = ndgrid(dim1Vec, dim2Vec, squeeze(min(min(storeMat,[],1),[],2)));
shiftedStoreMat = storeMat - shiftMatStorage;
scaledStoreMat = shiftedStoreMat./repScaleMat2D;

%% Van Hove function for each time
selectTimes = 1:5:100;
subWin = 150;   %window size of inner region to query
dataMat = shiftedHeights;
shiftedInts = double(iMat) - repmat(meanHeights, [size(iMat,1), size(iMat,2) 1]);
% dataMat = shiftedInts;
%Generate Hann functions to scale full correlation and subselection of correlation
firstTime = dataMat(:,:,1);
currPadded = padarray(firstTime, ceil(size(firstTime)/2), 0); %pad array for proper fftn
fullHann = generateNDHann(size(currPadded));
partHann = generateNDHann(2*[subWin, subWin]+1);
%Generate ring bin matrices
fullRad = generateRadialMatrix(size(fullHann),ringBin);
partRad = generateRadialMatrix(size(partHann),ringBin);

% Iterate over time
allMeans = [];
for currT = 1:numel(selectTimes)

    currFrame = dataMat(:,:,selectTimes(currT));
    currPadded = padarray(currFrame, ceil(size(currFrame)/2), 0); %pad array for proper fftn
    vanHove = generateVanHove(currPadded);
    
    partvanHove = vanHove(ceil(size(vanHove,1)/2)+(-subWin:subWin),ceil(size(vanHove,2)/2)+(-subWin:subWin));
    scaledPartHove = partvanHove.*partHann;
    fftPartHove = abs(fftshift(fftn(scaledPartHove)));
    [meanVals,binRads] = radiallyAverageMatrix(fftPartHove,2);
    allMeans = [allMeans, meanVals];

end

%%
figure
colormapMap = meldNcolors([0 0 1; 1 0 0],numel(selectTimes));
for currT = 1:numel(selectTimes)

    loglog(binRads, allMeans(:,currT),'.','MarkerSize',15,'Color',colormapMap(currT,:));
    hold on
end
set(gca, 'FontSize', 15);
xlabel('Log \Deltax')
ylabel('Log height power spectrum')
title('Power spectrum of height')
colorbar
colormap(colormapMap)

%%
%Calculate correlation
fftpH = fftn(currPadded);
prodpH = fftpH.*conj(fftpH);
corrpH = ifftshift(ifftn(prodpH));
scaleMat2D = genCorrScaleMat(size(corrpH));
vanHove = corrpH./scaleMat2D;       %apply hann function on full or partial image?
partvanHove = vanHove(ceil(size(vanHove,1)/2)+(-subWin:subWin),ceil(size(vanHove,2)/2)+(-subWin:subWin));

%Scale by Hann function
scaledVanHove = vanHove.*fullHann;
scaledPartHove = partvanHove.*partHann;

%Scale by Hann function and fourier transform
fftScaledAutoCorr = abs(fftshift(fftn(scaledVanHove)));
fftPartScaledAutoCorr = abs(fftshift(fftn(scaledPartHove)));

%% Plot power spectrum from fft of cropped, scaled, van Hove of data
[meanVals,binRads] = radiallyAverageMatrix(fftPartScaledAutoCorr,2);
% figure
loglog(binRads, meanVals,'.')








%% Liang sanity check: use flipping to calculate corr.
baseMat = shiftedHeights(:,:,1);
flipMat = flip(flip(baseMat,1),2);
convMats = conv2(baseMat, flipMat);
scaleMat2D = genCorrScaleMat(size(convMats));
corrConvMats = convMats./scaleMat2D;

%% Plot power spectrum from fft of cropped, scaled, van Hove of data


%% Radial average before autocorr (returns 1D instead of 2D)
radVanHove = zeros(ringBin,1);
for currBin = 1:ringBin
    radVanHove(currBin) = mean(partIntScatFunc( partRad == currBin ), 'all');
end

autoCorrH = fft(radVanHove);

%% Power spectrum: pad height array, fourier transform, product with conjugate, ifft, scale by array
paddedH = padarray(shiftedHeights, ceil(size(hMat)/2), 0);
fftpH = fftn(paddedH);
prodpH = fftpH.*conj(fftpH);
corrpH = ifftshift(ifftn(prodpH));
scaleMat3D = genCorrScaleMat(size(prodpH));
scaledpH = corrpH./scaleMat3D;
fftinpH = abs((fftn(scaledpH)));
% fftinpH = abs(fftshift(fftn(scaledpH)));
innerpH = reshape(scaledpH(logical(paddedH)), size(hMat));
fftinpH = abs(fftshift(fftn(innerpH)));

%% Average radially to extract power spectrum
% hcorrsOverT = zeros(size(hcorrMat,3), ringBin);
test = zeros(size(fftinpH,3), ringBin);

for currT = 1:size(fftinpH,3)
    
    for currBin = 1:ringBin
        
        [rows2D, cols2D] = ind2sub(size(rowInds), find(ringIndMat == currBin));
        inds3D = sub2ind(size(fftinpH), rows2D, cols2D, currT*ones(size(rows2D)));
%         inds3D = sub2ind(size(hcorrMat), rows2D, cols2D, currT*ones(size(rows2D)));
        test(currT, currBin) = mean(fftinpH(inds3D));

    end

end

%% FFT attempt
fftH = fftn(hMat);
fftIc = conj(fftn(iMat));
prodHIc = fftH.*fftIc;
xCorrHI = ifftshift(ifftn(prodHIc));
% scaledxCorr = xCorrHI./scaleMat3D;
% orthosliceViewer(scaledxCorr(149:189, 151:211, :))

%% Time only
fftH = fftn(hMat);
fftIc = conj(fftn(flip(flip(iMat,1),2)));
prodHIc = fftH.*fftIc;
xCorrHI = ifftshift(ifftn(prodHIc));

scaledxCorr = xCorrHI./scaleMat3D;

%% Time correlation of intensity vs change in height
deltaHMat = diff(hMat,1,3);
fftdH = fftn(deltaHMat);
fftIc = conj(fftn(flip(flip(iMat(:,:,2:end),1),2)));
proddHIc = fftdH.*fftIc;
xCorrdHI = ifftshift(ifftn(proddHIc));
