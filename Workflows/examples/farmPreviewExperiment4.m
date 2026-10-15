function report = farmPreviewExperiment4(c)

%FARMPREVIEWEXPERIMENT4 Header checks and semantic preview before full processing.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', false);

if nargin<1, c = farmExperiment4Config; end
out = farmWorkflowNewRun(c,'preview'); frame = c.Frames(1);
a = farmWorkflowIntensity(c,frame,'560'); b = farmWorkflowIntensity(c,frame,'647');
if ~isequal(size(a),size(b)), error('memoworkflow:Registration','Intensity grids differ.'); end
[regions,info] = farmWorkflowRegions(c,frame,size(a));
report = struct('Directory',out,'Frame',frame,'Size',size(a),'RegionInfo',info, ...
    'Spacing',c.Spacing,'CropMetadata',load(c.CropMetadata));
farmWorkflowSaveNew(fullfile(out,'report.mat'),report);
z = round(size(a,3)/2); f = figure('Visible','off'); cleanup = onCleanup(@()close(f));
subplot(1,3,1); imagesc(a(:,:,z)); axis image; title('560 density');
subplot(1,3,2); imagesc(b(:,:,z)); axis image; title('647 filaments');
subplot(1,3,3); imagesc(regions(:,:,z)); axis image; clim([0 3]); colorbar; title('0 unclassified; 1 inside; 2 wall; 3 outside');
farmFigSaves(f,out,'channel-semantics','png',true);
fprintf('Inspect semantic preview: %s\n',fullfile(out,'channel-semantics.png'));
end
