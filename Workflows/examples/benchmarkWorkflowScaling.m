function result=benchmarkWorkflowScaling(c,cases)
%BENCHMARKWORKFLOWSCALING Controlled synthetic voxel/frame/channel/group sweeps.
% No all-time field stack; cases specify Size, Frames, Channels, ObjectCount.
% Measures native objects, scalar sampling and filament measurements separately.
% Fixed foreground occupancy within each size; group count may represent
% disconnected IDs. This isolates ID count, not realistic filament packing.
% Real workflow timing is stored in per-frame results where provided.
if nargin<1, c=experiment4Config; end
if nargin<2
    cases=repmat(struct('Size',[64 64 32],'Frames',1,'Channels',1,'ObjectCount',20),1,5);
    cases(2).Size=[128 128 64]; cases(3).Frames=4; cases(4).Channels=3; cases(5).ObjectCount=100;
end
out=memoworkflow.newRun(c,'benchmark'); rows=cell(numel(cases),1);
for k=1:numel(cases)
    spec=cases(k); dims=spec.Size; n=prod(dims); foreground=min(floor(n/4),max(1000,spec.ObjectCount));
    labels=zeros(dims); index=(1:foreground)';
    labels(index)=mod(index-1,spec.ObjectCount)+1; % Same occupied sites across group counts.
    timer=tic; measurementSeconds=0; sampleSeconds=0; filamentSeconds=0;
    for frame=1:spec.Frames
        objects=objectgeometry.objects.prepareObjects(labels,struct('InputType','labels','Frame',frame));
        start=tic; objectgeometry.objects.measureObjects(objects,{'Volume','Centroid'}); measurementSeconds=measurementSeconds+toc(start);
        start=tic; objectgeometry.centerlines.measureFilaments(objects,{'Directors','Lengths'}); filamentSeconds=filamentSeconds+toc(start);
        for channel=1:spec.Channels
            field=ones(dims)*channel;
            start=tic; objectrelativeprofiles.fieldSampling.queryField(field,objects,{'Mean','Sum'}); sampleSeconds=sampleSeconds+toc(start);
        end
    end
    memory=whos('labels','field');
    rows{k}=table(n,spec.Frames,spec.Channels,spec.ObjectCount,foreground,measurementSeconds,filamentSeconds,sampleSeconds,toc(timer), ...
        sum([memory.bytes]),'VariableNames',{'VoxelCount','Frames','Channels','Groups','ForegroundVoxels','ObjectMeasurementSeconds', ...
        'FilamentMeasurementSeconds','SamplingSeconds','TotalSeconds','RetainedArrayBytes'});
end
result=struct('Directory',out,'Timings',vertcat(rows{:}),'Cases',cases, ...
    'MemoryMeaning','Retained arrays only; not peak memory','Method','Synthetic disconnected label groups; not real filament shape scaling');
memoworkflow.saveNew(fullfile(out,'benchmark.mat'),result);
disp(result.Timings);
end
