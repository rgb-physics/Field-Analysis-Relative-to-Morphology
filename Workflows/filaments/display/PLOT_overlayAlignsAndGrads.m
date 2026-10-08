%% Plots output data from C_fil2ObjAlignmentQTensor3D.m
% inOnOutDir = '<redacted original absolute path>';
inOnOutDir = 'Session 83';
inOnOutName = 'Time%06i_Probabilities_smoothbin.tif';

% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 83';
filDataName = 'Filament Statistics %03i.mat';
selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};
% alignDataDir = '<redacted original absolute path>';
alignDataDir = 'Session 83';
alignDataName = 'Time%03i_alignData.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 83';
mdDir = filDataDir;
mdName = 'FilamentDetect_metadata.mat';

% sparseDir = '<redacted original absolute path>';
sparseDir = 'Session 83';
sparseName = 'Time%06i_raw647_Probabilities.tif';

selTimes = 40;
outInOn = [1 2 3];
binVals = [0 100 200 300];

%% Load metadata
load(fullfile(mdDir,mdName));

%% Iterate through time, calculate things at each frame

for tInd = 1:numel(selTimes)

    % Load current data
    currT = selTimes(tInd);
    load(fullfile(filDataDir,sprintf(filDataName,currT)));
    load(fullfile(alignDataDir,sprintf(alignDataName,currT)));
    currSparse = tiffreadVolume(fullfile(sparseDir,sprintf(sparseName,currT)));
    currSparse = double(imresize3(currSparse,imgSize));
    currSegs = tiffreadVolume(fullfile(inOnOutDir,sprintf(inOnOutName,currT)));
    currSegs = imresize3(currSegs,imgSize);

    % Bin segmentations, then map indices to match outInOn order
    [~,~,binInds] = histcounts(currSegs,binVals);
    if tInd == 1
        mapVec = [0 outInOn];
        xyzDims = [imgSize(2:-1:1) imgSize(3)];
        testStrel = strel('sphere',1);
    end
    binInds = mapVec(binInds+1);

end 

%% Filament reconstruction into matrices: 3D
% Display filament reconstructions
% Isolate filament CoM indices
close all
figure
orderVec = [4 5 6];
subsetInds = [1 10 100 1000 10000];

bwGradAtCens(:,2) = -bwGradAtCens(:,2);
allCoMs = [rp3D.Centroid];
allDirs = [rp3D.Directors]; allLens = [rp3D.Lengths];
temp = allDirs;
temp(1:3:end,:) = allDirs(2:3:end,:);
temp(2:3:end,:) = allDirs(1:3:end,:);
allDirs = temp;

% Construct matrix from backboness
filDimInfo = zeros(size(allDirs,1),9);
filDimInfo(:,orderVec) = allCoMs + allDirs.*allLens;
filDimInfo(:,orderVec+3)  = allCoMs - allDirs.*allLens;

gradInfo = filDimInfo;
gradInfo(:,orderVec) = allCoMs + bwGradAtCens.*allLens;
gradInfo(:,orderVec+3)  = allCoMs - bwGradAtCens.*allLens;

filTable = array2table(filDimInfo);
filMat = dat2Mat_Fils(filTable,imgSize,800);
filMat = permute(filMat,[2 1 3]);
filMat = imresize3(logical(filMat)*255,imgSize,'nearest');

gradTable = array2table(gradInfo);
gradMat = dat2Mat_Fils(gradTable,imgSize,800);
gradMat = permute(gradMat,[2 1 3]);
gradMat = imresize3(logical(gradMat)*255,imgSize,'nearest');

%%
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 83';
save3DTiff(uint8(filMat),fullfile(saveDir,sprintf('T%06i_filamentDirectors.tif',currT)));
save3DTiff(uint8(gradMat),fullfile(saveDir,sprintf('T%06i_gradientDirectors.tif',currT)));
% filInds = round(sub2ind(xyzDims,allCoMs(:,1),allCoMs(:,2),allCoMs(:,3)));      % matrix inds are (row,col) not (x,y)
% matCoMs = imdilate(consMatLnB(ones(imgSize),filInds),testStrel);
% orthosliceViewer(logical(filMat)*2 + logical(matCoMs)*5);
% test = currSparse + 400*imdilate(consMatLnB(ones(imgSize),filInds),testStrel);

%% STEPS FOR DISPLAY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameters to change
% Display slices (z) and time
selSlices = 37;
currT = 40;
% For gradients and quiver display
gridSpace = 10;
flipY = 1;          % 1 or -1
flipBGCensY = 1;

%% Load Background image:
% distDir = '<redacted original absolute path>';   % Distance transform; not a tif
distDir = 'Session 83';   % Distance transform; not a tif
distName = 'T%06i_distanceTransform.mat';
load(fullfile(distDir,sprintf(distName,currT)));

% bgImgDir = 'Session 83';     % Filaments
% bgImgName = 'Time%06i_raw647.tif';
% bgImgDir = '<redacted original absolute path>';    %Smoothed 3 channels
bgImgDir = 'Session 83';    %Smoothed 3 channels
bgImgName = 'Time%06i_Probabilities_smoothbin.tif';
currBG = tiffreadVolume(fullfile(bgImgDir,sprintf(bgImgName,currT)));
rsBG = imresize3(currBG,imgSize,'nearest');

% rsBG = imresize3(distMat,imgSize,'nearest');

%% Load filament components and select logic - From rp3D
rndCoMs = round([rp3D.Centroid]);
allLens = [rp3D.Lengths];
filAligns = [rp3D.Directors];
normAligns = getUnitVecs(filAligns);
normGrads = getUnitVecs(bwGradAtCens);

sliceLogic = ismember(rndCoMs(:,3),selSlices);
selLens = allLens(sliceLogic);
selCoMs = rndCoMs(sliceLogic,:);

%% Calculate backbones - From rp3D
selAligns = normAligns(sliceLogic,1:2);
backboneXs = selCoMs(:,1) + [selAligns(:,1), -selAligns(:,1)].*selLens/2;
backboneYs = selCoMs(:,2) + [selAligns(:,2), -selAligns(:,2)].*selLens/2;

selGrads = normGrads(sliceLogic,1:2);
bbGRX = selCoMs(:,1) + [selGrads(:,1), -selGrads(:,1)].*selLens/2;
bbGRY = selCoMs(:,2) + [selGrads(:,2), -selGrads(:,2)].*selLens/2*flipBGCensY;

%% Calculate gradients of distance transform - from distMat
% Take gradient of distance transform
[gradx,grady,gradz] = gradient(distMat);
% Rescale gradients to img dimensions
rsgx = imresize3(gradx,imgSize);
rsgy = imresize3(grady*flipY,imgSize);
rsgz = imresize3(gradz,imgSize);

% Get gradients on a grid
% Meshgrid: use (x,y,z) / (col, row, page)
[xMat,yMat,zMat] = meshgrid(1:gridSpace:imgSize(2),1:gridSpace:imgSize(1),selSlices);
gridInds = sub2ind(imgSize,yMat,xMat,zMat);     % Use (row, col, page) / (y,x,z)
gradsOnGrid = zeros([size(gridInds),3]);
gradsOnGrid(:,:,1) = mean(rsgx(gridInds),3);
gradsOnGrid(:,:,2) = mean(rsgy(gridInds),3);
gradsOnGrid(:,:,3) = mean(rsgz(gridInds),3);

%% Plot a background
figure
imagesc(mean(rsBG(:,:,selSlices),3));
hold on
% clim([349 390])
colormap('gray')
axis equal
%% Plot various overlay properties    
% scatter(selCoMs(:,1),selCoMs(:,2),'filled')
plot(backboneXs',backboneYs','magenta');
plot(bbGRX',bbGRY','blue');              
quiver(xMat,yMat,gradsOnGrid(:,:,1),gradsOnGrid(:,:,2),3,'red')
% quiver(xMat,yMat,gradsOnGrid(:,:,1),-gradsOnGrid(:,:,2),3,'red')

