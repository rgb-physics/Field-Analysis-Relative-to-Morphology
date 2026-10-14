function tests=testConfigBuilders
tests=functiontests(localfunctions);
end
function setupOnce(~)
experiment4Config;
end
function testSourceAndExperiment(t)
source=imagestackio.config.makeSource('Format','custom','Loader',@(f)f*ones(4,5,3), ...
    'Spacing',[2 3 4],'SpacingUnit','um');
e=memoworkflow.config.makeExperiment('DatasetID','test','Frames',[3 1 3], ...
    'Sources',struct('Intensity',source));
verifyEqual(t,e.Frames,[3 1]);
image=memoworkflow.loadSource(e,'Intensity',3);
verifyEqual(t,image.Data,3*ones(4,5,3)); verifyEqual(t,image.Spacing,[2 3 4]);
verifyEqual(t,image.Frame,3);
end
function testInvalidConfiguration(t)
verifyError(t,@()imagestackio.config.makeSource('Format','hdf5','Folder','x','NamePattern','x.h5'), ...
    'imagestackio:SourceConfig');
verifyError(t,@()imagestackio.config.makeSource('Spcing',[1 1 1]),'sharedutilities:Config');
verifyError(t,@()objectrelativeprofiles.config.makeQuery('Name','I','Support','objects'), ...
    'objectrelativeprofiles:QueryConfig');
verifyError(t,@()objectgeometry.config.makeObjectOptions('InputType','indices'), ...
    'objectgeometry:Config');
verifyError(t,@()segmentationtools.config.makeProbabilityOptions('EnsureDisjoint',false), ...
    'segmentationtools:Config');
end
function testCanonicalNamesAndLegacyAliases(t)
source=imagestackio.config.makeSource('Folder','x','NamePattern','f%03i.tif');
legacy=imagestackio.config.makeSource('Folder','x','Pattern','f%03i.tif');
verifyEqual(t,source,legacy); verifyFalse(t,isfield(source,'Pattern'));
verifyError(t,@()imagestackio.config.makeSource('Folder','x', ...
    'NamePattern','a.tif','Pattern','b.tif'),'imagestackio:SourceConfig');
e=memoworkflow.config.makeExperiment('DatasetID','A','Frames',[10 12], ...
    'Sources',struct('Intensity',source),'TimeStep',.5,'TimeUnit','min');
verifyEqual(t,e.TimeStep,.5); verifyEqual(t,e.TimeUnit,'min');
verifyEqual(t,diff(e.Frames)*e.TimeStep,1); % minute separation of selections
verifyFalse(t,isfield(e,'TimeStepSeconds'));
old=memoworkflow.config.makeExperiment('DatasetID','A','Frames',1, ...
    'Sources',struct('Intensity',source),'TimeStepSeconds',30);
verifyEqual(t,old.TimeStep,30); verifyEqual(t,old.TimeUnit,'s');
verifyError(t,@()memoworkflow.config.makeExperiment('DatasetID','A','Frames',1, ...
    'Sources',struct('Intensity',source),'TimeStep',30),'memoworkflow:ExperimentConfig');
verifyError(t,@()memoworkflow.config.makeExperiment('DatasetID','A','Frames',1, ...
    'Sources',struct('Intensity',source),'TimeStep',1,'TimeUnit','min', ...
    'TimeStepSeconds',60),'memoworkflow:ExperimentConfig');
end
function testFileSources(t)
folder=tempname; mkdir(folder);
cleanup=onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
data=uint16(reshape(1:60,4,5,3));
imagestackio.writeTiff(data,fullfile(folder,'frame001.tif'));
s=imagestackio.config.makeSource('Folder',folder,'NamePattern','frame%03i.tif', ...
    'Spacing',[2 3 4],'SpacingUnit','um');
e=memoworkflow.config.makeExperiment('DatasetID','files','Frames',1, ...
    'Sources',struct('Intensity',s));
image=memoworkflow.loadSource(e,'Intensity',1);
verifyEqual(t,image.Data,data); verifyEqual(t,image.Spacing,[2 3 4]);
h5create(fullfile(folder,'frame001.h5'),'/data',[4 5 3 2]);
h5write(fullfile(folder,'frame001.h5'),'/data',cat(4,double(data),2*double(data)));
s=imagestackio.config.makeSource('Format','hdf5','Folder',folder, ...
    'NamePattern','frame%03i.h5','DatasetPath','/data','SourceAxes','YXZC','Channels',2);
e.Sources.Intensity=s;
image=memoworkflow.loadSource(e,'Intensity',1);
verifyEqual(t,image.Data,2*double(data)); verifyEqual(t,image.SelectedChannels,2);
end
function testIdentityAndScalarQueryConsumer(t)
mask=false(5,6,3); mask(2:3,2:4,2)=true;
identity=objectgeometry.config.makeObjectOptions('DatasetID','A','Frame',4,'InputType','mask');
objects=objectgeometry.objects.prepareObjects(mask,identity);
q=objectrelativeprofiles.config.makeQuery('Name','Intensity','Support','objects', ...
    'Field','I','Statistics',{'Mean','Sum'});
result=objectrelativeprofiles.fieldSampling.queryFrame(struct('I',2*ones(size(mask))), ...
    struct('objects',objects),q);
verifyEqual(t,result.Intensity_Mean,2); verifyEqual(t,result.Intensity_Sum,12);
verifyEqual(t,result.Frame,4); verifyEqual(t,string(result.DatasetID),"A");
end
function testMixedQueryConsumer(t)
mask=true(3,4,2); objects=objectgeometry.objects.prepareObjects(mask);
a=objectrelativeprofiles.config.makeQuery('Name','Scalar','Support','objects','Field','X');
b=objectrelativeprofiles.config.makeQuery('Name','Difference','Support','objects', ...
    'Operation',@(fields)fields.X-fields.Y,'Fields',{'X','Y'});
queries=[a b];
r=objectrelativeprofiles.fieldSampling.queryFrame(struct('X',3*ones(size(mask)), ...
    'Y',ones(size(mask))),struct('objects',objects),queries);
verifyEqual(t,r.Scalar_Mean,3); verifyEqual(t,r.Difference_Mean,2);
v=objectrelativeprofiles.config.makeQuery('Name','Velocity','Support','objects', ...
    'Kind','vector','Fields',{'X','Y'});
verifyEqual(t,fieldnames(v),fieldnames(a));
rv=objectrelativeprofiles.fieldSampling.queryFrame(struct('X',3*ones(size(mask)), ...
    'Y',ones(size(mask))),struct('objects',objects),v);
verifyEqual(t,rv.Velocity_MeanVector,[3 1]);
verifyEqual(t,rv.Velocity_MeanMagnitude,sqrt(10),'AbsTol',1e-12);
end
function testSegmentationAndAlias(t)
options=segmentationtools.config.makeIntensityOptions('Method','fixed','Threshold',5);
r=segmentationtools.binarization.segmentIntensity(reshape(1:9,3,3),options);
verifyEqual(t,r.Mask,reshape(1:9,3,3)>5);
a=segmentationtools.config.makeClasses([1 2],.5,struct('Names',{{'inside','outside'}}));
b=segmentationtools.binarization.makeClassConfig([1 2],.5,struct('Names',{{'inside','outside'}}));
verifyEqual(t,a,b);
p=cat(4,.8*ones(3,4,2),.2*ones(3,4,2));
r=segmentationtools.binarization.classifyProbabilities(p,a,segmentationtools.config.makeProbabilityOptions());
verifyEqual(t,r.LabelVolume,ones(3,4,2,'like',r.LabelVolume));
end
function testWorkflow1NamedSource(t)
c=struct('Frames',1,'Supports',{{'objects'}},'GeometrySigma',1, ...
    'ObjectLoader',@(~)true(4,5,3),'ObjectInputType','mask','LocalInertia',false);
here=fileparts(mfilename('fullpath')); repo=fileparts(fileparts(here));
c.OutputRoot=fullfile(repo,'test-data','workflow-results');
c.RepositoryRoot=repo;
source=imagestackio.config.makeSource('Format','custom','Loader',@(~)10*ones(4,5,3), ...
    'Spacing',[2 3 4],'SpacingUnit','nm');
c.Experiment=memoworkflow.config.makeExperiment('DatasetID','new-grid','Frames',1, ...
    'Sources',struct('Intensity',source));
r=workflow1Objects(c);
verifyEqual(t,r.Measurements.PhysicalVolume,60*24);
verifyEqual(t,r.Measurements.IntensityOnobjects_Mean,10);
i=strcmp(r.Measurements.Properties.VariableNames,'PhysicalVolume');
verifyEqual(t,r.Measurements.Properties.VariableUnits{i},'nm^3');
verifyEqual(t,string(r.Measurements.DatasetID),"new-grid");
verifyFalse(t,ismember('IntensityOnobjects_FiniteCount',r.Measurements.Properties.VariableNames));
verifyEqual(t,r.Diagnostics.IntensityOnobjects_FiniteCount,60);
verifyEqual(t,r.Diagnostics(:,{'DatasetID','Frame','ObjectID'}), ...
    r.Measurements(:,{'DatasetID','Frame','ObjectID'}));
saved=load(fullfile(r.Directory,'frame001.mat'));
verifyFalse(t,isfield(saved.result,'Geometry'));
verifyFalse(t,isfield(saved.result,'Supports'));
verifyTrue(t,isfield(saved.result,'Measurements'));
verifyEqual(t,saved.result.Diagnostics.Properties.VariableNames,r.Diagnostics.Properties.VariableNames);
verifyEqual(t,saved.result.Diagnostics.IntensityOnobjects_FiniteCount, ...
    r.Diagnostics.IntensityOnobjects_FiniteCount);
c.IncludeDiagnostics=true;
debug=workflow1Objects(c);
verifyEqual(t,debug.Measurements.IntensityOnobjects_FiniteCount,60);
verifyEqual(t,debug.Measurements.IntensityOnobjects_Mean,r.Measurements.IntensityOnobjects_Mean);
verifyEqual(t,debug.Diagnostics,r.Diagnostics);
verifyEqual(t,width(debug.Measurements)-width(r.Measurements),20);
end

function testWorkflow1SetupMeasurementRequests(t)
here=fileparts(mfilename('fullpath')); repo=fileparts(fileparts(here));
c=struct('Frames',1,'Supports',{{'objects'}},'GeometryOptions',struct(), ...
    'ObjectLoader',@(~)true(4,5,3),'ObjectInputType','mask','LocalInertia',false, ...
    'RepositoryRoot',repo,'OutputRoot',fullfile(repo,'test-data','workflow-results'));
source=imagestackio.config.makeSource('Format','custom', ...
    'Loader',@(~)reshape(1:60,4,5,3),'Spacing',[2 3 4],'SpacingUnit','nm');
c.Experiment=memoworkflow.config.makeExperiment('DatasetID','custom-requests', ...
    'Frames',1,'Sources',struct('Intensity',source));
c.ObjectProperties={'BoundingBox'}; c.PhysicalVolume=false;
c.MeasurementOptions=struct();
c.Queries=objectrelativeprofiles.config.makeQuery('Name','ChosenSignal', ...
    'Field','Intensity','Support','objects','Statistics',{'Max','Quantiles'}, ...
    'Options',struct('Quantiles',[0 1]));
r=workflow1Objects(c);
verifyTrue(t,ismember('BoundingBox',r.Measurements.Properties.VariableNames));
verifyFalse(t,any(ismember({'Volume','Centroid','PhysicalVolume', ...
    'ChosenSignal_Mean','ChosenSignal_Std'},r.Measurements.Properties.VariableNames)));
verifyEqual(t,r.Measurements.ChosenSignal_Max,60);
verifyEqual(t,r.Measurements.ChosenSignal_Quantiles,[1 60]);
verifyEqual(t,r.Diagnostics.ChosenSignal_FiniteCount,60);
c.Queries=[]; c.PhysicalVolume=true;
r=workflow1Objects(c);
verifyEqual(t,r.Measurements.PhysicalVolume,60*24);
verifyFalse(t,ismember('Volume',r.Measurements.Properties.VariableNames));
verifyEqual(t,r.Diagnostics.Properties.VariableNames,{'DatasetID','Frame','ObjectID'});
end
