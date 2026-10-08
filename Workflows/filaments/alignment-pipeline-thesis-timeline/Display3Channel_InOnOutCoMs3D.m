%% Plot centroids for in, on, out channels, taken from filaments
% Assumptions: 
%   - filName are filament segmentations of original image size
%   - ccName are regionprops3 of binarized filName
%       - Contains deltar, gradient, and index info: AppendDensePropsToFilCCs.m
%   - dispName is in/on/out with cubic/symmetrical voxels
% 2025-04-21 - Rémi Boros

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
selTimes = 25;
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

%% Load data and prepare
%load data
tInd = 1;
    currT = selTimes(tInd);
    currFils = logical(tiffreadVolume(fullfile(filDir,sprintf(filName,currT))));
    currCCs = load(fullfile(ccDir,sprintf(ccName,currT)),ccField).(ccField);
    currDisp = double(tiffreadVolume(fullfile(denseDir,sprintf(denseName,currT))));
    % Use bwlabeln to map cutoff filaments - 0 is background, so n+1 elements
    labelFils = bwlabeln(currFils);

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
    arLogic = allARs > cutAR;       zLogic = ismember(zSlice, zRange);
    inplaneLogic = zAligns < cutZ;
    fullLogic = lenLogic & volLogic & arLogic & zLogic;

% Sample disp field at cens
    [scaleInds] = rescaleCoords_Inds(allInds,size(currFils),size(currDisp));
    dispAtCens = currDisp(scaleInds);

% Plot centroids, filaments, and in/on/out domains
    % Rescaled display
    scDisp = imresize3(currDisp,size(currFils),'nearest');
    dispAtCensSc = scDisp(allInds);
    
    selLogic = lenLogic & arLogic & volLogic;
    
    centersMat = zeros([size(currFils) 3]);
    unqDisps = unique(dispAtCens);
    testStrel = strel('sphere',3);
    for index = 1:3
        currLogic = (dispAtCens == unqDisps(index)) & selLogic;
        centersMat(:,:,:,index)  = imdilate(consMatLnB(ones(size(currFils)),allInds(currLogic)),testStrel)*150;
    end
    totComs = sum(centersMat,4);
    totBG = consMatLnB(scDisp,~logical(totComs));
    finalMat = centersMat + repmat(totBG,1,1,1,3)/3 + repmat(currFils,1,1,1,3)*200;
    finalMat = uint8(finalMat);


