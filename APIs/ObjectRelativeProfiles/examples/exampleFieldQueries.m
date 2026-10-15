%% Same-frame querying, scalar components and named custom operations
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this saved script.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

folder = fileparts(mfilename('fullpath')); root = fullfile(folder,'..','..','..');
for api = {'ObjectRelativeProfiles','ObjectGeometry','SharedUtilities'}
    addpath(fullfile(root,'APIs',api{1},'src'));
end
[y,x,z] = ndgrid(1:20,1:24,1:10);
mask = (x-12).^2+(y-10).^2+(z-5).^2<16;
objects = farmPrepareObjects(mask,struct('DatasetID','example','Frame',1));
intensity = 100+2*x+3*y;
[gradients,distance] = farmObjectDistanceGradients(mask,struct('Sigma',1));
supports = struct('objects',objects);
supports.boundary = farmGenerateGeometry(objects,'boundary',struct('Sigma',0));
fields = struct('Intensity',intensity,'DistanceMagnitude',abs(distance),'GradientX',gradients(:,:,:,1));
q(1) = struct('Name','Intensity_Object','Support','objects','Statistics',{{'Mean','Variance','Max'}},'Field','Intensity');
q(2) = struct('Name','Distance_Boundary','Support','boundary','Statistics',{{'Mean','Median'}},'Field','DistanceMagnitude');
q(3) = struct('Name','GradientX_Object','Support','objects','Statistics',{{'Mean','Std'}},'Field','GradientX');
results = farmQueryFrame(fields,supports,q);
properties = farmMeasureObjects(objects,{'Volume','Centroid'});
properties = farmAttachResults(properties,results);
disp(properties)

%% A custom composition receives selected values from multiple fields
operation = @(f) f.Intensity.*f.GradientX;
product = farmQueryField(fields,objects,{'Mean','Max'}, ...
    struct('FieldName','IntensityGradient','SampleOperation',operation, ...
    'CustomOperations',struct('MeanAbsolute',@(v) mean(abs(v)))));
properties = farmAttachResults(properties,product);

%% One-frame-at-a-time batching: callbacks load/generate only the requested XYZ
specs(1) = struct('Name','Intensity','Loader',@(frame) intensity+frame);
specs(2) = struct('Name','DistanceMagnitude','Loader',@(frame) abs(distance));
% In production, use file-loading functions that select one channel/time.
% These demo closures capture only ONE example frame, never an XYZT dataset.
supportLoader = @(frame,fields) struct('objects',mask);
batchQuery = struct('Name','Intensity_Object','Support','objects', ...
    'Statistics',{{'Mean','Std'}},'Field','Intensity');
outputDirectory = tempname;
manifest = farmRunFieldBatch([1 2 3], ...
    specs,supportLoader,batchQuery, ...
    struct('DatasetID','example','OutputDirectory',outputDirectory,'RetainTables',true));
combined = farmConcatenateResults(manifest.Tables);
disp(combined); fprintf('Incremental result files: %s\n',outputDirectory);
