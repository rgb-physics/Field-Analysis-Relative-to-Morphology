%% Take up from in-on-out segmentations and segmented.characterized MTs
% 2025-04-17 - Rémi Boros

% basestDir = '<redacted original absolute path>';
basestDir = 'Session 88';
subDirs = {'Exp 1', 'Exp 2', 'Exp 3', 'Exp 4 - Rmin Redo', 'Exp 5'};

for dirInd = 1:numel(subDirs)

denseDir = fullfile(basestDir,subDirs{dirInd},'4 Tracked Blobs\In On Out Segmentation');
denseName = 'T%03i_CleanInOnOut.tif';
sparseDir = fullfile(basestDir,subDirs{dirInd},'6 Filament Data');
sparseName = 'Time%06i_threshFils.tif';

selTimes = 1:57;
denseVoxSize = [0.55 0.55 0.7];   % voxel dimensions of dense tifs when loaded below

outInOn = [1 3 2];
denseBnds = [0 255];

selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation'};
selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};
saveCCs = 1;
ccSaveDir = fullfile(sparseDir,'CC Objects');

if ~exist(ccSaveDir,'dir')
    mkdir(ccSaveDir);
end

%% 
% Generate a vector to map values in dense tifs to out/in/on domains
denseVals = outInOn/max(max(outInOn)) .* (abs(diff(denseBnds)));

for tInd = 1:numel(selTimes)

    % Load
    currT = selTimes(tInd);
    currDense = double(tiffreadVolume(fullfile(denseDir,sprintf(denseName,currT))));
    currSparse = logical(tiffreadVolume(fullfile(sparseDir,sprintf(sparseName,currT))));
    
    if tInd == 1
        sparseSize = size(currSparse);
    end
    
    % Prepare dense
    % Rescale dense, if not cubic
    if prod(denseVoxSize/max(denseVoxSize)) ~= 1
        currDense = imresize3(currDense, size(currDense).*denseVoxSize/min(denseVoxSize),'nearest');
    end
    tempVoxSize = repmat(min(denseVoxSize),1,3);
    
    % Get distance transform ons, outs, in
    [distMat,~,~,~,~,keepMat] = distTransFromBoundary(...
        currDense == denseVals(3), currDense == denseVals(1), currDense == denseVals(2), 1);
    
    % Get 2D and 3D field properties from current sparse
    if ~exist(fullfile(ccSaveDir,sprintf('Filament Statistics %03i.mat',currT)),'file')
        [rp3D,rp2D] = storeFilCCs(currSparse);
    else
        load(fullfile(ccSaveDir,sprintf('Filament Statistics %03i.mat',currT)));
    end
    
    % Store matrix indices of CoMs from (x,y,z) centroid coordinates
    rndCoMs = round([rp3D.Centroid]);       % in (x,y,z)/(col, row, page)
    scaledCoMs = rescaleCoords(rndCoMs,size(currSparse),size(currDense));
    comScaledInds = sub2ind(size(currDense),scaledCoMs(:,2),scaledCoMs(:,1),scaledCoMs(:,3));
    comInds = sub2ind(size(currSparse),rndCoMs(:,2),rndCoMs(:,1),rndCoMs(:,3));
    
    % Store deltaR value at each filament CoM; mark if in valid distMat roi
    filDeltaRs = distMat(comScaledInds);
    maskedFils = keepMat(comScaledInds);
    
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
    % allGrads = imresize3_4mat(allGrads,imgSize);
    % Sample dist trans gradient at (rough) filament CoMs
    signFlip = [1 1 1];                    % Flip sign of y (img coords)
    bwGradAtCens = zeros(size([rp3D.Directors]));
    for index = 1:size(allGrads,4)
        currGrad = imgaussfilt3(allGrads(:,:,:,index)*signFlip(index),2);
        bwGradAtCens(:,index) = currGrad(comScaledInds);
    end
    rp3D.('GradsAtCens') = bwGradAtCens;

    save(fullfile(ccSaveDir,sprintf('Filament Statistics %03i.mat',currT)),"rp2D",'rp3D');
end

end



