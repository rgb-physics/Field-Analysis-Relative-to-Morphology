function tracking = trackOverlaps(frames, loader, options)
%TRACKOVERLAPS Stream successive supplied frames using overlap inheritance.
% LOADER=@(frame) -> mask, label array, TIFF path or prepared objects.
% Numeric binary input defaults to components; InputType='labels' preserves
% disconnected pieces carrying label 1. Other label IDs are preserved.
% OPTIONS.DatasetID='default'; Identity=struct() prepareObjects options;
% Ranking='overlap'|'volume'; MergePolicy='inherit'|'new'; SplitPolicy likewise;
% ExportDirectory=''; Overwrite=false. Arbitrary spacing/order is accepted.
% Repeated frame numbers are omitted, retaining their first occurrence.
% No missing-detection gap recovery; load failure stops processing.
% Ancestry follows the supplied processing order, including reverse order.
% Ranking volume uses source+target voxel count: largest parent at pure merges
% and largest child at pure splits. For many-to-many events, ranked greedy
% one-to-one inheritance is deterministic (not global assignment optimization).
% Ties: smallest source then target ObjectID. ALL ancestry edges remain saved.
% Assumes modest displacement and spatially registered masks across frames.
if nargin<3, options=struct(); end
options=objectgeometry.internal.options(options,struct('DatasetID','default','Identity',struct(), ...
    'Ranking','overlap','MergePolicy','inherit','SplitPolicy','inherit', ...
    'ExportDirectory','','Overwrite',false));
validateattributes(frames,{'numeric'},{'vector','finite','integer','nonnegative','nonempty'});
frames=unique(double(frames(:)),'stable');
if ~isa(loader,'function_handle'), error('objecttracking:InvalidLoader','Supply @(frame) loader.'); end
options.Ranking=validatestring(options.Ranking,{'overlap','volume'});
options.MergePolicy=validatestring(options.MergePolicy,{'inherit','new'});
options.SplitPolicy=validatestring(options.SplitPolicy,{'inherit','new'});
validateattributes(options.Overwrite,{'logical'},{'scalar'});
dataset=string(options.DatasetID);
if ~isscalar(dataset)||ismissing(dataset)||strlength(dataset)==0, error('objecttracking:DatasetID','Use nonempty scalar DatasetID.'); end
detections=table(strings(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
    'VariableNames',{'DatasetID','Frame','ObjectID','DetectionID','TrajectoryID','VoxelCount'});
links=table(zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1),zeros(0,1), ...
    zeros(0,1),zeros(0,1),zeros(0,1),false(0,1), ...
    'VariableNames',{'SourceDetectionID','TargetDetectionID','SourceFrame','TargetFrame', ...
    'OverlapCount','SourceOverlapFraction','TargetOverlapFraction','IoU','InheritanceChosen'});
events=table(zeros(0,1),zeros(0,1),zeros(0,1),strings(0,1),cell(0,1),cell(0,1), ...
    'VariableNames',{'EventID','SourceFrame','TargetFrame','Type','ParentDetectionIDs','ChildDetectionIDs'});
gridMetadata=cell(numel(frames),1); nextDetection=1; nextTrajectory=1;
for k=1:numel(frames)
    frame=frames(k); input=loader(frame);
    if isstruct(input)&&isfield(input,'ObjectGeometryVersion')
        current=input;
        if current.Frame~=frame||string(current.DatasetID)~=dataset
            error('objecttracking:InputIdentity','Prepared input must match dataset/frame.');
        end
    else
        identity=options.Identity; identity.Frame=frame; identity.DatasetID=dataset;
        current=objectgeometry.objects.prepareObjects(input,identity);
    end
    n=numel(current.ObjectIDs); ids=(nextDetection:nextDetection+n-1).'; nextDetection=nextDetection+n;
    trajectories=zeros(n,1);
    if k==1
        for i=1:n, trajectories(i)=nextTrajectory; nextTrajectory=nextTrajectory+1; end
    else
        evidence=objecttracking.overlapLinks(previous,current);
        [~,s]=ismember(evidence.SourceObjectID,previous.ObjectIDs);
        [~,t]=ismember(evidence.TargetObjectID,current.ObjectIDs);
        outDegree=zeros(numel(previous.ObjectIDs),1); inDegree=zeros(n,1);
        if ~isempty(s)
            outDegree=accumarray(s,1,[numel(previous.ObjectIDs) 1]);
            inDegree=accumarray(t,1,[n 1]);
        end
        eligible=true(height(evidence),1);
        if strcmp(options.MergePolicy,'new'), eligible=eligible & inDegree(t)<=1; end
        if strcmp(options.SplitPolicy,'new'), eligible=eligible & outDegree(s)<=1; end
        if strcmp(options.Ranking,'overlap'), score=evidence.OverlapCount;
        else, score=evidence.SourceVoxelCount+evidence.TargetVoxelCount; end
        [~,order]=sortrows([-score evidence.SourceObjectID evidence.TargetObjectID],[1 2 3]);
        chosen=false(height(evidence),1); used=false(numel(previous.ObjectIDs),1);
        for row=order(:).'
            if eligible(row)&&~used(s(row))&&trajectories(t(row))==0
                trajectories(t(row))=previousTrajectories(s(row)); used(s(row))=true; chosen(row)=true;
            end
        end
        for i=1:n
            if trajectories(i)==0, trajectories(i)=nextTrajectory; nextTrajectory=nextTrajectory+1; end
        end
        pairLinks=table(previousDetectionIDs(s),ids(t),repmat(frames(k-1),height(evidence),1), ...
            repmat(frame,height(evidence),1),evidence.OverlapCount,evidence.SourceOverlapFraction, ...
            evidence.TargetOverlapFraction,evidence.IoU,chosen,'VariableNames',links.Properties.VariableNames);
        links=[links;pairLinks]; %#ok<AGROW>
        % Preserve simple and compound events per connected bipartite component.
        total=numel(previous.ObjectIDs)+n;
        graph=digraph(s,t+numel(previous.ObjectIDs),[],total);
        groups=conncomp(graph,'Type','weak');
        for group=unique(groups)
            parents=find(groups(1:numel(previous.ObjectIDs))==group);
            children=find(groups(numel(previous.ObjectIDs)+1:end)==group);
            if isempty(parents)
                type="appearance";
            elseif isempty(children)
                type="disappearance";
            elseif numel(parents)==1&&numel(children)==1
                type="continuation";
            elseif numel(parents)==1
                type="split";
            elseif numel(children)==1
                type="merge";
            else
                type="merge-split";
            end
            event=table(height(events)+1,frames(k-1),frame,type, ...
                {previousDetectionIDs(parents).'}, {ids(children).'},'VariableNames',events.Properties.VariableNames);
            events=[events;event]; %#ok<AGROW>
        end
    end
    rows=table(repmat(dataset,n,1),repmat(frame,n,1),current.ObjectIDs,ids,trajectories, ...
        cellfun(@numel,current.Components.PixelIdxList).','VariableNames',detections.Properties.VariableNames);
    detections=[detections;rows]; %#ok<AGROW>
    gridMetadata{k}=struct('Frame',frame,'Grid',current.Grid);
    if strlength(string(options.ExportDirectory))>0
        if ~isfolder(options.ExportDirectory), mkdir(options.ExportDirectory); end
        filename=fullfile(options.ExportDirectory,sprintf('trajectory_ids_frame_%09d.tif',frame));
        objecttracking.renderTrackingFrame(current,rows,struct('FilePath',filename,'Overwrite',options.Overwrite));
    end
    previous=current; previousDetectionIDs=ids; previousTrajectories=trajectories;
end
tracking=struct('Detections',detections,'Links',links,'Events',events,'GridMetadata',{gridMetadata}, ...
    'Options',options,'Method','overlap','DatasetID',dataset);
end
