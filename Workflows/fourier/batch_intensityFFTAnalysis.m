%% Takes in a directory of tifs and returns Fourier Analysis... things
% 2023-12-07

%% Data info
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 81, Exp 2';
dataDir = fullfile(baseDir,'6 Illumination Bleach Corrected 16bit');
% dataDir = fullfile(baseDir,'6 Illumination Bleach Corrected 16bit');
dataName = 't%03i_illBleachCorr16bit_560.tif';
% dataName = 't%03i_illBleachCorr16bit.tif';
saveDir = fullfile(baseDir,'Fourier Analysis');
saveStr = 'Sigma %02i Average Fourier Profiles 2D z%i-%i t%i-%i HannSmooth%i.mat';

timeRange = 1:230;
scaleVec = [1 1 1];
pixSize = 11*2/20;
zRanges = [30 50];  zIncr = 2;
hannBool = 1;   % Using Hanning to smooth?

qRange = 1:370;
sigmaVal = 2;

timeColorVec = [1 0 0; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
% timeColorStamps = [1 25 50 75 100];
timeColorStamps = [1 5 19 37 110 250];     % Session 35 exp 2
% timeColorStamps = [1 12 25 60 100];     % Session 35 exp 1
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);
% save(fullfile(saveDir,'Colormap.mat'),'timeColorArray');

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Calculate and store 2D Fourier on each 2D slice
zRange = zRanges(1):zIncr:zRanges(2); 
for tInd = 1:numel(timeRange)

    % Instantiate loading indices and scaling matrices
    currT = timeRange(tInd);
    if tInd == 1
        currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));
        imgSize = size(currTif);  
        % If applying Gaussian smoothing to bins, image must be square
        if sigmaVal > 0 
            rMaxes = [floor(min(imgSize(1:2))/2) floor(min(imgSize(1:2))/2)];
        else
            rMaxes = round(imgSize(1:2)/2) - mod(imgSize(1:2),2);       % Even/odd edgecase
        end
        xyStarts = 1 + floor(imgSize(1:2)/2) - rMaxes;
        xyEnds = round(imgSize(1:2)/2) + rMaxes;
        % Generate Hanning function for low q correction, if requested
        if hannBool == 1
            hannMat = repmat(generateNDHann(2*rMaxes + mod(imgSize(1:2),2)),[1 1 numel(zRange)]);
        else
            hannMat = ones(imgSize(1:2),numel(zRange));
        end
    end

    % Load fraction of image of interest
    currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)),...
        'PixelRegion',{[xyStarts(1) 1 xyEnds(1)],[xyStarts(2) 1 xyEnds(2)],[zRanges(1) zIncr zRanges(2)]}));
    scaleMat = hannMat;
    % Calculate POWER SPECTRUM of each 2D xy slice
    storeMat = fftshift(abs(fft2(currTif.*scaleMat).^2));       % hanning, then shift (hanning is nonlinear)
    % Calculate 2D POWER SPECTRUM of real space projection along z
    storeMat2D = fftshift(abs(fft2(mean(currTif,3).*scaleMat(:,:,1)).^2));
    % Radially average and store
    if tInd == 1
        FFTPixSize = 1/(2*rMaxes(1)*pixSize);
        if sigmaVal > 0
            [~,k_bins,~,kInds] = radiallyAverageMatrix(storeMat2D,sigmaVal,1,qRange);
            kValsMid = FFTPixSize*(k_bins(1:end-1) + k_bins(2:end))/2;
            kVals = FFTPixSize*k_bins;
            kInds3D = repmat(kInds,[1 1 numel(zRange)]);
            lowLogic = kInds3D < min(qRange);
        else
            kMat = sqrt(genScaledKVec(imgSize(1))'.^2 + genScaledKVec(imgSize(2)).^2);
            k_bins = qRange/(sqrt(dot(imgSize,imgSize)));
            [~,~,kInds] = histcounts(kMat,k_bins);
            kVals = k_bins/pixSize;
            kValsMid = FFTPixSize*(k_bins(1:end-1) + k_bins(2:end))/2;
        end
        meanVals = []; meanValsProj = [];
    end

    if sigmaVal > 0
        storeMat(lowLogic) = mean(storeMat(kInds3D == qRange(1)),'all');
        storeMat2D(lowLogic(:,:,1)) = mean(storeMat2D(kInds == qRange(1)),'all');
        temp = radiallyAverageMatrix(storeMat,sigmaVal,1,qRange);
        tempProj = radiallyAverageMatrix(storeMat2D,sigmaVal,1,qRange);
    else
        temp = zeros(numel(k_bins),1); tempProj = temp;
        for currBin = 1:numel(k_bins)
            temp(currBin) = mean(storeMat(kInds == currBin));
            tempProj(currBin) = mean(storeMat2D(kInds == currBin));
        end
    end
    meanVals = [meanVals, temp];
    meanValsProj = [meanValsProj, tempProj];

end

%% Save data
save(fullfile(saveDir,sprintf(saveStr,sigmaVal,min(zRange),max(zRange),min(timeRange),max(timeRange),hannBool)),...
    'meanVals','meanValsProj','k_bins','kVals','kValsMid','sigmaVal');

%% Plot everything
% selTimes = 64:2:100;
selTimes = 1:4:46;
figure
plot(kVals(1:end)/2,meanVals((1:end),selTimes),'LineWidth',2)
% loglog(kVals(1:end)/2,meanVals((1:end),selTimes),'LineWidth',2)
hold on
% loglog(kVals,meanValsProj(:,selTimes),'LineWidth',2)
% loglog(kVals,meanVals(:,selTimes)./meanVals(:,1),'LineWidth',2)
colororder(timeColorArray(selTimes,:))
xlabel('q (1/um)')
ylabel('Mean FFT Profile')
title('Power Spectra Over Time')
set(gca,'FontSize',15)
% ylim(10.^([-8 -3]))
% yticks(10.^(-8:-3));
% xlim([0 .5])
% ylim([0 4]*10^7)

%% 3D Plots
selTimes = 1:94;
scatterTimes = 1:94;
kRange = 4:numel(kVals);
currField = meanVals;
validK = kVals(kRange);
% [~,pkInds] = max(meanVals(kRange,scatterTimes));
[~,pkInds] = max(log(currField(kRange,scatterTimes)./currField(kRange,1)));
pkIndsShift = pkInds + min(kRange) - 1;
% [pkVals,~] = max(meanVals(kRange,scatterTimes));
pkVals = currField(sub2ind(size(currField),pkIndsShift,scatterTimes));
figure
plot3(log10(repmat(kVals',[1 numel(selTimes)])),...
    repmat(selTimes,[numel(kVals) 1]), ...
    log10(currField(:,selTimes)),'LineWidth',2);
% plot3(log10(repmat(kVals(kRange)',[1 numel(selTimes)])),...
%     repmat(selTimes,[numel(kRange) 1]), ...
%     log10(meanVals(kRange,selTimes)./meanVals(kRange,1)),'LineWidth',2);
hold on
scatter3(log10(validK(pkInds)),scatterTimes,log10(pkVals),80,[1 .8 1],'filled')
colororder(timeColorArray(selTimes,:))
xlabel('q (1/um)')
ylabel('Time')
zlabel('Mean FFT Profile')
title('Power Spectra Over Time')
set(gca,'FontSize',20)

%% Plot spectra peak amps and freqs peaks found above
scaledTimes = selTimes*35;
figure
subplot(2,1,1)
scatter(scaledTimes,log10(validK(pkInds)),[],timeColorArray(scatterTimes,:),'filled')
ylabel('Peak qs (1/um power)')
ylim([-2.1 -1.5])
set(gca,'FontSize',15)
box on

subplot(2,1,2)
scatter(scaledTimes,log10(pkVals),[],timeColorArray(scatterTimes,:),'filled')
% scatter(scatterTimes(1:end-1),log10(validK(pkInds(1:end-1)))-log10(validK(pkInds(2:end))),[],timeColorArray(scatterTimes(1:end-1),:),'filled')
ylabel('Peak Amplitude')
xlabel('Time (sec)')
set(gca,'FontSize',15)
box on

%% Plot peak spectra and amps over time
selTimes = 1:100;
[normpkVals,pkInds] = max((meanVals(:,selTimes)./meanVals(:,1)));
matInds = sub2ind(size(meanVals),pkInds,selTimes);
figure
subplot(2,1,1)
plot(selTimes,log10(kVals(pkInds)),'LineWidth',3)
hold on
scatter(selTimes,log10(kVals(pkInds)),[],timeColorArray(selTimes,:),'filled')
ylabel('Peak qs (1/um power)')
set(gca,'FontSize',20)
subplot(2,1,2)
plot(selTimes,log10(meanVals(pkInds)),'LineWidth',3)
hold on
scatter(selTimes,log10(meanVals(pkInds)),[],timeColorArray(selTimes,:),'filled')
ylabel('Peak Amplitude')
xlabel('Time (frame)')
set(gca,'FontSize',20)
% ylim([13.5 14.5])

%% Plot diffs in peak spectra and amps over time
selTimes = 6:94;
[normpkVals,pkInds] = max((meanVals(:,selTimes)./meanVals(:,1)));
matInds = sub2ind(size(meanVals),pkInds,selTimes);
diffKs = log(kVals(pkInds));
figure
subplot(2,1,1)
plot(selTimes,log(kVals(pkInds)),'LineWidth',3)
hold on
scatter(selTimes,log(kVals(pkInds)),[],timeColorArray(selTimes,:),'filled')
ylabel('Peak qs (1/um power)')
set(gca,'FontSize',20)
subplot(2,1,2)
plot(selTimes,log(meanVals(pkInds)),'LineWidth',3)
hold on
scatter(selTimes,log(meanVals(pkInds)),[],timeColorArray(selTimes,:),'filled')
ylabel('Peak Amplitude')
xlabel('Time (frame)')
set(gca,'FontSize',20)
ylim([13.5 14.5])
%% 
timeColorArray = stitchGradients(timeColorVec,timeColorStamps,1);
set(gca,'FontSize',15)
xlabel('Frame (30s/frame)')

%% Plot slopes of power spectra over time

slopesXY = ( log10(meanVals(2:end,:)) - log10(meanVals(1:(end-1),:)) )./( log10(kVals(2:end)) - log10(kVals(1:(end-1))) )';
% slopesXY = ( log10(meanValsProj(2:end,:)) - log10(meanValsProj(1:(end-1),:)) )./( log10(kVals(2:end)) - log10(kVals(1:(end-1))) )';
figure
semilogx(kVals(1:end-1),slopesXY);
colororder(timeColorArray);
xlabel('q_r (1/um)')
ylabel('Slope of power spectrum')
set(gca,'FontSize',15)
title('Semilogx of derivative of power spectrum q_r (power)')

%% Data fitting
targFun = @(param,q)params(3)*(1-exp(-q*param(1)).^loAlph)./(1 + (q*param(2)).^hiAlph);


