%% Takes in rp3D and displays filament xy directors on a 2D cut of a tif
% Used for displaying
% 2025-04-18 - Rémi Boros

expDir = {'Exp 1','Exp 2','Exp 3','Exp 4 - Rmin Redo','Exp 5'};
currExp = expDir{1};

% filDir = fullfile('<redacted original absolute path>',currExp,'6 Filament Data');
filDir = fullfile('Session 88',currExp,'6 Filament Data');
filName = 'Time%06i_threshFils.tif';
% ccDir = fullfile(filDir,'CC Objects');
% ccDir = fullfile('<redacted original absolute path>',currExp,'6 Filament Data\AlignmentData - Fils2Aligns_TIFS');
ccDir = fullfile('Session 88',currExp,'6 Filament Data\AlignmentData - Fils2Aligns_TIFS');
ccName = 'Filament Statistics %03i.mat';
% dispDir = fullfile('<redacted original absolute path>',currExp,'4 Tracked Blobs\In On Out Segmentation');
dispDir = fullfile('Session 88',currExp,'4 Tracked Blobs\In On Out Segmentation');
dispName = 'T%03i_CleanInOnOut.tif';
% dispDir2 = filDir;
% dispName2 = filName;
% dispDir2 = fullfile('<redacted original absolute path>',currExp,'3 Illumination Bleach Corrected 16bit');
dispDir2 = fullfile('Session 88',currExp,'3 Illumination Bleach Corrected 16bit');
dispName2 = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = fullfile('<redacted original absolute path>',currExp,'Figures\Overlay Filament Orientations');
saveDir = fullfile('Session 88',currExp,'Figures\Overlay Filament Orientations');
saveName = 'Time%06i_alignCompare.png';

% filDir = 'Session 88, Exp 4';
% filName = 'Time%06i_threshFils.tif';
% ccDir = fullfile(filDir,'CC Objects');
% ccName = 'Filament Statistics %03i.mat';
% dispDir = 'Session 88, Exp 4';
% dispName = 'Time%06i_3ChanSegs.tif';
% dispDir2 = 'Session 88, Exp 4';
% dispName2 = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = 'Session 88, Exp 4';
% saveName = 'Time%06i_alignCompare.png';

selTimes = 40;
zRange = 68:72;
cutAR = 1.5;    
cutLen = 2;     
cutVol = 4; 
voxelSize = [0.55 0.55 0.7];
colorBnds = [2000 10000];

if ~exist(saveDir,'dir')
    mkdir(saveDir)
end

%% Load data and prepare
%load data
% tInd = 1;
for tInd = 1:numel(selTimes)
currT = selTimes(tInd);
currFils = logical(tiffreadVolume(fullfile(filDir,sprintf(filName,currT))));
currCCs = load(fullfile(ccDir,sprintf(ccName,currT)),'rp3D').('rp3D');
currDisp = double(tiffreadVolume(fullfile(dispDir,sprintf(dispName,currT))));
currDisp2 = double(tiffreadVolume(fullfile(dispDir2,sprintf(dispName2,currT))));
if numel(currDisp) ~= numel(currFils)
    currDisp = imresize3(currDisp,size(currFils));
    currDisp2 = imresize3(currDisp2,size(currFils));
end
% currDisp = currDisp2;

% concatenate data
allCens = [currCCs.Centroid];
allDirecs2 = vertcat(currCCs.AniDirectors{:});
allDirecs = [currCCs.Directors];
allLens = [currCCs.Lengths(:)];
allARs = [currCCs.AspectRatios(:)];
allVols = [currCCs.Volume(:)];
allGrads = [currCCs.distGrads];
% allGrads = [currCCs.GradsAtCens];
allInds = [currCCs.CoMInds];

rescaleVec = min(voxelSize)./voxelSize;
scaleDirecs = allDirecs.*rescaleVec;
renormDirecs = scaleDirecs./sqrt(sum(scaleDirecs.^2,2));

zAligns = allDirecs(:,3);
scaleZAligns = renormDirecs(:,3);
zSlice = round(allCens(:,3));
% oris2D = atan2(allDirecs(:,1),allDirecs(:,2));

% Logic
lenLogic = allLens > cutLen;
volLogic = allVols > cutVol;
arLogic = allARs > cutAR;
zLogic = ismember(zSlice, zRange);
fullLogic = lenLogic & volLogic & arLogic & zLogic;
% Make backbones
allBBs = filBackBonesND(allCens',allLens',allDirecs');
allBBs2 = filBackBonesND(allCens',allLens',allDirecs2');

%% Intensity gradients
% For Qi - Calculate gradient of intensities, then sample at fil cens.
    % Get indices of filament centroids in display image. Needed if display
    % and filament matrices have different dimensions/scales
    filImgSize = size(currFils);    dispImgSize = size(currDisp2);
    scaleInds = rescaleCoords_Inds(allInds,filImgSize,dispImgSize); 
    [gradX,gradY,gradZ] = gradient(imgaussfilt3(currDisp2,4));
    % Sample gradients at filament centroids
    if tInd == 1
        intGrads = zeros([size(gradX) 3]);
    end
    intGrads(:,:,:,1) = gradX;  intGrads(:,:,:,2) = gradY;  intGrads(:,:,:,3) = gradZ;
    gradAtCens = zeros(size(allDirecs));
    for index = 1:3
        currGrad = intGrads(:,:,:,index);
        gradAtCens(:,index) = currGrad(scaleInds);
    end
    gradAtCens(sum(gradAtCens,2)==0,:) = 1;
    normGradCens = gradAtCens./sqrt(sum(gradAtCens.^2,2));

    %% Make field backbones
% rescBBs = filBackBonesND(allCens',allLens',renormDirecs');
gradBBs = filBackBonesND(allCens',allLens',allGrads');
intBBs = filBackBonesND(allCens',allLens',normGradCens');

selLogic = fullLogic;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compare intensities to distance gradients
% testDir = 'Session 88, Exp 1';
% testFile = 'testGrads.mat';
% temp = load(fullfile(testDir,testFile)).temp;

% temp = zeros([size(currDisp2,[1 2]),3]);
% temp(:,:,1) = currDisp2(:,:,round(mean(zRange)));
% temp(:,:,3) = sum(currFils(:,:,zRange),3);
% imagesc(squeeze(temp(:,:,round(mean(zRange)),:)))
imagesc(currDisp2(:,:,round(mean(zRange))));
% imagesc(sum(currFils(:,:,zRange),3));

cmap = colormap('gray');
colormap(flipud(cmap));
clim(colorBnds);
hold on
% plot(outXs,outYs,'red');
% scatter(allCens(selLogic,1),allCens(selLogic,2),10,'red','filled');
% plot(allBBs2(1).BBs(:,selLogic),allBBs2(2).BBs(:,selLogic),'red','LineWidth',3);
plot(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),'black','LineWidth',1);
% plot(intBBs(1).BBs(:,selLogic),intBBs(2).BBs(:,selLogic),'green','LineWidth',2);
% plot(gradBBs(1).BBs(:,selLogic),gradBBs(2).BBs(:,selLogic),'blue','LineWidth',1);
% plot(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),'red','LineWidth',2);
% plot(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),'black','LineWidth',1);
% axis equal
% ylim([280 720])
% xlim([150 590])
axis equal
hold off
exportgraphics(gcf,fullfile(saveDir,sprintf(saveName,currT)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% Plot orientations over display frame
% selLogic = fullLogic;
% % Plot
% % figure
% subplot(1,2,1)
% imagesc(currDisp(:,:,round(mean(zRange))));
% cmap = colormap('gray');
% colormap(flipud(cmap));
% % clim();
% hold on
% % plot(outXs,outYs,'red');
% % scatter(allCens(selLogic,1),allCens(selLogic,2),10,'red','filled');
% plot(gradBBs(1).BBs(:,selLogic),gradBBs(2).BBs(:,selLogic),'blue','LineWidth',2);
% plot(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),'red','LineWidth',2);
% plot(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),'black','LineWidth',1);
% % axis equal
% hold off
% subplot(1,2,2)
% imagesc(currDisp2(:,:,round(mean(zRange))));
% cmap = colormap('gray');
% colormap(flipud(cmap));
% clim(colorBnds);
% hold on
% % plot(outXs,outYs,'red');
% % scatter(allCens(selLogic,1),allCens(selLogic,2),10,'red','filled');
% plot(intBBs(1).BBs(:,selLogic),intBBs(2).BBs(:,selLogic),'green','LineWidth',2);
% plot(gradBBs(1).BBs(:,selLogic),gradBBs(2).BBs(:,selLogic),'blue','LineWidth',1);
% % plot(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),'red','LineWidth',2);
% % plot(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),'black','LineWidth',1);
% % axis equal
% hold off
% exportgraphics(gcf,fullfile(saveDir,sprintf(saveName,currT)));

end

