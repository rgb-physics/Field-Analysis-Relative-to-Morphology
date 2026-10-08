%% From part B of COMBINED_Fils2Aligns_InOnOut.m
% 2026-06-30 - Rémi Boros

% basestDir = '<redacted original absolute path>';
basestDir = 'Session 88';
subDirs = {'Exp 1','Exp 2','Exp 3','Exp 4 - Rmin Redo', 'Exp 5'};

for dirIndex = 1:numel(subDirs)

% segDir = '<redacted original absolute path>';
segDir = 'Session 88';
segName = 't%03i_illCorr8bit_560_E%i_Probabilities Stage 2.h5';
filDir = fullfile(basestDir,subDirs{dirIndex},'6 Filament Data');
filDataDir = fullfile(filDir,'CC Objects');
filDataName = 'Filament Statistics %03i.mat';
saveDir = fullfile(filDir,'AlignmentData');

if ~exist(saveDir,'dir')
    mkdir(saveDir)
end

timeRange = 1:57;
segChans = [1 2 3];
outInOnChans = [1 3 2];
segthresh = 0.33;
ogPixSize = [.55 .55 .7];      % Pixel size of microscope image;
inOnDist = 1;           % 1 to distinguish drop interiors and boundaries, otherwise combine interiors and boundaries and compare to bg
saveDistMats = 0;

%% PART B - Filament Alignments %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

temp = tiffreadVolume(fullfile(filDir,'Time000001_threshFils.tif'));
imgSize = size(temp);

% Iterate over time
for tInd = 1:numel(timeRange)

    % Load filament data
    currT = timeRange(tInd);
    load(fullfile(filDataDir,sprintf(filDataName,currT)),'rp3D');
% Load .h5 and calculate perimeter, distance transform, etc.
    % load h5, split into in out on, get gradients from distance transform
    % Consider saving tifs of gradients to avoid having to recalculate from h5s
    % Load the h5
    currH5 = loadH5(fullfile(segDir,sprintf(segName,currT,dirIndex)),'/exported_data',segChans);
    segSize = size(currH5);
    segPixSize = (imgSize./segSize(1:3)).*ogPixSize;
    cubicVoxelsSegSize = round(segSize(1:3).*segPixSize);
    % Separate into ins, outs, ons
    [cleanIns,cleanOuts,cleanOns] = h5toSmooth3Chans(...
        imresize3_4mat(currH5, cubicVoxelsSegSize),outInOnChans,segthresh,1,1);
    % Calculate the distance transform
    if inOnDist == 1
        [distMat,~,~,~,~,keepMat] = distTransFromBoundary(cleanOns, cleanOuts, cleanIns, 1);
    else
        [distMat,~,~,~,~,keepMat] = distTransFromBoundary(cleanOns|cleanIns, cleanOuts, false(size(cleanIns)), 1);
    end
    % Save, if requested
    if saveDistMats == 1
        if ~exist(bwSaveDir,'dir')
            mkdir(bwSaveDir)
        end
        save(fullfile(bwSaveDir,sprintf(bwSaveName,currT)),'distMat');
        if tInd == 1
            save(fullfile(bwSaveDir,'metadata.mat'),'segDir','segChans','segPixSize','ogPixSize')
        end
    end

    % Resize the distance transform and ignore matrix
    rescaledDistMat = imresize3(distMat,imgSize,'nearest');
    rescaledIgnoreMat = imresize3(~keepMat,imgSize,'nearest');

    % Store matrix indices of CoMs from (x,y,z) centroid coordinates
    rndCoMs = round([rp3D.Centroid]);       % in (x,y,z)/(col, row, page)
    comInds = sub2ind(imgSize,rndCoMs(:,2),rndCoMs(:,1),rndCoMs(:,3));

    % Store deltaR value at each filament CoM; mark if in valid distMat roi
    filDeltaRs = rescaledDistMat(comInds);
    maskedFils = rescaledIgnoreMat(comInds);

    % Add index and filter data to rp3D
    rp3D.('CoMInds') = comInds;
    rp3D.('MaskedInds') = maskedFils;
    rp3D.('DeltaR') = filDeltaRs;

% Get surface gradients, surface normals, sample at filament CoMs
    % Take the gradient of the distance transform
    [gradx,grady,gradz] = gradient(distMat);
    allGrads = zeros([size(gradx) 3]);
    allGrads(:,:,:,1) = gradx; allGrads(:,:,:,2) = grady; allGrads(:,:,:,3) = gradz;
    % Rescale gradients to img dimensions
    allGrads = imresize3_4mat(allGrads,imgSize);
    % Sample dist trans gradient at (rough) filament CoMs
    signFlip = [1 1 1];                    % Flip sign of y (img coords)
    bwGradAtCens = zeros(size([rp3D.Directors]));
    for index = 1:size(allGrads,4)
        currGrad = imgaussfilt3(allGrads(:,:,:,index)*signFlip(index),2);
        bwGradAtCens(:,index) = currGrad(comInds);
    end

% Calc dot prod between filament and local gradient orientations
    % Load filament alignment vectors
    filDirs = [rp3D.Directors];

    % Define dot-product and get angle difference in 3D   
    vDim = 3;
    filAligns3D  = getUnitVecs(filDirs(:,1:vDim));
    grads3D = getUnitVecs(bwGradAtCens(:,1:vDim)); 
    dotFN3D = dot(filAligns3D,grads3D,2);
    dotFN3D = sqrt(dotFN3D.^2);
    thetaFN3D = acos(dotFN3D);

    % Define dot-product and get angle difference in 2D   
    vDim = 2;
    filAligns2D  = getUnitVecs(filDirs(:,1:vDim));
    grads2D = getUnitVecs(bwGradAtCens(:,1:vDim));
    dotFN2D = dot(filAligns2D,grads2D,2);
    dotFN2D = sqrt(dotFN2D.^2);
    thetaFN2D = acos(dotFN2D);

    % Order parameters: cos^2(theta) - 0.5
    order3D = dotFN3D.^2 - 0.5;
    order2D = dotFN2D.^2 - 0.5;

% Save
    save(fullfile(saveDir,sprintf('Time%03i_alignData.mat',currT)),...
        'dotFN3D','thetaFN3D','dotFN2D','thetaFN2D','bwGradAtCens','filDirs','signFlip','order3D','order2D');
    save(fullfile(filDataDir,sprintf(filDataName,currT)),'rp3D','-append');
end

end
