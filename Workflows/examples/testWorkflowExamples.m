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
