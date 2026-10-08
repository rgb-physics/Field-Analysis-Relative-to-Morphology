%% For specific data set, get delta r intensity and SHG data
% 2024-10-02 Rémi Boros

% dataDir = '<redacted original absolute path>';
dataDir = '';
segName = 'annulusmask.tif';
denseName = 'T320000.tif';
shgName = 'T320001.tif';

rBins = -30:2:50;
pixScale = 1;
strelRad = 15;

%% Load
segData = double(tiffreadVolume(fullfile(dataDir,segName)));
denseData = double(tiffreadVolume(fullfile(dataDir,denseName)));
shgData = double(tiffreadVolume(fullfile(dataDir,shgName)));

patchedSeg = imfill(segData,'holes');
smoothedSeg = imdilate(imerode(patchedSeg,strel('disk',strelRad)),strel('disk',strelRad));

%% Get boundaries and distance level sets
distMat = double(distTransFromBoundary(smoothedSeg, ~smoothedSeg, false(size(smoothedSeg)), 1));

[ringVols,~,binInds] = histcounts(distMat,rBins);
boundedDenseNorm = sum(denseData((distMat >= min(rBins)) & (distMat <= max(rBins))),'all');
boundedSHGData = sum(shgData((distMat >= min(rBins)) & (distMat <= max(rBins))),'all');

%% Query field values in rings
storeVec = zeros(numel(rBins)-1,2);
for rInd = 1:(numel(rBins)-1)
    storeVec(rInd,1) = sum(denseData(binInds == rInd),'all');
    storeVec(rInd,2) = sum(shgData(binInds == rInd),'all');
end

%% Plot distributions
color1 = [1 0 0];
color2 = [0 .7 .7];
meanBinVals = (rBins(1:(end-1)) + rBins(2:end))/2;
figure
yyaxis left
plot(meanBinVals*pixScale,storeVec(:,1)./ringVols(:),'Color',color1,'LineWidth',2)
hold on
ax = gca;
yyaxis right
plot(meanBinVals*pixScale,storeVec(:,2)./ringVols(:),'Color',color2,'LineWidth',2)
legend('MTs','SHG')
ax.YAxis(1).Color = color1;
ax.YAxis(2).Color = color2;

xlabel('\Deltar (pixels)')
set(gca,'FontSize',15)
xlim([min(rBins) max(rBins)])
box on

%% Image overlay of level sets on intensity data
figure
mat3D = zeros([size(binInds) 3]);
mat3D(:,:,1) = denseData/200;
mat3D(:,:,3) = patchedSeg*100;
imagesc(mat3D);

