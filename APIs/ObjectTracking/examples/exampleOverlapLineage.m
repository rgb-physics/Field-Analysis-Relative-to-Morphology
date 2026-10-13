%% Synthetic network -> splitting objects -> merge, no Python needed
folder=fileparts(mfilename('fullpath')); root=fullfile(folder,'..','..','..');
for api={'ObjectTracking','ObjectGeometry','ImageStackIO','SharedUtilities'}
    addpath(fullfile(root,'APIs',api{1},'src'));
end
frames=cell(1,4);
frames{1}=10*ones(12,16);
frames{2}=zeros(12,16); frames{2}(:,1:8)=11; frames{2}(:,9:16)=22;
frames{3}=zeros(12,16); frames{3}(:,1:4)=31; frames{3}(:,5:8)=32;
frames{3}(:,9:12)=51; frames{3}(:,13:16)=61;
frames{4}=zeros(12,16); frames{4}(:,1:8)=70; frames{4}(:,9:16)=80;
tracking=objecttracking.trackOverlaps(1:4,@(frame) frames{frame});
history=objecttracking.selectLineage(tracking,struct('ObjectIDs',61,'Frame',3));
disp(history.Detections); disp(tracking.Events);
figure; plot(objecttracking.lineageGraph(tracking),'NodeLabel', ...
    string(tracking.Detections.DetectionID)); title('Directed detection ancestry');
% Field sampling can use history.Detections to select each frame's objects.
outputDirectory=tempname; mkdir(outputDirectory);
for frame=1:4
    objects=objectgeometry.objects.prepareObjects(frames{frame},struct('Frame',frame));
    rows=tracking.Detections(tracking.Detections.Frame==frame,:);
    objecttracking.renderTrackingFrame(objects,rows, ...
        struct('FilePath',fullfile(outputDirectory,sprintf('frame_%03d.tif',frame))));
end
save(fullfile(outputDirectory,'tracking.mat'),'tracking','history');
fprintf('Example outputs: %s\n',outputDirectory);
