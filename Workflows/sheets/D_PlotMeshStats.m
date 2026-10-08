%% Data directories
% dataHome = '<redacted original absolute path>';
dataHome = 'Session 28, Exp 6';
dataSubs = {'Bot Layer', 'Top Layer'};
dataNameForm = '%sDataStoreStructT%i.mat';
dataNameSubs = {'bot', 'top'};

% ptCloudDir = '<redacted original absolute path>';
ptCloudDir = 'Session 28, Exp 6';
ptCloudName = 'Time%06i_regionsStruct.mat';
% surfCloudDir = '<redacted original absolute path>';
surfCloudDir = 'Session 28, Exp 6';
surfSubs = {'Bot Layers', 'Top Layers'};
surfCloudName = '%sLayer_vertices_t%03i.ply';
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 28, Exp 6';
imgName = 't%03i_illBleachCorr16bit.tif';
selectTimes = 100:20:200;

%% Distributions of curvature
figure
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    load(fullfile(dataHome,dataSubs{1},sprintf(dataNameForm,dataNameSubs{1},currT)),'currStruct');
    [a,b] = histcounts(currStruct.curvV,-1:.01:1);
    plot(b(2:end), a/max(a(:)), 'Color', [tInd/numel(selectTimes) 0 (1 - tInd/numel(selectTimes))]);
%     plot(b(2:end), a/max(a(:)) + (tInd - 1)/5, 'Color', [tInd/numel(selectTimes) 0 (1 - tInd/numel(selectTimes))]);
    hold on
end
xlabel('Curvature')
ylabel('Normalized Dist.')
set(gca,'FontSize',15)

%% Distributions of curvature (normalized by first dist)
figure
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    load(fullfile(dataHome,dataSubs{1},sprintf(dataNameForm,dataNameSubs{1},currT)),'currStruct');
    [a,b] = histcounts(currStruct.curvV,-1:.01:1);
    if tInd == 1
        c = a;  d = b;
    end
    plot(b(2:end), a/max(a(:))*max(c(:))./c + (tInd - 1)/5, 'Color', [tInd/numel(selectTimes) 0 (1 - tInd/numel(selectTimes))]);
    hold on
end

%% Intensity vs. curvature
figure
for tInd = 1:numel(selectTimes)
    currT = selectTimes(tInd);
    load(fullfile(dataHome,dataSubs{1},sprintf(dataNameForm,dataNameSubs{1},currT)),'currStruct');
    histogram2(currStruct.curvV, currStruct.intV, -1:.01:1, 0:100:30000)
    hold on
end

%% 
tri = triangulation(currStruct.f, -currStruct.v);
trisurf(tri, currStruct.intV.*currStruct.curvV, 'edgecolor', 'none');
cmax = prctile(abs(currStruct.intV.*currStruct.curvV),95);
caxis([-cmax cmax]);

%% Sample intensities in regions of "high" curvature (top 10%)
curveMax = prctile(abs(currStruct.curvV),80);
maxInds = abs(currStruct.curvV) > curveMax;
intsAtMax = currStruct.intV(maxInds);
curvesAtMax = currStruct.curvV(maxInds);

dispVec = zeros(size(currStruct.intV));
dispVec(maxInds) = intsAtMax.*curvesAtMax;

trisurf(tri, abs(dispVec), 'edgecolor', 'none');
cmax = prctile(abs(dispVec),95);
caxis([-cmax cmax]);
axis equal
colorbar

%% intensity select
dispVec = zeros(size(currStruct.intV));
dispVec(maxInds) = intsAtMax;

trisurf(tri, dispVec, 'edgecolor', 'none');
cmax = prctile(abs(dispVec),95);
caxis([-cmax cmax]);
axis equal
colorbar

%% Curvatures on outer pt cloud vs intensities in entirety of segmented layer
tInd = 1;
currT = selectTimes(tInd);
load(fullfile(ptCloudDir,sprintf(ptCloudName,currT)));
currTif = double(tiffreadVolume(fullfile(imgDir,sprintf(imgName,currT))));

ptCloud = outputStruct.botInds;
tifDown = imresize3(double(currTif),size(ptCloud));

mesh = read_ply_mod(fullfile(surfCloudDir, surfSubs{1}, sprintf(surfCloudName,dataNameSubs{1},currT))) ;
% Verify point cloud outside location
boundCoords = floor(mesh.v);
for index = 1:3
    boundCoords(:,index) = min(boundCoords(:,index), size(tifDown,index));
end
boundInds = sub2ind(size(tifDown), boundCoords(:,1), boundCoords(:,2), boundCoords(:,3));
outSurf = zeros(size(tifDown));
outSurf(boundInds) = 1;

% Distance transform
distTrans = bwdist(logical(outSurf));
selDists = consMatLnB(distTrans, ptCloud);
% load(fullfile(dataHome,dataSubs{1},sprintf(dataNameForm,dataNameSubs{1},currT)),'currStruct');
% % Verify point cloud outside location
% boundCoords = floor(currStruct.v);
% for index = 1:3
%     boundCoords(:,index) = min(boundCoords(:,index), size(tifDown,index));
% end
% boundInds = sub2ind(size(tifDown), boundCoords(:,1), boundCoords(:,2), boundCoords(:,3));
% outSurf = zeros(size(tifDown));
% outSurf(boundInds) = tifDown(boundInds);

% Distance transform of surface
% test = zeros()

%% Project along surface normals for set of vectors along normal
deltaX = -(0:14);

load(fullfile(dataHome,dataSubs{1},sprintf(dataNameForm,dataNameSubs{1},currT)),'currStruct');
currVerts = currStruct.v; currFaces = currStruct.f;
currTri = triangulation(currFaces, currVerts);
norms = faceNormal(currTri);
bcs = currStruct.bcs;

% Get distance transform of barycenters
boundCoords = floor(bcs);
for index = 1:3
    boundCoords(:,index) = min(boundCoords(:,index), size(tifDown,index));
    boundCoords(:,index) = max(boundCoords(:,index), 1);
end
boundInds = sub2ind(size(tifDown), boundCoords(:,1), boundCoords(:,2), boundCoords(:,3));
outSurf = zeros(size(tifDown));
outSurf(boundInds) = 1;
distMat = bwdist(logical(outSurf));

% Project each barycenter along norm by selected delta x
scaleMat = repmat(reshape(deltaX, [1 1 numel(deltaX)]),[size(bcs) 1]);
normMat = repmat(norms, [1 1 numel(deltaX)]);
coordMat = repmat(bcs, [1 1 numel(deltaX)]);

shiftMat = coordMat + scaleMat.*normMat;

% Reshape for vectorized interpolation
permuted = permute(shiftMat, [1 3 2]);
reshaped = reshape(permuted, [size(permuted,1)*size(permuted,2) size(permuted,3)]);
permSteps = permute(scaleMat, [1 3 2]);
reshSteps = reshape(permSteps, [size(permuted,1)*size(permuted,2) size(permuted,3)]);
stepCompare = reshSteps(:,1);

% Bound to points within tif boundaries
validInds = ones(size(reshaped,1),1);
validInds(min(reshaped,[],2) < 1) = 0;
validInds(max(reshaped - size(tifDown),[],2) > 0) = 0;

% Generate gridded interporlant objects
dataGInt = griddedInterpolant(tifDown);
distGInt = griddedInterpolant(distMat);

% Store interpolated values
interpInts = dataGInt(reshaped(:,1), reshaped(:,2), reshaped(:,3));
interpDist = distGInt(reshaped(:,1), reshaped(:,2), reshaped(:,3));

% Filter invalid data points
interpDist(interpDist < 0) = 0;
interpDist(interpDist > abs(stepCompare)) = 0;

% Return to og matrix dims
intVals =  reshape(interpInts, [size(permuted,1) size(permuted,2)]);
distVals = reshape(interpDist, [size(permuted,1) size(permuted,2)]);
validVals = reshape(validInds, [size(permuted,1) size(permuted,2)]);
selInts = consMatLnB(intVals, logical(validVals));
selDists = consMatLnB(distVals, logical(validVals));

% Compare to dist transform
% finalDists = consMatLnB(selDists, (selDists + squeeze(scaleMat(:,1,:))) > 0);
finalDists = selDists;

% reshaped = reshaped(sum(reshaped,2) > 0,:);
% stepCompare = stepCompare(sum(reshaped,2) > 0);




% Define values at appropriate indices
% temp = reshaped(logical(validInds),:);
% finalInds = sub2ind(size(tifDown), round(temp(:,1)),round(temp(:,2)),round(temp(:,3)));
% outSurf = zeros(size(tifDown));
% outSurf(finalInds) = distVals(logical(validInds));
% orthosliceViewer(outSurf);

% % % View (approximate) projection along normal
% outSurf = zeros(size(tifDown));
% for currShift = 1:numel(deltaX)
%     boundCoords = floor(shiftMat(:,:,currShift));
%     for index = 1:3
%         boundCoords(:,index) = min(boundCoords(:,index), size(tifDown,index));
%         boundCoords(:,index) = max(boundCoords(:,index), 1);
%     end
%     boundInds = sub2ind(size(tifDown), boundCoords(:,1), boundCoords(:,2), boundCoords(:,3));
% %     outSurf = zeros(size(tifDown));
%     outSurf(boundInds) = dataGInt(boundCoords(1,index),boundCoords(2,index),boundCoords(3,index));
% %     outSurf(boundInds) = currShift;
% end

% trisurf(currTri, 'edgecolor', 'none')
% hold on
% axis equal
% quiver3(bcs(1:10:end,1), bcs(1:10:end,2), bcs(1:10:end,3), norms(1:10:end,1), norms(1:10:end,2), norms(1:10:end,3), 4, 'r');
% surfnorm(currVerts(:,1), currVerts(:,2), currVerts(:,3));

%% Carve segmentations
% structDir = '<redacted original absolute path>';
structDir = 'Session 28, Exp 6';
structName = 'Time%06i_regionsStruct.mat';
selectTimes = 150:151;
strelSize = 2;
strelObj = strel('sphere', strelSize);

for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    load(fullfile(structDir, sprintf(structName, currT)));
    sheetInds = outputStruct.botInds + outputStruct.topInds;

    save3DTiff(uint8(imdilate(sheetInds,strelObj) - sheetInds),fullfile(structDir,'Dilated Perimeters', sprintf('strel%i_dilatedSeg_T%03i.tif',strelSize,currT)));
end



