% Convert data structures at each time point and concatenate into a single
% structure. Data pre-processing should be done in
% plotFilamentStats_2Dand3D.m
% Rémi Boros - 2023-08-28; 2025-02-17

%% DO NOT RUN! This has been moved to A_getFilamentStats_2Dand3D.m %%%%%%%%

% %% Data info
% baseDir = 'Session 83';
% segSuperDir = fullfile(baseDir,'8 Filament Detection');
% rawSuperDir = fullfile(baseDir,'0 Raw Data');
% segSubDirForm = 'Analyzed Filament Data';
% dataDir = (fullfile(segSuperDir,segSubDirForm));
% rawSubDirForm = segSubDirForm; allRawDirs = dir(fullfile(rawSuperDir,rawSubDirForm));
% objNameForm = 'Filament Statistics %03i.mat';
% selFields3D = {'Centroid','Volume','PrincipalAxisLength','EigenVectors'};
% pixSize = 11*2/60;
% timesVec = 1:90;
% 
% %% Loop through each time and add aspect ratio/director properties
% for tInd = 1:numel(timesVec)
%     % Load data set
%     currT = timesVec(tInd);
%     currObjDir = fullfile(dataDir,sprintf(objNameForm,currT));    
%     if ~isfile(currObjDir)
%         continue
%     end
%     load(currObjDir);
%     % Make filament properties calculated from regionprops
%     catEVecs = [rp3D.EigenVectors{:}];
%     catEVec1s = catEVecs(1,:);
%     filAligns = reshape(catEVec1s,3,numel(catEVec1s)/3)';
%     filLens = [rp3D.PrincipalAxisLength(:,1)];
%     filOffLens = [rp3D.PrincipalAxisLength(:,2:3)];
%     filARs = filLens./filOffLens(:,1);
% 
%     % Append properties
%     rp3D.('Directors') = filAligns;
%     rp3D.('Lengths') = filLens;
%     rp3D.('AspectRatios') = filARs;
%     save( fullfile(dataDir,sprintf(objNameForm,currT)), 'rp3D');   
% 
% end

