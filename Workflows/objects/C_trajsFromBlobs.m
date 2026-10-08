%% Generate tracks from parsed blobs
% Takes in storeStruct with fields Vol and Cens and FrameNum corresponding 
% to object volumes and centroids and the frame. Returns a table totTable 
% with time, object, and trajectory information to be used as a map. 
% If the fields have custom names, define customFields, a cell array with
% three comma-separated strings corresponding to volume, centroid, and
% frame field names to access in storeStruct

% Dir info
% structDir = '<redacted original absolute path>';
structDir = 'Session 56, Exp 1';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';
dataNameForm = 'storageStruct.mat';
totSaveName = 'TimeObjectTrajectory_Table.mat';
load(fullfile(structDir, dataNameForm));

% Variables
coDist = 6;             %radius of neighborhood in which to look for trajectories (pixels)
memWin = 2;             %number of frames objects can "dissapear" for while still being considered part of the same trajectory
minTrajLength = 4;      %Minimum length of trajectory

% Cutoff parameters
cutOffBool = 0;
cutOffField = 'Volume';
minCut = 0;
maxCut = 65628640;
fieldsToUpdate = {'Volume', 'Centroid'};
customFields = {'Volume','Centroid','FrameNum'};

%% Apply cut offs, if desired
if cutOffBool == 1
    storeStruct = structCutOffThresh(storeStruct, cutOffField, minCut, maxCut, fieldsToUpdate);
end

%% Calculate trajectories
[trajStruct,totTable] = generateTracksFromStoreStruct(storeStruct,minTrajLength, coDist, memWin,customFields);

%% Save trajectories structure
save(fullfile(saveDir, 'TrajectoryInds_C.mat'), 'trajStruct');
save(fullfile(saveDir, totSaveName), 'totTable');
