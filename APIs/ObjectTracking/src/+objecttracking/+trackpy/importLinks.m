function membership = importLinks(linkedRows, map)
%IMPORTLINKS Python [RowID TrajectoryID] -> original identities, any row order.
% Both IDs must already be one-based. Every exported row must be returned once.
validateattributes(linkedRows,{'numeric'},{'real','finite','2d','integer','positive'});
if size(linkedRows,2)~=2||size(linkedRows,1)~=height(map)
    error('objecttracking:TrackpyRows','Expected one [RowID TrajectoryID] row per exported detection.');
end
if numel(unique(linkedRows(:,1)))~=height(map), error('objecttracking:TrackpyRows','Duplicate returned row IDs.'); end
[found,position]=ismember(map.RowID,linkedRows(:,1));
if any(~found), error('objecttracking:TrackpyRows','Missing exported row identity.'); end
membership=map(:,{'DatasetID','Frame','ObjectID'});
membership.DetectionID=map.RowID; membership.TrajectoryID=linkedRows(position,2);
if height(unique(membership(:,{'DatasetID','Frame','TrajectoryID'})))~=height(membership)
    error('objecttracking:TrackpyBranch','Position tracking cannot assign two detections to one trajectory in the same frame.');
end
end
