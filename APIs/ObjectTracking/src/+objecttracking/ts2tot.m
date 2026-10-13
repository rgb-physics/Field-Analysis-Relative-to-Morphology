function totTable = ts2tot(trajStruct,fieldNames)
%TS2TOT Historical output columns, with stable IDs for upgraded structures.
if nargin<2, fieldNames={'objIDs','Frames'}; end
allIDs=zeros(0,1); allFrames=zeros(0,1); trajectory=zeros(0,1);
for i=1:numel(trajStruct)
    ids=trajStruct(i).(fieldNames{1}); frames=trajStruct(i).(fieldNames{2});
    if numel(ids)~=numel(frames), error('objecttracking:StructureRows','IDs and frames must have equal lengths.'); end
    id=i; if isfield(trajStruct,'TrajectoryID'), id=trajStruct(i).TrajectoryID; end
    allIDs=[allIDs;ids(:)]; allFrames=[allFrames;frames(:)]; %#ok<AGROW>
    trajectory=[trajectory;repmat(id,numel(ids),1)]; %#ok<AGROW>
end
[Time,order]=sort(allFrames); ObjectID=allIDs(order); Trajectory=trajectory(order);
totTable=table(Time,ObjectID,Trajectory);
end
