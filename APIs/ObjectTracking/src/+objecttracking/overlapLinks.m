function links = overlapLinks(source, target)
%OVERLAPLINKS Count intersecting voxel-label pairs, preserving all ancestry.
% Prepared ObjectGeometry inputs (or masks/labels/index groups prepared by the
% caller) represent one frame each. No centroid matching, dilation or motion
% correction. Same spatial grid dimensions required. Any overlap is accepted.
% Reuses historical intersection -> paired labels -> unique pair workflow,
% adding counts rather than discarding repeated pairs. No dense label arrays.
source=objectgeometry.objects.prepareObjects(source);
target=objectgeometry.objects.prepareObjects(target);
a=source.Grid.Size; b=target.Grid.Size;
if numel(a)==2, a(3)=1; end
if numel(b)==2, b(3)=1; end
if ~isequal(a,b), error('objecttracking:GridMismatch','Overlap frames must share spatial dimensions.'); end
[si,sl]=localVectors(source); [ti,tl]=localVectors(target);
[~,ia,ib]=intersect(si,ti);
if isempty(ia)
    pairs=zeros(0,2); counts=zeros(0,1);
else
    [pairs,~,groups]=unique([sl(ia) tl(ib)],'rows');
    counts=accumarray(groups,1);
end
sourceIDs=source.ObjectIDs; targetIDs=target.ObjectIDs;
sourceVolumes=cellfun(@numel,source.Components.PixelIdxList).';
targetVolumes=cellfun(@numel,target.Components.PixelIdxList).';
[~,s]=ismember(pairs(:,1),sourceIDs); [~,t]=ismember(pairs(:,2),targetIDs);
links=table(pairs(:,1),pairs(:,2),counts,sourceVolumes(s),targetVolumes(t), ...
    'VariableNames',{'SourceObjectID','TargetObjectID','OverlapCount','SourceVoxelCount','TargetVoxelCount'});
links.SourceOverlapFraction=counts./links.SourceVoxelCount;
links.TargetOverlapFraction=counts./links.TargetVoxelCount;
links.IoU=counts./(links.SourceVoxelCount+links.TargetVoxelCount-counts);
end
function [indices,labels]=localVectors(objects)
count=sum(cellfun(@numel,objects.Components.PixelIdxList));
indices=zeros(count,1); labels=zeros(count,1); offset=0;
for i=1:numel(objects.ObjectIDs)
    current=objects.Components.PixelIdxList{i};
    rows=offset+(1:numel(current)); indices(rows)=current(:); labels(rows)=objects.ObjectIDs(i);
    offset=offset+numel(current);
end
if numel(unique(indices))~=numel(indices)
    error('objecttracking:OverlappingObjectGroups','Different object IDs within a frame cannot own the same voxel.');
end
end
