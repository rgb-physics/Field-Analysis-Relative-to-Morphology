%% Takes in thresholded filaments and in/on/out segmentations. 
% Returns tifs of filaments and drop boundaries.
% The script applies bwlabeln to thresholded filaments, which can be used
% to map specific quantities (such as alignment) onto appropriate filaments
% 2025-04-18 - Rémi Boros
% Assumptions: 
%   - filName are filament segmentations of original image size
%   - ccName are regionprops3 of binarized filName
%       - Contains deltar, gradient, and index info: AppendDensePropsToFilCCs.m
%   - dispName is in/on/out with cubic/symmetrical voxels

% filDir = '<redacted original absolute path>';
filDir = 'Session 88, Exp 4';
filName = 'Time%06i_threshFils.tif';
ccDir = fullfile(filDir,'CC Objects');
ccName = 'Filament Statistics %03i.mat';
ccField = 'rp3D';
% denseDir = '<redacted original absolute path>';
denseDir = 'Session 88, Exp 4';
denseName = 'Time%06i_3ChanSegs.tif';
% baseSaveDir = '<redacted original absolute path>';
baseSaveDir = 'Session 88, Exp 4';
% saveDir = fullfile('Session 87, Exp 2','Trinary - All Fils and Bnds');
saveName = 'Time%06i_bndFils.tif';
% mkdir(saveDir);

% Load data variables
segThresh = 100;
selTimes = 1:70;
zRange = 62:78;
ogVoxSz = [0.3667 0.3667 0.7];
% Filter parameters
cutAR = 1.5;    
cutLen = 2;     
cutVol = 4; 
cutZ = 0.5;
% Tif intensity variables
bndVal = 2000;
filBnds = [6000 12000];
numBins = 12;

%% Load data and prepare
%load data
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    currFils = logical(tiffreadVolume(fullfile(filDir,sprintf(filName,currT))));
    currCCs = load(fullfile(ccDir,sprintf(ccName,currT)),ccField).(ccField);
    currDisp = double(tiffreadVolume(fullfile(denseDir,sprintf(denseName,currT))));
  
    % Get indices of all filaments in filament image for mapping
    conncompFils = bwconncomp(currFils).PixelIdxList;
    allPixs = vertcat(conncompFils{:});
    cellLens = cellIndSizes(conncompFils',1);
    indexVec = genLenVec(1:numel(cellLens),cellLens);
    % Reconstruct labeled filament tif that agrees with regionprops(3)
    labelFils = zeros(size(currFils));
    labelFils(allPixs) = indexVec;

% Collect fields
    % Concatenate filament properties
    allCens = [currCCs.Centroid];   allDirecs = [currCCs.Directors];
    allLens = [currCCs.Lengths(:)]; allARs = [currCCs.AspectRatios(:)];
    allVols = [currCCs.Volume(:)];  allGrads = [currCCs.GradsAtCens];
    allInds = [currCCs.CoMInds];        % CoMs are (x,y,z), sub2ind needs (row, col, depth) (y,x,z)
    zAligns = allDirecs(:,3);
    zSlice = round(allCens(:,3));    
% Calculate order parameters
    gnDot = sum(allDirecs.*allGrads,2);
    order3D = min(1,max(-0.5,1/2*(3*gnDot.^2 - 1)));
    order2D = min(1,max(-1,(1/1*(2*gnDot.^2 - 1))));
% Generate Logic
    lenLogic = allLens > cutLen;    volLogic = allVols > cutVol;
    arLogic = allARs > cutAR;       
    % zLogic = ismember(zSlice, zRange);
    inplaneLogic = zAligns < cutZ;
    fullLogic = lenLogic & volLogic & arLogic;

% Sample disp field at cens
    [scaleInds] = rescaleCoords_Inds(allInds,size(currFils),size(currDisp));
    dispAtCens = currDisp(scaleInds);
    scDisp = imresize3(currDisp,size(currFils),'nearest');
    dispAtCensSc = scDisp(allInds);

%% Plot Perimeters and Filaments
% Generate perimeter
    bwSeg = currDisp > segThresh;
    erodedBnd = returnSmoothBound(bwSeg,2,size(currFils));
    rsBnd = imresize3(erodedBnd,size(currFils));
     
% Filaments in on out - filtered
    selLogic = lenLogic & volLogic & arLogic;
    mapVec = dispAtCens;  
    mapVec = abs(diff(filBnds))*(mapVec - min(mapVec))/(max(mapVec) - min(mapVec)) + min(filBnds);
    saveDir = fullfile(baseSaveDir,'Filaments In On Out');
    % Map filaments to desired values stored in mapVec (append for bg 0)
    mapVec(~selLogic) = 0;
    mapVec = [0; mapVec];
    baseFils = mapVec(labelFils+1);
    % Combine seg and filaments
    bndField = bndVal*rsBnd;
    outMat = consMatLnB(bndField,~currFils) + baseFils;
    % Save
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    save3DTiff(uint16(outMat),fullfile(saveDir,sprintf(saveName,currT)));

% 2D order parameter - Filter
    selLogic = lenLogic & volLogic & arLogic & inplaneLogic;
    [~,~,mapVec] = histcounts(order2D,numBins);  
    mapVec = abs(diff(filBnds))*(mapVec - min(mapVec))/(max(mapVec) - min(mapVec)) + min(filBnds);
    saveDir = fullfile(baseSaveDir,'Len Vol AR InPlane Filter - 2D Order');
    % Map filaments to desired values stored in mapVec (append for bg 0)
    mapVec(~selLogic) = 0;
    mapVec = [0; mapVec];
    baseFils = mapVec(labelFils+1);
    % Combine seg and filaments
    bndField = bndVal*rsBnd;
    outMat = consMatLnB(bndField,~currFils) + baseFils;
    % Save
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    save3DTiff(uint16(outMat),fullfile(saveDir,sprintf(saveName,currT)));

% 3D order parameter - Filter
    selLogic = lenLogic & volLogic & arLogic;
    [~,~,mapVec] = histcounts(order3D,numBins);  
    mapVec = abs(diff(filBnds))*(mapVec - min(mapVec))/(max(mapVec) - min(mapVec)) + min(filBnds);
    saveDir = fullfile(baseSaveDir,'Len Vol AR Filter - 3D Order');
    % Map filaments to desired values stored in mapVec (append for bg 0)
    mapVec(~selLogic) = 0;
    mapVec = [0; mapVec];
    baseFils = mapVec(labelFils+1);
    % Combine seg and filaments
    bndField = bndVal*rsBnd;
    outMat = consMatLnB(bndField,~currFils) + baseFils;
% Save
    if ~exist(saveDir,'dir')
        mkdir(saveDir);
    end
    save3DTiff(uint16(outMat),fullfile(saveDir,sprintf(saveName,currT)));

    % 3D order parameter - All
    % [~,~,mapVec] = histcounts(order3D,numBins); 
    % mapVec = abs(diff(filBnds))*(mapVec - min(mapVec))/(max(mapVec) - min(mapVec)) + min(filBnds);
    % selLogic = true(size(fullLogic));
    % saveDir = fullfile(baseSaveDir,'All Fils - 3D Order');

    % Binary filaments
    % mapVec = ones(size(fullLogic))*abs(diff(filBnds))/2;
    % selLogic = true(size(fullLogic));
    % saveDir = fullfile(baseSaveDir,'Trinary - All Fils and Bnds');
    
%     % Map filaments to desired values stored in mapVec (append for bg 0)
%     mapVec(~selLogic) = 0;
%     mapVec = [0; mapVec];
%     baseFils = mapVec(labelFils+1);
%     % Combine seg and filaments
%     bndField = bndVal*rsBnd;
%     outMat = consMatLnB(bndField,~currFils) + baseFils;
% 
% % Save
%     if ~exist(saveDir,'dir')
%         mkdir(saveDir);
%     end
%     save3DTiff(uint16(outMat),fullfile(saveDir,sprintf(saveName,currT)));
% end

end
clear all


%% Plot orientations over display frame
% selLogic = ones(size(currFils));
% % Plot
% figure
% % imagesc(currDisp(:,:,round(mean(zRange))));
% imagesc(sum(currFils(:,:,zRange),3));
% colormap('gray')
% hold on
% % plot(outXs,outYs,'red');
% % scatter(allCens(selLogic,1),allCens(selLogic,2),10,'red','filled');
% plot(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),'red');
% plot(gradBBs(1).BBs(:,selLogic),gradBBs(2).BBs(:,selLogic),'blue');
% axis equal
% 
% %% Plot lines in 3D
% selLogic = lenLogic & volLogic & arLogic;
% 
% figure
% plot3(allBBs(1).BBs(:,selLogic),allBBs(2).BBs(:,selLogic),allBBs(3).BBs(:,selLogic),'red')
% hold on
% plot3(rescBBs(1).BBs(:,selLogic),rescBBs(2).BBs(:,selLogic),rescBBs(3).BBs(:,selLogic),'blue')
% plot3(gradBBs(1).BBs(:,selLogic),gradBBs(2).BBs(:,selLogic),gradBBs(3).BBs(:,selLogic),'green')
% axis equal

