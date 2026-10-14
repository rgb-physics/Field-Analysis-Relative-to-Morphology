function tests=testWorkflowExamples
tests=functiontests(localfunctions);
end
function setupOnce(t)
folder=fileparts(mfilename('fullpath')); repo=fileparts(fileparts(folder));
for api={'FieldAnalysis','SharedUtilities','ObjectGeometry','ImageStackIO','SegmentationTools','ObjectTracking','ObjectRelativeProfiles','VisualizationTools'}
    addpath(fullfile(repo,'APIs',api{1},'src'));
end
addpath(folder); t.TestData.Config=experiment4Config;
end
function testExplicitReferenceScaling(t)
[a,f]=fieldanalysis.preprocessing.scaleToReferenceTotal(2*ones(3),9);
verifyEqual(t,a,ones(3)); verifyEqual(t,f,.5);
end
function testCorrectionNoHiddenStretch(t)
a=reshape(1:24,[3 4 2]); model=struct('Correction',2*ones(size(a)),'ReferenceTotal',sum(a(:)));
[r,info]=fieldanalysis.preprocessing.applyIlluminationCorrection(a,model);
verifyEqual(t,r,a/2); verifyEqual(t,info.AppliedFactor,1);
[r,info]=fieldanalysis.preprocessing.applyIlluminationCorrection(2*a,model,struct('BleachScale',true));
verifyEqual(t,r,a/2); verifyEqual(t,info.AppliedFactor,.5);
end
function testUniformReferenceAndStream(t)
frames=[];
model=fieldanalysis.preprocessing.fitIlluminationCorrection([1 2 3],@loadReference,struct('FirstSigma',1,'SecondSigma',1));
verifyEqual(t,frames,[1 2 3]);
verifyEqual(t,model.Correction,ones(4,5,3),'AbsTol',1e-12);
    function a=loadReference(frame)
        frames(end+1)=frame; a=10*frame*ones(4,5,3);
    end
end
function testLocalInertiaKnownTensor(t)
a=false(7,7,7); a(4,4,4)=true;
r=objectgeometry.objects.localInertia(a,sub2ind(size(a),4,4,3), ...
    struct('Radius',1,'Sigma',0,'ReturnTensors',true));
verifyEqual(t,r.Tensors,diag([1 1 0]),'AbsTol',1e-12);
verifyEqual(t,r.EigenvalueRatio,0); verifyEqual(t,r.FractionalAnisotropy,1/sqrt(2),'AbsTol',1e-12);
batched=objectgeometry.objects.localInertia(a,[sub2ind(size(a),4,4,3);sub2ind(size(a),4,3,4)], ...
    struct('Radius',1,'Sigma',0,'BatchSize',2));
serial=objectgeometry.objects.localInertia(a,batched.Indices,struct('Radius',1,'Sigma',0,'BatchSize',1));
verifyEqual(t,batched.Eigenvalues,serial.Eigenvalues,'AbsTol',1e-12);
end
function testLocalInertiaSamplingAndEmpty(t)
a=true(5,5,5);
r=objectgeometry.objects.localInertia(a,(1:10)',struct('Radius',1,'Sigma',0,'SampleLimit',3));
verifyEqual(t,nnz(r.Computed),3); verifyTrue(t,all(isnan(r.Eigenvalues(~r.Computed,:)),'all'));
r=objectgeometry.objects.localInertia(a,[],struct('Radius',1,'Sigma',0));
verifySize(t,r.Eigenvalues,[0 3]);
end
function testOutputProtection(t)
c=t.TestData.Config; c.OutputRoot=c.IntensityDirectory;
verifyError(t,@()memoworkflow.newRun(c,'test'),'memoworkflow:OutputLocation');
c=t.TestData.Config; out=memoworkflow.newRun(c,'synthetic-test');
path=fullfile(out,'unique.mat'); memoworkflow.saveNew(path,42);
verifyError(t,@()memoworkflow.saveNew(path,99),'memoworkflow:Exists');
r=load(path); verifyEqual(t,r.result,42);
end
function testSyntheticWorkflow1(t)
c=t.TestData.Config; c.DatasetID='synthetic-workflow'; c.Frames=1; c.Supports={'objects'}; c.ObjectLoader=@(~)localMask;
fixture=memoworkflow.newRun(c,'synthetic-input');
imagestackio.writeTiff(uint16(10*ones(8,9,4)),fullfile(fixture,'t001_illBleachCorr16bit_560.tif'));
c.IntensityDirectory=fixture;
r=workflow1Objects(c);
verifyEqual(t,height(r.Measurements),1); verifyEqual(t,r.Measurements.IntensityOnobjects_Mean,10);
index=strcmp(r.Measurements.Properties.VariableNames,'PhysicalVolume');
verifyEqual(t,r.Measurements.Properties.VariableUnits{index},'um^3');
end
function mask=localMask
mask=false(8,9,4); mask(3:5,3:6,2:3)=true;
end

function testSyntheticWorkflow2CombinedScript(t)
c=localNamedWorkflowFixture;
r=workflow2Filaments(c); % compatibility entry executes combined script's helper
verifyEqual(t,height(r.Filaments),1);
verifyEqual(t,r.Filaments.Frame,1);
verifyEqual(t,double(r.Filaments.RegionClass),1);
verifyTrue(t,isfinite(r.Filaments.BoundaryDistance));
saved=load(fullfile(r.Directory,'frame001.mat'));
verifyTrue(t,isfield(saved.result,'ReferenceInfo'));
verifyFalse(t,isfield(saved.result,'FilamentMask'));
end
function testSyntheticWorkflow3CombinedScript(t)
c=localNamedWorkflowFixture;
c.TrackingFrames=1; c.SeedFrame=1; c.SeedObjectID=[];
c.ExportTrackingTiffs=false; c.RetainMasks=false;
c.ExportMaskedIntensity=false; c.TrackingLabelMode='trajectory';
r=workflow3Lineage(c);
verifyEqual(t,height(r.Tracking.Detections),1);
verifyEqual(t,r.Measurements.Intensity_Mean,17);
verifyEqual(t,r.Measurements.Frame,1);
verifyFalse(t,isfield(r,'HeavyMasks'));
end
function testSyntheticWorkflow4CombinedScript(t)
c=localNamedWorkflowFixture;
c.SpectrumFrames=1; c.SelectedSlices=[2 4]; c.NumBins=4;
c.MeanSubtract=false; c.Window=true; c.Projection='max';
c.CorrelationMode='2d'; c.CorrelationCrossChannel=true;
r=workflow4Spectra(c); saved=load(r.Files{1}); data=saved.result;
verifyEqual(t,numel(data.Slices),2);
verifyEqual(t,data.Projection.Method,'max');
verifyEqual(t,data.Volume.SpacingUnit,'um');
verifyTrue(t,isfield(data,'CrossCorrelation'));
end
function testSyntheticWorkflow5CombinedScript(t)
c=localNamedWorkflowFixture;
c.ProfileReference='boundary'; c.ProfileEdges=-20:2:20;
c.ProfileChannels={'560','647'}; c.GeometrySigma=1;
r=workflow5Profiles(c); saved=load(r.Files{1});
stats=saved.result.Channel560.Statistics;
verifyEqual(t,stats.Mean(isfinite(stats.Mean)),17*ones(nnz(isfinite(stats.Mean)),1));
verifyTrue(t,isfield(saved.result,'Channel647'));
% Optional second argument must also be forwarded through compatibility entry.
filaments=workflow2Filaments(c);
r=workflow5Profiles(c,filaments); saved=load(r.Files{1});
verifyTrue(t,isfield(saved.result,'Alignment'));
end
function c=localNamedWorkflowFixture
c=experiment4Config; c.Frames=1; c.Spacing=[1 1 1]; c.SpacingUnit='um';
inside=false(14,15,10); inside(4:10,5:11,4:7)=true;
wall=imdilate(inside,strel('sphere',1)) & ~inside;
outside=~(inside|wall);
p=cat(4,double(outside),double(wall),double(inside));
probabilityImage=struct('Data',p,'Axes','YXZCT','Spacing',[1 1 1],'SpacingUnit','um');
density=imagestackio.config.makeSource('Format','custom','Loader',@(~)17*ones(size(inside)), ...
    'Spacing',[1 1 1],'SpacingUnit','um');
filaments=imagestackio.config.makeSource('Format','custom','Loader',@(~)ones(size(inside)), ...
    'Spacing',[1 1 1],'SpacingUnit','um');
probabilities=imagestackio.config.makeSource('Format','custom','Loader',@(~)probabilityImage, ...
    'Spacing',[1 1 1],'SpacingUnit','um');
c.Experiment=memoworkflow.config.makeExperiment('DatasetID','synthetic-workflows', ...
    'Frames',1,'TimeStep',2,'TimeUnit','s', ...
    'Sources',struct('Intensity560',density,'Intensity647',filaments,'Probabilities',probabilities));
c.DatasetID=c.Experiment.DatasetID; c.TimeStep=2; c.TimeUnit='s';
filamentMask=false(size(inside)); filamentMask(5:9,7,5:6)=true;
c.FilamentLoader=@(~)filamentMask; c.ObjectLoader=@(~)inside;
c.SemanticChannels=[3 2 1]; c.Thresholds=[.5 .5 .5]; c.OpeningRadius=0;
c.ProfileSigma=1;
end
