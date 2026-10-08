%% Gets segmented filament statistics and saves in appropriate directory(s)

%% Part I - regionprops on filaments
%% 2023-12-05
% This script takes in directory/directories containing .tifs of segmented
% filaments from .h5s. It measures the statistics of said filaments without
% considering statistics from the 3rd dimension
% 2023-11-13 Rémi Boros
% ideally, loads .h5s directly, applies threshold, returns binarized
% objects. Then the script will do statistics
% Filament directory information
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 56, Exp 1';
segDirSuper = fullfile(baseDir,'7 Ilastik Segmentations\Filament Segmentations');
subDirLabel = '*Subbed';
% segSaveSuperDir = '<redacted original absolute path>';
segSaveSuperDir = 'Session 56, Exp 1';
saveDirLabel = '%s';
filH5Query = '*.h5';  filH5String = '/exported_data';
filH5Chans = 2; filH5Thresh = 0.6;
filScaleFacts = [1 1 1]; pixSize = 11*2/60;
selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation'};

binarizeBool = 1; saveBool = 1;

% Iterate through h5 directories, convert contents
dirNames = dir(fullfile(segDirSuper,subDirLabel));
for dirInd = 1:numel(dirNames)
    currDir = fullfile(segDirSuper,dirNames(dirInd).name);
    fileNames = dir(fullfile(currDir,filH5Query));
    % Iterate through each file in the current directory; load and convert
    % to binarized matrix; save, if requested
    for fileInd = 1:numel(fileNames)
        newBool = 1;        % Used to define new storage struct in cases where no objects are observed in first z slice
        [~,currFileName,fileExt] = fileparts(fileNames(fileInd).name);
        currSeg = loadH5(fullfile(currDir,[currFileName fileExt]),filH5String,filH5Chans);
        currMat = h5toTif(currSeg,filScaleFacts,binarizeBool,filH5Thresh,0);
        currSaveDir = sprintf(saveDirLabel,fullfile(segSaveSuperDir,dirNames(dirInd).name));
        if exist(currSaveDir,'dir') == 0
            mkdir(currSaveDir);
        end
        % Save the thresholded segmentation as a tif, if requested
        if saveBool == 1
            save3DTiff(currMat, fullfile(currSaveDir,[currFileName '.tif']));
            fprintf('Saving file %06i...\n',fileInd)
        end
        % Get regionprops in 2D and 3D, store in .mat files for each time
        bwObjs = logical(currMat);
        rp3D = regionprops3(bwObjs, 'Volume','Centroid','Orientation');
        for zInd = 1:size(bwObjs,3)
            curr2D = regionprops(bwObjs(:,:,zInd),selFields2D);
            indexVec = repmat(zInd, size(curr2D,1), 1); %distinguish z
            curr2D = addFieldStruct(curr2D,'Slice_Index',indexVec);
            if (newBool == 1) && ~isempty(curr2D)
                rp2D = curr2D;
                newBool = 0;
            elseif (newBool == 0) && ~isempty(curr2D)
                rp2D = vertcat(rp2D,curr2D);
            end
        end
        save(fullfile(currSaveDir,sprintf('Filament Statistics %03i',fileInd)),"rp2D",'rp3D','filScaleFacts','filH5Thresh','filH5Chans');
    end
end
% At this point, filament/region properties have been saved in individual
% structures for each time point.
%% Part II - convert regionprop stuctures to vectors for fast access
% 2023-11-14 - 2023-11-27
%% Data info
% segSuperDir = '<redacted original absolute path>';
segSuperDir = 'Session 56, Exp 1';
% segSubDir = 'p200_ChamberSide_GaussCorr Segmentations Statistics';
segSubDirForm = '*Gauss Subbed';  allSubDirs = dir(fullfile(segSuperDir,segSubDirForm));
objNameForm = 'Filament Statistics %03i.mat';
selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation','Slice_Index'};

% Concatenate and label indices of all requested data
% Super loop over multiple directories/data sets
allallrp2D = struct();
for subInd = 1:numel(allSubDirs)
    % Concatenate object statistics
    segSubDir = allSubDirs(subInd).name;
    allrp2D = struct();
    currDir = fullfile(segSuperDir,segSubDir);
    % Iterate over data sets in current directory/data set
    for objInd = 1:100
        % Load current data set
        currObjDir = fullfile(currDir,sprintf(objNameForm,objInd));
        if ~isfile(currObjDir)
            continue
        end
        load(currObjDir);
        % Isolate requested fields
        selFieldVals2D = structFields2Cell(rp2D,selFields2D);
        temprp2D = addFieldsStruct(struct(),selFields2D,selFieldVals2D);
        temprp2D = addFieldStruct(temprp2D,'Object_Index',repmat(objInd,numel(rp2D),1));
        % Concatenate data
        if numel(allrp2D) == 1
            allrp2D = temprp2D;
        else
            allrp2D = [allrp2D, temprp2D];
        end    
    end

    % Differentiate based on data set, then concatenate
    allrp2D = addFieldStruct(allrp2D, 'Sub_Dir_Index', repmat(subInd,numel(allrp2D),1));
    if subInd == 1
        allallrp2D = allrp2D;
    else
        allallrp2D = [allallrp2D, allrp2D];
    end
end
% Convert structures to array for analysis (consider storing in cell with key)
sliceInds = [allallrp2D.Slice_Index];
objInds = [allallrp2D.Object_Index];
subIndsVec = [allallrp2D(:).Sub_Dir_Index];
CoMs = vertcat(allallrp2D.Centroid)';
allVols = [allallrp2D.Area];
allOris = [allallrp2D.Orientation];
allThetas = pi/180*allOris;
majAxes = [allallrp2D.MajorAxisLength]; minAxes = [allallrp2D.MinorAxisLength];
aspectRatio = majAxes./minAxes;
cos2th = cos(2*allThetas);
% Transform the two points (1,0) and (-1,0) s.t. they share orientation of
% appropriate object (stored in Orientation)
backboneXs = CoMs(1,:) + [cos(allThetas); -cos(allThetas)].*majAxes/2;
backboneYs = CoMs(2,:) + [-sin(allThetas); sin(allThetas)].*majAxes/2;

% Save the above vectors, then clear structs
clear allallrp2D allrp2D rp2D rp3D temprp2D
save(fullfile(segSuperDir,'Concatenated_2D_Info.mat'),'allOris','allThetas','CoMs',...
    'allVols','sliceInds','objInds','subIndsVec','majAxes','minAxes','backboneXs','backboneYs');

% Vectors of filament properites with z slice and time indices have been
% saved

%% Part III - Query interpolated field data at filament centers
%% Analysis for comparing orientation fields, velocities, and other quants
% This code assumes that PIV data has been saved in the form [x,y,z] rather
% than [row,col,depth]/[y,x,z]. This important is carried out through PIV
% calculation and griddedinterpolant object instantiation. 
% 2023-11-28
% filDataDir = '<redacted original absolute path>';
filDataDir = 'Session 56, Exp 1';
filDataName = 'Concatenated_2D_Info.mat';
% segDir = '<redacted original absolute path>';
segDir = 'Session 56, Exp 1';
segName = 'PassOne_t%03i_16bitSubSamp_Probabilities Stage 2.h5';
% pivDir = '<redacted original absolute path>';
pivDir = 'Session 56, Exp 1';
pivNameForm = 't%03i_pivOUT.mat';
% perimDir = '<redacted original absolute path>';
perimDir = 'Session 56, Exp 1';
perimTifs = 'inOnPerim_t%03i.tif';

% imgSaveDir = 'Session 56, Exp 1';

timeRange = 1:100;
h5chans = [1 2 3];
outInOnChans = [1 2 3];
h5thresh = 0.33;
imgScaling = [1 1 4]/2;
% thetaBinNum = 40;
% rBinNum = 100;
% deltarBounds = [-80 30];

% desColorMap = [250 131 13; 0 0 0; 13 242 250; 255 255 255; 250 131 13]/255;

% Image size
% imgDir = '<redacted original absolute path>';
imgDir = 'Session 56, Exp 1';
sampleImg = tiffreadVolume(fullfile(imgDir,'t003_illBleachCorr16bit.tif'));
imgSize = size(sampleImg); clear sampleImg

% Load filament data and instantiate new variables
load(fullfile(filDataDir,filDataName));
gradxs = zeros(size(majAxes));
gradys = gradxs; gradThetas = gradxs; allAligns = gradxs; deltaRs = gradxs;

% Define logic to select for specific classes of filaments
allVec = ones(size(allVols));
sizeFilt = allVols > 8;         % pixels (allVols)
arFilt = majAxes./minAxes > 1;  % Ratio major/minor axes (aspectRatio)
sliceFilt = allVec;             % slice index   (sliceInds)
lengthFilt = majAxes > 2;       % pixels (majAxes)
generalFilt = sizeFilt & arFilt & sliceFilt & lengthFilt;

% Load piv, orientations, perimeters -> distance transform
for tInd = 1:numel(timeRange)
    currT = timeRange(tInd);
    if mod1b(tInd,10) == 1
        fprintf('Currently analyzing Frame %03i...\n',currT)
    end
    % Load piv and filament info
    % load(fullfile(pivDir,sprintf(pivNameForm,currT)),'allShifts','cenCoords');
    validOris = allOris(objInds == currT);
    % load h5, split into in out on, get gradients from distance transform
    % Consider saving tifs of gradients to avoid having to recalculate from h5s
    [allGrads,distMat] = getDistGrads(fullfile(segDir,sprintf(segName,currT)),h5chans,outInOnChans,h5thresh,imgSize,imgScaling,0);
    if tInd == 1
        scaleDiff = imgSize./size(distMat);
    end

    % Generate interpolation objects for sampling vels and dist. gradients
    % Fields to sample: x,y velocities, x,y dist transf. gradients
    % Define coordinate matrices over which fields are defined
    % velIntObjs = generateVelocityInterpolants(cenCoords,allShifts);
    fullImgCoords = {1:imgSize(2),1:imgSize(1),1:imgSize(3)};
    bwgradIntObjs = generateFieldInterps(fullImgCoords,...
        mat2cell(allGrads,size(allGrads,1),size(allGrads,2),size(allGrads,3),[1 1 1]));
    bwIntObj = generateFieldInterps(fullImgCoords,imresize3(distMat,size(allGrads(:,:,:,1))));
    % clear allGrads
    
    % Select z slice and prepare data
    currFilt = generalFilt & (objInds == currT);
    thetasFromGrads = atan2(allGrads(:,:,:,2),allGrads(:,:,:,1));
    bndgradThetas = bndmod(thetasFromGrads,-pi/2,pi/2);
    
    % Collect gradient orientations at filament centers; compare to filament orientations
    gradThetaObj = generateFieldInterps(fullImgCoords,bndgradThetas);
    gradThetas(currFilt) = gradThetaObj(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
    bwgxInterp = bwgradIntObjs{1};   bwgyInterp = bwgradIntObjs{2};
    gradxs(currFilt) = bwgxInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
    gradys(currFilt) = bwgyInterp(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
    deltaRs(currFilt) = bwIntObj(CoMs(1,currFilt),CoMs(2,currFilt),sliceInds(currFilt));
    
    % Calculate alignment
    allAligns(currFilt) = cos(bndmod(gradThetas(currFilt) - allThetas(currFilt),-pi/2,pi/2));

end
save(fullfile(filDataDir,'FilamentAlignment_AngleData.mat'),'allAligns','gradxs','gradys','gradThetas','deltaRs','generalFilt','imgSize');
