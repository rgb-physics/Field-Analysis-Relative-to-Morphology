%Plot volumes, intensities, etc. from segmentations, then subsample
%intensity data and get average quantities from tifs using segmentations as
%masks.
% Rémi Boros
% Edit dates: 2024-05-07 
%% Directory info
% tifDirs = {'<redacted original absolute path>',...
tifDirs = {'Session 81, Exp 2',...
    % '<redacted original absolute path>'};
    'Session 81, Exp 2'};
tifNames = {'t%03i_illBleachCorr16bit_488.tif','t%03i_illBleachCorr16bit_560.tif'};
% blobDir = '<redacted original absolute path>';
blobDir = 'Session 81, Exp 2';
blobName = 'BlobMat_t%03i_illBleachCorr16bit.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 2';

% For multiple sampled tifs (intensities)
bgIntsTag = 'bgInts%i';
blobInts1Tag = 'blob1Ints%i';
blobInts2Tag = 'blob2Ints%i';
meanIntsTag = 'meanInts%i';
medZTag = 'medZInts%i';
tifTag = 'fullDir%i';
pixSizeTag = 'intPixSize%i';

% Parameters
selectTimes = 1:125;
objMag = 20;            % Objective mag in x
camPixSize = 11;        % camera pixel size in um/pix
camBinning = 2;         % Binning of camera pixels
segRescale = [1 1 1];   % Segmentation should have square voxels before volume/area calculations
tifZSize = 1.5;         % Distance between z slices, um
timeStep = 30;          % Time between frames in seconds
tifVoxelDims = [camPixSize*camBinning/objMag camPixSize*camBinning/objMag tifZSize];

% Channels to distinguish
chansBin = [1 Inf];
chans1 = chansBin;
chans2 = [];
overlapChans = chans1(ismember(chans1,chans2));     % Identify channels that overlap

saveName = sprintf('t%03i-%03i_globalIntVolStats_Binary.mat',min(selectTimes),max(selectTimes));

%% Reset storage struct
timeStore = struct();

%% Calculate average quantities
tic
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    % Generate binarized matrix of blob indices, then threshold + rescale (square voxels)
    currBlobs = double(tiffreadVolume(fullfile(blobDir, sprintf(blobName,currT))));
    squareVoxBlobs = imresize3(currBlobs,segRescale.*size(currBlobs));
    [~,~,binnedBlobs] = histcounts(squareVoxBlobs,chansBin);
    binaryBlobs1 = ismember(binnedBlobs,chans1);
    binaryBlobs2 = ismember(binnedBlobs,chans2);
    binaryOverlap = ismember(binnedBlobs, overlapChans);
    blobsSeg = binaryBlobs2 | binaryBlobs1;
    blobsMatSize = size(blobsSeg);
    % Iterate over intensity data directories
    for dirInd = 1:numel(tifNames)
        % Load intensity data
        dataDir = tifDirs{dirInd}; dataName = sprintf(tifNames{dirInd},currT);
        fullDir = fullfile(dataDir,dataName);
        currTif = double(tiffreadVolume(fullDir));
        tifSize = size(currTif);
        % Match segmentation and intensity tif sizes
        rescaledBlobs1 = imresize3(binaryBlobs1,tifSize);
        rescaledBlobs2 = imresize3(binaryBlobs2,tifSize);
        rescaledOverlap = imresize3(binaryOverlap,tifSize);
        % Correct for overlap in non-overlapping channels
        rescaledBlobs2 = (rescaledBlobs2 & ~rescaledBlobs1) | rescaledOverlap;
        rescaledBlobsSeg = (rescaledBlobs2 | rescaledBlobs1) ;
        % Subsample quantities
        blobData1 = consMatLnB(currTif, rescaledBlobs1);
        blobData2 = consMatLnB(currTif, rescaledBlobs2);
        bgData = consMatLnB(currTif, ~rescaledBlobsSeg);
        % Store
        timeStore(tInd).(sprintf(meanIntsTag,dirInd)) = mean(currTif,'all');
        timeStore(tInd).(sprintf(medZTag,dirInd)) = squeeze(median(currTif, [1,2]));
        timeStore(tInd).(sprintf(bgIntsTag,dirInd)) = sum(bgData(:));
        timeStore(tInd).(sprintf(blobInts1Tag,dirInd)) = sum(blobData1(:));
        timeStore(tInd).(sprintf(blobInts2Tag,dirInd)) = sum(blobData2(:));
        timeStore(tInd).(sprintf(tifTag,dirInd)) = fullDir;
        timeStore(tInd).(sprintf(pixSizeTag,dirInd)) = tifVoxelDims;        
    end
    % Store blob/segmentation info
    timeStore(tInd).blobTotVols = sum(blobsSeg,'all');
    timeStore(tInd).blob1Vols = sum(binaryBlobs1,'all');
    timeStore(tInd).blob2Vols = sum(binaryBlobs2,'all');
    surfaceLogic = (bwdist(~blobsSeg)<=1) & (bwdist(~blobsSeg)>0);     
    timeStore(tInd).blobAreas = sum(surfaceLogic(:));
    timeStore(tInd).blobPixRescale = segRescale;
    timeStore(tInd).blobPixSize = tifSize./blobsMatSize.*tifVoxelDims;  %In um
end

% Save info
save(fullfile(saveDir, saveName), 'timeStore');
toc
%% Global bleach rate 
currField = 'meanInts2';

figure
subplot(1,2,1)
plot(selectTimes*timeStep, vertcat(timeStore(:).(currField)));
xlabel('Time (s)')
ylabel('Mean Global Int.')
set(gca,'FontSize',15)
title('Mean global intensity over time')

subplot(1,2,2)
plot(selectTimes(2:end)*timeStep, diff(vertcat(timeStore(:).(currField)))./timeStep)
xlabel('Time (s)')
ylabel('\Delta Global Int. Change')
set(gca,'FontSize',15)
title('Rate of global intensity change over time')

figure
loglog(selectTimes*timeStep, vertcat(timeStore(:).(currField)))

%% Load things
bgIntsKif = vertcat(timeStore.('bgInts1'));
bgIntsMTs = vertcat(timeStore.('bgInts2'));
blobIntsKifOn = vertcat(timeStore.('blobInts1'));
blobIntsMTsOn = vertcat(timeStore.('blobInts2'));
blobIntsKifIn = vertcat(timeStore.('blobInts1'));
blobIntsMTsIn = vertcat(timeStore.('blobInts2'));
blobVols = vertcat(timeStore.blobTotVols);
blobOnVols = vertcat(timeStore.blob1Vols);
blobInVols = vertcat(timeStore.blob2Vols);
blobAreas = vertcat(timeStore.blobAreas);
times = selectTimes*timeStep;

totIntsMTs = (blobIntsMTsOn + blobIntsMTsIn + bgIntsMTs);
totIntsKif = (blobIntsKifOn+blobIntsKifIn + bgIntsKif);

% objIntPerVoxOn = blobIntsKifOn./blobVols;
% objIntPerVoxIn = blobIntsMTs./blobVols;
% bgIntPerVox = bgIntsMTs./(numel(currBlobs) - blobVols);

%% Intensity fractions chans1/chans2 total
figure
hold on
scatter(selectTimes*timeStep, blobIntsMTsOn./(blobIntsMTsOn + blobIntsMTsIn), 'r','filled')
scatter(selectTimes*timeStep, blobIntsMTsIn./(blobIntsMTsOn+blobIntsMTsIn), 'b','filled')
scatter(selectTimes*timeStep, blobIntsKifOn./(blobIntsKifOn+blobIntsKifIn), 16, [.8 .3 0],'d')
scatter(selectTimes*timeStep, blobIntsKifIn./(blobIntsKifOn+blobIntsKifIn), 16, [0 .3 .8],'d')
set(gca,'FontSize',15)
xlabel('Time (s)')
ylabel('Normalized ')

%% Intensity fractions chans1 and chans2 as fractions of whole
kifColor = [55 132 255]/255;
mtColor = [45 51 62]/255*2;
dotSize = 42;
MTIntFrac = (blobIntsMTsOn + blobIntsMTsIn)./totIntsMTs;
KifIntFrac = (blobIntsKifOn + blobIntsKifIn)./totIntsMTs;
figure
hold on
plot(selectTimes*timeStep, MTIntFrac,'Color', min(1,mtColor*1.3),'LineWidth',2)
plot(selectTimes*timeStep, KifIntFrac,'Color',min(1,kifColor*1.3),'LineWidth',2)
% scatter(selectTimes*timeStep, blobIntsMTsOn./totIntsMTs, dotSize*1.5,mtColor,'filled')
% scatter(selectTimes*timeStep, blobIntsMTsIn./totIntsMTs, dotSize*1.5,(mtColor*.7) + .1,'filled')
% scatter(selectTimes*timeStep, blobIntsKifOn./totIntsKif, dotSize, kifColor,'d')
% scatter(selectTimes*timeStep, blobIntsKifIn./totIntsKif, dotSize, (kifColor*.7) + .1,'d')
xlim([0 7000])
xlabel('Time (s)')
set(gca,'FontSize',15)

legend('Total Vesicle MT Mass Frac','Total Vesicle Kif4 Mass Frac','MT Mass Frac ON','MT Mass Frac IN','Kif4 Mass Frac ON','Kif4 Mass Frac IN')

% Plot total 
% figure
% hold on

%% Intensity fractions
figure
semilogy(selectTimes*timeStep,blobIntsMTsOn./blobIntsMTsIn)
hold on
semilogy(selectTimes*timeStep,blobIntsKifOn./blobIntsKifIn)

%% Volumes
figure
plot(selectTimes*timeStep,blobVols)
hold on
plot(selectTimes*timeStep,blobOnVols)
plot(selectTimes*timeStep,blobInVols)
legend('Full Blob Volumes', 'Blob Volumes On', 'Blob Volumes In')
set(gca,'FontSize',15)
xlabel('Time (s)')

%% Scaled densities in regions
figure
subplot(1,3,1)
scatter(selectTimes*timeStep,blobIntsMTsIn./blobInVols,'filled');
hold on
scatter(selectTimes*timeStep,blobIntsMTsOn./blobOnVols,'filled');
title('Densities')
xlabel('Time (s)')
set(gca,'FontSize',15)
xlim([0 7000])
subplot(1,3,2)
plot(selectTimes*timeStep,blobInVols);
hold on
plot(selectTimes*timeStep,blobOnVols);
title('Volumes')
xlabel('Time (s)')
set(gca,'FontSize',15)
xlim([0 7000])
subplot(1,3,3)
plot(selectTimes*timeStep,blobIntsMTsIn);
hold on
plot(selectTimes*timeStep,blobIntsMTsOn);
title('Intensities')
xlabel('Time (s)')
legend('In Vesicles','On Vesicles')
set(gca,'FontSize',15)
xlim([0 7000])

%% Intensity fractions over time in diff regions
figure
hold on
scatter(selectTimes*timeStep, blobIntsMTs./(bgIntsMTs+blobIntsMTs), 'r','filled')
scatter(selectTimes*timeStep, bgIntsMTs./(bgIntsMTs+blobIntsMTs), 'b','filled')
scatter(selectTimes*timeStep, blobIntsKif./(blobIntsKif+bgIntsKif), 16, [.8 .3 0],'d')
scatter(selectTimes*timeStep, bgIntsKif./(blobIntsKif+bgIntsKif), 16, [0 .3 .8],'d')
legend('Object MT Ints (sum)', 'Background MT Ints (sum)','Object Kif4 Ints (sum)', 'Background Kif4 Ints (sum)')
xlabel('Time (s)')
ylabel('Intensity fraction (normalized)')
set(gca,'FontSize',15)
title('Global intensity fraction per time')
%% volume fraction
figure
hold on
scatter(times, blobVols./vertcat(timeStore(:).segMatVol), 'filled')
xlabel('Time (s)')
ylabel('Total object vol fraction')
set(gca,'FontSize',15)
title('Global volume fraction per time')
