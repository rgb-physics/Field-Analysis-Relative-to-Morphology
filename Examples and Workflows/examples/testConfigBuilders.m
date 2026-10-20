function tests = testConfigBuilders

farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

tests = functiontests(localfunctions);
end
function setupOnce(~)
farmExperiment4Config;
end
function testSourceAndExperiment(t)
source = farmMakeSource('Format','custom','Loader',@(f)f*ones(4,5,3), ...
    'Spacing',[2 3 4],'SpacingUnit','um');
e = farmMakeExperiment('DatasetID','test','Frames',[3 1 3], ...
    'Sources',struct('Intensity',source));
verifyEqual(t,e.Frames,[3 1]);
image = farmLoadSource(e,'Intensity',3);
verifyEqual(t,image.Data,3*ones(4,5,3)); verifyEqual(t,image.Spacing,[2 3 4]);
verifyEqual(t,image.Frame,3);
end
function testInvalidConfiguration(t)
verifyError(t,@()farmMakeSource('Format','hdf5','Folder','x','NamePattern','x.h5'), ...
    'imagestackio:SourceConfig');
verifyError(t,@()farmMakeSource('Spcing',[1 1 1]),'sharedutilities:Config');
verifyError(t,@()farmMakeQuery('Name','I','Support','objects'), ...
    'objectrelativeprofiles:QueryConfig');
verifyError(t,@()farmMakeObjectOptions('InputType','indices'), ...
    'objectgeometry:Config');
verifyError(t,@()farmMakeProbabilityOptions('EnsureDisjoint',false), ...
    'segmentationtools:Config');
end
function testCanonicalNamesAndLegacyAliases(t)
source = farmMakeSource('Folder','x','NamePattern','f%03i.tif');
legacy = farmMakeSource('Folder','x','Pattern','f%03i.tif');
verifyEqual(t,source,legacy); verifyFalse(t,isfield(source,'Pattern'));
verifyError(t,@()farmMakeSource('Folder','x', ...
    'NamePattern','a.tif','Pattern','b.tif'),'imagestackio:SourceConfig');
e = farmMakeExperiment('DatasetID','A','Frames',[10 12], ...
    'Sources',struct('Intensity',source),'TimeStep',.5,'TimeUnit','min');
verifyEqual(t,e.TimeStep,.5); verifyEqual(t,e.TimeUnit,'min');
verifyEqual(t,diff(e.Frames)*e.TimeStep,1); % minute separation of selections
verifyFalse(t,isfield(e,'TimeStepSeconds'));
old = farmMakeExperiment('DatasetID','A','Frames',1, ...
    'Sources',struct('Intensity',source),'TimeStepSeconds',30);
verifyEqual(t,old.TimeStep,30); verifyEqual(t,old.TimeUnit,'s');
timing = farmMakeExperiment('DatasetID','A','Frames',1, ...
    'Sources',struct('Intensity',source),'TimeStep',30);
verifyEqual(t,timing.TimeStep,30); verifyEqual(t,timing.TimeUnit,'frame');
timing = farmMakeExperiment('DatasetID','A','Frames',1, ...
    'Sources',struct('Intensity',source),'TimeUnit','min');
verifyEqual(t,timing.TimeStep,1); verifyEqual(t,timing.TimeUnit,'min');
timing = farmMakeExperiment('DatasetID','A','Frames',1, ...
    'Sources',struct('Intensity',source));
verifyEqual(t,timing.TimeStep,1); verifyEqual(t,timing.TimeUnit,'frame');
verifyError(t,@()farmMakeExperiment('DatasetID','A','Frames',1, ...
    'Sources',struct('Intensity',source),'TimeStep',1,'TimeUnit','min', ...
    'TimeStepSeconds',60),'memoworkflow:ExperimentConfig');
end
function testIndependentMetadataAndSamplingOptions(t)
source = farmMakeSource('Folder','x','NamePattern','x.tif','Spacing',[2 3 4]);
verifyEqual(t,source.SpacingUnit,'pixel');
source = farmMakeSource('Folder','x','NamePattern','x.tif','SpacingUnit','um');
verifyEqual(t,source.Spacing,[1 1 1]);
identity = farmMakeObjectOptions('Frame',9);
verifyEqual(t,identity.DatasetID,'default');
identity = farmMakeObjectOptions('DatasetID','A');
verifyEqual(t,identity.Frame,1);
identity = farmMakeObjectOptions('ObjectIDs',42);
objects = farmPrepareObjects(true(4,5),identity);
labels = farmGeometryToMatrix(objects,'OutputType','labels');
verifyTrue(t,all(labels(:)==42)); % no ObjectIDs selection required for labels
mask = farmGeometryToMatrix(objects,'ObjectIDs',42);
verifyClass(t,mask,'logical'); % no OutputType needed for selection
[~,grid] = farmPointsToMatrix([2 2],struct('Size',[4 5]));
verifyEqual(t,grid.Axes,'YX'); verifyEqual(t,grid.Spacing,[1 1]);
verifyEqual(t,grid.SpacingUnit,'pixel');
field = reshape(1:20,4,5);
a = farmQueryField(field,objects,{'Histogram'}, ...
    struct('NumBins',3));
b = farmQueryField(field,objects,{'Histogram'}, ...
    struct('BinEdges',[0 10 20]));
verifyEqual(t,sum(a.Field_Histogram{1}.Counts),20);
verifyEqual(t,b.Field_Histogram{1}.Counts,[9 11]);
mask = farmPointsToMatrix([2 2],grid,'Threshold',.5);
verifyEqual(t,nnz(mask),1); % Threshold alone; Sigma alone is tested in geometry suite
tracking = farmTrackOverlaps(1,@(~)true(4,5));
selection = farmSelectLineage(tracking,struct('DetectionIDs',1));
verifyEqual(t,height(selection.Detections),1);
selection = farmSelectLineage(tracking,struct('TrajectoryIDs',1));
verifyEqual(t,height(selection.Detections),1);
end
function testFileSources(t)
folder = tempname; mkdir(folder);
cleanup = onCleanup(@()rmdir(folder,'s')); %#ok<NASGU>
data = uint16(reshape(1:60,4,5,3));
farmWriteTiff(data,fullfile(folder,'frame001.tif'));
s = farmMakeSource('Folder',folder,'NamePattern','frame%03i.tif', ...
    'Spacing',[2 3 4],'SpacingUnit','um');
e = farmMakeExperiment('DatasetID','files','Frames',1, ...
    'Sources',struct('Intensity',s));
image = farmLoadSource(e,'Intensity',1);
verifyEqual(t,image.Data,data); verifyEqual(t,image.Spacing,[2 3 4]);
h5create(fullfile(folder,'frame001.h5'),'/data',[4 5 3 2]);
h5write(fullfile(folder,'frame001.h5'),'/data',cat(4,double(data),2*double(data)));
s = farmMakeSource('Format','hdf5','Folder',folder, ...
    'NamePattern','frame%03i.h5','DatasetPath','/data','SourceAxes','YXZC','Channels',2);
e.Sources.Intensity = s;
image = farmLoadSource(e,'Intensity',1);
verifyEqual(t,image.Data,2*double(data)); verifyEqual(t,image.SelectedChannels,2);
end
function testIdentityAndScalarQueryConsumer(t)
mask = false(5,6,3); mask(2:3,2:4,2) = true;
identity = farmMakeObjectOptions('DatasetID','A','Frame',4,'InputType','mask');
objects = farmPrepareObjects(mask,identity);
q = farmMakeQuery('Name','Intensity','Support','objects', ...
    'Field','I','Statistics',{'Mean','Sum'});
result = farmQueryFrame(struct('I',2*ones(size(mask))), ...
    struct('objects',objects),q);
verifyEqual(t,result.Intensity_Mean,2); verifyEqual(t,result.Intensity_Sum,12);
verifyEqual(t,result.Frame,4); verifyEqual(t,string(result.DatasetID),"A");
end
function testMixedQueryConsumer(t)
mask = true(3,4,2); objects = farmPrepareObjects(mask);
a = farmMakeQuery('Name','Scalar','Support','objects','Field','X');
b = farmMakeQuery('Name','Difference','Support','objects', ...
    'Operation',@(fields)fields.X-fields.Y,'Fields',{'X','Y'});
queries = [a b];
r = farmQueryFrame(struct('X',3*ones(size(mask)), ...
    'Y',ones(size(mask))),struct('objects',objects),queries);
verifyEqual(t,r.Scalar_Mean,3); verifyEqual(t,r.Difference_Mean,2);
v = farmMakeQuery('Name','Velocity','Support','objects', ...
    'Kind','vector','Fields',{'X','Y'});
verifyEqual(t,fieldnames(v),fieldnames(a));
rv = farmQueryFrame(struct('X',3*ones(size(mask)), ...
    'Y',ones(size(mask))),struct('objects',objects),v);
verifyEqual(t,rv.Velocity_MeanVector,[3 1]);
verifyEqual(t,rv.Velocity_MeanMagnitude,sqrt(10),'AbsTol',1e-12);
end
function testSegmentationAndAlias(t)
options = farmMakeIntensityOptions('Method','fixed','Threshold',5);
r = farmSegmentIntensity(reshape(1:9,3,3),options);
verifyEqual(t,r.Mask,reshape(1:9,3,3)>5);
a = farmMakeClasses([1 2],.5,struct('Names',{{'inside','outside'}}));
b = farmMakeClasses([1 2],.5,struct('Names',{{'inside','outside'}}));
verifyEqual(t,a,b);
p = cat(4,.8*ones(3,4,2),.2*ones(3,4,2));
r = farmClassifyProbabilities(p,a,farmMakeProbabilityOptions());
verifyEqual(t,r.LabelVolume,ones(3,4,2,'like',r.LabelVolume));
end
function testWorkflow1NamedSource(t)
c = struct('Frames',1,'Supports',{{'objects'}},'GeometrySigma',1, ...
    'ObjectLoader',@(~)true(4,5,3),'ObjectInputType','mask','LocalInertia',false);
here = fileparts(mfilename('fullpath')); repo = fileparts(fileparts(here));
c.OutputRoot = fullfile(repo,'tests', 'data','workflow-results');
c.RepositoryRoot = repo;
source = farmMakeSource('Format','custom','Loader',@(~)10*ones(4,5,3), ...
    'Spacing',[2 3 4],'SpacingUnit','nm');
c.Experiment = farmMakeExperiment('DatasetID','new-grid','Frames',1, ...
    'Sources',struct('Intensity',source));
r = farmWorkflow1Objects(c);
verifyEqual(t,r.Measurements.PhysicalVolume,60*24);
verifyEqual(t,r.Measurements.IntensityOnobjects_Mean,10);
i = strcmp(r.Measurements.Properties.VariableNames,'PhysicalVolume');
verifyEqual(t,r.Measurements.Properties.VariableUnits{i},'nm^3');
verifyEqual(t,string(r.Measurements.DatasetID),"new-grid");
verifyFalse(t,ismember('IntensityOnobjects_FiniteCount',r.Measurements.Properties.VariableNames));
verifyEqual(t,r.Diagnostics.IntensityOnobjects_FiniteCount,60);
verifyEqual(t,r.Diagnostics(:,{'DatasetID','Frame','ObjectID'}), ...
    r.Measurements(:,{'DatasetID','Frame','ObjectID'}));
saved = load(fullfile(r.Directory,'frame001.mat'));
verifyFalse(t,isfield(saved.result,'Geometry'));
verifyFalse(t,isfield(saved.result,'Supports'));
verifyTrue(t,isfield(saved.result,'Measurements'));
verifyEqual(t,saved.result.Diagnostics.Properties.VariableNames,r.Diagnostics.Properties.VariableNames);
verifyEqual(t,saved.result.Diagnostics.IntensityOnobjects_FiniteCount, ...
    r.Diagnostics.IntensityOnobjects_FiniteCount);
c.IncludeDiagnostics = true;
debug = farmWorkflow1Objects(c);
verifyEqual(t,debug.Measurements.IntensityOnobjects_FiniteCount,60);
verifyEqual(t,debug.Measurements.IntensityOnobjects_Mean,r.Measurements.IntensityOnobjects_Mean);
verifyEqual(t,debug.Diagnostics,r.Diagnostics);
verifyEqual(t,width(debug.Measurements)-width(r.Measurements),20);
end

function testWorkflow1SetupMeasurementRequests(t)
here = fileparts(mfilename('fullpath')); repo = fileparts(fileparts(here));
c = struct('Frames',1,'Supports',{{'objects'}},'GeometryOptions',struct(), ...
    'ObjectLoader',@(~)true(4,5,3),'ObjectInputType','mask','LocalInertia',false, ...
    'RepositoryRoot',repo,'OutputRoot',fullfile(repo,'tests', 'data','workflow-results'));
source = farmMakeSource('Format','custom', ...
    'Loader',@(~)reshape(1:60,4,5,3),'Spacing',[2 3 4],'SpacingUnit','nm');
c.Experiment = farmMakeExperiment('DatasetID','custom-requests', ...
    'Frames',1,'Sources',struct('Intensity',source));
c.ObjectProperties = {'BoundingBox'}; c.PhysicalVolume = false;
c.MeasurementOptions = struct();
c.Queries = farmMakeQuery('Name','ChosenSignal', ...
    'Field','Intensity','Support','objects','Statistics',{'Max','Quantiles'}, ...
    'Options',struct('Quantiles',[0 1]));
r = farmWorkflow1Objects(c);
verifyTrue(t,ismember('BoundingBox',r.Measurements.Properties.VariableNames));
verifyFalse(t,any(ismember({'Volume','Centroid','PhysicalVolume', ...
    'ChosenSignal_Mean','ChosenSignal_Std'},r.Measurements.Properties.VariableNames)));
verifyEqual(t,r.Measurements.ChosenSignal_Max,60);
verifyEqual(t,r.Measurements.ChosenSignal_Quantiles,[1 60]);
verifyEqual(t,r.Diagnostics.ChosenSignal_FiniteCount,60);
c.Queries = []; c.PhysicalVolume = true;
r = farmWorkflow1Objects(c);
verifyEqual(t,r.Measurements.PhysicalVolume,60*24);
verifyFalse(t,ismember('Volume',r.Measurements.Properties.VariableNames));
verifyEqual(t,r.Diagnostics.Properties.VariableNames,{'DatasetID','Frame','ObjectID'});
end
