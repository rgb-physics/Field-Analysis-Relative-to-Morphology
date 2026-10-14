function manifest=workflow1Objects(c)
%WORKFLOW1OBJECTS User-selected supports and same-frame fields.
if nargin<1, c=experiment4Config; end
out=memoworkflow.newRun(c,'workflow1'); tables=cell(numel(c.Frames),1);
for k=1:numel(c.Frames)
    frame=c.Frames(k); timer=tic;
    intensity=memoworkflow.intensity(c,frame,'560');
    [objects,mask]=memoworkflow.objects(c,frame,size(intensity));
    properties=objectgeometry.objects.measureObjects(objects,{'Volume','Centroid'});
    properties.PhysicalVolume=properties.Volume*prod(c.Spacing);
    properties=memoworkflow.setColumnUnit(properties,'PhysicalVolume',[c.SpacingUnit '^3']);
    distance=bwdist(~logical(mask));
    fields=struct('Intensity',intensity,'InteriorDistanceVoxels',distance);
    supports=struct('objects',objects); geometry=struct;
    for s=1:numel(c.Supports)
        name=c.Supports{s};
        if ~strcmp(name,'objects')
            geometry.(name)=objectgeometry.objects.generateGeometry(objects,name,struct('Sigma',c.GeometrySigma));
            supports.(name)=geometry.(name);
        end
        queries(2*s-1)=struct('Name',['IntensityOn' name],'Support',name,'Statistics',{{'Mean','Sum','Std'}},'Field','Intensity'); %#ok<AGROW>
        queries(2*s)=struct('Name',['InteriorDistanceOn' name],'Support',name,'Statistics',{{'Mean','Max'}},'Field','InteriorDistanceVoxels'); %#ok<AGROW>
    end
    results=objectrelativeprofiles.fieldSampling.queryFrame(fields,supports,queries);
    properties=objectrelativeprofiles.fieldSampling.attachResults(properties,results);
    payload=struct('Measurements',properties,'Geometry',geometry,'Seconds',toc(timer));
    if c.LocalInertia
        if isfield(geometry,'skeleton')
            indices=unique(vertcat(geometry.skeleton.Records.Indices));
        else
            xyz=round(properties.Centroid);
            indices=sub2ind(size(mask),xyz(:,2),xyz(:,1),xyz(:,3));
        end
        opts=c.InertiaOptions; opts.Spacing=c.Spacing; opts.SpacingUnit='um';
        payload.LocalInertia=objectgeometry.objects.localInertia(logical(mask),indices,opts);
    end
    memoworkflow.saveNew(fullfile(out,sprintf('frame%03i.mat',frame)),payload);
    tables{k}=properties;
end
manifest=struct('Directory',out,'Measurements',objectgeometry.objects.concatenateMeasurements(tables));
memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 1 outputs: %s\n',out);
end
