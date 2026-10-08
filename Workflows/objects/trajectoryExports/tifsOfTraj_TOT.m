function [skippedTimes] = tifsOfTraj_TOT(totTable,desTrajIDs,objDir,objNameForm,saveDir)
%TIFSOFTRAJ_TOT Takes in totTable, a table containing time, object, trajectory
%info, as well as a the ID corresponding to a trajectory that the user
%would like sampled (desTrajID). Matrices are generated from PixelIdxLists
%stored in connected component structure objects, the IDs of which
%correspond to those stored in totTable. One connected component structure
%is expected to be saved for each time point.
%2023-11-21

% Convert to array, get indices of objects in requested trajectories
totMat = table2array(totTable);
logicVec = ismember(totMat(:,3), desTrajIDs);
validIDs = table2array(totTable(logicVec,1:2));

% Iterate and save tifs
if ~exist("saveDir",'dir')
    mkdir(saveDir);
end
objTimes = unique(validIDs(:,1));
for index = 1:numel(objTimes)
    currT = validIDs(index,1);
    currLogic = validIDs(:,1) == index;
    load(fullfile(objDir,sprintf(objNameForm,currT)));
    outTif = consMatLnB(ones(currCC.ImageSize),vertcat(currCC.PixelIdxList{validIDs(currLogic,2)}));
    save3DTiff(uint8(outTif*255),fullfile(saveDir,sprintf('Time%03i.tif',currT)));
end

% A vector of time with no objects within the range defined by trajectories
timeRange = min(objTimes):max(objTimes);
skippedTimes = timeRange(~ismember(timeRange,objTimes));

end

