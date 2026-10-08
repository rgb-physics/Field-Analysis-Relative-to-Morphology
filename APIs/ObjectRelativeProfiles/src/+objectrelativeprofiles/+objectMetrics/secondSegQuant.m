% Looks at drops that have been segmented twice, once to detect drop
% perimeters, once to distinguish drop interiors from surfaces. Expects 3
% two channels in secondary segmentation (at least), one for drop
% interiors, one for drop exteriors

% imgDir = '<redacted original absolute path>';
imgDir = 'Session 56, Exp 1';
% pass1Dir = '<redacted original absolute path>';
pass1Dir = 'Session 56, Exp 1';
% pass2Dir = '<redacted original absolute path>';
pass2Dir = 'Session 56, Exp 1';
% ogDir = '<redacted original absolute path>';
ogDir = 'Session 56, Exp 1';

imgName = 't%03i_illBleachCorr16bit.tif';
pass1Name = 'PatchedSeg_PassOne_t%03i_16bitSubSamp.tif';
pass2Name = 'PassOne_t%03i_16bitSubSamp_Probabilities.h5';
ogName = 't%03i_illBleachCorr16bit.tif';     

selectTimes = 25:2:100;
p1Chan = 2;
p2ChanIn = 3;
p2ChanOut = 2;
h5Str = '/exported_data';
 
cutOffProb = .6;

%% Iterate through time and store relevant prob. and int. data
dataStore = struct();
strelObj = strel('sphere',2);
figure
for tInd = 1:numel(selectTimes)

    tic
    currT = selectTimes(tInd);  dataStore(tInd).t = currT;
    %Load img data
    currImgDir = fullfile(imgDir,sprintf(imgName,currT));
    currImg = double(tiffreadVolume(currImgDir));
    dataStore(tInd).imgName = currImgDir;
    % Load segmentations
    pass1 = logical(tiffreadVolume(fullfile(pass1Dir,sprintf(pass1Name,currT))));      
    pass2 = loadH5(fullfile(pass2Dir,sprintf(pass2Name,currT)),h5Str,[p2ChanIn p2ChanOut]);
    % Define interior vs exterior channel
    inSeg = pass2(:,:,:,1); outSeg = pass2(:,:,:,2);
    inCut = imbinarize(inSeg,cutOffProb); outCut = imbinarize(outSeg,cutOffProb);
    
    % compare scaled volume fracs - in vs. out refer to interior and shell
    % Total probabilities "inside" and "outside"
    dataStore(tInd).inTots = sum(inSeg,'all');
    dataStore(tInd).outTots = sum(outSeg,'all');
    
    % Total intensities inside and outside, scaled by probs
    dataStore(tInd).scInInts = sum(currImg.*inSeg,'all');
    dataStore(tInd).scOutInts = sum(currImg.*outSeg,'all');
    dataStore(tInd).consInInts = sum(currImg(inCut));
    dataStore(tInd).consOutInts = sum(currImg(outCut));

    % Total intensity in current image
    dataStore(tInd).totInts = sum(currImg, 'all');   

    % Intensities of background
    scpass1 = imresize3(pass1, size(currImg));
    bgImg = consMatLnB(currImg, scpass1);
    dataStore(tInd).bgInts = sum(bgImg(:));

    % Define boundary between drop insides and shells
    % First, take overlap of in/shell prob. fields below 40% certainty
    % AND with overlap of dilated in/shell prob. fields above 60% certainty
    % AND with dilated first segmentation of drops
    lowCertPixels = ~inCut & ~outCut;
    highCertOverlap = (imdilate(inCut,strelObj) & imdilate(outCut,strelObj));
    pass1OverGuess = imerode(scpass1,strelObj);
    inOutBound = lowCertPixels & highCertOverlap & pass1OverGuess;
    dataStore(tInd).ioBounds = find(inOutBound);
    dataStore(tInd).inCut = find(inCut);

    % Generate distance transform matrix scaled by interior vs shell
    distMat = bwdist(inOutBound);
    distMat(inCut) = -distMat(inCut);

    histogram(distMat(:),-30:90)
    hold on
    pause(.1)
    toc
end
%% 
% Calculate fraction of intensities inside vs. total drop
inIntFrac = inInts./(inInts + outInts);
% Calculate fraction of probabilities inside vs. total drop
probFracs = inTots./(inTots + outTots);

%% Snigle frame tests
currT = 70;
imbthresh = .6;
%Load data
currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
pass1 = loadH5(fullfile(pass1Dir,sprintf(pass1Name,currT)),h5Str,p1Chan);
pass2 = loadH5(fullfile(pass2Dir,sprintf(pass2Name,currT)),h5Str,[p2ChanIn p2ChanOut]);    
% Define interior vs exterior channel
if p2ChanIn < p2ChanOut
    inSeg = pass2(:,:,:,1); outSeg = pass2(:,:,:,2);
else
    inSeg = pass2(:,:,:,2); outSeg = pass2(:,:,:,1);
end
% Construct matrices of in and out
inThresh = consMatLnB(currImg, imbinarize(inSeg,imbthresh));
outThresh = consMatLnB(currImg, imbinarize(outSeg,imbthresh));

% Approximate background intensity

ogImg = double(tiffreadVolume(fullfile(ogDir,sprintf(ogName,currT))));       

newDims = max(size(pass1),size(ogImg));
scpass1 = imresize3(pass1, max(size(pass1),size(ogImg)));
bgImg = consMatLnB(ogImg, ~imbinarize(scpass1,.7));

%% 
% look at intensity distributions
figure
histogram(inThresh(:),1:100:40000)
hold on
histogram(outThresh(:),1:100:40000)
legend('Intensities of interior','Intensities of shell')

figure
orthosliceViewer(inThresh + outThresh);

%% Plot intensities
figure
plot(inInts);
hold on
plot(outInts);
plot(bgInts);
legend('Interiors', 'shells', 'backgounds')
set(gca,'FontSize',15)

%% Plot mean intensity per value of the distance transform
binVals = -40:2:100;
% saveImgDir = '<redacted original absolute path>';
saveImgDir = 'Session 56, Exp 1';
saveImgName = 'IntProfile_t%03i.png';

for tInd = 1:size(dataStore,2)
    currT = dataStore(tInd).t;
    currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
    inOutBound = consMatLnB(ones(size(currImg)), dataStore(tInd).ioBounds);
    distMat = bwdist(inOutBound);
    distMat([dataStore(tInd).inCut]) = -distMat([dataStore(tInd).inCut]);
    
    [a,b,c] = histcounts(distMat, binVals);
    c = binVals(c + 1);
    
    meanInts = zeros(numel(binVals),1);
    medianInts = meanInts; stdInts = meanInts;
    for index = 1:numel(binVals)
    
        meanInts(index) = mean(currImg(c == binVals(index)));
        medianInts(index) = median(currImg(c == binVals(index)));
        stdInts(index) = std(currImg(c == binVals(index)));
    
    end
    
    figure( 'Position', [30 100 900 600])
    subplot(1,3,1)
    plot(b,meanInts);
    hold on
    plot(b,medianInts);
    title(sprintf('Intensity Profile at frame %i',currT));
    xlabel('Distance to shell interface (pixe   ls)')
    ylabel('Intensity')
    legend('Mean Int','Median Int')
    xlim([min(binVals) max(binVals)])
    ylim([7000 24000])
    subplot(1,3,2)
    plot(b(2:end),a)
    xlim([min(binVals) max(binVals)])
    ylim([0 4*10^6])
    xlabel('Distance to shell interface (pixels)')
    ylabel('Counts')
    title('Number of voxels at this distance')
    subplot(1,3,3)
    imagesc(currImg(:,:,40));
    colormap('gray')   
    clim([0 30000])
    exportgraphics(figure(5),fullfile(saveImgDir,sprintf(saveImgName,currT)));
    close(figure(5))
end