%% Directory info
% motherDir = '<redacted original absolute path>';
motherDir = 'Session 35, Exp 1';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 35, Exp 1';
dataNameForm = 'storageStruct_cropped.mat';
load(fullfile(motherDir, dataNameForm));
minTrajLength = 4;
saveName = 'MAT2PY_%iMinTrajLen.mat';
% Max dist trackpy

%% Generate matrix
% Trackpy reads in a namba DataFrame with the following fields as headers
% x y (z) mass size ecc signal raw_mass ep frame particle
% z can be dropped for 2D data; as I have it formatted, Centroids contains
% an Nx3 array of coordinates, so simply feeding an Nx2 array here will
% work fine. I set all "unimportant" distinguishers to 1 by default
pyMat = mat2pyTrackMat(storeStruct);

%% Generate trajectories using python script
Trajectories = double(pyrunfile("cens2TrajsSimple.py", "trajData", dataMat = pyMat, cutOffDist = 8, memoryWindow = 3));
% An object named Trajectories should be loaded with columns corresponding
% to [x, y, z, mass, time, trajectoryId, objectID] (one-indexed)

%% Make time object traj table
totTable = getTrajObjTimeTableFromPyTrajs(Trajectories);

%% Save trajectory structure with each index correesponding to single traj
trajStruct = tot2ts(table2array(totTable),minTrajLength);

%% Save trajectories structure
save(fullfile(saveDir, 'Ordered_Trajectories_Struct.mat'), 'trajStruct');
save(fullfile(saveDir, 'TimeObjectTrajectory_Table.mat'), 'totTable');

% 
% %% Get IDs of each object who's traj ends in a frame
% trajEndStruct = struct();
% for currTrajID = 1:numel(trajStruct)
%     currTraj = trajStruct(currTrajID).TrajInds;
%     if currTraj(end,2) < timeRange(end)
%         trajEndStruct(currTrajID).trajID = currTrajID;
%         trajEndStruct(currTrajID).objID = currTraj(end,1);
%         trajEndStruct(currTrajID).endTime = currTraj(end,2);
%     end
% end
% Have to iterate through each time pair and attempt to stitch; can turn to
% python with a series of matrices for each consecutive time pair
