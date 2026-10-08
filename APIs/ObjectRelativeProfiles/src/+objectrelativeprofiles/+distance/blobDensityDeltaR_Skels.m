%% Returns density profiles as a function of distance over time
% Requires processed images and a mask from which to construct distance
% transforms and bin data as a function of distance from a surface of
% interest. The mask used is expected to be skeletons calculated from
% segmented blob .tifs

% imgDirs = {'<redacted original absolute path>',...
imgDirs = {'Session 81, Exp 3',...
    % '<redacted original absolute path>'};
    'Session 81, Exp 3'};
imgNames = {'t%03i_illBleachCorr16bit_560.tif','t%03i_illBleachCorr16bit_488.tif'};
% maskDir = '<redacted original absolute path>';
maskDir = 'Session 81, Exp 3';
maskName = 'T%03i_IDedSkelMat.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 81, Exp 3';

selTimes = 2:2:60;

imgVoxSize = [.3667 .3667 1.5];     % um/pix in each dimension
rStep = .5;                          % step size for binning in um
rBnds = [-30 30];                   % in um
deltaRBins = min(rBnds):rStep:max(rBnds);
% Factors for generating a smoothed boundary from blob segmentations
layerMean = 0;  layerWidth = 1; gKern = 2;

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% 
% instantiate storage matrices
denseVoxInts = zeros(numel(selTimes),numel(deltaRBins)-1,numel(imgNames));
denseIntSTDs = denseVoxInts;
denseVoxCounts = zeros(numel(selTimes),numel(deltaRBins)-1);
sumInts = zeros(numel(selTimes),numel(imgNames));

for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    % Load mask
    currMask = logical(tiffreadVolume(fullfile(maskDir,sprintf(maskName,currT))));
    % Scale factors for later calculation
    if tInd == 1
        imgName = imgNames{1};  imgDir = imgDirs{1};
        currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        maskVoxSize = size(currImg)./size(currMask).*imgVoxSize;
        scaleFact = maskVoxSize/rStep;      % Factor to rescale mask before constructing shells
        distScale = rStep;                  % scale of pixels in distance transform matrix
    end

    % Rescale blobs prior to generating boundaries
    rsMask = imresize3(currMask,round(size(currMask).*scaleFact),'nearest');
    % Generate signed distance transform, then bin indices
    rsDist = signedBWDist(rsMask)*distScale;
    rsDist = rsDist - min(rsDist(:));
    % Rescale again to image size
    distMap = imresize3(rsDist,size(currImg),'nearest');

    % Bin dense protein intensities by delta R in distMat
    [denseVoxCounts(tInd,:),~,binInds] = histcounts(distMap,deltaRBins);

    % Define all indices that are within distances of deltaRBin away from
    % the blob boundaries
    validDomain = (distMap >= min(deltaRBins)) & (distMap <= max(deltaRBins));

    % Iterate over image directories that use the current mask
    tic
    for index = 1:numel(imgNames)
        imgName = imgNames{index};   imgDir = imgDirs{index};
        currImg = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));
        sumInts(tInd,index) = sum(currImg(validDomain),'all');
        % Iterate over layers a distance r from boundaries, bin intensities
        for rInd = 1:(numel(deltaRBins)-1)
            currVals = currImg(binInds == rInd);
            denseVoxInts(tInd,rInd,index) = sum(currVals,'all');
            denseIntSTDs(tInd,rInd,index) = std(currVals);
        end
    end
    toc

end
numVox = numel(currImg);
save(fullfile(saveDir,'metadata.mat'),'numVox','imgNames','imgDirs','selTimes',...
    'layerMean','layerWidth','gKern','rStep','imgVoxSize','distScale','deltaRBins');
save(fullfile(saveDir,'ints_vols_overDeltaR.mat'),'denseIntSTDs',...
    'denseVoxCounts','denseVoxInts','sumInts');

%% Plot distributions
concFracMT = 42/1670;
concFracK4 = 290/315;
subTimes = sort([2:6:14 16:2:32 36:4:40 ]);
% subTimes = sort([14:4:42 30]);
timeInds = find(ismember(selTimes,subTimes));
fracCut = 1/1000;
fracLogic = denseVoxCounts(timeInds,:) > numVox*fracCut;

timeColorArray = othercolor('BuPu3',max(subTimes));


figure
cutOffVoxInts = consMatLnB(denseVoxInts(timeInds,:,1),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(timeInds,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*concFracMT,'LineWidth',2);
colororder(timeColorArray(subTimes,:));

figure
cutOffVoxInts = consMatLnB(denseVoxInts(timeInds,:,2),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(timeInds,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts*concFracK4,'LineWidth',2);
colororder(timeColorArray(subTimes,:));

% rescale intensities by total sampled intensity
% figure
% 
% % yyaxis right
% scaleInts = denseVoxInts.*sumInts;
% cutOffVoxInts = consMatLnB(scaleInts,fracLogic);
% cutOffVoxCounts = consMatLnB(denseVoxCounts,fracLogic);
% plot(deltaRBins(1:(end-1))',cutOffVoxInts./cutOffVoxCounts,'LineWidth',2);

%% Plot max rho over time
deltaT = 0.5;
concFrac = 290/315;
chanInd = 2;
% concFrac = 42/1670;
% chanInd = 1;
frameZero = 34;
% subTimes = sort([14:4:42 28]);
subTimes = [18 22 26 28 30 32 36 42];
timeInds = find(ismember(selTimes,subTimes));
fracCut = 1/1000;
fracLogic = denseVoxCounts(:,:) > numVox*fracCut;


legendCell = {};
for index = 1:numel(subTimes)
    legendCell{index} = sprintf('%i minutes', (subTimes(index) - frameZero)*deltaT);
end


allRhos = denseVoxInts(:,:,chanInd)./denseVoxCounts(:,:);
cutOffRhos = consMatLnB(allRhos,fracLogic);

[maxRhos,maxInds] = max(cutOffRhos,[],chanInd);
figure
cutOffVoxInts = consMatLnB(denseVoxInts(:,:,chanInd),fracLogic);
cutOffVoxCounts = consMatLnB(denseVoxCounts(:,:),fracLogic);
plot(deltaRBins(1:(end-1))',cutOffVoxInts(timeInds,:)./cutOffVoxCounts(timeInds,:)*concFrac,'LineWidth',2);
colororder(timeColorArray(subTimes,:));
hold on
scatter(deltaRBins(maxInds(timeInds)),maxRhos(timeInds)*concFrac,...
    'MarkerFaceColor',[.8 .2 .7],'MarkerEdgeColor','black','Marker','^','SizeData',60)
box on
legend(legendCell);
xlabel('Distance to Perimeter (um)')
ylabel('[Kif4a] (nM)')
% ylabel('[MT] (\mum)')
set(gca,'FontSize',15)

figure
scatter((selTimes-frameZero)*deltaT,maxRhos*concFrac,...
    'MarkerFaceColor',[.8 .8 .8],'MarkerEdgeColor','black','SizeData',30)
hold on
scatter((selTimes(timeInds)-frameZero)*deltaT,maxRhos(timeInds)*concFrac,...
    'MarkerFaceColor',[.8 .2 .7],'MarkerEdgeColor','black','Marker','^','SizeData',60)
box on
xlabel('Time (min)')
ylabel('[MT] (\mum)')
set(gca,'FontSize',15)
