function manifest=workflow3Lineage(c)
%WORKFLOW3LINEAGE Light ancestry plus optional per-frame TIFF/heavy matrices.
if nargin<1, c=experiment4Config; end
out=memoworkflow.newRun(c,'workflow3');
firstImage=memoworkflow.intensity(c,c.TrackingFrames(1),'560'); gridSize=size(firstImage); clear firstImage
tracking=objecttracking.trackOverlaps(c.TrackingFrames,@loadObjects,struct('DatasetID',c.DatasetID));
frameRows=tracking.Detections(tracking.Detections.Frame==c.SeedFrame,:);
if isempty(frameRows), error('memoworkflow:Seed','No detection in seed frame.'); end
if isempty(c.SeedObjectID), [~,largest]=max(frameRows.VoxelCount); seedID=frameRows.ObjectID(largest);
else, seedID=c.SeedObjectID; end
seed=struct('Frame',c.SeedFrame,'ObjectIDs',seedID);
ancestors=objecttracking.selectLineage(tracking,seed,struct('Direction','ancestors'));
descendants=objecttracking.selectLineage(tracking,seed,struct('Direction','descendants'));
seedRow=frameRows(frameRows.ObjectID==seedID,:);
trajectory=tracking.Detections(ismember(tracking.Detections.TrajectoryID,seedRow.TrajectoryID),:);
selected=union(ancestors.Detections.DetectionID,descendants.Detections.DetectionID);
membership=tracking.Detections(ismember(tracking.Detections.DetectionID,selected),:);
tables={}; heavy={};
for frame=unique(membership.Frame)'
    a=memoworkflow.intensity(c,frame,'560'); objects=loadObjects(frame);
    properties=objectgeometry.objects.measureObjects(objects,{'Volume'});
    stats=objectrelativeprofiles.fieldSampling.queryField(a,objects,{'Mean','Sum'},struct('FieldName','Intensity'));
    properties=objectrelativeprofiles.fieldSampling.attachResults(properties,stats);
    properties=objecttracking.attachMembership(properties,tracking.Detections);
    properties=properties(ismember(properties.DetectionID,selected),:);
    properties.PhysicalVolume=properties.Volume*prod(c.Spacing);
    properties=memoworkflow.setColumnUnit(properties,'PhysicalVolume',[c.SpacingUnit '^3']);
    tables{end+1}=properties; %#ok<AGROW>
    if c.ExportTrackingTiffs||c.RetainMasks||c.ExportMaskedIntensity
        rows=tracking.Detections(tracking.Detections.Frame==frame,:);
        mode=validatestring(c.TrackingLabelMode,{'trajectory','object'});
        if strcmp(mode,'object'), rows.TrajectoryID=rows.ObjectID; end
        labels=objecttracking.renderTrackingFrame(objects,rows);
        if strcmp(mode,'object'), selectedIDs=membership.ObjectID(membership.Frame==frame);
        else, selectedIDs=membership.TrajectoryID(membership.Frame==frame); end
        selectionMask=ismember(labels,selectedIDs);
        labels(~selectionMask)=0;
        if c.ExportTrackingTiffs
            if max(labels(:))>65535, error('memoworkflow:IDs','TIFF IDs exceed uint16; use compact export explicitly.'); end
            imagestackio.writeTiff(uint16(labels),fullfile(out,sprintf('selected_%sIDs_t%03i.tif',mode,frame)), ...
                struct('Spacing',c.Spacing,'SpacingUnit','um'));
        end
        if c.ExportMaskedIntensity
            masked=a; masked(~selectionMask)=0;
            imagestackio.writeTiff(masked,fullfile(out,sprintf('selectedIntensity_t%03i.tif',frame)), ...
                struct('Spacing',c.Spacing,'SpacingUnit','um'));
        end
        if c.RetainMasks, heavy{end+1}=struct('Frame',frame,'Mask',selectionMask,'Labels',labels,'LabelMode',mode); end %#ok<AGROW>
    end
end
manifest=struct('Directory',out,'Tracking',tracking,'Seed',seed,'Ancestors',ancestors, ...
    'Descendants',descendants,'Trajectory',trajectory,'Measurements',objectgeometry.objects.concatenateMeasurements(tables));
if c.RetainMasks, manifest.HeavyMasks=heavy; end
memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
f=figure('Visible','off'); cleanup=onCleanup(@()close(f));
subplot(1,2,1);
g=objecttracking.lineageGraph(tracking);
g=subgraph(g,find(ismember(g.Nodes.DetectionID,selected)));
plot(g,'Layout','layered'); title('Selected ancestry and descendants');
subplot(1,2,2); hold on;
t=manifest.Measurements;
for trajectoryID=unique(t.TrajectoryID)'
    rows=t(t.TrajectoryID==trajectoryID,:); rows=sortrows(rows,'Frame');
    plot((rows.Frame-1)*c.TimeStepSeconds/60,rows.Intensity_Mean,'-o');
end
xlabel('Time from frame 1 (min)'); ylabel('Mean corrected intensity');
visualizationtools.export.figSaves(f,out,'lineage-and-measurements','png',true); clear cleanup
fprintf('Workflow 3 outputs: %s\n',out);
    function objects=loadObjects(frame)
        objects=memoworkflow.objects(c,frame,gridSize);
    end
end
