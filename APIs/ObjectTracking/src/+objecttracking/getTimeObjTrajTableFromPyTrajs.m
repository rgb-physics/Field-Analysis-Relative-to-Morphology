function [totTable] = getTimeObjTrajTableFromPyTrajs(Trajectories)
%GETTRAJOBJTIMETABLEFROMPYTRAJS Takes in Trajectories dictionary from
%python trackpy output with contents 
% ['x', 'y', 'z', 'mass', 'frames', 'trajectory ID', 'object ID']
%and returns an Nx3 table with columns 'Time' 'Object' 'Trajectory'
%corresponding to each object detected by trackpy

% Make time object traj table
%Generate vector of object IDs for each frame from vector of global IDs
allTimes = unique(Trajectories(:,5));
objsPerT = arrayfun(@(x) sum(Trajectories(:,5)==x), allTimes);
cumsumObjsPerT = [0 arrayfun(@(x) sum(objsPerT(1:x)), 1:numel(objsPerT))];
objIDInT = Trajectories(:,7); 
for currT = 1:numel(unique(Trajectories(:,5)))
    currInds = (cumsumObjsPerT(currT) + 1):cumsumObjsPerT(currT+1);
    objIDInT(currInds) = objIDInT(currInds) - cumsumObjsPerT(currT);
end
totTable = table(Trajectories(:,5), objIDInT, Trajectories(:,6),'VariableNames', {'Time', 'Object', 'Trajectory'});

end

