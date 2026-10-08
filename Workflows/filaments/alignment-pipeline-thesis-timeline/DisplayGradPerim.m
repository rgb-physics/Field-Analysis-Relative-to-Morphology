%% Load image of segmented perimeter, load fils, add flow field
% iOODir = 'Session 88, Exp 4';
% iOOName = 'Time%06i_3ChanSegs.tif';
% perimDir = 'Session 88, Exp 4';
% perimName = 'vesicleBounds_T%03i.tif';
% filDir = 'Session 88, Exp 4';
% filName = 'Filament Statistics %03i.mat';

% iOODir = '<redacted original absolute path>';
iOODir = 'Session 88, Exp 4';
iOOName = 'Time%06i_3ChanSegs.tif';
% perimDir = '<redacted original absolute path>';
perimDir = 'Session 88, Exp 4';
perimName = 'vesicleBounds_T%03i.tif';
% filDir = '<redacted original absolute path>';
filDir = 'Session 88, Exp 4';
filName = 'Filament Statistics %03i.mat';

selTimes = 40;
denseVoxSize = [0.7 0.7 0.7];   % voxel dimensions of dense tifs when loaded below

outInOn = [1 3 2];
denseBnds = [0 255];

ogDims = [775 775];
ogDims3D = [ogDims 95];

selZ = 70;
zRange = 38:50;
cutAR = 1.5;
cutVol = 4;
xBnds = [100 500];
yBnds = [100 500];
% xBnds = [454 644];
% yBnds = [55 285];
filToDisp = 0.52;   % ratio

xRange = round(min(xBnds):max(xBnds));
yRange = round(min(yBnds):max(yBnds));

filColors = [[120, 0, 140]; [255, 200, 200]; [40, 250 170]]/255;
unqRs = [85 170 255];

%%
tInd = 1;
currT = selTimes(tInd);
currIOO = tiffreadVolume(fullfile(iOODir,sprintf(iOOName,currT)));
perim = tiffreadVolume(fullfile(perimDir,sprintf(perimName,currT)));
currFils = load(fullfile(filDir, sprintf(filName,currT)),'rp3D').('rp3D');
rTable = load(fullfile(filDir, 'Concatenated_rsAtCens.mat'),'superTable').('superTable');

% Prepare dense
% Rescale dense, if not cubic
if prod(denseVoxSize/max(denseVoxSize)) ~= 1
    currIOO = imresize3(currIOO, size(currIOO).*denseVoxSize/min(denseVoxSize),'nearest');
end
scperim = imresize3(perim,size(currIOO));
tempVoxSize = repmat(min(denseVoxSize),1,3);

% Generate a vector to map values in dense tifs to out/in/on domains
denseVals = outInOn/max(max(outInOn)) .* (abs(diff(denseBnds)));

% Get distance transform ons, outs, in
[distMat,~,~,~,~,keepMat] = distTransFromBoundary(...
    currIOO == denseVals(3), currIOO == denseVals(1), currIOO == denseVals(2), 1);

% Get surface gradients, surface normals, sample at filament CoMs
    % Take the gradient of the distance transform
    [gradx,grady,gradz] = gradient(imgaussfilt3(distMat,2));
    allGrads = zeros([size(gradx) 3]);
    allGrads(:,:,:,1) = gradx; allGrads(:,:,:,2) = grady; allGrads(:,:,:,3) = gradz;

% Get filament centers
    allCens = [currFils.Centroid];
    allARs = [currFils.AspectRatios];
    allVols = [currFils.Volume];
    % Generate logic
    arLogic = allARs > cutAR;
    zLogic = ismember(round(allCens(:,3)),zRange);
    xLogic = ismember(round(allCens(:,1)),xRange);
    yLogic = ismember(round(allCens(:,2)),yRange);
    volLogic = allVols > cutVol;
% r vals from superTable
    rVals = [rTable.rAtCens(([rTable.Frame] == currT))];

% Get surface gradients, surface normals, sample at filament CoMs
    % Take the gradient of the distance transform
    [gradx,grady,gradz] = gradient(imgaussfilt3(-(distMat),2));
    allGradsN = zeros([size(gradx) 3]);
    allGradsN(:,:,:,1) = gradx; allGradsN(:,:,:,2) = grady; allGradsN(:,:,:,3) = gradz;

%% Select slice and display
% Display slice
perimSlice = scperim(:,:,selZ) == 0;
gradsSlice = squeeze(allGrads(:,:,selZ,:));
gradsSliceN = squeeze(allGradsN(:,:,selZ,:));
[xMat, yMat] = meshgrid(1:size(perimSlice,2), 1:size(perimSlice,1));
% Streamline starts
% allInds = find(perimSlice);   randSet = randsample(numel(allInds),round(numel(allInds)/4));
% [startY,startX] = ind2sub(size(perimSlice),allInds(randSet));

selLogic = arLogic & volLogic & zLogic & xLogic & yLogic;
selCoords = allCens(selLogic,1:2);
scCoords = rescaleCoords(selCoords,ogDims,size(xMat));
startX = scCoords(:,1); startY = scCoords(:,2);

figure
% Display background
imagesc(scperim(:,:,selZ));
% imagesc(gradsSlice)
% imagesc(distMat(:,:,selZ) + (~(perim(:,:,selZ)==0))*max(distMat(:)))
cmap = flipud(colormap('gray'));
cmap(1:60,:) = repmat([0 0 0],60,1);
colormap((cmap));
clim([0 80])
hold on
% Display flowfields
verts1 = stream2(xMat,yMat,gradsSlice(:,:,1),gradsSlice(:,:,2),startX',startY');
verts2 = stream2(xMat,yMat,gradsSliceN(:,:,1),gradsSliceN(:,:,2),startX',startY');
lines1 = streamline(verts1);
lines2 = streamline(verts2);
% Display color coded filament centers
scatter(startX,startY,30,'black','filled')
selRs = rVals(selLogic);
for index = 1:numel(unqRs)
    currLogic = (selRs == unqRs(index));
    scatter(startX(currLogic),startY(currLogic),15,filColors(index,:),'filled');
end
% Recolor flow fields
[~,~,rIDs] = histcounts(selRs, [-inf unqRs inf]);
rIDs = rIDs - 1;
for index = 1:numel(lines1)
    lines1(index).Color = filColors(rIDs(index),:);
    lines1(index).LineWidth = 1;
    lines2(index).Color = filColors(rIDs(index),:);
    lines2(index).LineWidth = 1;
end
% scatter(startX,startY,5,'black','filled')
axis equal
xlim(xBnds*filToDisp)
ylim(yBnds*filToDisp)
set(gca, 'XTick',[])
set(gca, 'YTick',[])

%% Select slice and display quiver of gradient field

% Display slice
qSpc = 5;
perimSlice = scperim(:,:,selZ) == 0;
gradsSlice = squeeze(allGrads(1:qSpc:end,1:qSpc:end,selZ,:));
gradsSliceN = squeeze(allGradsN(1:qSpc:end,1:qSpc:end,selZ,:));
[xMat, yMat] = meshgrid(1:qSpc:size(perimSlice,2), 1:qSpc:size(perimSlice,1));
% Streamline starts
% allInds = find(perimSlice);   randSet = randsample(numel(allInds),round(numel(allInds)/4));
% [startY,startX] = ind2sub(size(perimSlice),allInds(randSet));

selLogic = arLogic & volLogic & zLogic & xLogic & yLogic;
selCoords = allCens(selLogic,1:2);
scCoords = rescaleCoords(selCoords,ogDims,size(perimSlice));
startX = scCoords(:,1); startY = scCoords(:,2);

figure
% Display background
imagesc(scperim(:,:,selZ));
% imagesc(gradsSlice)
% imagesc(distMat(:,:,selZ) + (~(perim(:,:,selZ)==0))*max(distMat(:)))
cmap = flipud(colormap('gray'));
cmap(1:60,:) = repmat([0 0 0],60,1);
colormap((cmap));
clim([0 80])
hold on

% Display color coded filament centers
scatter(startX,startY,50,'black','filled')
selRs = rVals(selLogic);
for index = 1:numel(unqRs)
    currLogic = (selRs == unqRs(index));
    scatter(startX(currLogic),startY(currLogic),30,filColors(index,:),'filled');
end
% Display quiver fields
quiver(xMat,yMat,gradsSlice(:,:,1),gradsSlice(:,:,2),0.7,'black');

% scatter(startX,startY,5,'black','filled')
axis equal
xlim(xBnds*filToDisp)
ylim(yBnds*filToDisp)
set(gca, 'XTick',[])
set(gca, 'YTick',[])

%% Isolate to single object - also rmv fils
% Select a few filaments
% thFilDir = '<redacted original absolute path>';
thFilDir = 'Session 88, Exp 4';
thFilName = 'Time%06i_threshFils.tif';
% Unlike above, do NOT reduce size of image
selectCens = [280 267 281 300 281; 92 104 114 115 133]';
colorlims = [20 70];
filVals = 24;
perimClr = [193 0 114]/255;
filClr = [0 200 255]/255;

% xBnds = [454 644];
% yBnds = [55 285];
xBnds = [480 620];
yBnds = [160 260];
% xBnds = [286 325]/filToDisp;
% yBnds = [72 120]/filToDisp;

% Generate logical of single object 
blobSlice = ismember(max(currIOO(:,:,zRange),[],3),denseVals(2:3));
% blobSlice = ismember(currIOO(:,:,round(mean(selZ))),denseVals(2:3));
labBlobs = bwlabel(blobSlice);
midID = labBlobs(startY(round(end/2)),startX(round(end/2)));

% Isolate region of interest
baseDist = bwdist(blobSlice);
singleDist = bwdist(labBlobs == midID);
% roiDist = imerode((baseDist - singleDist) == 0,strel('disk',3));
roiDist = (baseDist - singleDist) == 0;

% Subselect quiver coordinates in roiDist
quivInds = sub2ind(size(currIOO),yMat,xMat);
quivInROI = ismember(quivInds,find(roiDist));
sparseX = consMatLnB(xMat,quivInROI);
sparseY = consMatLnB(yMat,quivInROI);
% RESCALE Quiver coordinates
sparseCoords = [sparseX(:) sparseY(:)];
sparseCoordsSc = rescaleCoords(sparseCoords,size(scperim,[1 2]),size(perim,[1 2]));
sparseXsc = reshape(sparseCoordsSc(:,1),size(sparseX));
sparseYsc = reshape(sparseCoordsSc(:,2),size(sparseX));

% Subsample coordinates
U = gradsSlice(:,:,1); V = gradsSlice(:,:,2);
sparseU = consMatLnB(U,quivInROI);
sparseV = consMatLnB(V,quivInROI);

% Select filaments
filInds = ismember([startX, startY], selectCens,'rows');
buildLogic = selLogic;
buildLogic(find(buildLogic)) = filInds;
% Rebuild select filament coordinates
selCensSC = rescaleCoords(selectCens,size(currIOO,[1 2]),ogDims);
%%%%%%%%%%%%%%%%%%%%
allDirs = [currFils.Directors];
selDirs = allDirs(buildLogic,1:2);
allGrads = [currFils.GradsAtCens];
selGrads = allGrads(buildLogic,1:2);
selGradsNorm = selGrads./sqrt(sum(selGrads.^2,2));
%%%%%%%%%%%%%%

% Remove filaments from background
thFils = tiffreadVolume(fullfile(thFilDir,sprintf(thFilName,currT)));

% Get indices of all filaments in filament image for mapping
conncompFils = bwconncomp(thFils).PixelIdxList;
allPixs = vertcat(conncompFils{:});
cellLens = cellIndSizes(conncompFils',1);
indexVec = genLenVec(1:numel(cellLens),cellLens);

% Fill in using selLogic
selPixs = vertcat(conncompFils{buildLogic});
logicFils = consMatLnB(ones(size(thFils)),selPixs);
rmvFils = logical( imresize( max(logicFils,[],3), size(perim(:,:,selZ)),'nearest') );

figure
% Display background
bgMat = consMatLnB(perim(:,:,selZ),~rmvFils) + filVals*uint8(rmvFils);
imagesc(bgMat);
% imagesc(gradsSlice)
% imagesc(distMat(:,:,selZ) + (~(perim(:,:,selZ)==0))*max(distMat(:)))
cmap = colormap('gray');
% cmap(:,2:3) = 0;
cmap = flipud(cmap);
% cmap(1:10,:) = repmat([255 255 255]/255,10,1);
pMin = 1;      pMax = round(min(colorlims)/4);
cmap(pMin:pMax,:) = repmat(perimClr,(pMax - pMin)+1,1);
cmap(pMax:filVals,:) = repmat(filClr,(filVals - pMax)+1,1);
colormap((cmap));
clim(colorlims)
% clim([0 255])
hold on

% Display color coded filament centers
% scatter(startX,startY,50,'black','filled')
% selRs = rVals(selLogic);
% for index = 1:numel(unqRs)
%     currLogic = (selRs == unqRs(index));
%     scatter(startX(currLogic),startY(currLogic),30,filColors(index,:),'filled');
% end
% Display quiver fields
% quiver(sparseXsc,sparseYsc,sparseU,sparseV,1.5,'black');
% quiver(sparseXsc,sparseYsc,sparseU,sparseV,1,'Color','white','ShowArrowHead','off','LineWidth',2);
% quiver(sparseXsc,sparseYsc,sparseU,sparseV,1,'Color','black','ShowArrowHead','off','LineWidth',1);
quiver(selCensSC(:,1),selCensSC(:,2),selDirs(:,1),selDirs(:,2),1,'Color','white','ShowArrowHead','off','LineWidth',2);
quiver(selCensSC(:,1),selCensSC(:,2),selDirs(:,1),selDirs(:,2),1,'Color','black','ShowArrowHead','off','LineWidth',1);
% quiver(sparseXsc,sparseYsc,sparseU,sparseV,1,'Color',[0 0.9 1],'ShowArrowHead','off','LineWidth',2);

% scatter(startX,startY,5,'black','filled')
axis equal
xlim(xBnds)
ylim(yBnds)
% xlim(xBnds*filToDisp)
% ylim(yBnds*filToDisp)
set(gca, 'XTick',[])
set(gca, 'YTick',[])

%%
% print(fullfile('Session 88, Exp 4','GradFlowField.jpg'),'-djpeg','-r600')

soft_cream_colormap_grb = [
    243, 255, 212;  % Soft Cream
    209, 255, 169;  % Light Peach
    165, 244, 130;  % Warm Sand
     96, 214,  77;  % Terra Cotta
     50, 153,  50   % Burnt Umber
];