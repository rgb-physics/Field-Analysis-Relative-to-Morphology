function [labels, map] = farmRenderTrackingFrame(objects, membership, options)
%FARMRENDERTRACKINGFRAME Optional trajectory labels; no scientific mask changes.
% OPTIONS.FilePath=''; Overwrite=false; CompactIDs=false. TIFF writers support
% uint16; larger trajectories error unless CompactIDs=true. Compact rendering
% returns/stores a map from StoredID to TrajectoryID; never silently truncates.
% Input membership must match dataset/frame and cover every current ObjectID.
if nargin<3, options = struct(); end
options = farmOGOptions(options,struct('FilePath','','Overwrite',false,'CompactIDs',false));
objects = farmPrepareObjects(objects);
if any(membership.Frame~=objects.Frame)||any(membership.DatasetID~=string(objects.DatasetID))
    error('objecttracking:MembershipFrame','Membership must match the spatial frame/dataset.');
end
if height(unique(membership(:,{'DatasetID','Frame','ObjectID'})))~=height(membership)
    error('objecttracking:DuplicateMembership','Duplicate frame-local identities.');
end
[found,position] = ismember(objects.ObjectIDs,membership.ObjectID);
if any(~found), error('objecttracking:MissingMembership','An object has no trajectory assignment.'); end
trajectory = membership.TrajectoryID(position);
validateattributes(trajectory,{'numeric'},{'real','finite','integer','positive','<=',flintmax});
uniqueIDs = unique(trajectory); stored = uniqueIDs;
if options.CompactIDs, stored = (1:numel(uniqueIDs)).'; end
map = table(stored,uniqueIDs,'VariableNames',{'StoredID','TrajectoryID'});
[~,mapping] = ismember(trajectory,uniqueIDs);
labels = zeros(objects.Grid.Size);
for i = 1:numel(objects.ObjectIDs), labels(objects.Components.PixelIdxList{i}) = stored(mapping(i)); end
if strlength(string(options.FilePath))>0
    if any(stored>65535), error('objecttracking:TiffRange','TIFF IDs exceed uint16; use explicit CompactIDs and keep its map.'); end
    farmWriteTiff(uint16(labels),options.FilePath,struct('Overwrite',options.Overwrite, ...
        'Spacing',objects.Grid.Spacing,'SpacingUnit',objects.Grid.SpacingUnit));
    if options.CompactIDs, save([char(options.FilePath) '.ids.mat'],'map'); end
end
end
