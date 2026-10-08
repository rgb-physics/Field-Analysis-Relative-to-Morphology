% Convert data structures at each time point and concatenate into a single
% structure. Data pre-processing should be done in
% plotFilamentStats_2Dand3D.m
% Rémi Boros - 2023-08-28

%% Data info
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 83';
segSuperDir = fullfile(baseDir,'8 Filament Detection');
rawSuperDir = fullfile(baseDir,'0 Raw Data');
segSubDirForm = 'Analyzed Filament Data';
allSubDirs = (fullfile(segSuperDir,segSubDirForm));
rawSubDirForm = segSubDirForm; allRawDirs = dir(fullfile(rawSuperDir,rawSubDirForm));
objNameForm = 'Filament Statistics %03i.mat';
selFields2D = {'Centroid','Area','MinorAxisLength','MajorAxisLength','Orientation','Slice_Index'};
pixSize = 11*2/60;
timesVec = 1:90;

%% Concatenate and label indices of all requested data
% Super loop over multiple directories/data sets
allrp2D = struct();
currDir = allSubDirs;
% currDir = fullfile(segSuperDir,segSubDir);
% Iterate over data sets in current directory/data set
for objInd = 1:numel(timesVec)
    % Load current data set
    currObj = timesVec(objInd);
    currObjDir = fullfile(currDir,sprintf(objNameForm,currObj));
    if ~isfile(currObjDir)
        continue
    end
    load(currObjDir);
    % Isolate requested fields
    selFieldVals2D = structFields2Cell(rp2D,selFields2D);
    temprp2D = addFieldsStruct(struct(),selFields2D,selFieldVals2D);
    temprp2D = addFieldStruct(temprp2D,'Object_Index',repmat(currObj,numel(rp2D),1));
    % Concatenate data
    if numel(allrp2D) == 1
        allrp2D = temprp2D;
    else
        allrp2D = [allrp2D, temprp2D];
    end    
end

% Differentiate based on data set, then concatenate
allrp2D = addFieldStruct(allrp2D, 'Sub_Dir_Index', repmat(subInd,numel(allrp2D),1));

%% %%%%%%%%%%%%%%%%%%%%%%%%%  ANALYSES  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
% Consider rewriting to have values stored in vectors directly from loaded
% structures (individual)
%% Convert structures to array for analysis (consider storing in cell with key)
sliceInds = [allrp2D.Slice_Index];
objInds = [allrp2D.Object_Index];
subIndsVec = [allrp2D(:).Sub_Dir_Index];
CoMs = vertcat(allrp2D.Centroid)';
allVols = [allrp2D.Area];
allOris = [allrp2D.Orientation];
allThetas = pi/180*allOris;
majAxes = [allrp2D.MajorAxisLength]; minAxes = [allrp2D.MinorAxisLength];
aspectRatio = majAxes./minAxes;
cos2th = cos(2*allThetas);
% Transform the two points (1,0) and (-1,0) s.t. they share orientation of
% appropriate object (stored in Orientation)
backboneXs = CoMs(1,:) + [cos(allThetas); -cos(allThetas)].*majAxes/2;
backboneYs = CoMs(2,:) + [-sin(allThetas); sin(allThetas)].*majAxes/2;

%% Save the above vectors, then clear structs
clear  allrp2D rp2D rp3D temprp2D
save(fullfile(segSuperDir,'Concatenated_2D_Info.mat'),'allOris','allThetas','CoMs',...
    'allVols','sliceInds','objInds','subIndsVec','majAxes','minAxes','backboneXs','backboneYs');


