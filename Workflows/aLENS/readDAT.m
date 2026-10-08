% For aLENS data from Chris
% Takes in aLENS data of microtubules and motors. Motors crosslink
% microtubules. The following script does a few things:
% 1) An adjacency matrix is generated from the motor crosslinks.
% 2) Polarity and Q fields are defined from filament positions in 2D and 3D
% 3) Motors are distinguished into free, bound to one, or bound to two MTs
% 4) Microtubules are IDed based on motor connectivity into clusters
% 5) Matrices of predefined size are defined with microtubule locations; ie
%   data is converted into viewable 3D tifs
% 2024-10-18, Rémi Boros

% Indices of different directories
expInds = 1:16;

% Parameters
selTimes = 1:399;
outMatSideLen = 800;
initBoxDims = [4.34 4.34 0.28];
filWidth = round(.02*outMatSideLen/initBoxDims(1)/2)*3;       % Used for convolution; estimate as filament radius
scaleFactor = outMatSideLen/initBoxDims(1);
zScale = initBoxDims(:,3)/initBoxDims(:,1);
scaledMatSize = [outMatSideLen,outMatSideLen,round(outMatSideLen*zScale)];
saveFields = 1;
saveFils = 1;
quiverScale = 40;

for overIndex = 1:numel(expInds)
% Current directory index
expIndex = expInds(overIndex);
% Generate names of directories and files for current index
% dataDir = fullfile('<redacted original absolute path>',sprintf('%i',expIndex),'\result\result0-399');
dataDir = fullfile('',sprintf('%i',expIndex),'\result\result0-399');
MTData = 'SylinderAscii_%i.dat';
kif4Data = 'ProteinAscii_%i.dat';
% baseSaveDir = fullfile('<redacted original absolute path>',sprintf('%i',expIndex));
baseSaveDir = fullfile('',sprintf('%i',expIndex));
saveDir = fullfile(baseSaveDir,'3Width Convolution - Psqrd and sqrtQ');
saveName = 'Time%06i_IDedFilaments.tif';
idSaveDir = fullfile(saveDir,'IDed Filaments');
pSaveDir = fullfile(saveDir,'Polarizations');
qSaveDir = fullfile(saveDir,'Trace Q-Squared');
pSaveName = 'Time%06i_Polarization.png';
qSaveName = 'Time%06i_TraceQQ.png';
clusterDir = fullfile(saveDir,'Filament Clusters');
clusterName = 'T%06i_clusterIDs.tif';

% Make save directories
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end
if ~exist(pSaveDir,'dir')
    mkdir(pSaveDir)
end
if ~exist(qSaveDir,'dir')
    mkdir(qSaveDir)
end
if ~exist(idSaveDir,'dir')
    mkdir(idSaveDir)
end

% Generate adjacency and cluster info from motor data
countsXFB = zeros(numel(selTimes),3);   % Crosslink, Free, Bound (1 side)

% Load aLENS raw data, generate filaments, polarity and Q fields. Save all
for tInd = 1:numel(selTimes)    

    % Load filaments
    currT = selTimes(tInd);
    if isfile(fullfile(dataDir,sprintf(MTData,currT)))
        currMTs = readtable(fullfile(dataDir,sprintf(MTData,currT)));
    else
        continue
    end
    numFils = size(currMTs,1);

    % Convert filaments to matrix; get fil indices and a map for fields
    [filMat,filInds3D,validLogic] = dat2Mat_Fils(currMTs, initBoxDims, outMatSideLen);
    
    % Filament lengths, CoMs, and vector lengths
    mtCoords = table2array(currMTs(:,4:9));
    mtVecs = zeros(numFils,3);
    mtCOMs = mtVecs;
    for currDim = 1:3
        mtVecs(:,currDim) = mtCoords(:,3+currDim) - mtCoords(:,currDim);
        mtCOMs(:,currDim) = (mtCoords(:,3+currDim) + mtCoords(:,currDim))/2;
    end
    scaledCoMs = mtCOMs*scaleFactor;
    xyLens = sqrt(sum(mtVecs(:,1:2).^2,2));
    mtLens = sqrt(sum(mtVecs.^2,2));
    % Angle x-y
    mtThetas = atan2(-mtVecs(:,2), mtVecs(:,1));
    % Polarization vectors
    rawPs = mtVecs./xyLens;
    rawPs3 = mtVecs./mtLens;
    % Q-tensors
    rawQs = zeros(2,2,numFils);
    rawQs3 = zeros(3,3,numFils);
    for currFil = 1:numFils
        rawQs(:,:,currFil) = rawPs(currFil,1:2).*rawPs(currFil,1:2)' - eye(2)/2;
        rawQs3(:,:,currFil) = rawPs3(currFil,:).*rawPs3(currFil,:)' - eye(3)/3;
    end

% Generate polarization fields
    mtPXs = imgaussfilt3(fieldOnObjs(rawPs3(:,2),scaledMatSize,filInds3D,validLogic),filWidth);
    mtPYs = imgaussfilt3(fieldOnObjs(rawPs3(:,1),scaledMatSize,filInds3D,validLogic),filWidth);
    mtPZs = imgaussfilt3(fieldOnObjs(rawPs3(:,3),scaledMatSize,filInds3D,validLogic),filWidth);

    % 2D projection
    mtPXs2D = sum(mtPXs,3);
    mtPYs2D = sum(mtPYs,3);
    polMag = sqrt(mtPXs2D.^2 + mtPYs2D.^2);

% Generate Q Tensor fields
    % Diagonal terms
    mtQXXs = imgaussfilt3(fieldOnObjs(rawQs3(2,2,:),scaledMatSize,filInds3D,validLogic),filWidth);
    mtQYYs = imgaussfilt3(fieldOnObjs(rawQs3(1,1,:),scaledMatSize,filInds3D,validLogic),filWidth);
    mtQZZs = imgaussfilt3(fieldOnObjs(rawQs3(3,3,:),scaledMatSize,filInds3D,validLogic),filWidth);
    % Off-diagonals
    mtQXYs = imgaussfilt3(fieldOnObjs(rawQs3(2,1,:),scaledMatSize,filInds3D,validLogic),filWidth);
    mtQYZs = imgaussfilt3(fieldOnObjs(rawQs3(1,3,:),scaledMatSize,filInds3D,validLogic),filWidth);
    mtQZXs = imgaussfilt3(fieldOnObjs(rawQs3(3,2,:),scaledMatSize,filInds3D,validLogic),filWidth);

    % Project to 2D
    mtQXXs2D = sum(mtQXXs,3); mtQYYs2D = sum(mtQYYs,3); mtQZZs2D = sum(mtQZZs,3);
    mtQXYs2D = sum(mtQXYs,3); mtQYZs2D = sum(mtQYZs,3); mtQZXs2D = sum(mtQZXs,3);

% Q-tensor traces
    % Trace of 3D Q = Qxx^2 + Qyy^2 + Qzz^2 + 2*(Qxy^2 + Qxz^2 + Qyz^2)
    trQQ3_2D = mtQXXs2D.^2 + mtQYYs2D.^2 + mtQZZs2D.^2 + 2*(mtQXYs2D.^2 + mtQYZs2D.^2 + mtQZXs2D.^2);
    % Trace of Q^2 = Qxx^2 + 2Qxy + Qyy^2
    % trQQ2D = mtQXXs2D.^2 + 2*mtQXYs2D.^2 + mtQYYs2D.^2;     

    % Plot, if requested, and save
    if saveFils == 1   
        % Picture of polarization magnitude
        if tInd == 1
            [rowmesh,colmesh] = meshgrid(1:scaledMatSize(1),1:scaledMatSize(2));
        end
        
        quiverCens = max(1,floor(scaledCoMs));
        cenInds = sub2ind(scaledMatSize,quiverCens(:,1),quiverCens(:,2));
        % Save matrices of fields
        save3DTiff(uint16(filMat),fullfile(idSaveDir,sprintf(saveName,currT)));
        save3DTiff(uint8(polMag.^2*255  + 1),fullfile(pSaveDir,sprintf(pSaveName,currT)));
        save3DTiff(uint8(sqrt(trQQ3_2D)*255 + 1),fullfile(qSaveDir,sprintf(qSaveName,currT)));
    end
    
    % Load motors
    currT = selTimes(tInd);
    if isfile(fullfile(dataDir,sprintf(kif4Data,currT)))
        currKIFs = readtable(fullfile(dataDir,sprintf(kif4Data,currT)));
    else
        continue
    end

    numMotors = size(currKIFs,1);
    
    % Calculate motor lengths, CoMs, and vector lengths
    motorCoords = table2array(currKIFs(:,4:9));
    motorVecs = zeros(numMotors,3);
    motorCoMs = motorVecs;
    for currDim = 1:3
        motorVecs(:,currDim) = motorCoords(:,3+currDim) - motorCoords(:,currDim);
        motorCoMs(:,currDim) = (motorCoords(:,3+currDim) + motorCoords(:,currDim))/2;
    end
    scaledMotorCoMs = motorCoMs*scaleFactor;
    xyMotorLens = sqrt(sum(motorVecs(:,1:2).^2,2));
    motorLens = sqrt(sum(motorVecs.^2,2));

    % Split into free, bound, and cross-linking motors
    xlinkLogic = ~(table2array(currKIFs(:,10) == -1) | table2array(currKIFs(:,11) == -1));
    freeLogic = table2array(currKIFs(:,10) == -1) & table2array(currKIFs(:,11) == -1);
    boundLogic = ~xlinkLogic & ~freeLogic;
    countsXFB(tInd,1) = sum(xlinkLogic);
    countsXFB(tInd,2) = sum(freeLogic);
    countsXFB(tInd,3) = sum(boundLogic);

    xlinkInds = table2array(currKIFs(xlinkLogic,10:11)) + 1;
    G = digraph(xlinkInds(:,1),xlinkInds(:,2));
    graphAdj = conncomp(G);
    groupSizes = groupcounts(graphAdj');
    largeLoops = find(groupSizes > 1);

% load(fullfile(saveDir,sprintf('T%06i_mtProps.mat',currT)));

    % Generate matrix of filaments colored by group ID
    % currFils = double(tiffreadVolume(fullfile(idSaveDir,sprintf(saveName,currT))));
    currFils = filMat;
    groupedFils = zeros(size(currFils));
    for currLoop = 1:numel(largeLoops)
        selGroup = largeLoops(currLoop);
        mtInds = find(graphAdj == selGroup);
        groupedFils = groupedFils + currLoop* ismember(currFils,mtInds);
    end
    groupedFils2D = nonZeroMean(groupedFils,3);

    if ~exist(clusterDir,'dir')
        mkdir(clusterDir);
    end

filamentGroupID = graphAdj; 
save3DTiff(uint8(groupedFils),fullfile(clusterDir,sprintf(clusterName,currT)));
save3DTiff(uint8(groupedFils2D),fullfile(clusterDir,sprintf(['2D_' clusterName],currT)));
save(fullfile(saveDir,sprintf('T%06i_motorProps.mat',currT)),'motorCoords','motorCoMs','motorVecs','motorLens')
save(fullfile(saveDir,sprintf('T%06i_mtProps.mat',currT)),'mtCoords','mtCOMs','mtVecs','mtLens','rawPs3','rawQs3','polMag','trQQ3_2D','filamentGroupID')
end

end





