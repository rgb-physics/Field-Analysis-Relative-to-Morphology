%% FFT analysis

% blobDir = '<redacted original absolute path>';
blobDir = 'Session 35, Exp 1';
blobNameForm = 'BlobMat_Time%06i_Blobs.tif';
% segDir = '<redacted original absolute path>';
segDir = 'Session 35, Exp 1';
segNameForm = 'Rescaled_Time%06i_acOpt_Probabilities Stage 2.h5';
selectTimes = 1:50;
selectZ = 45:90;
h5Chan = 2;
subWin = 100;   %window size of inner region to query
scaleFact = 2;
pixSize = 2*11/20;

%% 
currBlobs = tiffreadVolume(fullfile(blobDir,sprintf(blobNameForm,selectTimes(20))));
rawDims = size(currBlobs);
fftBlobs = abs(fftshift(fftn(currBlobs)));

%% scale down

newWin = round(subWin/scaleFact);
currFrame = imresize3(currBlobs,1/scaleFact);
currPadded = padarray(currFrame, ceil(size(currFrame)/2), 0); %pad array for proper fftn

winInds = ceil(size(currPadded)/2)+repmat((-newWin:newWin)',1,3);

partHann = generateNDHann(repmat(2*newWin+1,1,numel(size(currFrame))));

vanHove = generateVanHove(currPadded);
partvanHove = vanHove(winInds(:,1),winInds(:,2),winInds(:,3));
scaledPartHove = partvanHove.*partHann;

%% radially average in xy
% padScPartHove = padarray(scaledPartHove, ceil(size(scaledPartHove)/2), 0);
fftPartHove = abs(fftshift(fftn(scaledPartHove)));

%% 
[meanVals,binRads] = radiallyAverageMatrix(fftPartHove(:,:,round(size(fftPartHove,3)/2)),2);
midVals = squeeze(fftPartHove(round(size(fftPartHove,1)/2),round(size(fftPartHove,2)/2),:));
midValsRefl = (midVals(end/2:-1:1) + midVals((end/2+1):end))/2;

%% plug z into matrix before radially averaging
test = zeros(size(fftPartHove,1), size(fftPartHove,2));
test(round(size(fftPartHove,1)/2),:) = midVals;
[zAvg,b] = radiallyAverageMatrix(test,2);



%% over time
firstBlobs = tiffreadVolume(fullfile(blobDir,sprintf(blobNameForm,selectTimes(1))));
firstBlobs = firstBlobs(:,:,selectZ);
rawDims = round(size(firstBlobs)/scaleFact);

newWin = round(subWin/scaleFact);
xyProfiles = zeros(numel(selectTimes), min(newWin, min(rawDims(1:2))));
xyProfilesReal = xyProfiles;
zProfiles = zeros(numel(selectTimes), min(newWin, rawDims(3))); 
zProfilesReal = zProfiles;

for tInd = 1:numel(selectTimes)
    currBlobs = tiffreadVolume(fullfile(blobDir,sprintf(blobNameForm,selectTimes(tInd))));
    currBlobs = currBlobs(:,:,selectZ);
    
    % scale down
    currFrame = double(imresize3(currBlobs,1/scaleFact));
    shiftedFrame = currFrame - mean(currFrame(:));

    %Calc autocorr
    currPadded = padarray(shiftedFrame, ceil(size(currFrame)/2), 0); %pad array for proper fftn
    padDims = size(currPadded);
    winInds = ceil(size(currPadded)/2)+repmat((-newWin:newWin)',1,3);
    winIndsx = unique(min(max(winInds(:,1),1),padDims(1)));
    winIndsy = unique(min(max(winInds(:,2),1),padDims(2)));
    winIndsz = unique(min(max(winInds(:,3),1),padDims(3)));
    partHann = generateNDHann([numel(winIndsx) numel(winIndsy) numel(winIndsz)]);
    vanHove = generateVanHove(currPadded);
    partvanHove = vanHove(winIndsx,winIndsy,winIndsz);
    scaledPartHove = partvanHove.*partHann;
    
    % fft to get nd structure tensor
    % padScPartHove = padarray(scaledPartHove, ceil(size(scaledPartHove)/2), 0);
    fftPartHove = abs(fftshift(fftn(scaledPartHove)));
    
    % radially average xy mid plane
    [meanVals,~] = radiallyAverageMatrix(fftPartHove(:,:,round(size(fftPartHove,3)/2)),2);
    xyProfiles(tInd,:) = meanVals(1:(end-1));
    % Reflect z mid line and average
    midVals = squeeze(fftPartHove(round(size(fftPartHove,1)/2),round(size(fftPartHove,2)/2),:));
    midValsRefl = (midVals(end/2:-1:1) + midVals((end/2+1):end))/2;
    zProfiles(tInd,:) = midValsRefl;
    
    % plug z into matrix before radially averaging
%     test = zeros(numel(midVals),numel(midVals));
%     test(round(size(midVals,1)/2),:) = midVals;
%     [zAvg,~] = radiallyAverageMatrix(test,2);
%     zProfiles(tInd,:) = zAvg(1:(end-1));

    % radially average xy mid plane
    [meanVals,binRads] = radiallyAverageMatrix(scaledPartHove(:,:,round(size(scaledPartHove,3)/2)),2);
    xyProfilesReal(tInd,:) = meanVals(1:(end-1));
    % plug z into matrix before radially averaging
    midVals = squeeze(scaledPartHove(round(size(scaledPartHove,1)/2),round(size(scaledPartHove,2)/2),:));
    midValsRefl = (midVals(end/2:-1:1) + midVals((end/2+1):end))/2;
    zProfilesReal(tInd,:) = midValsRefl;
%     test = zeros(size(scaledPartHove,1), size(scaledPartHove,2));
%     test(round(size(scaledPartHove,1)/2),:) = midVals;
%     [zAvg,~] = radiallyAverageMatrix(test,2);
%     zProfilesReal(tInd,:) = zAvg(1:(end-1));


end

%%
% save('<redacted original absolute path>', 'zProfiles', 'xyProfiles')
save('Session 35, Exp 1', 'zProfiles', 'xyProfiles')

%% Plot power spectra
kMax = 1/(scaleFact * pixSize);
xyWin = size(xyProfiles,2);
zWin =  size(zProfiles,2);
kVals = 1/xyWin*kMax*(1:xyWin);
kzVals = 1/zWin*kMax*(1:zWin);
colorsMap = meldNcolors([0 0 1; 1 0 0], numel(selectTimes));

figure
for tInd = 1:numel(selectTimes)
    loglog(kVals, xyProfiles(tInd,:), 'Color', colorsMap(tInd,:));
    hold on
end
colorbar
colormap(colorsMap)
xlabel('q_r (1/um)')
ylabel('Power spectrum q_r')
set(gca,'FontSize',15)
title('Power spectrum of q_r')

figure
for tInd = 1:numel(selectTimes)
    loglog(kzVals, zProfiles(tInd,:), 'Color', colorsMap(tInd,:));
    hold on
end
colorbar
colormap(colorsMap)
xlabel('q_z (1/um)')
ylabel('Power spectrum q_z')
set(gca,'FontSize',15)
title('Power spectrum of q_z')

%% Plot autocorrelations
xyWin = size(xyProfilesReal,2);
zWin =  size(zProfilesReal,2);
pixValsxy = (1:xyWin)*pixSize*scaleFact;
pixValsz = (1:zWin)*pixSize*scaleFact;
colorsMap = meldNcolors([0 0 1; 1 0 0], numel(selectTimes));

figure
for tInd = 1:numel(selectTimes)
    plot(pixValsxy, xyProfilesReal(tInd,:), 'Color', colorsMap(tInd,:));
    hold on
end
colorbar
colormap(colorsMap)
xlabel('r(x,y) (um)')
ylabel('Spatial autocorrelation of r')
set(gca,'FontSize',15)
title('Radially averaged autocorrelation of r over time')

figure
for tInd = 1:numel(selectTimes)
    plot(pixValsz, zProfilesReal(tInd,:), 'Color', colorsMap(tInd,:));
    hold on
end
colorbar
colormap(colorsMap)
xlabel('z (um)')
ylabel('Spatial autocorrelation of z')
set(gca,'FontSize',15)
title('Spatial autocorrelation of z over time')

%% Plot slopes of power spectra over time
figure
for tInd = 1:numel(selectTimes)
    slopesXY = ( log(xyProfiles(tInd,2:end)) - log(xyProfiles(tInd,1:(end-1))) )./( log(kVals(2:end)) - log(kVals(1:(end-1))) );
    semilogx(kVals(1:(end-1)), slopesXY, 'Color', colorsMap(tInd,:));
    hold on
end
colorbar
colormap(colorsMap)
xlabel('q_r (1/um)')
ylabel('Slope of power spectrum')
set(gca,'FontSize',15)
title('Semilogx of derivative of power spectrum q_r (power)')

%% Split power spectrum by powers of 10 
powerShifts = (1.12*ones(size(xyProfiles))).^(repmat(1:size(xyProfiles,2), size(xyProfiles,1),1));
shiftedxys = xyProfiles + powerShifts';
peakInds = zeros(numel(selectTimes),1);
figure
for tInd = 1:numel(selectTimes)
    [pks,locs] = findpeaks(xyProfiles(tInd,:));
    maxPk = pks == max(pks);
    peakInds(tInd) = locs(maxPk);
    loglog(kVals, shiftedxys(tInd,:), 'Color', colorsMap(tInd,:));
    hold on
    loglog(kVals(locs(maxPk)), shiftedxys(tInd, locs(maxPk)), '.', 'Color', colorsMap(tInd,:), 'MarkerSize', 20)
    loglog(kVals(locs(maxPk)), shiftedxys(tInd, locs(maxPk)), 'o', 'Color', 'k', 'MarkerSize', 6)
end
colorbar
colormap(colorsMap)
xlabel('q_r (1/um)')
ylabel('Shifted power spectrum q_r')
set(gca,'FontSize',15)
title('Shifted power spectrum of q_r over time')

figure
for tInd = 1:numel(selectTimes)
    scatter(selectTimes(tInd), kVals(peakInds(tInd)), 20, colorsMap(tInd,:), 'filled')
    hold on
end
colorbar
colormap(colorsMap)
xlabel('Time (frame)')
ylabel('Peak Power Spectrum q (1/um)')
set(gca,'FontSize',15)
title('Power Spectrum "Turning Point" over time')