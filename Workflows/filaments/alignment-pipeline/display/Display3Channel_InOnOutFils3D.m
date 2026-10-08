 %% Isolated and run 2025-04-21 Rémi Boros
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
% saveDir = fullfile('Session 87, Exp 2','Trinary - All Fils and Bnds');
saveName = 'Time%06i_bndFils.tif';
% mkdir(saveDir);

% Load data variables
segThresh = 100;
selTimes = 20;
zRange = 62:78;
ogVoxSz = [0.3667 0.3667 0.7];
% Filter parameters
cutAR = 1.5;    
cutLen = 2;     
cutVol = 4; 
cutZ = 1;
% Tif intensity variables
bndVal = 1000;
filBnds = [10000 20000];
numBins = 12;

%% Generate a 3D image of filaments on segmented
tInd = 1;
currT = selTimes(tInd);
currFils = logical(tiffreadVolume(fullfile(filDir,sprintf(filName,currT))));
currCCs = load(fullfile(ccDir,sprintf(ccName,currT)),ccField).(ccField);
currDisp = double(tiffreadVolume(fullfile(denseDir,sprintf(denseName,currT))));

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
    % zLogic = ismember(zSlice, zRange);
    inplaneLogic = zAligns < cutZ;
    fullLogic = lenLogic & volLogic & arLogic;

% Sample disp field at cens
    scaleInds = rescaleCoords_Inds(allInds,size(currFils),size(currDisp));
    dispAtCens = currDisp(scaleInds);
    % lblFilsAtCens = labelFils(allInds);
    scDisp = imresize3(currDisp,size(currFils),'nearest');
    dispAtCensSc = scDisp(allInds);
% 3D Filament differentiation: In On Out 
    selLogic = fullLogic;

%%%%%%%%%%%%% THIS WORKS
% Combine filaments with centroids
% Plot centroids, filaments, and in/on/out domains
    % Instantiate
    centersMat = zeros([size(currFils) 3]);
    filsMat = centersMat;
    testStrel = strel('sphere',3);
    unqDisps = unique(dispAtCens);
    for index = 1:numel(unqDisps)
        currLogic = (dispAtCens == unqDisps(index)) & selLogic;
        % Find all 
        selIDs = find(currLogic);
        % Isolate pixels corresponding to filaments with selInds IDs
        selInds = allPixs(ismember(indexVec,selIDs));
        % Convert 3D indices to 4D indices in corresponding channel
        [rows3D,cols3D,deps3D] = ind2sub(size(currFils),selInds);
        inds4D = sub2ind(size(filsMat),rows3D,cols3D,deps3D,index*ones(size(rows3D)));
        filsMat(inds4D) = 150;
        % centersMat(:,:,:,index)  = imdilate(consMatLnB(ones(size(currFils)),allInds(currLogic)),testStrel)*150;
    end
    totComs = sum(centersMat,4);
    totBG = consMatLnB(scDisp,~logical(totComs));
    % finalMatPts = centersMat + repmat(totBG,1,1,1,3)/3 + repmat(currFils,1,1,1,3)*200;
    % finalMatPts = uint8(finalMatPts);
    finalMatFils = filsMat + repmat(totBG,1,1,1,3)/3;
    finalMatFils = uint8(finalMatFils);

%% Display
figure
orthosliceViewer(finalMatFils);
% figure
% orthosliceViewer(finalMatPts);
 

