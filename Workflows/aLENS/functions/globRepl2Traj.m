function [outInds,boundedIDs] = globRepl2Traj(inIDs,graphObj)
%GLOBREPL2TRAJ Super specialized easy function: given a collection of
%Global/Replace object IDs and a graph object containing them, return
%trajectories in which they are found.
% Rémi Boros - 2024-11-14

ID2Traj = conncompDG(graphObj);  
boundedIDs = inIDs(inIDs <= numel(ID2Traj));
[sharedLogic, sharedInds] = (ismember(ID2Traj,boundedIDs));
outInds = boundedIDs(sharedInds(sharedLogic));

end

