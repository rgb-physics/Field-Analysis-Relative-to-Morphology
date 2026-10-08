 %% Split filaments to in on out, then make image of 2D slice
 % 2025-04-21 Rémi Boros
% Takeaway: bwlabeln and bwconncomp do not always return identical 3D IDs
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
dispDir = denseDir;
dispName = denseName;
% dispDir = 'Session 88, Exp 4';
% dispName = 't%03i_illBleachCorr16bit_560.tif';
% saveDir = fullfile('<redacted original absolute path>');
saveDir = fullfile('Session 88, Exp 4');
saveName = 'Time%06i_bndFils.tif';
mkdir(saveDir);

% Load data variables
segThresh = 100;
selTimes = 40;
% selTimes = [9 14 19 31];
zRange = 38:50;     % middle slice used for dense; in same units as fil. cens
ogVoxSz = [0.3667 0.3667 0.7];
% Filter parameters
cutAR = 1.5;    
cutLen = 0;     
cutVol = 4; 
cutZ = 1;
% Tif intensity variables
bndVal = 180;
filBnds = [85 255];
ogFilVals = [85 170 255];
% bndVal = 10000;
% filBnds = [13000 15000];
% ogFilVals = [85 170 255];
numBins = 12;

%% Generate a 3D image of filaments on segmented

for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    currFils = logical(tiffreadVolume(fullfile(filDir,sprintf(filName,currT))));
    currCCs = load(fullfile(ccDir,sprintf(ccName,currT)),ccField).(ccField);
    rgnSeg = double(tiffreadVolume(fullfile(denseDir,sprintf(denseName,currT))));
    currDisp = double(tiffreadVolume(fullfile(dispDir,sprintf(dispName,currT))));

    % instantiate save objects
    if tInd == 1
        outBGs = zeros([size(currFils,[1 2]) numel(selTimes)]);
        totFils = outBGs;
    end
    
    % Get indices of all filaments in filament image for mapping
    conncompFils = bwconncomp(currFils).PixelIdxList;
    allPixs = vertcat(conncompFils{:});
    cellLens = cellIndSizes(conncompFils',1);
    indexVec = genLenVec(1:numel(cellLens),cellLens);

% Collect fields
    % Concatenate filament properties
    allCens = [currCCs.Centroid];   allDirecs = [currCCs.Directors];
    allLens = [currCCs.Lengths(:)]; allARs = [currCCs.AspectRatios(:)];
    allVols = [currCCs.Volume(:)];  allGrads = [currCCs.GradsAtCens];
    allInds = [currCCs.CoMInds];        % CoMs are (x,y,z), sub2ind needs (row, col, depth) (y,x,z)
    zAligns = allDirecs(:,3);
    zSlice = round(allCens(:,3));    
% Calculate order parameters
    % gnDot = sum(allDirecs.*allGrads,2);
    % order3D = min(1,max(-0.5,1/2*(3*gnDot.^2 - 1)));
    % order2D = min(1,max(-1,(1/1*(2*gnDot.^2 - 1))));
% Generate Logic
    lenLogic = allLens > cutLen;    volLogic = allVols > cutVol;
    arLogic = allARs > cutAR;       
    inplaneLogic = zAligns < cutZ;
% Get filament centroids in zrange
    zLogic = ismember(zSlice, zRange);
    fullLogic = lenLogic & volLogic & arLogic & zLogic;

% Sample region segmentation field at cens
    scaleInds = rescaleCoords_Inds(allInds,size(currFils),size(rgnSeg));
    rgnsAtCens = rgnSeg(scaleInds);
    % lblFilsAtCens = labelFils(allInds);
    scRgns = imresize3(rgnSeg,size(currFils),'nearest');
    scDisp = imresize(currDisp(:,:,mean(zRange)),size(currFils,[1 2]),'nearest');
    % dispAtCensSc = scRgns(allInds);
% 3D Filament differentiation: In On Out 
    selLogic = fullLogic;

%%%%%%%%%%%%% THIS WORKS
% Plot centroids, filaments, and in/on/out domains
    % Instantiate
    filsMat = zeros([size(scDisp) 3]);
    testStrel = strel('sphere',3);
    unqDisps = unique(rgnsAtCens);
    for index = 1:numel(unqDisps)
        currLogic = (rgnsAtCens == unqDisps(index)) & selLogic;
        % Find all 
        selIDs = find(currLogic);
        % Isolate pixels corresponding to filaments with selInds IDs
        selInds = allPixs(ismember(indexVec,selIDs));
        % Convert 3D indices to 2D indices
        [rows3D,cols3D,deps3D] = ind2sub(size(currFils),selInds);
        inds2D = sub2ind(size(filsMat),rows3D,cols3D,index*ones(size(rows3D)));
        filsMat(inds2D) = 1;
    end
    % Generate scaling vector for bounded values
    scaleVec = (ogFilVals - min(ogFilVals))./(max(ogFilVals) - min(ogFilVals));
    scaleVec = scaleVec.*abs(diff(filBnds)) + min(filBnds);
    scaleVec = permute(scaleVec,[1 3 2]);
    % Rescale filaments and convert to 2D
    filsMat2D = max(filsMat.*scaleVec,[],3);
    % Add background
    totComs = logical(filsMat2D);
    outDisp = scDisp/max(scDisp(:))*bndVal;
    totBG = consMatLnB(outDisp,~logical(totComs));
    % finalMatPts = centersMat + repmat(totBG,1,1,1,3)/3 + repmat(currFils,1,1,1,3)*200;
    % finalMatPts = uint8(finalMatPts);
    finalMatFils = filsMat2D + totBG;
    finalMatFils = uint8(finalMatFils);
    
    % Save
    save3DTiff(finalMatFils,fullfile(saveDir,sprintf(saveName, currT)));
    outBGs(:,:,tInd) = consMatLnB(scDisp,~logical(totComs));
    totFils(:,:,tInd) = filsMat2D;

end

save3DTiff(uint8(outBGs),fullfile(saveDir,'allBGs.tif'));
save3DTiff(uint8(totFils),fullfile(saveDir,'allFils.tif'));

%% Display
% figure
% imagesc(finalMatFils);
% figure
% orthosliceViewer(finalMatPts);
 

