function [currProps, selIDs] = Traj2Props(selTrajs,trajInds,IDConvert,allIDProps)
%TRAJ2PROPS Takes in a scalar vector of tajectory IDs, a vector mapping
%object ID i to trajectory ID stored at trajInds(i), a lookup table of 
% [Local, Global, Replace, Time] IDs, and table of cluster properties.
% Returns properties of clusters with IDs in the queried trajectories
% Rémi Boros - 2024-11-13

% Generate a matrix to search for IDs from selected trajectory
allPropsKey = [allIDProps.Local(:) allIDProps.Time(:)];

% Find IDs that are in the selected trajectory from trajInds
selIDs = find(ismember(trajInds, selTrajs));
% Get LT pairs from selIDs
outPairs = globRepl2LT(IDConvert,selIDs);
% Get cluster property rows for selected trajectory
trajLogic = ismember(allPropsKey,outPairs,'rows');
currProps = allIDProps(trajLogic,:);

end

