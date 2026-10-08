%% Test: given a trajectory ID, make tifs of blobs over time
% Needs totTable (times, objects IDs, trajectory IDs) and structure of
% connected component indices for each time, with object IDs corresponding
% to PixelIdxList order
% 2023-11-21 - 
%% Directory info
% objDir = '<redacted original absolute path>';
objDir = 'Session 56, Exp 1';
totDir = objDir;
objNameForm = 'objIDs_T%06i.mat';           % %i should span time range stored in totTable
totName = 'TimeObjectTrajectory_Table.mat';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 56, Exp 1';
saveNameSub = 'Trajectory 700 and 433';
desTrajIDs = [700 433];

%% Load totTable and identify valid indices
load(fullfile(totDir,totName));
currSaveDir = fullfile(saveDir,saveNameSub);

%% Iterate and save tifs
skippedTimes = tifsOfTraj(totTable,desTrajIDs,objDir,objNameForm,currSaveDir);
