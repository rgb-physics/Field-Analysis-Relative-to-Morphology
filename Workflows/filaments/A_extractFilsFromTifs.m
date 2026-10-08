% Takes in 3D tifs of sparse filaments, applies L.o.G. filter,
% then thresholds filaments
% NOTE: do not rescale images to fill in features on the length-scale of
% your point spread function, ie rescaling voxels to be cubic. This will
% likely bias filament directors by stretching them
% 2025-04-16 - Rémi Boros

% allDirs = {'<redacted original absolute path>',...
allDirs = {'Session 88, Exp 1',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 2',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 3',...
    % '<redacted original absolute path>',...
    'Session 88, Exp 4',...
    % '<redacted original absolute path>'};
    'Session 88, Exp 5'};

for index = 1:numel(allDirs)

baseDir = allDirs{index};
dataDir = fullfile(baseDir,'0 Raw Tifs');
dataName = 'Time%06i_raw647.tif';
saveDir = fullfile(baseDir,'6 Filament Data');
saveName = 'Time%06i_threshFils.tif';

selTimes = 1:60;
voxSize = [2*11/40 2*11/40 0.7];        % in um/pixel
thKern = 1;             % Kernel size for tophat filter
imgScale = 255;         % 255 to save as an 8bit binarized image
threshBnds = 20;        % Note: this is a threshold on the tophat-filtered image
selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation'};
selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};

% Load crop metadata - VERY IMPORTANT TO CROP IF DENSE WAS CROPPED
% Need topleft corner (cropCorner) and final mat dims (winSize)
cropBool = 1;       % crop images? Sparse should be same size as dense
load(fullfile(baseDir,'1 Cropped MATLAB','metadata.mat'));

%% Iterate through files, operate, save
ccSaveDir = fullfile(saveDir,'CC Objects');
if ~exist(saveDir,'dir') || ~exist(ccSaveDir,'dir')
    mkdir(saveDir);
    mkdir(ccSaveDir);
end
% Iterate over time
for tInd = 1:numel(selTimes)
    % Load data - check if file exists
    currT = selTimes(tInd);
    currFile = fullfile(dataDir,sprintf(dataName,currT));
    if ~exist(currFile,'file')
        continue
    end
    currImg = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));
    if cropBool == 1
        currImg = cropTiffSave(currImg, cropCorner, winSize, 0, '');    % This is where you need winSize and cropCorner
    end
    % Tophat filter 
    corrMat = -LOG(currImg,thKern);
    % Threshold
    bwObjs = imbinarize(corrMat,threshBnds);
    % Save thresholded image
    save3DTiff(uint8(255*bwObjs),fullfile(saveDir,sprintf(saveName,currT)));

    % Get regionprops for 3D, store in .mat file
    rp3D = regionprops3(bwObjs, selFields3D);
    % Make filament properties calculated from regionprops
    catEVecs = [rp3D.EigenVectors{:}];
    % EVecs are returned in (row,col,page) form; swap x,y
    % Isolate every third column. Each evec is a column. 1st col is dir.
    catEVecs1 = catEVecs([2 1 3],1:3:end); 
    filDirs = catEVecs1';                   % Convert to rows
    filLens = [rp3D.PrincipalAxisLength(:,1)];
    filOffLens = [rp3D.PrincipalAxisLength(:,2:3)];
    filARs = filLens./filOffLens(:,1);
    % Get indices of filament centroids
    rndCoMs = round([rp3D.Centroid]);       % in (x,y,z)/(col, row, page)
    comInds = sub2ind(size(currImg),rndCoMs(:,2),rndCoMs(:,1),rndCoMs(:,3));
    % Append properties
    rp3D.('Directors') = filDirs;
    rp3D.('Lengths') = filLens;
    rp3D.('AspectRatios') = filARs;
    rp3D.('CoMInds') = comInds;

    % Get regionprops for 2D, store in .mat file
    % Iterate through each Z slice, get 2D stats, store
    newBool = 1;        % Used to define new storage struct in cases where no objects are observed in first z slice
    for zInd = 1:size(bwObjs,3)
        curr2D = regionprops(bwObjs(:,:,zInd),selFields2D);
        IndVecCol = repmat(zInd, size(curr2D,1), 1);
        curr2D = addFieldStruct(curr2D,'Slice_Index',IndVecCol);
        if (newBool == 1) && ~isempty(curr2D)
            rp2D = curr2D;
            newBool = 0;
        elseif (newBool == 0) && ~isempty(curr2D)
            rp2D = vertcat(rp2D,curr2D);
        end
    end
    save(fullfile(ccSaveDir,sprintf('Filament Statistics %03i',currT)),"rp2D",'rp3D');
end
imgSize = size(currImg);
save(fullfile(ccSaveDir,'FilamentDetect_metadata.mat'),"voxSize",'imgSize','threshBnds','thKern','cropCorner','winSize')

end